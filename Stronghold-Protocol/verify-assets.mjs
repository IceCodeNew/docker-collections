import { existsSync } from "node:fs";
import { readFile, stat } from "node:fs/promises";

const report = JSON.parse(await readFile(".cache/assets-report.json", "utf8"));
if (report.fontErrors.length !== 0 || report.totals.error !== 0) {
  throw new Error("Asset download failed: check .cache/assets-report.json.");
}
if (report.orphans?.length || report.pruned?.some((file) => existsSync(`public/assets/${file}`))) {
  throw new Error("Unreferenced assets remain: check .cache/assets-report.json.");
}

async function verify(value) {
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
