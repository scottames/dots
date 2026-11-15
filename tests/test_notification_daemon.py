"""Check notification selection with real chezmoi, without applying anything."""

import json
import os
import shutil
import subprocess  # nosec B404 - Local chezmoi rendering temporary fixtures.
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHEZMOI = shutil.which("chezmoi")
USER = ".config/systemd/user"
ACTIVATION = ".local/share/dbus-1/services/org.freedesktop.Notifications.service"


@unittest.skipUnless(CHEZMOI, "requires chezmoi")
class NotificationDaemonTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="notification-daemon-")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.source = self.directory / "source"
        self.home = self.directory / "home"
        self.home.mkdir()
        self.config = self.directory / "chezmoi.json"
        for relative in (
            ".chezmoiignore",
            "private_dot_config/hokum/create_config.kdl",
            "private_dot_config/mako/config.tmpl",
            "private_dot_config/systemd/user/symlink_hokum.service.tmpl",
            "private_dot_config/systemd/user/symlink_mako.service.tmpl",
            "private_dot_config/systemd/user/niri.service.wants/symlink_hokum.service.tmpl",
            "private_dot_config/systemd/user/niri.service.wants/symlink_mako.service.tmpl",
            "dot_local/share/dbus-1/services/symlink_org.freedesktop.Notifications.service.tmpl",
        ):
            destination = self.source / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / "home" / relative, destination)

    def configure(self, daemon="mako", session="niri", variant="silverblue"):
        desktop = {"session": session, "fonts": {"monospace": "monospace"}}
        if daemon is not None:
            desktop["notification_daemon"] = daemon
        self.config.write_text(
            json.dumps({"data": {"desktop": desktop, "host": {"os_variant": variant}}})
        )

    def chezmoi(self, *args, check=True):
        return subprocess.run(  # nosec B603 - Explicit local tool and temporary paths.
            [
                CHEZMOI,
                "--config",
                str(self.config),
                "--source",
                str(self.source),
                "--destination",
                str(self.home),
                "--cache",
                str(self.directory / "cache"),
                "--persistent-state",
                str(self.directory / "state"),
                "--no-pager",
                *args,
            ],
            env={**os.environ, "DISTROBOX_ENTER_PATH": ""},
            capture_output=True,
            text=True,
            check=check,
            timeout=30,
        )

    def state(self):
        return json.loads(self.chezmoi("dump", "--format=json").stdout)

    def test_selection_and_existing_host_default(self):
        for selection in ("hokum", "mako", None):
            with self.subTest(selection=selection):
                self.configure(selection)
                selected = selection or "mako"
                other = "mako" if selected == "hokum" else "hokum"
                state = self.state()
                self.assertEqual(
                    state[f"{USER}/{other}.service"]["linkname"], "/dev/null"
                )
                self.assertNotIn(f"{USER}/{selected}.service", state)
                self.assertEqual(
                    state[f"{USER}/niri.service.wants/{selected}.service"]["linkname"],
                    f"/usr/lib/systemd/user/{selected}.service",
                )
                self.assertNotIn(f"{USER}/niri.service.wants/{other}.service", state)
                vendor = (
                    "app.hokum.Notifications"
                    if selected == "hokum"
                    else "fr.emersion.mako"
                )
                self.assertEqual(
                    state[ACTIVATION]["linkname"],
                    f"/usr/share/dbus-1/services/{vendor}.service",
                )
                config = "config.kdl" if selected == "hokum" else "config"
                self.assertIn(f".config/{selected}/{config}", state)
                self.assertFalse(
                    any(path.startswith(f".config/{other}/") for path in state)
                )

    def test_switch_removes_old_startup_and_new_daemon_mask(self):
        for selected, other in (("hokum", "mako"), ("mako", "hokum")):
            with self.subTest(selected=selected):
                self.configure(selected)
                stale = (
                    (f"{USER}/{selected}.service", "/dev/null"),
                    (
                        f"{USER}/niri.service.wants/{other}.service",
                        f"/usr/lib/systemd/user/{other}.service",
                    ),
                )
                for path, target in stale:
                    destination = self.home / path
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.symlink_to(target)
                diff = self.chezmoi("diff").stdout
                for path, _ in stale:
                    self.assertIn(f"--- a/{path}\n+++ /dev/null", diff)
                    (self.home / path).unlink()

    def test_hokum_settings_are_preserved(self):
        self.configure("hokum")
        path = self.home / ".config/hokum/config.kdl"
        path.parent.mkdir(parents=True)
        settings = 'theme "current"\nbehaviour { do-not-disturb #true; }\n'
        path.write_text(settings)
        self.assertEqual(self.state()[".config/hokum/config.kdl"]["contents"], settings)

    def test_other_sessions_are_untouched(self):
        for session, variant in (("gnome", "silverblue"), ("aqua", "darwin")):
            with self.subTest(session=session):
                self.configure("hokum", session, variant)
                state = self.state()
                self.assertNotIn(ACTIVATION, state)
                self.assertFalse(any(path.endswith(".service") for path in state))
                self.assertNotIn(".config/hokum/config.kdl", state)
                self.assertNotIn(".config/mako/config", state)

    def test_invalid_selection_fails(self):
        self.configure("typo")
        result = self.chezmoi("dump", "--format=json", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            "desktop.notification_daemon must be mako or hokum", result.stderr
        )


if __name__ == "__main__":
    unittest.main()
