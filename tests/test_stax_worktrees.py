"""Real Stax/Fish contracts; terminal clients alone are stubbed."""

import json
import shlex
import unittest
from pathlib import Path

from test_git_prune import ROOT, TOOLS, GitFixture

FUNCTIONS = ROOT / "home/private_dot_config/fish/custom_functions.d"


@unittest.skipUnless(all(TOOLS.values()), "requires Git, Fish, Stax")
class StaxWorktrees(GitFixture):
    def fish(self, script, *args, cwd=None):
        return self.run_command(
            TOOLS["fish"],
            "--no-config",
            "-c",
            'set -p fish_function_path "$argv[1]"; ' + script,
            "--",
            str(FUNCTIONS),
            *args,
            cwd=cwd,
            check=False,
        )

    def create(self, name, *options, cwd=None):
        result = self.fish(
            "_stax_worktree_path --create $argv[2..]", *options, name, cwd=cwd
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return Path(result.stdout.strip()).resolve()

    def test_default_parent_is_trunk_even_from_feature(self):
        parent = self.create("parent")
        self.commit(parent, "parent-change")
        child = self.create("independent", cwd=parent)
        self.assertEqual(child, self.directory / "demo/independent")
        self.assertEqual(self.read_metadata("independent")["parentBranchName"], "main")
        self.assertEqual(
            self.git("rev-parse", "independent"), self.git("rev-parse", "main")
        )
        self.create("child", "--base", "parent", cwd=parent)
        self.assertEqual(self.read_metadata("child")["parentBranchName"], "parent")
        self.create("current-child", "--base", "@", cwd=parent)
        self.assertEqual(
            self.read_metadata("current-child")["parentBranchName"], "parent"
        )

    def test_existing_worktrunk_checkout_and_metadata_unchanged(self):
        self.stax_init()
        old = self.worktree("old")
        metadata = self.metadata("old", "main", frozen=True, prInfo={"number": 9})
        before = self.git("show-ref")
        self.assertEqual(self.create("old", "--base", "different"), old)
        result = self.fish("_stax_worktree_path old; pwd")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [str(old), str(self.main)])
        self.assertEqual(self.git("show-ref"), before)
        self.assertEqual(self.read_metadata("old"), metadata)
        self.git("branch", "plain")
        self.create("plain")
        self.assertNotIn("refs/branch-metadata/plain", self.git("show-ref"))

    def test_legacy_bare_layout(self):
        bare = self.directory / "legacy/.bare"
        self.git("clone", "--bare", str(self.main), str(bare))
        main = bare.parent / "main"
        self.git("worktree", "add", str(main), "main", cwd=bare)
        child = self.create("feature", cwd=main)
        self.assertEqual(child, bare.parent / "feature")
        result = self.fish("_stax_primary_worktree", cwd=child)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()), main)
        self.assertEqual(
            self.fish("_stax_worktree_path feature", cwd=main).returncode, 0
        )

        result = self.fish("_stax_worktree_path main", cwd=child)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()), main)
        self.assertNotEqual(
            self.fish("_stax_worktree_path .bare", cwd=main).returncode, 0
        )

    def test_hooks_block_launch_and_failure_keeps_checkout(self):
        config = self.config / "config.toml"
        with config.open("a") as file:
            file.write('[worktree.hooks]\npost_create="touch setup-finished; exit 7"\n')
        result = self.fish("_stax_worktree_path --create failed")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("STAX_SHELL_PATH", result.stdout)
        self.assertTrue((self.directory / "demo/failed/setup-finished").exists())
        self.assertEqual(self.read_metadata("failed")["parentBranchName"], "main")
        # Re-entry intentionally does NOT retry post_create. Document manual repair.
        result = self.fish("_stax_worktree_path failed")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_herdr_opens_primary_then_child_without_cd(self):
        # Real Stax, real Herdr bridge, mocked desktop transport.
        script = self.bin / "herdr-app"
        log = self.directory / "herdr.jsonl"
        script.write_text(
            "#!/usr/bin/env python3\nimport json,sys\n"
            f'with open({str(log)!r},"a") as f: f.write(json.dumps(sys.argv[1:])+"\\n")\n'
            'print("{\\"spaces\\":[]}")\n'
        )
        script.chmod(0o755)
        self.env["HC_TERMINAL_ID"] = "test"
        result = self.fish("herdr_wt_switch --create agent; or exit $status; pwd")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.main))
        commands = [json.loads(line) for line in log.read_text().splitlines()]
        created = [c for c in commands if "space.new" in c]
        self.assertEqual(
            [c[c.index("--folder") + 1] for c in created],
            [str(self.main), str(self.directory / "demo/agent")],
        )

    def test_copy_ignored_and_configured_setup_failure(self):
        self.stax_init()
        (self.main / "ignored").mkdir()
        (self.main / "ignored/config").write_text("local config")
        (self.main / "ignored/link").symlink_to("/etc/passwd")
        import tomllib

        hook = tomllib.loads(
            (ROOT / "home/private_dot_config/stax/config.toml").read_text()
        )["worktree"]["hooks"]["post_create"]
        hook = hook.replace(
            '"$HOME/.config/stax/copy-ignored.py"',
            shlex.quote(str(ROOT / "home/private_dot_config/stax/copy-ignored.py")),
        )
        (self.config / "config.toml").write_text(
            '[worktree]\nroot_dir=".."\nreuse_slots=false\n[worktree.hooks]\npost_create='
            + json.dumps(hook)
            + "\n"
        )
        fake = self.bin / "thts"
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$*" > thts-ran\n')
        fake.chmod(0o755)
        destination = self.create("setup")
        self.assertEqual((destination / "ignored/config").read_text(), "local config")
        self.assertFalse((destination / "ignored/link").exists())
        self.assertEqual(
            (destination / "thts-ran").read_text().strip(), "init --no-agents --force"
        )
        fake.write_text("#!/bin/sh\nexit 19\n")
        result = self.fish("_stax_worktree_path --create setup-fails")
        self.assertNotEqual(result.returncode, 0)

    def test_native_remove_keeps_parent_metadata_and_child_revision(self):
        parent = self.create("parent")
        self.create("child", "--base", "parent")
        before = self.git("show-ref")
        self.run_command(TOOLS["stax"], "worktree", "remove", "parent")
        self.assertFalse(parent.exists())
        self.assertEqual(self.git("show-ref"), before)

    def test_completions_and_abbreviations(self):
        self.create("completion-test")
        result = self.fish(
            'source "$argv[2]"; complete -C "herdr_wt_switch "',
            str(ROOT / "home/private_dot_config/fish/completions/herdr_wt_switch.fish"),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("completion-test", result.stdout)
        abbrs = (ROOT / "home/private_dot_config/fish/conf.d/abbrs.fish").read_text()
        self.assertIn('abbr -a hwtc "herdr_wt_switch --create"', abbrs)
        self.assertNotIn('"wt ', abbrs)

    def test_graphite_bridge_keeps_checkout_and_stax_metadata_untouched(self):
        fake = self.bin / "gt"
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$*" > gt-arguments\n')
        fake.chmod(0o755)
        result = self.fish(
            "gt-wt-create --no-cd --base main graphite-only; or exit $status; pwd"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.main))
        self.assertEqual(self.git("branch", "--show-current"), "main")
        self.assertNotIn("refs/branch-metadata/graphite-only", self.git("show-ref"))
        self.assertEqual(
            (self.directory / "demo/graphite-only/gt-arguments").read_text().strip(),
            "track --parent main",
        )

    def test_conditional_trunk_failure_blocks_setup(self):
        import tomllib

        (self.main / ".trunk").mkdir()
        (self.main / ".trunk/trunk.yaml").write_text("version: 0.1\n")
        self.git("add", ".trunk/trunk.yaml")
        self.git("commit", "-m", "trunk config")
        hook = tomllib.loads(
            (ROOT / "home/private_dot_config/stax/config.toml").read_text()
        )["worktree"]["hooks"]["post_create"]
        hook = hook.replace(
            '"$HOME/.config/stax/copy-ignored.py"',
            shlex.quote(str(ROOT / "home/private_dot_config/stax/copy-ignored.py")),
        )
        (self.config / "config.toml").write_text(
            '[worktree]\nroot_dir=".."\nreuse_slots=false\n[worktree.hooks]\npost_create='
            + json.dumps(hook)
            + "\n"
        )
        fake = self.bin / "trunk"
        fake.write_text("#!/bin/sh\necho check > trunk-ran\nexit 23\n")
        fake.chmod(0o755)
        result = self.fish("_stax_worktree_path --create lint-fails")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.directory / "demo/lint-fails/trunk-ran").exists())

    def test_native_interactive_picker(self):
        try:
            import pexpect
        except ImportError:
            self.skipTest("optional pexpect is needed for terminal picker exercise")
        destination = self.create("picker-target")
        child = pexpect.spawn(
            TOOLS["fish"],
            [
                "--no-config",
                "-c",
                'set -p fish_function_path "$argv[1]"; set selected (_stax_worktree_path); printf "RESULT:%s\\n" "$selected"',
                "--",
                str(FUNCTIONS),
            ],
            cwd=str(self.main),
            env={**self.env, "TERM": "xterm-256color"},
            encoding="utf-8",
            timeout=10,
        )
        try:
            child.expect("Select worktree")
            child.send("picker-target")
            child.sendline("")
            child.expect("RESULT:" + str(destination))
            child.expect(pexpect.EOF)
        finally:
            child.close(force=True)
        self.assertEqual(child.exitstatus, 0)


if __name__ == "__main__":
    unittest.main()
