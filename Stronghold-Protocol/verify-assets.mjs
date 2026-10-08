import { existsSync } from "node:fs";
import { readFile, stat } from "node:fs/promises";

const imageMode = process.argv.includes("--image");
if (imageMode) {
  if (process.env.FETCH_ASSETS === "0") process.exit(0);
  if (process.env.FETCH_ASSETS !== "1") {
    throw new Error("FETCH_ASSETS must be 0 or 1.");
  }
} else {
  const report = JSON.parse(
    await readFile(".cache/assets-report.json", "utf8"),
  );
  const allowDownloadErrors = process.argv.includes("--allow-download-errors");
  if (
    !allowDownloadErrors &&
    (report.fontErrors.length !== 0 || report.totals.error !== 0)
  ) {
    throw new Error("Asset download failed: check .cache/assets-report.json.");
  }
  if (
    report.orphans?.length ||
    report.pruned?.some((file) => existsSync(`public/assets/${file}`))
  ) {
    throw new Error(
      "Unreferenced assets remain: check .cache/assets-report.json.",
    );
  }
}

let assetCount = 0;
async function verify(value) {
  if (typeof value === "string" && /^\/(assets|fonts)\//.test(value)) {
    if (value.startsWith("/assets/")) assetCount++;
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
if (imageMode && assetCount === 0) {
  throw new Error("No art files are listed in the image manifest.");
}
