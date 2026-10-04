import { readFile, stat } from "node:fs/promises";

const report = JSON.parse(await readFile(".cache/assets-report.json", "utf8"));
if (report.fontErrors.length !== 0 || report.totals.error !== 0) {
  throw new Error("Asset download failed: check .cache/assets-report.json.");
}

async function verify(value: unknown): Promise<void> {
  if (typeof value === "string" && /^\/(assets|fonts)\//.test(value)) {
    const file = `public${value}`;
    const metadata = await stat(file);
    if (!metadata.isFile() || metadata.size === 0) {
      throw new Error(`Asset file is empty or invalid: ${file}.`);
    }
  } else if (value !== null && typeof value === "object") {
    for (const entry of Object.values(value)) await verify(entry);
  }
}
await verify(JSON.parse(await readFile("data/assets.json", "utf8")));
