"""Resolve and cache Stronghold's optional assets by external source repository."""

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

SOURCES = {
    "yuanyan": "yuanyan3060/ArknightsGameResource",
    "fexli": "fexli/ArknightsResource",
    "models": "isHarryh/Ark-Models",
    "arkassets": "ArknightsAssets/ArknightsAssets2",
    "fonts": "TimWangZi/The-font-of-Arknights",
    "gamedata": "Kengxxiao/ArknightsGameData",
}
RAW_URL = re.compile(r"https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/")
CDN_URL = re.compile(r"https://cdn\.jsdelivr\.net/gh/([^/]+)/([^/@]+)@([^/]+)/")


def source_for(url):
    match = RAW_URL.search(url) or CDN_URL.search(url)
    if not match:
        return None
    repo = "/".join(match.group(1, 2))
    return next((name for name, value in SOURCES.items() if value == repo), None)


def revisions(source_file):
    refs = sorted(set(RAW_URL.findall(source_file.read_text())))
    if not refs:
        raise ValueError(f"No asset source refs found in {source_file}")
    by_repo = {repo: [] for repo in SOURCES.values()}
    unknown = []
    for owner, repo, branch in refs:
        full_repo = f"{owner}/{repo}"
        if full_repo not in by_repo:
            unknown.append(full_repo)
            continue
        by_repo[full_repo].append(branch)
    if unknown:
        print(f"::warning::New source repositories need cache shards: {', '.join(unknown)}", file=sys.stderr)
        for name in SOURCES:
            print(f"{name}={os.urandom(32).hex()}")
        return
    for name, repo in SOURCES.items():
        resolved = []
        try:
            for branch in by_repo[repo]:
                ref = f"refs/heads/{branch}"
                result = subprocess.run(
                    ["git", "ls-remote", f"https://github.com/{repo}.git", ref],
                    check=True, capture_output=True, text=True, timeout=30,
                )
                fields = result.stdout.strip().split()
                if len(fields) != 2 or fields[1] != ref or not re.fullmatch(r"[0-9a-f]{40}", fields[0]):
                    raise ValueError(f"Cannot resolve {repo}@{branch}")
                resolved.append(f"{branch}={fields[0]}")
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            print(f"::warning::Could not resolve {repo}: {error}; invalidating its cache", file=sys.stderr)
            resolved.append(os.urandom(32).hex())
        fingerprint = hashlib.sha256(("\n".join(resolved) + "\n").encode()).hexdigest()
        print(f"{name}={fingerprint}")


def read_ledger(path):
    if not path.exists():
        return {}
    return json.loads(path.read_text())["files"]


def write_ledger(path, files):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"files": files}))


def copy_files(source, target):
    if not source.exists():
        return
    for file in source.rglob("*"):
        if not file.is_file():
            continue
        dest = target / file.relative_to(source)
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            raise ValueError(f"Asset cache collision: {dest}")
        try:
            os.link(file, dest)
        except OSError:
            shutil.copy2(file, dest)


def restore(upstream, caches):
    merged = {}
    for name in SOURCES:
        shard = caches / name
        copy_files(shard / "assets", upstream / "public/assets")
        if name == "fonts":
            copy_files(shard / "fonts", upstream / "public/fonts")
            if (shard / "fonts-ledger.json").exists():
                target = upstream / ".cache/fonts-ledger.json"
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(shard / "fonts-ledger.json", target)
        if name in ("models", "gamedata"):
            copy_files(shard / "indexes", upstream / ".cache" / ("ark-models" if name == "models" else "gamedata"))
        entries = read_ledger(shard / "assets-ledger.json")
        if merged.keys() & entries.keys():
            raise ValueError(f"Asset cache ledger collision in {name}")
        merged.update(entries)
        if shard.exists():
            print(f"Restored {name}: {len(entries)} assets")
    write_ledger(upstream / ".cache/assets-ledger.json", merged)


def referenced_fonts(value):
    if isinstance(value, str) and value.startswith("/fonts/"):
        yield value.removeprefix("/fonts/")
    elif isinstance(value, dict):
        for item in value.values():
            yield from referenced_fonts(item)
    elif isinstance(value, list):
        for item in value:
            yield from referenced_fonts(item)


def prune_fonts(upstream):
    fonts = upstream / "public/fonts"
    if not fonts.exists():
        return
    keep = set(referenced_fonts(json.loads((upstream / "data/assets.json").read_text())))
    for file in fonts.rglob("*"):
        if file.is_file() and file.relative_to(fonts).as_posix() not in keep:
            file.unlink()


def save(upstream, caches):
    ledger = read_ledger(upstream / ".cache/assets-ledger.json")
    grouped = {name: {} for name in SOURCES}
    for file in (upstream / "public/assets").rglob("*"):
        if not file.is_file():
            continue
        rel = file.relative_to(upstream / "public/assets").as_posix()
        name = source_for(ledger.get(rel, {}).get("url", ""))
        if name is None:
            raise ValueError(f"No known source for {rel}; refusing to cache it")
        grouped[name][rel] = ledger[rel]
    for name in SOURCES:
        shard = caches / name
        shutil.rmtree(shard, ignore_errors=True)
        shard.mkdir(parents=True)
        for rel in grouped[name]:
            file = upstream / "public/assets" / rel
            dest = shard / "assets" / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            try:
                os.link(file, dest)
            except OSError:
                shutil.copy2(file, dest)
        write_ledger(shard / "assets-ledger.json", grouped[name])
        if name == "fonts":
            copy_files(upstream / "public/fonts", shard / "fonts")
            shutil.copy2(upstream / ".cache/fonts-ledger.json", shard / "fonts-ledger.json")
        if name in ("models", "gamedata"):
            folder = "ark-models" if name == "models" else "gamedata"
            copy_files(upstream / ".cache" / folder, shard / "indexes")
        print(f"Prepared {name}: {len(grouped[name])} assets")


if __name__ == "__main__":
    command, *args = sys.argv[1:]
    if command == "revisions" and len(args) == 1:
        revisions(Path(args[0]))
    elif command == "restore" and len(args) == 2:
        restore(Path(args[0]), Path(args[1]))
    elif command == "prune-fonts" and len(args) == 1:
        prune_fonts(Path(args[0]))
    elif command == "save" and len(args) == 2:
        save(Path(args[0]), Path(args[1]))
    else:
        raise SystemExit("Usage: asset_cache.py {revisions|restore|prune-fonts|save} ...")
