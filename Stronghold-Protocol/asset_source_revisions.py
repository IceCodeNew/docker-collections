"""Fingerprint the Git refs used by Stronghold's external asset sources."""

import hashlib
import re
import subprocess
import sys
from pathlib import Path

SOURCE_URL = re.compile(r"https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/")


def main() -> None:
    source_file = Path(sys.argv[1])
    refs = sorted(set(SOURCE_URL.findall(source_file.read_text())))
    if not refs:
        raise SystemExit(f"No GitHub asset sources found in {source_file}")

    revisions = []
    for owner, repo, branch in refs:
        full_ref = f"refs/heads/{branch}"
        result = subprocess.run(
            ["git", "ls-remote", f"https://github.com/{owner}/{repo}.git", full_ref],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        fields = result.stdout.strip().split()
        if (
            len(fields) != 2
            or fields[1] != full_ref
            or not re.fullmatch(r"[0-9a-f]{40}", fields[0])
        ):
            raise SystemExit(f"Cannot resolve asset source {owner}/{repo}@{branch}")
        revision = f"{owner}/{repo}@{branch}={fields[0]}"
        print(revision, file=sys.stderr)
        revisions.append(revision)

    print(hashlib.sha256(("\n".join(revisions) + "\n").encode()).hexdigest())


if __name__ == "__main__":
    main()
