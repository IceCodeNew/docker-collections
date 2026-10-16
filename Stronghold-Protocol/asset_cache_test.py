"""Source caches and byte-identical cross-job bundle reconstruction."""

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
        webview = {
            "ui/statistics/achievement-bond-frame.png": {"url": "data:image/png;base64,aW1hZ2U="},
            "ui/statistics/title-mask.svg": {"url": "data:image/svg+xml;base64,PHN2Zy8+"},
            "ui/statistics/fonts.css": {"url": "data:text/css;charset=utf-8,body%7B%7D"},
            "ui/statistics/number-font.woff2": {
                "url": "https://web.hycdn.cn/arknights/webview/assets/fonts/NovecentoWide-Medium.fb69ff.woff2",
            },
        }
        for rel in webview:
            self.write(self.upstream / "public/assets" / rel, b"webview bytes")
        self.write(self.upstream / ".cache/assets-ledger.json", {"files": ledger | webview})
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
        for rel in webview:
            self.assertEqual((self.upstream / "public/assets" / rel).read_bytes(), b"webview bytes")
        self.assertEqual(cache.read_ledger(self.upstream / ".cache/assets-ledger.json"), ledger | webview)
        shutil.rmtree(self.upstream)
        cache.restore(self.upstream, self.caches)
        self.assertFalse((self.upstream / "public/assets/ui/statistics").exists())
        self.assertFalse((self.caches / "fonts").exists())
        self.assertFalse((self.upstream / "public/fonts/obsolete.ttf").exists())
        self.assertEqual((self.upstream / "public/fonts/a.woff2").read_bytes(), b"converted bytes")
        self.assertEqual((self.upstream / ".cache/gamedata/excel/audio_data.json").read_bytes(), b'{"voice":"old"}')
        self.assertEqual((self.upstream / ".cache/ark-models/models_data.json").read_bytes(), b'{"model":"old"}')
        self.assertEqual(json.loads((self.upstream / ".cache/assets-ledger.json").read_text())["files"], ledger)
        for source in cache.GROUPS:
            self.assertEqual((self.upstream / f"public/assets/{source}/keep.png").read_bytes(), source.encode())

    def test_save_rejects_unknown_provenance_even_in_statistics(self):
        rel = "ui/statistics/achievement-bond-frame.png"
        self.write(self.upstream / "public/assets" / rel, b"image")
        for url in ("", "https://example.com/image.png", "data:application/octet-stream;base64,YQ==",
                    "https://web.hycdn.cn.example.com/arknights/webview/assets/image.png",
                    "https://raw.githubusercontent.com/unknown/repo/main/image.png"):
            with self.subTest(url=url):
                self.write(self.upstream / ".cache/assets-ledger.json", {"files": {rel: {"url": url}}})
                with self.assertRaisesRegex(ValueError, "No known source"):
                    cache.save(self.upstream, self.caches)

    def test_bundle_omits_only_unchanged_restored_files_and_reconstructs_exactly(self):
        self.write(self.caches / "yuanyan/assets/stable.png", b"stable")
        self.write(self.caches / "yuanyan/assets/changed.png", b"old")
        self.write(self.caches / "yuanyan/assets/obsolete.png", b"obsolete")
        self.write(self.caches / "gamedata/fonts/a.woff2", b"font")
        self.write(self.caches / "models/assets/unconfirmed.png", b"no key")
        consumer_caches = self.root / "consumer-caches"
        shutil.copytree(self.caches, consumer_caches)
        cache.restore(self.upstream, self.caches)
        # Same-size normalization mutates the local hard link, not the remote cache.
        self.write(self.upstream / "public/assets/changed.png", b"new")
        (self.upstream / "public/assets/obsolete.png").unlink()
        self.write(self.upstream / "public/assets/new.png", b"download")
        self.write(self.upstream / "public/assets/ui/statistics/frame.png", b"webview")
        self.write(self.upstream / "data/assets.json", {"assets": "current manifest"})
        bundle = self.root / "bundle"
        shutil.copytree(self.upstream / "public", bundle / "public")
        shutil.copytree(self.upstream / "data", bundle / "data")
        expected = {p.relative_to(bundle): p.read_bytes() for p in bundle.rglob("*") if p.is_file()}
        keys = {"yuanyan": "exact-art-key", "gamedata": "exact-font-key", "models": ""}
        cache.split_bundle(bundle, self.upstream / ".cache/restored-assets.json", keys)
        self.assertFalse((bundle / "public/assets/stable.png").exists())
        self.assertFalse((bundle / "public/fonts/a.woff2").exists())
        for rel in ("changed.png", "new.png", "ui/statistics/frame.png", "unconfirmed.png"):
            self.assertTrue((bundle / "public/assets" / rel).is_file())
        metadata = json.loads((bundle / "cache-files.json").read_text())
        self.assertEqual(metadata["keys"], {"yuanyan": "exact-art-key", "gamedata": "exact-font-key"})
        cache.hydrate_bundle(bundle, consumer_caches, keys)
        self.assertEqual({p.relative_to(bundle): p.read_bytes() for p in bundle.rglob("*") if p.is_file()}, expected)

    def test_bundle_without_restored_cache_is_self_contained_including_placeholder(self):
        for with_art in (True, False):
            with self.subTest(with_art=with_art):
                bundle = self.root / str(with_art)
                self.write(bundle / "data/assets.json", {"placeholder": not with_art})
                if with_art:
                    self.write(bundle / "public/assets/new.png", b"new art")
                expected = {p.relative_to(bundle): p.read_bytes() for p in bundle.rglob("*") if p.is_file()}
                cache.restore(self.upstream, self.caches)
                cache.split_bundle(bundle, self.upstream / ".cache/restored-assets.json", {})
                self.assertEqual(json.loads((bundle / "cache-files.json").read_text())["keys"], {})
                cache.hydrate_bundle(bundle, self.caches, {})
                self.assertEqual({p.relative_to(bundle): p.read_bytes() for p in bundle.rglob("*") if p.is_file()}, expected)

    def test_bundle_rejects_unavailable_wrong_or_corrupt_cache(self):
        self.write(self.caches / "yuanyan/assets/a.png", b"right")
        cache.restore(self.upstream, self.caches)
        bundle = self.root / "bundle"
        shutil.copytree(self.upstream / "public", bundle / "public")
        cache.split_bundle(bundle, self.upstream / ".cache/restored-assets.json", {"yuanyan": "exact"})
        for restored_keys in ({}, {"yuanyan": "prefix-match"}):
            with self.subTest(keys=restored_keys), self.assertRaisesRegex(ValueError, "Exact asset cache unavailable"):
                cache.hydrate_bundle(bundle, self.caches, restored_keys)
        self.write(self.caches / "yuanyan/assets/a.png", b"wrong")
        with self.assertRaisesRegex(ValueError, "Cached asset missing or changed"):
            cache.hydrate_bundle(bundle, self.caches, {"yuanyan": "exact"})
        (self.caches / "yuanyan/assets/a.png").unlink()
        with self.assertRaisesRegex(ValueError, "Cached asset missing or changed"):
            cache.hydrate_bundle(bundle, self.caches, {"yuanyan": "exact"})
        self.assertFalse((bundle / "public/assets/a.png").exists())

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

    def test_source_outage_invalidates_only_affected_cache(self):
        source = self.root / "source/tools/assets/sources.mjs"
        self.write(source, "\n".join(
            f"https://raw.githubusercontent.com/{repo}/main/" for repo in cache.SOURCES.values()
        ).encode())
        fingerprints = []
        for failed in (False, True):
            def api(endpoint):
                if failed and cache.SOURCES["yuanyan"] in endpoint:
                    raise OSError("unavailable")
                return {"commit": {"tree": {"sha": "unchanged"}}}
            output = io.StringIO()
            with patch.object(cache, "github_json", side_effect=api), \
                    contextlib.redirect_stdout(output), contextlib.redirect_stderr(io.StringIO()):
                cache.revisions(source)
            fingerprints.append(dict(line.split("=") for line in output.getvalue().splitlines()))
        self.assertNotEqual(fingerprints[0]["yuanyan"], fingerprints[1]["yuanyan"])
        for group in cache.GROUPS.keys() - {"yuanyan"}:
            self.assertEqual(fingerprints[0][group], fingerprints[1][group])
        self.write(source, b"https://raw.githubusercontent.com/unknown/repo/main/")
        with patch.object(cache, "github_json", side_effect=OSError("unavailable")):
            with self.assertRaisesRegex(ValueError, "New source repository"):
                cache.revisions(source)


if __name__ == "__main__":
    unittest.main()
