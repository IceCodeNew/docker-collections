import assert from "node:assert/strict";
import { createInterface } from "node:readline";
import { Readable } from "node:stream";

const script = (name: string) =>
  new URL(`./${name}.ts`, import.meta.url).pathname;
const deadlineMs = 10_000;
type Role = "server" | "tunnel";
type Event = {
  role: Role;
  event: string;
  pid: number;
  port: number;
  signal?: string;
};

// The cloudflared CLI fake records tunnel argv/env and runs real loopback
// services without creating a public tunnel.
const fixtureSource = `
const role = Deno.args[0] === "server" ? "server" : "tunnel";
const emit = (event, extra = {}) => Deno.stdout.writeSync(new TextEncoder().encode(JSON.stringify({
  fixture: true, role, event, pid: Deno.pid, ...extra,
}) + "\\n"));
const token = Deno.env.get("TUNNEL_TOKEN") ?? "";
const tokenFile = Deno.env.get("TUNNEL_TOKEN_FILE") ?? "";
const received = { args: Deno.args, token, tokenFile,
  fileToken: role === "tunnel" && tokenFile
    ? (await Deno.readTextFile(tokenFile)).trim() : "" };
const server = Deno.serve({ hostname: "127.0.0.1",
  port: role === "server" ? Number(Deno.env.get("PORT") || "3000") : 0,
  onListen() {},
}, (request) => new URL(request.url).pathname === "/healthz"
  ? Response.json(received, { status: Number(Deno.env.get("FIXTURE_HTTP_STATUS") || "200") })
  : new Response("not found", { status: 404 }));
Deno.addSignalListener("SIGTERM", async () => {
  emit("stopped", { signal: "SIGTERM" }); await server.shutdown(); Deno.exit(0);
});
Deno.addSignalListener("SIGUSR1", () => Deno.exit(Number(Deno.env.get("FIXTURE_EXIT_CODE") || "0")));
// Ready means both the socket and signal handlers are installed.
emit("ready", { port: server.addr.port });
await server.finished;
`;

async function bounded<T>(promise: Promise<T>): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_, reject) => {
        timer = setTimeout(
          () => reject(new Error("Subprocess/event deadline exceeded")),
          deadlineMs,
        );
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}
function kill(pid: number, signal: Deno.Signal) {
  try {
    Deno.kill(pid, signal);
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) throw error;
  }
}
function unusedPort() {
  const listener = Deno.listen({ hostname: "127.0.0.1", port: 0 });
  try {
    return (listener.addr as Deno.NetAddr).port;
  } finally {
    listener.close();
  }
}
async function pids(fixtureScript: string) {
  const result: number[] = [];
  for await (const entry of Deno.readDir("/proc")) {
    if (!/^\d+$/.test(entry.name)) continue;
    try {
      if (
        (await Deno.readTextFile(`/proc/${entry.name}/cmdline`)).split("\0")
          .includes(fixtureScript)
      ) {
        result.push(Number(entry.name));
      }
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) throw error;
    }
  }
  return result;
}
function spawn(cwd: string, args: string[], env: Record<string, string> = {}) {
  return new Deno.Command(Deno.execPath(), {
    args: ["run", "--no-config", "--no-lock", ...args],
    cwd,
    clearEnv: true,
    env: {
      DENO_DIR: `${cwd}/deno-cache`,
      DENO_NO_UPDATE_CHECK: "1",
      NO_COLOR: "1",
      ...env,
    },
    stdin: "null",
    stdout: "piped",
    stderr: "piped",
  }).spawn();
}
async function run(
  cwd: string,
  args: string[],
  env: Record<string, string> = {},
) {
  const child = spawn(cwd, args, env), output = child.output();
  try {
    return await bounded(output);
  } finally {
    kill(child.pid, "SIGKILL");
    await bounded(output);
  }
}
function observe(child: Deno.ChildProcess) {
  const events = new Map<
    string,
    ReturnType<typeof Promise.withResolvers<Event>>
  >();
  const event = (role: Role, name: string) => {
    const key = `${role}:${name}`;
    if (!events.has(key)) events.set(key, Promise.withResolvers<Event>());
    return events.get(key)!;
  };
  let stderr = "";
  const stdout = (async () => {
    for await (
      const line of createInterface({ input: Readable.fromWeb(child.stdout) })
    ) {
      if (!line.startsWith("{")) continue;
      const received = JSON.parse(line);
      if (received.fixture) {
        event(received.role, received.event).resolve(received);
      }
    }
  })();
  const errors = child.stderr.text().then((text) => {
    stderr = text;
  });
  const finished = Promise.all([child.status, stdout, errors]).then((
    [status],
  ) => status);
  return {
    child,
    finished,
    stderr: () => stderr,
    status: () => bounded(finished),
    event: (role: Role, name = "ready") =>
      bounded(Promise.race([
        event(role, name).promise,
        finished.then(() => {
          throw new Error(`Missing ${role} ${name}: ${stderr}`);
        }),
      ])),
  };
}
type Service = ReturnType<typeof observe>;
async function withFixture(
  test: (
    f: {
      dir: string;
      start: (env?: Record<string, string>) => Service;
      stopped: (port: number) => Promise<void>;
    },
  ) => Promise<void>,
) {
  const dir = await Deno.makeTempDir({
    dir: "/tmp",
    prefix: "stronghold-test-",
  });
  const services: Service[] = [], fixtureScript = `${dir}/service.ts`;
  try {
    await Deno.mkdir(`${dir}/bin`);
    await Deno.writeTextFile(fixtureScript, fixtureSource);
    const quote = (s: string) => `'${s.replaceAll("'", "'\\''")}'`;
    await Deno.writeTextFile(
      `${dir}/bin/cloudflared`,
      `#!/bin/sh\nexec ${
        quote(Deno.execPath())
      } run --no-config --no-lock --allow-net --allow-env --allow-read ${
        quote(fixtureScript)
      } "$@"\n`,
      { mode: 0o700 },
    );
    await test({
      dir,
      start: (env = {}) => {
        const service = observe(
          spawn(dir, [
            "-A",
            script("entrypoint"),
            fixtureScript,
            "server",
            "user-argument",
          ], { PATH: `${dir}/bin`, ...env }),
        );
        services.push(service);
        return service;
      },
      stopped: async (port) => {
        assert.deepEqual(
          await pids(fixtureScript),
          [],
          "no surviving children",
        );
        await assert.rejects(() => health(port), TypeError);
      },
    });
  } finally {
    try {
      for (const service of services) {
        kill(service.child.pid, "SIGTERM");
        try {
          await service.status();
        } catch {
          for (const pid of await pids(fixtureScript)) kill(pid, "SIGKILL");
          kill(service.child.pid, "SIGKILL");
          await bounded(service.finished);
        }
      }
    } finally {
      for (const pid of await pids(fixtureScript)) kill(pid, "SIGKILL");
      await Deno.remove(dir, { recursive: true });
    }
  }
}
const health = (port: number) =>
  fetch(`http://127.0.0.1:${port}/healthz`, {
    signal: AbortSignal.timeout(deadlineMs),
  });

