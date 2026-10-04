try {
  const port = Deno.env.get("PORT") || "3000";
  const response = await fetch(`http://127.0.0.1:${port}/healthz`, {
    signal: AbortSignal.timeout(3000),
  });
  await response.body?.cancel();
  Deno.exit(response.ok ? 0 : 1);
} catch {
  Deno.exit(1);
}
