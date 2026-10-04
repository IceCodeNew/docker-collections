const children = new Set<Deno.ChildProcess>();
const stopped = Promise.withResolvers<number>();
const onStop = () => stopped.resolve(0);
Deno.addSignalListener("SIGTERM", onStop);
Deno.addSignalListener("SIGINT", onStop);

function start(
  command: string,
  args: string[],
  env: Record<string, string> = {},
): Promise<Deno.CommandStatus> {
  const child = new Deno.Command(command, {
    args,
    env,
    stdin: "null",
    stdout: "inherit",
    stderr: "inherit",
  }).spawn();
  children.add(child);
  return child.status.then((status) => {
    children.delete(child);
    return status;
  });
}

function signalChildren(signal: Deno.Signal) {
  for (const child of children) {
    try {
      child.kill(signal);
    } catch (error) {
      // A child can exit before Deno receives its status.
      if (!(error instanceof Deno.errors.NotFound)) throw error;
    }
  }
}

let exitCode = 1;
try {
  const serverStatus = start(Deno.execPath(), [
    "run",
    "--cached-only",
    "--no-lock",
    "--node-modules-dir=manual",
    "--allow-net",
    "--allow-read",
    "--allow-env",
    "--allow-sys",
    ...Deno.args,
  ], { TUNNEL_TOKEN: "", TUNNEL_TOKEN_FILE: "" });
  const tunnelArgs = ["tunnel", "--no-autoupdate"];
  if (Deno.env.get("TUNNEL_TOKEN") || Deno.env.get("TUNNEL_TOKEN_FILE")) {
    tunnelArgs.push("run");
  } else {
    const port = Deno.env.get("PORT") || "3000";
    tunnelArgs.push("--url", `http://127.0.0.1:${port}`);
  }
  const tunnelStatus = start("cloudflared", tunnelArgs);
  exitCode = await Promise.race([
    stopped.promise,
    serverStatus.then((status) => status.code || 1),
    tunnelStatus.then((status) => status.code || 1),
  ]);
} catch (error) {
  console.error("Cannot start Stronghold-Protocol or cloudflared:", error);
} finally {
  signalChildren("SIGTERM");
  const timeout = setTimeout(() => signalChildren("SIGKILL"), 5000);
  await Promise.all([...children].map((child) => child.status));
  clearTimeout(timeout);
  Deno.removeSignalListener("SIGTERM", onStop);
  Deno.removeSignalListener("SIGINT", onStop);
}
Deno.exit(exitCode);
