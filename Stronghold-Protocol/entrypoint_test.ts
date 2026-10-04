import assert from "node:assert/strict";
import { spawn as spawnProcess } from "node:child_process";
import { once } from "node:events";
import {
  mkdir,
  mkdtemp,
  readdir,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import { createServer } from "node:net";
import process from "node:process";
import { createInterface } from "node:readline";
import { text } from "node:stream/consumers";
import test from "node:test";
import { fileURLToPath } from "node:url";

const script = (name: string) =>
  fileURLToPath(new URL(`./${name}.ts`, import.meta.url));
const deadlineMs = 10_000;
// Alternate engines can supply their launcher arguments without changing tests.
const runtimeArgs: string[] = JSON.parse(process.env.TEST_RUNTIME_ARGS || "[]");
assert.ok(
  Array.isArray(runtimeArgs) &&
    runtimeArgs.every((arg) => typeof arg === "string"),
);
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
import { writeSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { createServer } from "node:http";
import process from "node:process";
const args = process.argv.slice(2);
const role = args[0] === "server" ? "server" : "tunnel";
const emit = (event, extra = {}) => writeSync(1, JSON.stringify({
  fixture: true, role, event, pid: process.pid, ...extra,
}) + "\\n");
const token = process.env.TUNNEL_TOKEN ?? "";
const tokenFile = process.env.TUNNEL_TOKEN_FILE ?? "";
const received = { args, token, tokenFile,
  fileToken: role === "tunnel" && tokenFile
    ? (await readFile(tokenFile, "utf8")).trim() : "" };
const server = createServer((request, response) => {
  if (request.url === "/healthz") {
    response.writeHead(Number(process.env.FIXTURE_HTTP_STATUS || "200"), {
      "content-type": "application/json",
    });
    response.end(JSON.stringify(received));
  } else {
    response.writeHead(404); response.end("not found");
  }
});
process.on("SIGTERM", () => {
  emit("stopped", { signal: "SIGTERM" });
  server.close(() => process.exit(0));
  server.closeAllConnections();
});
process.on("SIGUSR1", () => process.exit(Number(process.env.FIXTURE_EXIT_CODE || "0")));
await new Promise((resolve, reject) => {
  server.once("error", reject);
  server.listen(role === "server" ? Number(process.env.PORT || "3000") : 0,
    "127.0.0.1", resolve);
});
// Ready means both the socket and signal handlers are installed.
emit("ready", { port: server.address().port });
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
function hasCode(error: unknown, code: string) {
  return error instanceof Error && "code" in error && error.code === code;
}
function kill(pid: number, signal: NodeJS.Signals) {
  try {
    process.kill(pid, signal);
  } catch (error) {
    if (!hasCode(error, "ESRCH")) throw error;
  }
}
async function unusedPort() {
  const listener = createServer();
  listener.listen(0, "127.0.0.1");
  await bounded(once(listener, "listening"));
  try {
    const address = listener.address();
    assert.ok(address && typeof address !== "string");
    return address.port;
  } finally {
    await new Promise<void>((resolve, reject) => {
      listener.close((error) => error ? reject(error) : resolve());
    });
  }
}
async function pids(fixtureScript: string) {
  const result: number[] = [];
  for (const name of await readdir("/proc")) {
    if (!/^\d+$/.test(name)) continue;
    try {
      if (
        (await readFile(`/proc/${name}/cmdline`, "utf8")).split("\0")
          .includes(fixtureScript)
      ) {
        result.push(Number(name));
      }
    } catch (error) {
      if (!hasCode(error, "ENOENT") && !hasCode(error, "ESRCH")) throw error;
    }
  }
  return result;
}
function spawn(cwd: string, args: string[], env: Record<string, string> = {}) {
  const child = spawnProcess(process.execPath, [...runtimeArgs, ...args], {
    cwd,
    env: { NO_COLOR: "1", ...env },
    stdio: ["ignore", "pipe", "pipe"],
  });
  const status = new Promise<
    { code: number | null; signal: NodeJS.Signals | null }
  >((resolve, reject) => {
    child.once("error", reject);
    // close also proves the child and inherited output pipes have closed.
    child.once("close", (code, signal) => resolve({ code, signal }));
  });
  return {
    stdout: child.stdout!,
    stderr: child.stderr!,
    status,
    kill: (signal: NodeJS.Signals) => {
      if (child.exitCode === null && child.signalCode === null) {
        child.kill(signal);
      }
    },
  };
}
async function run(
  cwd: string,
  args: string[],
  env: Record<string, string> = {},
) {
  const child = spawn(cwd, args, env);
  const output = Promise.all([
    child.status,
    text(child.stdout),
    text(child.stderr),
  ])
    .then(([status, stdout, stderr]) => ({ ...status, stdout, stderr }));
  try {
    return await bounded(output);
  } finally {
    child.kill("SIGKILL");
    await bounded(output);
  }
}
function observe(child: ReturnType<typeof spawn>) {
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
      const line of createInterface({ input: child.stdout })
    ) {
      if (!line.startsWith("{")) continue;
      const received = JSON.parse(line);
      if (received.fixture) {
        event(received.role, received.event).resolve(received);
      }
    }
  })();
  const errors = text(child.stderr).then((output) => {
    stderr = output;
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
  const dir = await mkdtemp("/tmp/stronghold-test-");
  const services: Service[] = [], fixtureScript = `${dir}/service.mjs`;
  try {
    await mkdir(`${dir}/bin`);
    await writeFile(fixtureScript, fixtureSource);
    const quote = (s: string) => `'${s.replaceAll("'", "'\\''")}'`;
    const launcher = [process.execPath, ...runtimeArgs, fixtureScript]
      .map(quote).join(" ");
    await writeFile(
      `${dir}/bin/cloudflared`,
      `#!/bin/sh\nexec ${launcher} "$@"\n`,
      { mode: 0o700 },
    );
    await test({
      dir,
      start: (env = {}) => {
        const service = observe(
          spawn(dir, [
            script("entrypoint"),
            process.execPath,
            ...runtimeArgs,
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
        service.child.kill("SIGTERM");
        try {
          await service.status();
        } catch {
          for (const pid of await pids(fixtureScript)) kill(pid, "SIGKILL");
          service.child.kill("SIGKILL");
          await bounded(service.finished);
        }
      }
    } finally {
      for (const pid of await pids(fixtureScript)) kill(pid, "SIGKILL");
      await rm(dir, { recursive: true });
    }
  }
}
const health = (port: number) =>
  fetch(`http://127.0.0.1:${port}/healthz`, {
    signal: AbortSignal.timeout(deadlineMs),
  });

for (const mode of ["quick default", "quick custom", "token", "token file"]) {
  test(`user Given ${mode} configuration When the entrypoint starts Then local server and tunnel receive isolated configuration`, () =>
    withFixture(async (f) => {
      const env: Record<string, string> = {};
      if (mode !== "quick default") env.PORT = String(await unusedPort());
      if (mode === "token") env.TUNNEL_TOKEN = "test-only-token";
      if (mode === "token file") {
        env.TUNNEL_TOKEN_FILE = `${f.dir}/token`;
        await writeFile(
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
  test(`user Given a running server and tunnel When the entrypoint receives ${signal} Then both children terminate and the entrypoint succeeds`, () =>
    withFixture(async (f) => {
      const service = f.start({ PORT: String(await unusedPort()) }),
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
    test(`user Given a running server and tunnel When the ${role} exits with code ${code} Then the entrypoint fails and terminates its remaining child`, () =>
      withFixture(async (f) => {
        const service = f.start({
          PORT: String(await unusedPort()),
          FIXTURE_EXIT_CODE: String(code),
        });
        const server = await service.event("server"),
          tunnel = await service.event("tunnel");
        kill((role === "server" ? server : tunnel).pid, "SIGUSR1");
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
test("user Given no cloudflared executable on PATH When tunnel spawn fails Then the entrypoint fails without leaving its server running", () =>
  withFixture(async (f) => {
    await rm(`${f.dir}/bin/cloudflared`);
    const port = await unusedPort(), service = f.start({ PORT: String(port) });
    assert.equal((await service.status()).code, 1);
    assert.match(service.stderr(), /cloudflared/);
    assert.match(service.stderr(), /ENOENT|No such file/);
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
  test(`user Given ${name} on the local health endpoint When the real healthcheck runs Then it exits with code ${exitCode}`, () =>
    withFixture(async (f) => {
      const port = await unusedPort();
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
      const result = await run(f.dir, [script("healthcheck")], {
        PORT: String(port),
      });
      assert.equal(result.code, exitCode);
      assert.equal(result.stderr, "");
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
      error: /ENOENT|No such file/,
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
  test(`user Given ${scenario.name} When build asset verification runs Then it ${scenario.error ? "rejects" : "accepts"} the resource bundle`, async () => {
    const dir = await mkdtemp("/tmp/stronghold-assets-test-");
    try {
      for (const path of [".cache", "data", "public/assets", "public/fonts"]) {
        await mkdir(`${dir}/${path}`, { recursive: true });
      }
      await writeFile(
        `${dir}/.cache/assets-report.json`,
        JSON.stringify({
          fontErrors: [],
          totals: { error: 0 },
          ...scenario.report,
        }),
      );
      await writeFile(
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
      if (scenario.file === "directory") await mkdir(asset);
      else if (scenario.file !== "missing") {
        await writeFile(asset, "fixture asset");
      }
      await writeFile(
        `${dir}/public/fonts/text.woff2`,
        scenario.file === "empty" ? "" : "fixture font",
      );
      const result = await run(dir, [script("verify-assets")]);
      assert.equal(result.code, scenario.error ? 1 : 0);
      const stderr = result.stderr;
      if (scenario.error) assert.match(stderr, scenario.error);
      else assert.equal(stderr, "");
    } finally {
      await rm(dir, { recursive: true });
    }
  });
}
