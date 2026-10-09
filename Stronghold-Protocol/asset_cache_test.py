"""Cache packaging and source fingerprints; byte verification belongs to upstream."""

import contextlib
import io
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import asset_cache as cache


class CacheTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.upstream = self.root / "upstream"
        self.caches = self.root / "caches"

    def write(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(value if isinstance(value, bytes) else json.dumps(value).encode())

    def test_roundtrip_merges_fonts_and_retains_every_source(self):
        ledger = {}
        for source, repo in cache.SOURCES.items():
            if source == "fonts":
                continue
            rel = f"{source}/keep.png"
            self.write(self.upstream / "public/assets" / rel, source.encode())
            ledger[rel] = {"url": f"https://raw.githubusercontent.com/{repo}/main/keep.png"}
        self.write(self.upstream / ".cache/assets-ledger.json", {"files": ledger})
        self.write(self.upstream / "public/fonts/a.ttf", b"font bytes")
        self.write(self.upstream / "public/fonts/a.woff2", b"converted bytes")
        self.write(self.upstream / "public/fonts/obsolete.ttf", b"obsolete")
        self.write(self.upstream / ".cache/fonts-ledger.json", {"files": {
            "a.ttf": {"url": f"https://raw.githubusercontent.com/{cache.SOURCES['fonts']}/main/a.ttf"},
        }})
        self.write(self.upstream / "data/assets.json", {"fonts": ["/fonts/a.ttf", "/fonts/a.woff2"]})
        self.write(self.upstream / ".cache/gamedata/excel/audio_data.json", b'{"voice":"old"}')
        self.write(self.upstream / ".cache/ark-models/models_data.json", b'{"model":"old"}')
        cache.prune_fonts(self.upstream)
        cache.save(self.upstream, self.caches)
        shutil.rmtree(self.upstream)
        cache.restore(self.upstream, self.caches)
        self.assertFalse((self.caches / "fonts").exists())
        self.assertFalse((self.upstream / "public/fonts/obsolete.ttf").exists())
        self.assertEqual((self.upstream / "public/fonts/a.woff2").read_bytes(), b"converted bytes")
        self.assertEqual((self.upstream / ".cache/gamedata/excel/audio_data.json").read_bytes(), b'{"voice":"old"}')
        self.assertEqual((self.upstream / ".cache/ark-models/models_data.json").read_bytes(), b'{"model":"old"}')
        self.assertEqual(json.loads((self.upstream / ".cache/assets-ledger.json").read_text())["files"], ledger)
        for source in cache.GROUPS:
            self.assertEqual((self.upstream / f"public/assets/{source}/keep.png").read_bytes(), source.encode())

    def test_fingerprint_ignores_commit_metadata_but_tracks_content_and_font_changes(self):
        source = self.root / "source/tools/assets/sources.mjs"
        self.write(source, "\n".join(f"https://raw.githubusercontent.com/{repo}/main/" for repo in cache.SOURCES.values()).encode())
        fingerprints = []
        for commit, font_tree in (("first", "same"), ("second", "same"), ("third", "different")):
            def api(endpoint):
                tree = font_tree if cache.SOURCES["fonts"] in endpoint else "unchanged"
                return {"sha": commit, "commit": {"tree": {"sha": tree}}}
            output = io.StringIO()
            with patch.object(cache, "github_json", side_effect=api), contextlib.redirect_stdout(output):
                cache.revisions(source)
            fingerprints.append(dict(line.split("=") for line in output.getvalue().splitlines()))
        self.assertEqual(fingerprints[0], fingerprints[1])
        self.assertNotEqual(fingerprints[1]["gamedata"], fingerprints[2]["gamedata"])
        self.assertEqual(fingerprints[1]["yuanyan"], fingerprints[2]["yuanyan"])
        snapshot = json.loads((source.parents[2] / ".cache/asset-sources.json").read_text())
        self.assertEqual(snapshot[f"{cache.SOURCES['fonts']}@main"], {"commit": "third", "tree": "different"})


if __name__ == "__main__":
    unittest.main()
