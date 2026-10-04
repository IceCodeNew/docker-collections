import { type ChildProcess, spawn } from "node:child_process";
import process from "node:process";

const children = new Map<ChildProcess, Promise<number>>();
const stopped = Promise.withResolvers<number>();
const onStop = () => stopped.resolve(0);
process.on("SIGTERM", onStop);
process.on("SIGINT", onStop);

function start(
  command: string,
  args: string[],
  env = process.env,
): Promise<number> {
  const child = spawn(command, args, {
    env,
    stdio: ["ignore", "inherit", "inherit"],
  });
  const status = new Promise<number>((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code) => {
      children.delete(child);
      resolve(code || 1);
    });
  });
  children.set(child, status);
  return status;
}

function signalChildren(signal: NodeJS.Signals) {
  for (const child of children.keys()) child.kill(signal);
}

let exitCode = 1;
try {
  const serverEnv = { ...process.env };
  delete serverEnv.TUNNEL_TOKEN;
  delete serverEnv.TUNNEL_TOKEN_FILE;
  const serverStatus = start(process.argv[2], process.argv.slice(3), serverEnv);
  const tunnelArgs = ["tunnel", "--no-autoupdate"];
  if (process.env.TUNNEL_TOKEN || process.env.TUNNEL_TOKEN_FILE) {
    tunnelArgs.push("run");
  } else {
    const port = process.env.PORT || "3000";
    tunnelArgs.push("--url", `http://127.0.0.1:${port}`);
  }
  const tunnelStatus = start("cloudflared", tunnelArgs);
  exitCode = await Promise.race([stopped.promise, serverStatus, tunnelStatus]);
} catch (error) {
  console.error("Cannot start Stronghold-Protocol or cloudflared:", error);
} finally {
  signalChildren("SIGTERM");
  const timeout = setTimeout(() => signalChildren("SIGKILL"), 5000);
  await Promise.allSettled(children.values());
  clearTimeout(timeout);
  process.off("SIGTERM", onStop);
  process.off("SIGINT", onStop);
}
process.exit(exitCode);
