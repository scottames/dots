"""Conservative eligibility checks; Stax alone removes eligible checkouts."""

import argparse
import json
import os
import shutil
import subprocess  # nosec B404 - Local Git/Stax and read-only activity probes.
import sys
import time
from pathlib import Path

AGE = 2 * 86400
OPERATIONS = (
    "rebase-merge",
    "rebase-apply",
    "MERGE_HEAD",
    "CHERRY_PICK_HEAD",
    "REVERT_HEAD",
    "BISECT_LOG",
    "sequencer",
)


def run(*args):
    return subprocess.run(  # nosec B603 - Explicit argv, never a shell.
        args,
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


def output(*args):
    result = run(*args)
    if result.returncode:
        raise RuntimeError(
            result.stderr.strip() or f"{args[0]} exited {result.returncode}"
        )
    return result.stdout


def inventory():
    entries = []
    for block in output("git", "worktree", "list", "--porcelain", "-z").split("\0\0"):
        if block:
            entries.append(
                dict(field.partition(" ")[::2] for field in block.split("\0") if field)
            )
    return entries


def process_paths():
    """Inspect current-user process CWDs, including idle terminal shells."""
    if sys.platform == "linux":
        paths = []
        for proc in Path("/proc").iterdir():
            if not proc.name.isdigit():
                continue
            try:
                if proc.stat().st_uid != os.getuid():
                    continue
                # Zombies have no cwd. Other inaccessible processes are unknown.
                state = (proc / "stat").read_text().rsplit(")", 1)[1].split()[0]
                if state == "Z":
                    continue
                paths.append(Path(os.readlink(proc / "cwd")))
            except FileNotFoundError as error:
                if proc.exists():
                    raise RuntimeError(f"cannot inspect process {proc.name}") from error
                continue  # Process exited during the snapshot.
        return paths
    if sys.platform == "darwin":
        result = run("lsof", "-a", "-u", str(os.getuid()), "-d", "cwd", "-Fn")
        if result.returncode or result.stderr:
            raise RuntimeError(
                "lsof could not inspect current-user process directories"
            )
        paths = [
            Path(line[1:])
            for line in result.stdout.splitlines()
            if line.startswith("n/")
        ]
        if not paths:
            raise RuntimeError("lsof returned no process directories")
        return paths
    raise RuntimeError("process activity check supports Linux and macOS only")


def herdr_paths():
    paths = []
    if os.environ.get("HC_TERMINAL_ID"):
        if not shutil.which("herdr-app"):
            raise RuntimeError("Herdr desktop CLI unavailable")
        spaces = json.loads(output("herdr-app", "ls"))["spaces"]
        for space in spaces:
            if space.get("machine") is not None:
                continue
            if space.get("folder"):
                paths.append(Path(space["folder"]))
            for tab in space["tabs"]:
                for terminal in tab["terminals"]:
                    live = json.loads(output("hc", "get", terminal["terminal"]))
                    cwd = (live.get("foreground") or {}).get("cwd") or live.get("cwd")
                    if not cwd:
                        raise RuntimeError("Herdr terminal has no readable cwd")
                    paths.append(Path(cwd))
    # Outside legacy Herdr, its live shells are covered by the process probe.
    if os.environ.get("HERDR_ENV") and not os.environ.get("HC_TERMINAL_ID"):
        panes = json.loads(output("herdr", "pane", "list"))["result"]["panes"]
        for pane in panes:
            if not pane.get("cwd"):
                raise RuntimeError("legacy Herdr pane has no readable cwd")
            paths.append(Path(pane["cwd"]))
    return paths


def activity_reason(path):
    try:
        for active in herdr_paths() + process_paths():
            if not active.is_absolute():
                raise RuntimeError("activity probe returned a relative directory")
            if active.resolve().is_relative_to(path):
                return "open in Herdr or used by a running process"
    except (
        OSError,
        RuntimeError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.TimeoutExpired,
    ) as error:
        return f"activity unknown: {error}"
    return None


def parents():
    result = set()
    for ref in output(
        "git", "for-each-ref", "--format=%(refname)", "refs/branch-metadata/"
    ).splitlines():
        metadata = json.loads(output("git", "show", ref))
        result.add(metadata["parentBranchName"])
    return result


def reason(entry, primary, current, trunk):
    path = Path(entry["worktree"]).resolve()
    if "bare" in entry or path in (primary, current):
        return "primary/current checkout"
    if "locked" in entry:
        return "locked"
    if not path.is_dir() or "prunable" in entry:
        return "missing checkout (handled by bookkeeping prune)"
    branch = entry.get("branch", "").removeprefix("refs/heads/")
    if not branch or branch == trunk:
        return "detached or trunk checkout"
    try:
        admin = Path(
            output("git", "-C", str(path), "rev-parse", "--absolute-git-dir").strip()
        )
        if any((admin / marker).exists() for marker in OPERATIONS):
            return "Git operation in progress"
        if output(
            "git", "-C", str(path), "status", "--porcelain", "--untracked-files=all"
        ):
            return "uncommitted changes"
        if branch in parents():
            return "has tracked children"
        # Conservative age proxy: creation/admin pointers and most recent checkout
        # or branch reflog writes. No new tracking database or hooks are needed.
        stamps = [path / ".git", admin / "gitdir"]
        common = Path(
            output(
                "git", "rev-parse", "--path-format=absolute", "--git-common-dir"
            ).strip()
        )
        stamps += [
            p
            for p in (admin / "logs/HEAD", common / "logs/refs/heads" / branch)
            if p.exists()
        ]
        if time.time() - max(p.stat().st_mtime for p in stamps) < AGE:
            return "younger than two days or recently used by Git"
        integrated = run(
            "git", "merge-base", "--is-ancestor", entry["HEAD"], f"refs/heads/{trunk}"
        )
        if integrated.returncode == 1:
            return "not integrated by ancestry (squash merges need manual review)"
        if integrated.returncode:
            return "integration unknown"
        return activity_reason(path)
    except (
        OSError,
        RuntimeError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.TimeoutExpired,
    ) as error:
        return f"state unknown: {error}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--primary", required=True, type=Path)
    parser.add_argument("--trunk", required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    primary = args.primary.resolve()
    current = Path(output("git", "rev-parse", "--show-toplevel").strip()).resolve()
    candidates = []
    for entry in inventory():
        why = reason(entry, primary, current, args.trunk)
        label = entry.get("branch", entry["worktree"]).removeprefix("refs/heads/")
        print(
            f"Keeping {label}: {why}"
            if why
            else f"Would remove checkout {label}: integrated; older than two days"
        )
        if why is None:
            candidates.append(entry)
    print(
        "Branches and stack metadata retained. Save ignored artifacts before applying."
    )
    if not args.apply:
        return
    for candidate in candidates:
        fresh = next(
            (e for e in inventory() if e["worktree"] == candidate["worktree"]), None
        )
        if (
            not fresh
            or fresh.get("HEAD") != candidate.get("HEAD")
            or fresh.get("branch") != candidate.get("branch")
        ):
            print(f"Keeping {candidate['worktree']}: checkout changed since preview")
            continue
        why = reason(fresh, primary, current, args.trunk)
        if why:
            print(f"Keeping {fresh['worktree']}: {why}")
            continue
        # Non-interactive stdin ensures a newly dirty checkout cannot be confirmed.
        result = run(
            "stax", "worktree", "remove", str(Path(fresh["worktree"]).resolve())
        )
        print(result.stdout, end="")
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or "Stax removal failed")


if __name__ == "__main__":
    try:
        main()
    except (
        OSError,
        RuntimeError,
        ValueError,
        KeyError,
        TypeError,
        subprocess.TimeoutExpired,
    ) as error:
        print(f"git_prune: {error}", file=sys.stderr)
        sys.exit(1)