for (const mode of ["quick default", "quick custom", "token", "token file"]) {
  Deno.test(`user Given ${mode} configuration When the entrypoint starts Then local server and tunnel receive isolated configuration`, () =>
    withFixture(async (f) => {
      const env: Record<string, string> = {};
      if (mode !== "quick default") env.PORT = String(unusedPort());
      if (mode === "token") env.TUNNEL_TOKEN = "test-only-token";
      if (mode === "token file") {
        env.TUNNEL_TOKEN_FILE = `${f.dir}/token`;
        await Deno.writeTextFile(
          env.TUNNEL_TOKEN_FILE,
          "test-only-file-token\n",
        );
      }
      const service = f.start(env),
        server = await service.event("server"),
        tunnel = await service.event("tunnel");
      // Query real HTTP in each child to inspect the CLI/env delivery boundary.
      const response = await health(tunnel.port),
        received = await response.json();
      assert.equal(response.status, 200);
      assert.deepEqual(
        received.args,
        mode.startsWith("quick")
          ? [
            "tunnel",
            "--no-autoupdate",
            "--url",
            `http://127.0.0.1:${env.PORT || "3000"}`,
          ]
          : ["tunnel", "--no-autoupdate", "run"],
      );
      assert.equal(received.token, env.TUNNEL_TOKEN || "");
      assert.equal(received.tokenFile, env.TUNNEL_TOKEN_FILE || "");
      assert.equal(
        received.fileToken,
        mode === "token file" ? "test-only-file-token" : "",
      );
      assert.equal(server.port, Number(env.PORT || "3000"));
      const serverResponse = await health(server.port),
        serverReceived = await serverResponse.json();
      assert.equal(serverResponse.status, 200);
      assert.deepEqual(serverReceived.args, ["server", "user-argument"]);
      assert.equal(serverReceived.token, "", "server must not inherit token");
      assert.equal(
        serverReceived.tokenFile,
        "",
        "server must not inherit token file",
      );
    }));
}
for (const signal of ["SIGTERM", "SIGINT"] as const) {
  Deno.test(`user Given a running server and tunnel When the entrypoint receives ${signal} Then both children terminate and the entrypoint succeeds`, () =>
    withFixture(async (f) => {
      const service = f.start({ PORT: String(unusedPort()) }),
        server = await service.event("server");
      await service.event("tunnel");
      service.child.kill(signal);
      assert.equal((await service.status()).code, 0);
      for (const role of ["server", "tunnel"] as const) {
        assert.equal((await service.event(role, "stopped")).signal, "SIGTERM");
      }
      await f.stopped(server.port);
    }));
}
for (const role of ["server", "tunnel"] as const) {
  for (const code of [0, 23]) {
    Deno.test(`user Given a running server and tunnel When the ${role} exits with code ${code} Then the entrypoint fails and terminates its remaining child`, () =>
      withFixture(async (f) => {
        const service = f.start({
          PORT: String(unusedPort()),
          FIXTURE_EXIT_CODE: String(code),
        });
        const server = await service.event("server"),
          tunnel = await service.event("tunnel");
        Deno.kill((role === "server" ? server : tunnel).pid, "SIGUSR1");
        assert.equal((await service.status()).code, code || 1);
        assert.equal(
          (await service.event(
            role === "server" ? "tunnel" : "server",
            "stopped",
          )).signal,
          "SIGTERM",
        );
        await f.stopped(server.port);
      }));
  }
}
Deno.test("user Given no cloudflared executable on PATH When tunnel spawn throws Then the entrypoint fails without leaving its server running", () =>
  withFixture(async (f) => {
    await Deno.remove(`${f.dir}/bin/cloudflared`);
    const port = unusedPort(), service = f.start({ PORT: String(port) });
    assert.equal((await service.status()).code, 1);
    assert.match(service.stderr(), /cloudflared/);
    assert.match(service.stderr(), /NotFound|No such file/);
    // Failure can precede server readiness; closed inherited pipes + /proc and
    // refused HTTP prove cleanup even in that startup race.
    await f.stopped(port);
  }));
