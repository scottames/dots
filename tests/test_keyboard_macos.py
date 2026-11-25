"""Check the saved Mac configuration without applying it or reading live input."""

import copy
import json
import os
import shutil
import subprocess  # nosec B404 - Local chezmoi with isolated temporary fixtures.
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = "private_dot_config/private_karabiner/private_karabiner.json"
OMNIWM = "private_dot_config/omniwm/settings.toml"
XREMAP = "private_dot_config/xremap/keyboard.json"
CHEZMOI = shutil.which("chezmoi")
BUILT_IN = {"is_built_in_keyboard": True, "is_keyboard": True}


class MacKeyboardTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((ROOT / "home" / CONFIG).read_text())
        self.profile = next(p for p in self.config["profiles"] if p.get("selected"))
        self.rules = self.profile["complex_modifications"]["rules"]

    def assert_safe_tree(self, value):
        if isinstance(value, dict):
            self.assertFalse(
                {"eval_js", "shell_command", "send_user_command"} & value.keys()
            )
            for child in value.values():
                self.assert_safe_tree(child)
        elif isinstance(value, list):
            for child in value:
                self.assert_safe_tree(child)

    def test_profiles_and_restricted_actions(self):
        self.assertEqual(
            [p["name"] for p in self.config["profiles"] if p.get("selected")],
            ["Unified keyboard"],
        )
        default = next(
            p for p in self.config["profiles"] if p["name"] == "Default profile"
        )
        self.assertFalse(default.get("complex_modifications", {}).get("rules"))
        self.assertFalse(default.get("simple_modifications"))
        self.assertFalse(default.get("devices"))
        self.assert_safe_tree(self.config)
        for rule in self.rules:
            for manipulator in rule["manipulators"]:
                self.assertEqual(manipulator["type"], "basic")
                for action in manipulator["to"]:
                    self.assertLessEqual(
                        action.keys(),
                        {"key_code", "pointing_button", "modifiers", "repeat"},
                    )
                    if "repeat" in action:
                        self.assertIs(action["repeat"], False)

    def test_restrictions_cover_disabled_profiles_and_nested_actions(self):
        for key in ("eval_js", "shell_command", "send_user_command"):
            with self.subTest(key=key):
                config = copy.deepcopy(self.config)
                config["profiles"].append(
                    {"selected": False, "delayed": [{"nested": {key: "not allowed"}}]}
                )
                with self.assertRaises(AssertionError):
                    self.assert_safe_tree(config)

    def test_caps_conversion_is_in_the_earlier_device_specific_stage(self):
        self.assertFalse(self.profile.get("simple_modifications"))
        self.assertEqual(
            self.profile["devices"],
            [
                {
                    "identifiers": {"is_keyboard": True},
                    "simple_modifications": [
                        {
                            "from": {"key_code": "caps_lock"},
                            "to": [{"key_code": "right_control"}],
                        }
                    ],
                },
                {
                    "identifiers": {
                        "vendor_id": 12951,
                        "product_id": 6519,
                        "is_pointing_device": True,
                    },
                    "ignore": False,
                },
            ],
        )

    def test_exact_inputs_device_scopes_and_terminal_exception(self):
        self.assertEqual(len(self.rules), 17)
        expected = [
            (
                ["left_arrow", "right_arrow", "down_arrow", "up_arrow"],
                "left_command",
            ),
            (
                [
                    "c",
                    "v",
                    "h",
                    "left_arrow",
                    "l",
                    "right_arrow",
                    "j",
                    "down_arrow",
                    "k",
                    "up_arrow",
                ],
                "right_control",
            ),
        ]
        outputs = {
            "c": "c",
            "v": "v",
            "h": "f13",
            "left_arrow": "f13",
            "l": "f16",
            "right_arrow": "f16",
            "j": "f14",
            "down_arrow": "f14",
            "k": "f15",
            "up_arrow": "f15",
        }
        for index, (keys, modifier) in enumerate(expected):
            manipulators = self.rules[index]["manipulators"]
            self.assertEqual([m["from"]["key_code"] for m in manipulators], keys)
            device = (
                {"vendor_id": 12951, "product_id": 6519, "is_keyboard": True}
                if index == 0
                else BUILT_IN
            )
            for m in manipulators:
                key = m["from"]["key_code"]
                self.assertEqual(
                    m["from"]["modifiers"], {"mandatory": [modifier], "optional": []}
                )
                conditions = [{"type": "device_if", "identifiers": [device]}]
                if key == "c":
                    conditions.append(
                        {
                            "type": "frontmost_application_unless",
                            "bundle_identifiers": [
                                "^com\\.mitchellh\\.ghostty$",
                                "^dev\\.herdr\\.app$",
                                "^com\\.superlogical\\.rex$",
                            ],
                        }
                    )
                self.assertEqual(m["conditions"], conditions)
                modifiers = ["left_command"]
                if key not in ("c", "v"):
                    modifiers.insert(0, "left_control")
                action = {"key_code": outputs[key], "modifiers": modifiers}
                if key == "v":
                    action["repeat"] = False
                self.assertEqual(m["to"], [action])

    def test_builtin_movement_owns_caps_or_control_shift_without_app_exclusions(self):
        outputs = {
            "h": "f13",
            "left_arrow": "f13",
            "l": "f16",
            "right_arrow": "f16",
            "j": "f14",
            "down_arrow": "f14",
            "k": "f15",
            "up_arrow": "f15",
        }
        manipulators = self.rules[2]["manipulators"]
        self.assertEqual([m["from"]["key_code"] for m in manipulators], list(outputs))
        for m in manipulators:
            with self.subTest(key=m["from"]["key_code"]):
                self.assertEqual(
                    m["from"]["modifiers"],
                    {"mandatory": ["control", "shift"], "optional": []},
                )
                self.assertEqual(
                    m["conditions"],
                    [{"type": "device_if", "identifiers": [BUILT_IN]}],
                )
                self.assertEqual(
                    m["to"],
                    [
                        {
                            "key_code": outputs[m["from"]["key_code"]],
                            "modifiers": ["left_control", "left_command", "left_shift"],
                        }
                    ],
                )

    def test_voyager_movement_uses_shift_and_leaves_control_for_monitors(self):
        outputs = {
            "left_arrow": "f13",
            "right_arrow": "f16",
            "down_arrow": "f14",
            "up_arrow": "f15",
        }
        manipulators = self.rules[3]["manipulators"]
        self.assertEqual([m["from"]["key_code"] for m in manipulators], list(outputs))
        for m in manipulators:
            with self.subTest(key=m["from"]["key_code"]):
                self.assertEqual(
                    m["from"]["modifiers"],
                    {"mandatory": ["left_command", "shift"], "optional": []},
                )
                self.assertEqual(
                    m["conditions"],
                    [
                        {
                            "type": "device_if",
                            "identifiers": [
                                {
                                    "vendor_id": 12951,
                                    "product_id": 6519,
                                    "is_keyboard": True,
                                }
                            ],
                        }
                    ],
                )
                self.assertEqual(
                    m["to"],
                    [
                        {
                            "key_code": outputs[m["from"]["key_code"]],
                            "modifiers": ["left_control", "left_command", "left_shift"],
                        }
                    ],
                )

    def test_omniwm_outputs_and_duplicate_bindings(self):
        config = tomllib.loads((ROOT / "home" / OMNIWM).read_text())
        bindings = {b["id"]: b["binding"] for b in config["hotkeys"]}
        self.assertEqual(bindings["focus.left"], "Control+Command+F13")
        self.assertEqual(bindings["focus.right"], "Control+Command+F16")
        self.assertEqual(bindings["focusWindowOrWorkspaceDown"], "Control+Command+F14")
        self.assertEqual(bindings["focusWindowOrWorkspaceUp"], "Control+Command+F15")
        self.assertEqual(bindings["focus.down"], "Unassigned")
        self.assertEqual(bindings["focus.up"], "Unassigned")
        self.assertEqual(bindings["moveColumn.left"], "Control+Shift+Command+F13")
        self.assertEqual(bindings["moveColumn.right"], "Control+Shift+Command+F16")
        self.assertEqual(
            bindings["moveWindowDownOrToWorkspaceDown"], "Control+Shift+Command+F14"
        )
        self.assertEqual(
            bindings["moveWindowUpOrToWorkspaceUp"], "Control+Shift+Command+F15"
        )
        self.assertEqual(bindings["move.left"], "Unassigned")
        self.assertEqual(bindings["move.right"], "Unassigned")
        self.assertEqual(bindings["toggleWorkspaceLayout"], "Unassigned")
        self.assertEqual(len(bindings), len(config["hotkeys"]))
        assigned = [b for b in bindings.values() if b != "Unassigned"]
        self.assertEqual(len(assigned), len(set(assigned)))

    @unittest.skipUnless(CHEZMOI, "requires chezmoi")
    def test_chezmoi_scope_permissions_and_unmanaged_state(self):
        for platform in ("darwin", "linux"):
            with self.subTest(platform=platform), tempfile.TemporaryDirectory(
                prefix="keyboard-macos-"
            ) as temporary:
                directory = Path(temporary)
                source = directory / "source"
                home = directory / "home"
                home.mkdir()
                for relative in (CONFIG, OMNIWM, XREMAP):
                    target = source / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / "home" / relative, target)
                ignore = (ROOT / "home/.chezmoiignore").read_text()
                (source / ".chezmoiignore").write_text(
                    '{{- $_ := set .chezmoi "os" "' + platform + '" -}}\n' + ignore
                )
                config = directory / "chezmoi.json"
                config.write_text(
                    json.dumps(
                        {
                            "data": {
                                "desktop": {"session": "niri"},
                                "host": {"os_variant": platform},
                            }
                        }
                    )
                )
                command = [
                    CHEZMOI,
                    "--config",
                    str(config),
                    "--source",
                    str(source),
                    "--destination",
                    str(home),
                    "--cache",
                    str(directory / "cache"),
                    "--persistent-state",
                    str(directory / "state"),
                    "--no-pager",
                ]
                # Preserve current backups and the historical pre-rename backups.
                for relative in (
                    "assets/keep.json",
                    "keyboard-backups/keep",
                    "keyboard-trial-backups/keep",
                ):
                    path = home / ".config/karabiner" / relative
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("unmanaged\n")
                results = [
                    subprocess.run(  # nosec B603 - Explicit tool, temporary fixtures.
                        command + args,
                        env={**os.environ, "DISTROBOX_ENTER_PATH": ""},
                        capture_output=True,
                        text=True,
                        check=True,
                        timeout=30,
                    ).stdout
                    for args in (["dump", "--format=json"], ["diff"])
                ]
                state = json.loads(results[0])
                if platform == "darwin":
                    self.assertEqual(state[".config/karabiner"]["perm"], 0o700)
                    target = state[".config/karabiner/karabiner.json"]
                    self.assertEqual(target["perm"], 0o600)
                    self.assertEqual(json.loads(target["contents"]), self.config)
                    self.assertEqual(
                        target["contents"], (ROOT / "home" / CONFIG).read_text()
                    )
                    self.assertIn(".config/omniwm/settings.toml", state)
                    self.assertNotIn(".config/xremap/keyboard.json", state)
                else:
                    self.assertFalse(
                        any(
                            p.startswith((".config/karabiner", ".config/omniwm"))
                            for p in state
                        )
                    )
                    xremap_config = state[".config/xremap/keyboard.json"]
                    self.assertEqual(
                        json.loads(xremap_config["contents"]),
                        json.loads((ROOT / "home" / XREMAP).read_text()),
                    )
                self.assertNotIn("keep.json", results[1])
                self.assertNotIn("keyboard-backups/keep", results[1])
                self.assertNotIn("keyboard-trial-backups/keep", results[1])


if __name__ == "__main__":
    unittest.main()
