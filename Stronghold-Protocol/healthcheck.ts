import process from "node:process";

try {
  const port = process.env.PORT || "3000";
  const response = await fetch(`http://127.0.0.1:${port}/healthz`, {
    signal: AbortSignal.timeout(3000),
  });
  await response.body?.cancel();
  process.exitCode = response.ok ? 0 : 1;
} catch {
  process.exitCode = 1;
}
