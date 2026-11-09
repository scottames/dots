"""Repair Stax tracking after Worktrunk deletes a branch, without rebasing."""

import fcntl
import json
import subprocess  # nosec B404 - Local Git only, with explicit argument lists.
import sys
from pathlib import Path


def git(*args, input=None):
    return (
        subprocess.check_output(  # nosec B603 B607 - Local Git with explicit arguments.
            ["git", *args], input=input, text=True
        ).strip()
    )


def exists(branch):
    return (
        subprocess.run(  # nosec B603 B607 - Local ref lookup, not shell input.
            ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
            check=False,
        ).returncode
        == 0
    )


def cleanup(branch):
    common = Path(git("rev-parse", "--git-common-dir"))
    # Worktrunk can remove several generations of a stack concurrently.
    with (common / "worktrunk-stax.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        refs = {}
        for line in git(
            "for-each-ref", "--format=%(refname) %(objectname)", "refs/branch-metadata/"
        ).splitlines():
            ref, oid = line.split()
            refs[ref.removeprefix("refs/branch-metadata/")] = (
                oid,
                json.loads(git("cat-file", "blob", oid)),
            )
        if exists(branch) or branch not in refs:
            return

        oid, metadata = refs[branch]
        children = {
            name: value
            for name, value in refs.items()
            if value[1].get("parentBranchName") == branch
        }
        commands = ["start", f"verify refs/heads/{branch} {'0' * len(oid)}"]
        if children:
            parent = metadata["parentBranchName"]
            seen = {branch}
            while not exists(parent):
                if parent in seen or parent not in refs:
                    raise ValueError(f"Cannot find a surviving parent for {branch}")
                seen.add(parent)
                parent = refs[parent][1]["parentBranchName"]
            if parent in children or parent == branch:
                raise ValueError(f"Reparenting {branch} would create a cycle")
            for child, (old_oid, child_metadata) in children.items():
                # Keep parentBranchRevision: it is the boundary after which the
                # child's own commits start, even after its parent was squashed.
                updated = {**child_metadata, "parentBranchName": parent}
                new_oid = git(
                    "hash-object", "-w", "--stdin", input=json.dumps(updated) + "\n"
                )
                commands.append(
                    f"update refs/branch-metadata/{child} {new_oid} {old_oid}"
                )
            # Abort rather than write dangling parents if another tool deletes it.
            commands.append(f"verify refs/heads/{parent} {git('rev-parse', parent)}")
        commands.extend(
            [f"delete refs/branch-metadata/{branch} {oid}", "prepare", "commit"]
        )
        # Compare-and-swap every metadata ref in one transaction. On a competing
        # Stax edit, keep all old metadata for manual repair rather than clobber it.
        git("update-ref", "--stdin", input="\n".join(commands) + "\n")
        print(
            f"Removed Stax tracking for {branch}; reparented {len(children)} child(ren)"
        )


if __name__ == "__main__":
    cleanup(sys.argv[1])