for (
  const [name, httpStatus, exitCode] of [["successful HTTP", 200, 0], [
    "failed HTTP",
    503,
    1,
  ], [
    "refused connection",
    undefined,
    1,
  ]] as const
) {
  Deno.test(`user Given ${name} on the local health endpoint When the real healthcheck runs Then it exits with code ${exitCode}`, () =>
    withFixture(async (f) => {
      const port = unusedPort();
      if (httpStatus !== undefined) {
        const service = f.start({
          PORT: String(port),
          FIXTURE_HTTP_STATUS: String(httpStatus),
        });
        await service.event("server");
        await service.event("tunnel");
        const response = await health(port);
        assert.equal(response.status, httpStatus);
        await response.body?.cancel();
      }
      const result = await run(f.dir, [
        "--allow-net",
        "--allow-env=PORT",
        script("healthcheck"),
      ], { PORT: String(port) });
      assert.equal(result.code, exitCode);
      assert.equal(new TextDecoder().decode(result.stderr), "");
    }));
}

// Build report success alone is insufficient: nested manifest resources must
// exist as nonempty files. The shipped validator runs against real directories.
for (
  const scenario of [
    { name: "valid nested assets and fonts", report: {}, error: undefined },
    {
      name: "font errors",
      report: { fontErrors: ["font"] },
      error: /assets-report\.json/,
    },
    {
      name: "a nonzero error total",
      report: { totals: { error: 1 } },
      error: /assets-report\.json/,
    },
    {
      name: "a missing nested asset",
      report: {},
      file: "missing",
      error: /NotFound|No such file/,
    },
    {
      name: "an empty nested font",
      report: {},
      file: "empty",
      error: /empty or invalid/,
    },
    {
      name: "a directory instead of an asset",
      report: {},
      file: "directory",
      error: /empty or invalid/,
    },
  ]
) {
  Deno.test(`user Given ${scenario.name} When build asset verification runs Then it ${scenario.error ? "rejects" : "accepts"} the resource bundle`, async () => {
    const dir = await Deno.makeTempDir({
      dir: "/tmp",
      prefix: "stronghold-assets-test-",
    });
    try {
      for (const path of [".cache", "data", "public/assets", "public/fonts"]) {
        await Deno.mkdir(`${dir}/${path}`, { recursive: true });
      }
      await Deno.writeTextFile(
        `${dir}/.cache/assets-report.json`,
        JSON.stringify({
          fontErrors: [],
          totals: { error: 0 },
          ...scenario.report,
        }),
      );
      await Deno.writeTextFile(
        `${dir}/data/assets.json`,
        JSON.stringify({
          nested: [{
            image: "/assets/icon.svg",
            fonts: { regular: "/fonts/text.woff2" },
          }],
          external: "https://example.invalid/image.svg",
          metadata: null,
        }),
      );
      const asset = `${dir}/public/assets/icon.svg`;
      if (scenario.file === "directory") await Deno.mkdir(asset);
      else if (scenario.file !== "missing") {
        await Deno.writeTextFile(asset, "fixture asset");
      }
      await Deno.writeTextFile(
        `${dir}/public/fonts/text.woff2`,
        scenario.file === "empty" ? "" : "fixture font",
      );
      const result = await run(dir, ["--allow-read", script("verify-assets")]);
      assert.equal(result.code, scenario.error ? 1 : 0);
      const stderr = new TextDecoder().decode(result.stderr);
      if (scenario.error) assert.match(stderr, scenario.error);
      else assert.equal(stderr, "");
    } finally {
      await Deno.remove(dir, { recursive: true });
    }
  });
}
