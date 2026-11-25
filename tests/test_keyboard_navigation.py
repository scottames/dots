"""Check the agreed navigation routes without devices or a running compositor."""

import json
import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "home/private_dot_config"
BUILT_IN = {"is_built_in_keyboard": True, "is_keyboard": True}
VOYAGER = {"vendor_id": 12951, "product_id": 6519, "is_keyboard": True}
DIRECTIONS = {
    "h": ("left_arrow", "Left", "left", "f13"),
    "j": ("down_arrow", "Down", "down", "f14"),
    "k": ("up_arrow", "Up", "up", "f15"),
    "l": ("right_arrow", "Right", "right", "f16"),
}


class NavigationTests(unittest.TestCase):
    def setUp(self):
        config = json.loads(
            (CONFIG / "private_karabiner/private_karabiner.json").read_text()
        )
        self.rules = next(p for p in config["profiles"] if p.get("selected"))[
            "complex_modifications"
        ]["rules"]
        omniwm = tomllib.loads((CONFIG / "omniwm/settings.toml").read_text())
        self.bindings = {b["id"]: b["binding"] for b in omniwm["hotkeys"]}
        self.hyper_modifiers = omniwm["general"]["hyperKeyModifiers"]
        text = (CONFIG / "niri/binds.kdl").read_text()
        self.niri = dict(re.findall(r"^\s*(\S+) \{ ([^{}]+); \}", text, re.M))

    def test_mac_monitor_inputs_outputs_devices_and_single_press(self):
        for index, device, base in (
            (6, BUILT_IN, ["right_control", "command"]),
            (7, VOYAGER, ["left_control", "left_command"]),
        ):
            expected = {}
            for letter, (arrow, _, direction, output) in DIRECTIONS.items():
                keys = [letter, arrow] if device == BUILT_IN else [arrow]
                for key in keys:
                    if direction in ("down", "up"):
                        expected[(key, tuple(base))] = output
                    expected[(key, (*base, "shift"))] = output
            actual = {}
            for m in self.rules[index]["manipulators"]:
                key = (
                    m["from"]["key_code"],
                    tuple(m["from"]["modifiers"]["mandatory"]),
                )
                self.assertNotIn(key, actual)
                actual[key] = m["to"][0]["key_code"]
                self.assertEqual(m["from"]["modifiers"]["optional"], [])
                self.assertEqual(
                    m["conditions"], [{"type": "device_if", "identifiers": [device]}]
                )
                modifiers = ["left_control", "left_option", "left_command"]
                if "shift" in key[1]:
                    modifiers.append("left_shift")
                self.assertEqual(
                    m["to"],
                    [
                        {
                            "key_code": expected[key],
                            "modifiers": modifiers,
                            "repeat": False,
                        }
                    ],
                )
            self.assertEqual(actual, expected)

    def test_mac_cycle_direction_transfer_scope_and_grave(self):
        self.assertEqual(self.hyper_modifiers, "Control+Option+Shift+Command")
        for action, output in (
            ("focusMonitorNext", "F14"),
            ("focusMonitorPrevious", "F15"),
        ):
            self.assertEqual(self.bindings[action], f"Control+Option+Command+{output}")
        for _, _, direction, output in DIRECTIONS.values():
            self.assertEqual(
                self.bindings[f"moveWindowToMonitor.{direction}"],
                f"Hyper+{output.upper()}",
            )
            self.assertEqual(
                self.bindings[f"moveWorkspaceToMonitor.{direction}"], "Unassigned"
            )
        self.assertEqual(self.bindings["focusMonitorLast"], "Control+Command+Grave")
        self.assertNotIn("Control+Shift+Command+Up Arrow", self.bindings.values())
        self.assertNotIn("Control+Shift+Command+Down Arrow", self.bindings.values())

    def test_mac_focus_follows_window_and_column_transfers(self):
        config = tomllib.loads((CONFIG / "omniwm/settings.toml").read_text())
        self.assertIs(config["focus"]["followsWindowToMonitor"], True)

    def test_mac_no_duplicate_inputs_or_option_navigation_ownership(self):
        inputs = set()
        for rule in self.rules:
            for m in rule["manipulators"]:
                device = json.dumps(m["conditions"][0], sort_keys=True)
                key = m["from"].get("key_code", "")
                event = key or m["from"]["pointing_button"]
                modifiers = tuple(sorted(m["from"]["modifiers"]["mandatory"]))
                identity = (device, event, modifiers)
                self.assertNotIn(identity, inputs)
                inputs.add(identity)
                if key in {"h", "j", "k", "l"} or key.endswith("_arrow"):
                    self.assertFalse(
                        {"option", "left_option", "right_option"} & set(modifiers)
                    )

    def test_linux_shift_moves_ctrl_targets_monitor_and_stack_is_preserved(self):
        moves = {
            "left": "move-column-left",
            "right": "move-column-right",
            "down": "move-window-down-or-to-workspace-down",
            "up": "move-window-up-or-to-workspace-up",
        }
        focuses = {
            "left": "focus-column-left",
            "right": "focus-column-right",
            "down": "focus-window-or-workspace-down",
            "up": "focus-window-or-workspace-up",
        }
        for letter, (_, arrow, direction, _) in DIRECTIONS.items():
            for key in (letter.upper(), arrow):
                self.assertEqual(self.niri[f"Mod+{key}"], focuses[direction])
                self.assertEqual(self.niri[f"Mod+Shift+{key}"], moves[direction])
                self.assertEqual(
                    self.niri[f"Mod+Ctrl+{key}"], f"focus-monitor-{direction}"
                )
                self.assertEqual(
                    self.niri[f"Mod+Shift+Ctrl+{key}"],
                    f"move-column-to-monitor-{direction}",
                )
        self.assertEqual(self.niri["Mod+Ctrl+Home"], "move-column-to-first")
        self.assertEqual(self.niri["Mod+Ctrl+End"], "move-column-to-last")
        for number in range(1, 10):
            self.assertEqual(
                self.niri[f"Mod+Ctrl+{number}"], f"move-column-to-workspace {number}"
            )

    def test_linux_caps_requires_device_and_virtual_marker_not_physical_ctrl(self):
        config = json.loads((CONFIG / "xremap/keyboard.json").read_text())
        self.assertEqual(config["virtual_modifiers"], ["F24"])
        modmap = config["modmap"][0]
        self.assertEqual(modmap["remap"], {"CapsLock": ["F24", "Ctrl_L"]})
        keymap = config["keymap"][0]
        self.assertEqual(modmap["device"], keymap["device"])
        self.assertTrue(keymap["device"]["only"])
        self.assertEqual(keymap["device"]["not"], ["ids:0x3297:0x1977"])
        self.assertIs(keymap["exact_match"], True)
        self.assertNotIn("application", keymap)
        expected = {}
        for letter, (_, arrow, _, _) in DIRECTIONS.items():
            for key in (letter.upper(), arrow):
                for modifiers, output in (
                    ("", "Super"),
                    ("-Shift", "Super-Shift"),
                    ("-Super", "Super-Ctrl"),
                    ("-Super-Shift", "Super-Ctrl-Shift"),
                ):
                    expected[f"F24-Ctrl{modifiers}-{key}"] = f"{output}-{arrow}"
        self.assertEqual(keymap["remap"], expected)
        # Every output reaches the corresponding native Voyager binding.
        for output in expected.values():
            parts = output.split("-")
            modifiers = set(parts[:-1]) - {"Super"}
            prefix = "Mod"
            for modifier in ("Shift", "Ctrl"):
                if modifier in modifiers:
                    prefix += f"+{modifier}"
            self.assertIn(f"{prefix}+{parts[-1]}", self.niri)


if __name__ == "__main__":
    unittest.main()
