"""Seed a cold worktree from the primary checkout without overwriting files."""

import os
import shutil
import subprocess  # nosec B404 - Local tools on known checkout paths.
from pathlib import Path


def git(*args):
    return subprocess.check_output(
        ["git", *args]
    )  # nosec B603 B607 - Git path arguments.


def main():
    target = Path(git("rev-parse", "--show-toplevel").decode().strip()).resolve()
    primary = Path(git("worktree", "list", "--porcelain").decode().splitlines()[0][9:])
    if git("-C", str(primary), "rev-parse", "--is-bare-repository").strip() == b"true":
        trunk = git("show", "refs/stax/trunk").decode().strip()
        for entry in git("worktree", "list", "--porcelain").decode().split("\n\n"):
            lines = entry.splitlines()
            if f"branch refs/heads/{trunk}" in lines:
                primary = Path(lines[0][9:])
                break
        else:
            raise RuntimeError(
                "The bare repository needs a trunk checkout to seed ignored files"
            )
    if primary.resolve() == target:
        return
    # NUL-delimited paths preserve spaces. Copy files, never follow source links;
    # skip existing destinations and any path through a destination symlink.
    files = git(
        "-C",
        str(primary),
        "ls-files",
        "--others",
        "--ignored",
        "--exclude-standard",
        "-z",
    )
    for raw in files.split(b"\0"):
        if not raw:
            continue
        relative = Path(os.fsdecode(raw))
        source, destination = primary / relative, target / relative
        if source.is_symlink() or not source.is_file():
            continue
        if any(parent.is_symlink() for parent in source.parents if parent != primary):
            continue
        if destination.exists() or destination.is_symlink():
            continue
        if any(parent.is_symlink() for parent in destination.parents):
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive creation prevents a concurrent setup command being overwritten.
        with destination.open("xb") as output, source.open("rb") as input_file:
            shutil.copyfileobj(input_file, output)
        shutil.copystat(source, destination)


if __name__ == "__main__":
    main()
