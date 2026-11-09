"""Exercise cleanup with real Git, Fish, Worktrunk, and Stax in temporary repos."""

import json
import os
import shlex
import shutil
import subprocess  # nosec B404 - Local tools operating on temporary fixtures.
import sys
import tempfile
import time
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUNCTION = ROOT / "home/private_dot_config/fish/custom_functions.d/git_prune.fish"
CONFIG = ROOT / "home/private_dot_config/worktrunk/config.toml"
HOOK = CONFIG.with_name("stax-post-remove.py")


def tool(name):
    path = shutil.which(name)
    if path and "/mise/shims/" in path:
        return subprocess.check_output(  # nosec B603 B607 - Resolve installed tool.
            ["mise", "which", name], text=True
        ).strip()
    return path


TOOLS = {name: tool(name) for name in ("git", "fish", "wt", "stax")}


@unittest.skipUnless(all(TOOLS.values()), "requires Git, Fish, Worktrunk, and Stax")
class GitPruneTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="git prune ")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name).resolve()
        self.main = self.directory / "demo/main"
        self.main.mkdir(parents=True)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        for name, binary in {**TOOLS, "python3": sys.executable}.items():
            (self.bin / name).symlink_to(binary)
        self.config = self.directory / "wt.toml"
        hook = tomllib.loads(CONFIG.read_text())["post-remove"]["stax_untrack"]
        hook = hook.replace(
            '"$HOME/.config/worktrunk/stax-post-remove.py"', shlex.quote(str(HOOK))
        )
        self.config.write_text(f"[post-remove]\nstax_untrack = '''\n{hook}'''\n")
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "WORKTRUNK_CONFIG_PATH": str(self.config),
            "WORKTRUNK_SYSTEM_CONFIG_PATH": str(self.directory / "no-system.toml"),
            "WORKTRUNK_PROJECT_CONFIG_PATH": str(self.directory / "no-project.toml"),
        }
        self.git("init", "--quiet", "--initial-branch=main")
        # Fixtures use the existing author identity, without hardware signing or
        # user hooks. Never configure an alternate author/committer identity.
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", str(self.directory / "no-hooks"))
        self.git("config", "worktrunk.default-branch", "main")
        (self.main / ".gitignore").write_text("ignored/\n")
        self.git("add", ".gitignore")
        self.commit(self.main, "initial")
        self.remote = self.directory / "remote.git"
        self.git("init", "--quiet", "--bare", "--initial-branch=main", str(self.remote))
        self.git("remote", "add", "origin", str(self.remote))
        self.git("push", "--quiet", "--set-upstream", "origin", "main")

    def run_command(self, *args, cwd=None, check=True, input=None):
        return subprocess.run(  # nosec B603 - Explicit local arguments and fixtures.
            args,
            cwd=cwd or self.main,
            env=self.env,
            input=input,
            text=True,
            capture_output=True,
            check=check,
            timeout=30,
        )

    def git(self, *args, cwd=None, **kwargs):
        return self.run_command(TOOLS["git"], *args, cwd=cwd, **kwargs).stdout.strip()

    def commit(self, path, name):
        (path / name).write_text(name + "\n")
        self.git("add", name, cwd=path)
        self.git("commit", "--quiet", "-m", name, cwd=path)
        return self.git("rev-parse", "HEAD", cwd=path)

    def worktree(self, name, base="main"):
        path = self.directory / "demo" / name
        self.git("worktree", "add", "--quiet", "-b", name, str(path), base)
        return path

    def metadata(self, name, parent, revision=None, **extra):
        data = {
            "parentBranchName": parent,
            "parentBranchRevision": revision or self.git("rev-parse", parent),
            "frozen": False,
            **extra,
        }
        self.write_ref(f"refs/branch-metadata/{name}", json.dumps(data))
        return data

    def write_ref(self, ref, text):
        oid = self.git("hash-object", "-w", "--stdin", input=text)
        self.git("update-ref", ref, oid)

    def read_metadata(self, name):
        return json.loads(self.git("show", f"refs/branch-metadata/{name}"))

    def wait_for_parent(self, name, parent):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if self.read_metadata(name)["parentBranchName"] == parent:
                return
            time.sleep(0.02)
        logs = "\n".join(
            path.read_text() for path in (self.main / ".git/wt/logs").rglob("*.log")
        )
        self.fail(f"Post-remove hook did not reparent {name} to {parent}:\n{logs}")

    def stax_init(self):
        self.write_ref("refs/stax/trunk", "main")

    def prune(self, *args, cwd=None):
        return self.run_command(
            TOOLS["fish"],
            "--no-config",
            "-c",
            'source "$argv[1]"; git_prune $argv[2..]',
            "--",
            str(FUNCTION),
            *args,
            cwd=cwd,
            check=False,
        )

    def wt(self, *args):
        return self.run_command(TOOLS["wt"], *args)

    def test_preview_changes_neither_refs_nor_worktrees(self):
        self.stax_init()
        clean = self.worktree("integrated")
        artifact = clean / "ignored/evidence"
        artifact.parent.mkdir()
        artifact.write_text("keep")
        self.metadata("integrated", "main")
        self.metadata("orphan", "main")
        before = self.git("show-ref")
        result = self.prune("--min-age=0s")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("integrated", result.stdout)
        self.assertIn("orphan", result.stdout)
        self.assertEqual(self.git("show-ref"), before)
        self.assertEqual(artifact.read_text(), "keep")

    def test_apply_preserves_dirty_locked_and_unmerged_worktrees(self):
        self.stax_init()
        clean = self.worktree("integrated")
        self.metadata("integrated", "main")
        dirty = self.worktree("dirty")
        (dirty / "unsaved").write_text("keep")
        self.metadata("dirty", "main")
        locked = self.worktree("locked")
        self.git("worktree", "lock", str(locked))
        active = self.worktree("active")
        tip = self.commit(active, "unmerged")
        self.git("push", "--quiet", "--set-upstream", "origin", "active", cwd=active)
        self.git("push", "--quiet", "origin", "--delete", "active")
        result = self.prune("--apply", "--min-age=0s")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(clean.exists())
        self.assertNotIn("refs/branch-metadata/integrated", self.git("show-ref"))
        self.assertEqual((dirty / "unsaved").read_text(), "keep")
        self.assertEqual(self.read_metadata("dirty")["parentBranchName"], "main")
        self.assertTrue(locked.exists())
        self.assertEqual(self.git("rev-parse", "active"), tip)
        self.assertTrue(self.main.exists())

    def test_default_age_keeps_fresh_worktree(self):
        fresh = self.worktree("fresh")
        result = self.prune("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(fresh.exists())
        self.assertIn("2d", result.stdout)

    def test_apply_refuses_linked_or_dirty_primary_worktree(self):
        linked = self.worktree("linked")
        result = self.prune("--apply", "--min-age=0s", cwd=linked)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run --apply from", result.stderr)
        (self.main / "unsaved").write_text("keep")
        result = self.prune("--apply", "--min-age=0s")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be clean", result.stderr)
        self.assertTrue(linked.exists())
        self.assertEqual((self.main / "unsaved").read_text(), "keep")

    def test_apply_refuses_nondefault_primary_and_unknown_flags(self):
        self.git("switch", "--quiet", "-c", "not-default")
        result = self.prune("--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run --apply from", result.stderr)
        for args in (("--force",), ("--apply", "unexpected"), ("--min-age=invalid",)):
            with self.subTest(args=args):
                before = self.git("show-ref")
                self.assertNotEqual(self.prune(*args).returncode, 0)
                self.assertEqual(self.git("show-ref"), before)

    def test_pull_fast_forwards_but_refuses_divergence_before_cleanup(self):
        source = self.worktree("remote-source")
        remote_tip = self.commit(source, "remote-change")
        self.git("push", "--quiet", "origin", "remote-source:main")
        self.git("switch", "--quiet", "main")
        self.assertEqual(self.prune("--apply").returncode, 0)
        self.assertEqual(self.git("rev-parse", "main"), remote_tip)
        candidate = self.worktree("candidate")
        self.commit(source, "remote-again")
        self.git("push", "--quiet", "origin", "remote-source:main")
        local_tip = self.commit(self.main, "local-only")
        result = self.prune("--apply", "--min-age=0s")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("rev-parse", "main"), local_tip)
        self.assertTrue(candidate.exists())

    def test_remove_reparents_without_rewriting_child_or_rebase_boundary(self):
        self.stax_init()
        parent = self.worktree("parent")
        parent_tip = self.commit(parent, "parent-change")
        self.metadata("parent", "main")
        child = self.worktree("child", "parent")
        child_tip = self.commit(child, "child-change")
        expected = self.metadata("child", "parent", frozen=True, prInfo={"number": 7})
        self.git("merge", "--squash", "parent")
        self.git("commit", "--quiet", "-m", "squashed parent")
        self.commit(self.main, "later-main-change")
        self.assertNotEqual(self.git("merge-base", "main", "child"), parent_tip)
        self.wt("remove", "--foreground", "parent")
        self.assertFalse(parent.exists())
        self.wait_for_parent("child", "main")
        self.assertEqual(
            self.read_metadata("child"), {**expected, "parentBranchName": "main"}
        )
        self.assertEqual(self.git("rev-parse", "child"), child_tip)
        self.assertEqual(self.git("status", "--porcelain", cwd=child), "")

    def test_retained_branch_keeps_metadata_and_parent_relationship(self):
        self.stax_init()
        self.worktree("parent")
        expected = self.metadata("parent", "main")
        self.worktree("child", "parent")
        child_metadata = self.metadata("child", "parent")
        self.wt("remove", "--foreground", "--no-delete-branch", "parent")
        self.assertEqual(self.read_metadata("parent"), expected)
        self.assertEqual(self.read_metadata("child"), child_metadata)

    def test_concurrent_prune_reparents_surviving_leaf(self):
        self.stax_init()
        parent = self.worktree("parent")
        self.metadata("parent", "main")
        self.commit(parent, "parent-change")
        middle = self.worktree("middle", "parent")
        self.metadata("middle", "parent")
        self.commit(middle, "middle-change")
        leaf = self.worktree("leaf", "middle")
        tip = self.commit(leaf, "unmerged-leaf")
        expected = self.metadata("leaf", "middle")
        self.git("merge", "--ff-only", "middle")
        self.wt("step", "prune", "--min-age=0s", "--foreground")
        self.wait_for_parent("leaf", "main")
        self.assertEqual(
            self.read_metadata("leaf"), {**expected, "parentBranchName": "main"}
        )
        self.assertEqual(self.git("rev-parse", "leaf"), tip)
        self.assertNotIn("refs/branch-metadata/parent", self.git("show-ref"))
        self.assertNotIn("refs/branch-metadata/middle", self.git("show-ref"))

    def test_apply_cleans_branch_only_metadata_and_replay_is_idempotent(self):
        self.stax_init()
        self.git("branch", "branch-only")
        self.metadata("branch-only", "main")
        result = self.prune("--apply", "--min-age=0s")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("refs/branch-metadata/branch-only", self.git("show-ref"))
        before = self.git("show-ref")
        self.run_command(sys.executable, str(HOOK), "branch-only")
        self.assertEqual(self.git("show-ref"), before)

    def test_missing_parent_keeps_metadata_for_manual_repair(self):
        self.stax_init()
        self.metadata("removed", "missing", revision=self.git("rev-parse", "main"))
        self.worktree("child")
        expected = self.metadata(
            "child", "removed", revision=self.git("rev-parse", "main")
        )
        before = self.git("show-ref")
        result = self.run_command(sys.executable, str(HOOK), "removed", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("show-ref"), before)
        self.assertEqual(self.read_metadata("child"), expected)


if __name__ == "__main__":
    unittest.main()
