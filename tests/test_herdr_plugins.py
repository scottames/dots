"""Focused source/binary compatibility tests; no upstream network access."""

import importlib.util
import io
import unittest
import urllib.error
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import call, patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/check-herdr-plugins.py"
SPEC = importlib.util.spec_from_file_location("herdr_plugins", SCRIPT)
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)
SHA = "7c8f5a177b8285dc56efc471ef04f7ab44a2b4b6"
PIN = '{{ $herdrAnnotateRef := "' + SHA + '" -}}'
MISE = b"""[tools]
"github:plannotator/herdr-annotate" = { version = "rust-lite-v0.1.0", bin = "herdr-annotate", prerelease = true, os = ["linux", "macos"] }
"github:plannotator/plannotator-tui" = { version = "v0.8.0", bin = "plannotator-tui", os = ["linux", "macos"] }
"""


class CompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(Path, "read_text", return_value=PIN))
        self.config = self.enterContext(patch.object(Path, "open"))
        self.config.return_value.__enter__.side_effect = lambda: io.BytesIO(MISE)
        self.fetch = self.enterContext(
            patch.object(checker, "fetch_metadata", side_effect=["0.1.0", "0.8.0"])
        )
        self.enterContext(redirect_stdout(io.StringIO()))

    def test_both_versions_match(self):
        checker.check(Path("/repo"))
        self.fetch.assert_has_calls(
            [call(SHA, "herdr-annotate.version"), call(SHA, "plannotator-tui.version")]
        )
        self.assertEqual(self.fetch.call_count, 2)

    def test_each_mismatch(self):
        for name, versions in (
            ("herdr-annotate", ["0.2.0", "0.8.0"]),
            ("plannotator-tui", ["0.1.0", "0.9.0"]),
        ):
            with self.subTest(name=name):
                self.fetch.side_effect = versions
                with self.assertRaisesRegex(ValueError, f"{name} .* requires"):
                    checker.check(Path("/repo"))

    def test_invalid_metadata(self):
        for invalid in ("", "v0.1.0", "0.1", "01.2.3", "<html>", "0.1.0\n0.2.0"):
            for index in range(2):
                with self.subTest(metadata=invalid, index=index):
                    versions = ["0.1.0", "0.8.0"]
                    versions[index] = invalid
                    self.fetch.side_effect = versions
                    with self.assertRaisesRegex(ValueError, "malformed"):
                        checker.check(Path("/repo"))

    def test_bad_mise(self):
        for config in (
            b"[",
            b"[tools]",
            MISE.replace(b'version = "rust-lite-v0.1.0"', b"version = 1"),
        ):
            with self.subTest(config=config):
                self.config.return_value.__enter__.side_effect = (
                    lambda config=config: io.BytesIO(config)
                )
                with self.assertRaises(ValueError):
                    checker.check(Path("/repo"))

    def test_fetch_failure_fails_cli(self):
        self.fetch.side_effect = ValueError("cannot fetch metadata")
        with patch("sys.argv", [str(SCRIPT), "/repo"]), patch(
            "sys.stderr", new_callable=io.StringIO
        ) as stderr:
            self.assertEqual(checker.main(), 1)
            self.assertIn("cannot fetch metadata", stderr.getvalue())


class InputTests(unittest.TestCase):
    def test_pin(self):
        self.assertEqual(checker.read_pin(PIN), SHA)
        for source in (
            "",
            PIN + "\n" + PIN,
            PIN.replace(SHA, "main"),
            PIN.replace(SHA, "a" * 39),
            PIN.replace(":=", "="),
            PIN + '\n{{ $herdrAnnotateRef = "main" -}}',
        ):
            with self.subTest(source=source), self.assertRaises(ValueError):
                checker.read_pin(source)

    def test_fetch_fixed_url_and_timeout(self):
        with patch.object(checker.urllib.request.OpenerDirector, "open") as request:
            request.return_value.__enter__.return_value.read.return_value = b"0.1.0\n"
            self.assertEqual(
                checker.fetch_metadata(SHA, "herdr-annotate.version"), "0.1.0"
            )
            request.assert_called_once_with(
                f"https://raw.githubusercontent.com/plannotator/herdr-annotate/{SHA}/herdr-annotate.version",
                timeout=15,
            )
            for sha, filename in (
                ("../main", "herdr-annotate.version"),
                (SHA, "../install.sh"),
            ):
                with self.subTest(sha=sha, filename=filename), self.assertRaises(
                    ValueError
                ):
                    checker.fetch_metadata(sha, filename)
            self.assertEqual(request.call_count, 1)

    def test_malformed_response_bytes(self):
        for data in (b"\xff", b"0.1.0" + b" " * 124):
            with self.subTest(data=data), patch.object(
                checker.urllib.request.OpenerDirector, "open"
            ) as request:
                request.return_value.__enter__.return_value.read.return_value = data
                with self.assertRaises(ValueError):
                    checker.fetch_metadata(SHA, "herdr-annotate.version")

    def test_redirect_is_not_followed(self):
        with patch.object(checker.urllib.request.HTTPSHandler, "https_open") as request:
            response = request.return_value
            response.code = 302
            response.msg = "Found"
            response.info.return_value = {
                "Location": "https://example.invalid/metadata"
            }
            with self.assertRaisesRegex(ValueError, "HTTP Error 302"):
                checker.fetch_metadata(SHA, "herdr-annotate.version")
            request.assert_called_once()

    def test_fetch_errors(self):
        for error in (
            urllib.error.URLError("offline"),
            TimeoutError(),
            urllib.error.HTTPError("https://example.invalid", 404, "missing", {}, None),
        ):
            with self.subTest(error=error), patch.object(
                checker.urllib.request.OpenerDirector, "open", side_effect=error
            ):
                with self.assertRaisesRegex(ValueError, "cannot fetch"):
                    checker.fetch_metadata(SHA, "herdr-annotate.version")


if __name__ == "__main__":
    unittest.main()
