"""Exercise eligibility with real Git/Stax; mock only external activity snapshots."""

import contextlib
import importlib.util
import io
import os
import subprocess  # nosec B404 - Temporary fixture processes only.
import sys
import time
import unittest
from pathlib import Path
from unittest.mock import patch

from test_git_prune import ROOT, GitFixture

HELPER = ROOT / "home/private_dot_config/stax/prune-worktrees.py"
spec = importlib.util.spec_from_file_location("prune_worktrees", HELPER)
prune = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prune)


class LiveCleanupTests(GitFixture):
    def setUp(self):
        super().setUp()
        self.stax_init()
        self.previous_cwd = Path.cwd()
        os.chdir(self.main)
        self.addCleanup(os.chdir, self.previous_cwd)
        self.environment = patch.dict(os.environ, self.env)
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def old(self, name, base="main"):
        path = self.worktree(name, base)
        self.metadata(name, base)
        self.age(path)
        return path

    def age(self, path):
        admin = Path(self.git("rev-parse", "--absolute-git-dir", cwd=path))
        common = Path(
            self.git(
                "rev-parse", "--path-format=absolute", "--git-common-dir", cwd=path
            )
        )
        stamp = time.time() - 3 * 86400
        for file in [
            path / ".git",
            admin / "gitdir",
            admin / "logs/HEAD",
            *list((common / "logs/refs/heads").rglob("*")),
        ]:
            if file.is_file():
                os.utime(file, (stamp, stamp))

    def reason(self, name):
        entry = next(
            e for e in prune.inventory() if e.get("branch") == "refs/heads/" + name
        )
        return prune.reason(entry, self.main, self.main, "main")

    def execute(self, apply=False):
        args = [str(HELPER), "--primary", str(self.main), "--trunk", "main"]
        if apply:
            args.append("--apply")
        with patch.object(sys, "argv", args), contextlib.redirect_stdout(
            io.StringIO()
        ) as text:
            prune.main()
        return text.getvalue()

    def test_preview_then_native_remove_preserves_refs(self):
        path = self.old("merged")
        before = self.git("show-ref")
        with patch.object(prune, "herdr_paths", return_value=[]), patch.object(
            prune, "process_paths", return_value=[]
        ):
            self.assertIn("Would remove checkout merged", self.execute())
            self.assertTrue(path.exists())
            self.assertEqual(self.git("show-ref"), before)
            report = self.execute(apply=True)
        self.assertFalse(path.exists(), report)
        self.assertEqual(self.git("show-ref"), before)

    def test_bare_layout_removal_preserves_metadata(self):
        bare = self.directory / "legacy/.bare"
        self.git("clone", "--bare", str(self.main), str(bare))
        main = bare.parent / "main"
        self.git("worktree", "add", str(main), "main", cwd=bare)
        self.main = main
        os.chdir(main)
        self.stax_init()
        path = bare.parent / "done"
        self.git("worktree", "add", "-b", "done", str(path), "main")
        self.metadata("done", "main")
        self.age(path)
        before = self.git("show-ref")
        with patch.object(prune, "herdr_paths", return_value=[]), patch.object(
            prune, "process_paths", return_value=[]
        ):
            report = self.execute(apply=True)
        self.assertFalse(path.exists(), report)
        self.assertEqual(self.git("show-ref"), before)

    def test_unknown_age_and_detached_checkout_kept(self):
        path = self.old("uncertain")
        real_stat = Path.stat

        def stat(file, *args, **kwargs):
            if file == path / ".git":
                raise PermissionError("age unavailable")
            return real_stat(file, *args, **kwargs)

        with patch.object(Path, "stat", stat):
            self.assertIn("state unknown", self.reason("uncertain"))
        self.git("checkout", "--detach", cwd=path)
        entry = next(e for e in prune.inventory() if e["worktree"] == str(path))
        self.assertIn("detached", prune.reason(entry, self.main, self.main, "main"))

    def test_safety_reasons(self):
        dirty = self.old("dirty")
        (dirty / "untracked").write_text("keep")
        self.old("locked")
        self.git("worktree", "lock", str(self.directory / "demo/locked"))
        self.old("parent")
        self.old("child", "parent")
        fresh = self.worktree("fresh")
        operation = self.old("operation")
        admin = Path(self.git("rev-parse", "--absolute-git-dir", cwd=operation))
        (admin / "MERGE_HEAD").write_text(self.git("rev-parse", "main"))
        for branch, expected in [
            ("dirty", "uncommitted"),
            ("locked", "locked"),
            ("parent", "children"),
            ("fresh", "two days"),
            ("operation", "operation"),
        ]:
            self.assertIn(expected, self.reason(branch))
        self.assertTrue(fresh.exists())

    def test_squash_merge_and_recent_git_use_retained(self):
        squash = self.old("squashed")
        self.commit(squash, "feature")
        self.git("merge", "--squash", "squashed")
        self.git("commit", "-m", "squash")
        self.age(squash)
        self.assertIn("squash", self.reason("squashed"))
        recent = self.old("recent")
        admin = Path(self.git("rev-parse", "--absolute-git-dir", cwd=recent))
        os.utime(admin / "logs/HEAD", None)
        self.assertIn("recently used", self.reason("recent"))

    def test_active_and_unknown_activity_retained(self):
        path = self.old("active")
        for provider in ("herdr_paths", "process_paths"):
            with patch.object(prune, "herdr_paths", return_value=[]), patch.object(
                prune, "process_paths", return_value=[]
            ):
                with patch.object(prune, provider, return_value=[path / "nested"]):
                    self.assertIn("running process", self.reason("active"))
                    self.execute(apply=True)
                    self.assertTrue(path.exists())
                with patch.object(
                    prune, provider, side_effect=PermissionError("unreadable")
                ):
                    self.assertIn("activity unknown", self.reason("active"))
                    self.execute(apply=True)
                    self.assertTrue(path.exists())

    def test_recheck_catches_new_activity_and_checkout_change(self):
        path = self.old("race")
        with patch.object(prune, "herdr_paths", return_value=[]), patch.object(
            prune, "process_paths", side_effect=[[], [path]]
        ):
            self.execute(apply=True)
        self.assertTrue(path.exists())
        original = prune.inventory
        calls = 0

        def inventory():
            nonlocal calls
            calls += 1
            if calls == 2:
                self.commit(path, "new-work")
            return original()

        with patch.object(prune, "inventory", side_effect=inventory), patch.object(
            prune, "herdr_paths", return_value=[]
        ), patch.object(prune, "process_paths", return_value=[]):
            self.assertIn("changed since preview", self.execute(apply=True))
        self.assertTrue(path.exists())

    @unittest.skipUnless(sys.platform == "linux", "Linux /proc contract")
    def test_real_process_cwd_protection(self):
        path = self.old("agent")
        child = subprocess.Popen(
            [sys.executable, "-c", "import time; time.sleep(30)"], cwd=path
        )  # nosec B603
        try:
            with patch.object(prune, "herdr_paths", return_value=[]):
                why = self.reason("agent")
                self.assertIsNotNone(why)
                self.assertTrue(
                    "running process" in why or "activity unknown" in why, why
                )
        finally:
            child.terminate()
            child.wait(timeout=5)

    def test_stax_hook_failure_propagates_without_deleting(self):
        path = self.old("hook-fails")
        with (self.config / "config.toml").open("a") as config:
            config.write('[worktree.hooks]\npre_remove="exit 9"\n')
        before = self.git("show-ref")
        with patch.object(prune, "herdr_paths", return_value=[]), patch.object(
            prune, "process_paths", return_value=[]
        ):
            with self.assertRaises(RuntimeError):
                self.execute(apply=True)
        self.assertTrue(path.exists())
        self.assertEqual(self.git("show-ref"), before)

    def test_herdr_desktop_paths_and_malformed_response(self):
        def output(*args):
            if args == ("herdr-app", "ls"):
                return '{"spaces":[{"folder":"/repo/old","tabs":[{"terminals":[{"terminal":"t1"}]}]}]}'
            return (
                '{"cwd":"/repo/current", "foreground":{"cwd":"/repo/current/subdir"}}'
            )

        with patch.object(
            prune.shutil, "which", return_value="/bin/tool"
        ), patch.object(prune, "output", side_effect=output), patch.dict(
            os.environ, {"HC_TERMINAL_ID": "test"}
        ):
            self.assertEqual(
                prune.herdr_paths(), [Path("/repo/old"), Path("/repo/current/subdir")]
            )
        with patch.object(
            prune.shutil, "which", return_value="/bin/tool"
        ), patch.object(prune, "output", return_value="{}"), patch.dict(
            os.environ, {"HC_TERMINAL_ID": "test"}
        ):
            self.assertIn("activity unknown", prune.activity_reason(self.main))

    def test_herdr_optional_outside_runtime(self):
        with patch.dict(os.environ, {}, clear=True), patch.object(
            prune, "output"
        ) as command:
            self.assertEqual(prune.herdr_paths(), [])
            command.assert_not_called()
        with patch.dict(
            os.environ, {"HC_TERMINAL_ID": "test"}, clear=True
        ), patch.object(prune.shutil, "which", return_value=None):
            with self.assertRaisesRegex(RuntimeError, "unavailable"):
                prune.herdr_paths()

    def test_macos_lsof_paths_and_errors(self):
        result = subprocess.CompletedProcess(
            [], 0, "p42\nfcwd\nn/example/repo space\n", ""
        )
        with patch.object(prune.sys, "platform", "darwin"), patch.object(
            prune, "run", return_value=result
        ):
            self.assertEqual(prune.process_paths(), [Path("/example/repo space")])
            result.stderr = "permission denied"
            with self.assertRaises(RuntimeError):
                prune.process_paths()


if __name__ == "__main__":
    unittest.main()
