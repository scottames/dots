"""Exercise desktop Fish helpers without changing the running Herdr app."""

import json
import os
import shutil
import subprocess  # nosec B404 - Run local Fish helpers against test-only executables.
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUNCTIONS = ROOT / "home/private_dot_config/fish/custom_functions.d"


@unittest.skipUnless(
    shutil.which("fish") and shutil.which("jq"), "requires fish and jq"
)
class HerdrAppWorkflow(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name).resolve()
        self.main = self.directory / "demo/main"
        self.child = self.directory / "demo/feature space"
        self.main.mkdir(parents=True)
        self.child.mkdir()
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        self.log = self.directory / "commands.jsonl"
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "TEST_LOG": str(self.log),
            "TEST_MAIN": str(self.main),
            "TEST_CHILD": str(self.child),
            "TEST_SPACES": '{"spaces":[]}',
            "TEST_CORE": '{"terminals":[]}',
            "PROJECT_LABEL_SUBSTITUTIONS": "",
            "HC_TERMINAL_ID": "t-test",
            "HERDR_ENV": "legacy-inherited",
        }
        self.mock(
            "herdr-app",
            """
if args == ['ls']:
    print(os.environ['TEST_SPACES'])
elif os.environ.get('TEST_APP_FAIL'):
    sys.exit(1)
else:
    print('{}')
""",
        )
        self.mock(
            "hc",
            "print(json.dumps(json.loads(os.environ['TEST_CORE'])['terminals'][0]))",
        )
        self.mock(
            "git",
            """
cwd = args[1]
if args[2:] == ['rev-parse', '--show-toplevel']:
    print(os.environ['TEST_CHILD'] if cwd.startswith(os.environ['TEST_CHILD']) else os.environ['TEST_MAIN'])
else:
    sys.exit(1)
""",
        )
        self.mock(
            "wt",
            """
if os.environ.get('TEST_WT_FAIL'):
    sys.exit(1)
if args[0] == 'step':
    print(os.environ['TEST_MAIN'])
else:
    print(json.dumps({'path': '' if os.environ.get('TEST_CANCEL') else os.environ['TEST_CHILD']}))
""",
        )

    def mock(self, name, body):
        script = self.bin / name
        script.write_text(
            f"#!{shutil.which('python3')}\n"
            "import json, os, sys\n"
            "args = sys.argv[1:]\n"
            "with open(os.environ['TEST_LOG'], 'a') as f:\n"
            "    f.write(json.dumps([os.path.basename(sys.argv[0]), *args]) + '\\n')\n"
            + body
        )
        script.chmod(0o755)

    def run_helper(self, expression):
        # Real project_label has its own tests; isolate this workflow's naming input.
        script = """
set -p fish_function_path "$argv[1]"
function project_label
    if test "$argv[1]" = "$TEST_MAIN"
        echo demo
    else
        echo demo:feature
    end
end
""" + expression
        return subprocess.run(  # nosec B603 - Script and arguments are test-controlled.
            [shutil.which("fish"), "--no-config", "-c", script, "--", str(FUNCTIONS)],
            env=self.env,
            cwd=self.main,
            capture_output=True,
            text=True,
            check=False,
        )

    def commands(self, program="herdr-app"):
        return [
            c[1:]
            for c in map(json.loads, self.log.read_text().splitlines())
            if c[0] == program
        ]

    def test_new_space_and_label_override(self):
        result = self.run_helper(
            'herdr_new_workspace --label "my project" "$TEST_MAIN"'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            ["do", "space.new", "--folder", str(self.main), "--name", "my project"],
            self.commands(),
        )

    def test_legacy_and_outside_runtime_keep_legacy_default(self):
        self.env.pop("HC_TERMINAL_ID")
        self.mock("herdr", "print('{}')")
        for legacy_env in (True, False):
            with self.subTest(legacy_env=legacy_env):
                if not legacy_env:
                    self.env.pop("HERDR_ENV", None)
                result = self.run_helper(
                    'herdr_new_workspace --simple --label legacy "$TEST_MAIN"'
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    self.commands("herdr")[-1],
                    [
                        "workspace",
                        "create",
                        "--cwd",
                        str(self.main),
                        "--label",
                        "legacy",
                        "--focus",
                    ],
                )
                self.assertEqual(self.commands(), [])

    def test_reuses_live_checkout_not_starting_folder(self):
        self.env["TEST_SPACES"] = json.dumps(
            {
                "spaces": [
                    {
                        "id": "s1",
                        "folder": "/old",
                        "tabs": [{"terminals": [{"terminal": "t1"}]}],
                    }
                ]
            }
        )
        self.env["TEST_CORE"] = json.dumps(
            {
                "terminals": [
                    {
                        "address": "t1",
                        "cwd": "/old",
                        "foreground": {"cwd": str(self.main / "src")},
                    }
                ]
            }
        )
        result = self.run_helper('herdr_new_workspace "$TEST_MAIN"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands()[-1], ["do", "space.select", "--id", "s1"])
        self.assertFalse(any("space.new" in c for c in self.commands()))

    def test_worktree_creates_parent_first_and_forwards_options(self):
        result = self.run_helper("herdr_wt_switch --create --base @ feature")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            [
                "switch",
                "--no-cd",
                "--create",
                "--base",
                "@",
                "feature",
                "--format",
                "json",
            ],
            self.commands("wt"),
        )
        created = [c for c in self.commands() if "space.new" in c]
        self.assertEqual(
            [c[c.index("--folder") + 1] for c in created],
            [str(self.main), str(self.child)],
        )
        self.assertEqual([c[-1] for c in created], ["demo", "demo:feature"])

    def test_picker_cancel_does_not_open_spaces(self):
        self.env["TEST_CANCEL"] = "1"
        result = self.run_helper("herdr_wt_switch")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.commands(), [["ls"]])

    def test_worktrunk_failure_does_not_open_spaces(self):
        self.env["TEST_WT_FAIL"] = "1"
        self.assertNotEqual(self.run_helper("herdr_wt_switch feature").returncode, 0)
        self.assertEqual(self.commands(), [["ls"]])

    def test_parent_open_failure_stops_child(self):
        self.env["TEST_APP_FAIL"] = "1"
        self.assertNotEqual(self.run_helper("herdr_wt_switch feature").returncode, 0)
        self.assertEqual(len([c for c in self.commands() if "space.new" in c]), 1)

    def test_missing_path(self):
        self.assertNotEqual(
            self.run_helper(
                "herdr_new_workspace /nonexistent/herdrapp-test"
            ).returncode,
            0,
        )
        self.assertFalse(self.log.exists())

    def test_file_path_uses_parent(self):
        (self.main / "README.md").write_text("test\n")
        result = self.run_helper('herdr_new_workspace "$TEST_MAIN/README.md"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.commands()[-1][-4:], ["--folder", str(self.main), "--name", "demo"]
        )

    def test_remote_space_is_not_reused(self):
        self.env["TEST_SPACES"] = json.dumps(
            {
                "spaces": [
                    {
                        "id": "remote/s1",
                        "machine": "remote",
                        "tabs": [{"terminals": [{"terminal": "t1"}]}],
                    }
                ]
            }
        )
        self.env["TEST_CORE"] = json.dumps(
            {"terminals": [{"address": "t1", "cwd": str(self.main)}]}
        )
        result = self.run_helper('herdr_new_workspace "$TEST_MAIN"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("space.new", self.commands()[-1])

    def test_picker_opens_selected_worktree(self):
        result = self.run_helper("herdr_wt_switch")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(["switch", "--no-cd", "--format", "json"], self.commands("wt"))
        self.assertEqual(len([c for c in self.commands() if "space.new" in c]), 2)


if __name__ == "__main__":
    unittest.main()
