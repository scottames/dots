"""Exercise cleanup with real Git, Fish, Stax in temporary repos."""

import json
import os
import shutil
import subprocess  # nosec B404 - Local tools operating on temporary fixtures.
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUNCTION = ROOT / "home/private_dot_config/fish/custom_functions.d/git_prune.fish"
CONFIG = ROOT / "home/private_dot_config/stax/config.toml"


def tool(name):
    path = shutil.which(name)
    if path and "/mise/shims/" in path:
        return subprocess.check_output(  # nosec B603 B607 - Resolve installed tool.
            ["mise", "which", name], text=True
        ).strip()
    return path


TOOLS = {name: tool(name) for name in ("git", "fish", "stax")}


@unittest.skipUnless(all(TOOLS.values()), "requires Git, Fish, Stax")
class GitFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="git prune ")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name).resolve()
        self.main = self.directory / "demo/main"
        self.main.mkdir(parents=True)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        for name, binary in TOOLS.items():
            (self.bin / name).symlink_to(binary)
        self.config = self.directory / "config"
        self.config.mkdir()
        (self.config / "config.toml").write_text(
            '[worktree]\nroot_dir=".."\nreuse_slots=false\n'
        )
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "STAX_CONFIG_DIR": str(self.config),
        }
        self.git("init", "--quiet", "--initial-branch=main")
        # Fixtures use the existing author identity, without hardware signing or
        # user hooks. Never configure an alternate author/committer identity.
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", str(self.directory / "no-hooks"))
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

    def stax_init(self):
        self.write_ref("refs/stax/trunk", "main")

    def prune(self, *args, cwd=None):
        return self.run_command(
            TOOLS["fish"],
            "--no-config",
            "-c",
            'set -p fish_function_path (path dirname "$argv[1]"); git_prune $argv[2..]',
            "--",
            str(FUNCTION),
            *args,
            cwd=cwd,
            check=False,
        )


class GitPruneTests(GitFixture):
    def test_preview_changes_neither_refs_nor_worktrees(self):
        self.stax_init()
        clean = self.worktree("integrated")
        self.metadata("integrated", "main")
        before = self.git("show-ref")
        result = self.prune()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git("show-ref"), before)
        self.assertTrue(clean.exists())

    def test_apply_retains_all_live_worktrees_and_metadata(self):
        self.stax_init()
        for name in ("integrated", "dirty", "locked", "active"):
            path = self.worktree(name)
            self.metadata(name, "main")
            if name == "dirty":
                (path / "unsaved").write_text("keep")
            if name == "locked":
                self.git("worktree", "lock", str(path))
        before = self.git("show-ref", "--heads")
        result = self.prune("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git("show-ref", "--heads"), before)
        for name in ("integrated", "dirty", "locked", "active"):
            self.assertTrue((self.directory / "demo" / name).exists())

    def test_default_age_keeps_fresh_worktree(self):
        fresh = self.worktree("fresh")
        result = self.prune("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(fresh.exists())
        self.assertIn("retained", result.stdout)

    def test_apply_refuses_linked_or_dirty_primary_worktree(self):
        linked = self.worktree("linked")
        result = self.prune("--apply", cwd=linked)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run --apply from", result.stderr)
        (self.main / "unsaved").write_text("keep")
        result = self.prune("--apply")
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
        result = self.prune("--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("rev-parse", "main"), local_tip)
        self.assertTrue(candidate.exists())

    def test_invalid_metadata_blocks_apply(self):
        self.stax_init()
        self.worktree("child")
        self.metadata("child", "missing", revision=self.git("rev-parse", "main"))
        before = self.git("show-ref", "--heads")
        result = self.prune("--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("show-ref", "--heads"), before)

    def test_stale_bookkeeping_age_and_staged_recovery(self):
        import time

        self.stax_init()
        old = self.worktree("old-missing")
        recent = self.worktree("recent-missing")
        locked = self.worktree("locked-missing")
        self.git("worktree", "lock", str(locked))
        shutil.rmtree(old)
        shutil.rmtree(recent)
        shutil.rmtree(locked)
        admin = self.main / ".git/worktrees"
        timestamp = time.time() - 3 * 86400
        os.utime(admin / "old-missing/gitdir", (timestamp, timestamp))
        os.utime(admin / "locked-missing/gitdir", (timestamp, timestamp))
        self.git("config", "gc.worktreePruneExpire", "now")
        result = self.prune("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((admin / "old-missing").exists())
        self.assertTrue((admin / "recent-missing").exists())
        os.utime(admin / "recent-missing/gitdir", (timestamp, timestamp))
        result = self.prune("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((admin / "old-missing").exists())
        self.assertFalse((admin / "recent-missing").exists())
        self.assertTrue((admin / "locked-missing").exists())
        staged = self.worktree("staged-missing")
        (staged / "recover").write_text("staged content")
        self.git("add", "recover", cwd=staged)
        shutil.rmtree(staged)
        os.utime(admin / "staged-missing/gitdir", (timestamp, timestamp))
        result = self.prune("--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((admin / "staged-missing/index").exists())


if __name__ == "__main__":
    unittest.main()
