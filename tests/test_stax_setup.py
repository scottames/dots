"""Exercise blocking Stax setup without controlling a running terminal app."""

import os
import selectors
import subprocess  # nosec B404 - Local tools operating on temporary fixtures.
import unittest
from pathlib import Path

from test_stax_worktrees import FUNCTIONS, TOOLS, StaxFixture


class StaxSetup(StaxFixture):
    def test_copy_failure_stops_remaining_setup(self):
        self.configure_setup()
        copier = self.bin / "wt"
        copier.unlink()
        copier.write_text("#!/bin/sh\nexit 23\n")
        copier.chmod(0o755)
        fake = self.bin / "thts"
        fake.write_text("#!/bin/sh\ntouch thts-ran\n")
        fake.chmod(0o755)
        result = self.fish("_stax_worktree_path --create copy-fails")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("Copying ignored files (Worktrunk)...", result.stderr)
        destination = self.directory / "demo/copy-fails"
        self.assertTrue(destination.exists())
        self.assertFalse((destination / "thts-ran").exists())

    def test_setup_output_streams_before_launch(self):
        self.configure_setup()
        gate = self.directory / "setup-gate"
        os.mkfifo(gate)
        gate_fd = os.open(gate, os.O_RDWR | os.O_NONBLOCK)
        self.env["TEST_SETUP_GATE"] = str(gate)
        fake = self.bin / "thts"
        fake.write_text(
            "#!/bin/sh\n"
            "echo thoughts-output\n"
            'read -r answer < "$TEST_SETUP_GATE"\n'
            'test "$answer" = continue\n'
        )
        fake.chmod(0o755)
        process = subprocess.Popen(  # nosec B603 - Explicit local fixture command.
            [
                TOOLS["fish"],
                "--no-config",
                "-c",
                'set -p fish_function_path "$argv[1]"; _stax_worktree_path --create visible',
                "--",
                str(FUNCTIONS),
            ],
            cwd=self.main,
            env=self.env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(process.stderr, selectors.EVENT_READ)
                output = b""
                while b"thoughts-output" not in output:
                    self.assertTrue(selector.select(timeout=5), output)
                    chunk = process.stderr.read1(65536)
                    self.assertTrue(chunk, output)
                    output += chunk
            self.assertIn(b"Copying ignored files (Worktrunk)...", output)
            self.assertIsNone(process.poll(), output)
            os.write(gate_fd, b"continue\n")
            stdout, stderr = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, stderr)
            self.assertEqual(
                Path(stdout.decode().strip()).resolve(), self.directory / "demo/visible"
            )
        finally:
            os.write(gate_fd, b"continue\n")
            os.close(gate_fd)
            if process.poll() is None:
                process.kill()
            process.communicate(timeout=5)

    def test_copy_ignored_from_legacy_bare_layout(self):
        self.configure_setup()
        bare = self.directory / "legacy/.bare"
        self.git("clone", "--bare", str(self.main), str(bare))
        main = bare.parent / "main"
        self.git("worktree", "add", str(main), "main", cwd=bare)
        (main / "ignored").mkdir()
        (main / "ignored/config").write_text("bare checkout config")
        fake = self.bin / "thts"
        fake.write_text("#!/bin/sh\nexit 0\n")
        fake.chmod(0o755)
        destination = self.create("seeded", cwd=main)
        self.assertEqual(
            (destination / "ignored/config").read_text(), "bare checkout config"
        )


if __name__ == "__main__":
    unittest.main()
