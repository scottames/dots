#!/usr/bin/env python3
"""Check pinned Herdr plugin source metadata against mise binary versions."""

import argparse
import re
import sys
import tomllib
import urllib.error
import urllib.request
from pathlib import Path

PLUGINS = {"herdr-annotate": "rust-lite-v", "plannotator-tui": "v"}
EXTERNAL = Path("home/.chezmoiexternals/herdr.toml.tmpl")
MISE = Path("mise/config.toml")


def read_pin(source):
    pins = re.findall(r"{{-?\s*\$herdrAnnotateRef\s*(:?=.*?)\s*-?}}", source)
    pin = re.fullmatch(r':=\s*"([0-9a-fA-F]{40})"', pins[0]) if len(pins) == 1 else None
    if pin is None:
        raise ValueError("external must declare exactly one 40-hex herdrAnnotateRef")
    return pin[1]


def fetch_metadata(sha, filename):
    if not re.fullmatch(r"[0-9a-fA-F]{40}", sha) or filename not in {
        f"{name}.version" for name in PLUGINS
    }:
        raise ValueError("invalid metadata SHA or filename")
    url = (
        f"https://raw.githubusercontent.com/plannotator/herdr-annotate/{sha}/{filename}"
    )
    # Only HTTPS, with no redirect handler: never follow metadata to another URL.
    opener = urllib.request.OpenerDirector()
    for handler in (
        urllib.request.HTTPSHandler(),
        urllib.request.HTTPDefaultErrorHandler(),
        urllib.request.HTTPErrorProcessor(),
    ):
        opener.add_handler(handler)
    try:
        with opener.open(url, timeout=15) as response:
            data = response.read(129)
            if len(data) > 128:
                raise ValueError(f"malformed {filename} at {sha}: metadata too long")
            return data.decode("ascii").strip()
    except (OSError, urllib.error.URLError, UnicodeError) as error:
        if isinstance(error, urllib.error.HTTPError):
            error.close()
        raise ValueError(f"cannot fetch {filename} at {sha}: {error}") from error


def check(repo_root):
    sha = read_pin((repo_root / EXTERNAL).read_text(encoding="utf-8"))
    with (repo_root / MISE).open("rb") as config:
        tools = tomllib.load(config).get("tools", {})
    for name, prefix in PLUGINS.items():
        key = f"github:plannotator/{name}"
        entry = tools.get(key)
        if not isinstance(entry, dict) or not isinstance(entry.get("version"), str):
            raise ValueError(f"mise {key} must be a table with a string version")
        version = fetch_metadata(sha, f"{name}.version")
        if not re.fullmatch(
            r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version
        ):
            raise ValueError(f"malformed {name}.version at {sha}: expected X.Y.Z")
        expected = prefix + version
        if entry["version"] != expected:
            raise ValueError(
                f"{name} at {sha} requires {expected}; mise pins {entry['version']}"
            )
        print(f"{name}: {expected} matches source {sha}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "repo_root", nargs="?", type=Path, default=Path(__file__).resolve().parents[1]
    )
    args = parser.parse_args()
    try:
        check(args.repo_root)
    except (OSError, ValueError) as error:
        print(f"herdr plugin check failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
