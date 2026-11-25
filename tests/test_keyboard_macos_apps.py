"""Check saved app routes, not physical input or Karabiner runtime behavior."""

import itertools
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILT_IN = {"is_built_in_keyboard": True, "is_keyboard": True}
VOYAGER = {"vendor_id": 12951, "product_id": 6519, "is_keyboard": True}
BROWSERS = (
    "app.zen-browser.zen",
    "com.google.Chrome",
    "org.mozilla.firefox",
    "com.apple.Safari",
)
TERMINALS = ("com.mitchellh.ghostty", "dev.herdr.app", "com.superlogical.rex")
GUI = "com.apple.TextEdit"
INPUTS = (
    (BUILT_IN, "right_control"),
    (VOYAGER, "left_control"),
    (VOYAGER, "right_control"),
)


class AppShortcutTests(unittest.TestCase):
    def setUp(self):
        config = json.loads(
            (
                ROOT
                / "home/private_dot_config/private_karabiner/private_karabiner.json"
            ).read_text()
        )
        self.rules = next(p for p in config["profiles"] if p.get("selected"))[
            "complex_modifications"
        ]["rules"]

    def route(self, device, app, key, modifiers):
        """Model exact saved-rule matching after Simple Modifications."""
        for rule in self.rules:
            for m in rule["manipulators"]:
                if m["from"].get("key_code") != key:
                    continue
                remaining = set(modifiers)
                for modifier in m["from"]["modifiers"]["mandatory"]:
                    choices = (
                        {f"left_{modifier}", f"right_{modifier}"}
                        if modifier in ("control", "command", "option", "shift")
                        else {modifier}
                    )
                    matched = remaining & choices
                    if not matched:
                        break
                    remaining -= matched
                else:
                    if remaining:
                        continue
                    for condition in m["conditions"]:
                        kind = condition["type"]
                        if kind == "device_if":
                            matches = any(
                                all(device.get(k) == v for k, v in identity.items())
                                for identity in condition["identifiers"]
                            )
                        else:
                            matches = any(
                                re.fullmatch(pattern, app)
                                for pattern in condition["bundle_identifiers"]
                            )
                            if kind == "frontmost_application_unless":
                                matches = not matches
                        if not matches:
                            break
                    else:
                        return m["to"]
        return [{"key_code": key, "modifiers": list(modifiers)}]

    def assert_native(self, device, app, key, modifiers):
        self.assertEqual(
            self.route(device, app, key, modifiers),
            [{"key_code": key, "modifiers": list(modifiers)}],
        )

    def assert_command(self, device, app, key, modifiers, shifted=False):
        output = ["left_command"] + (["left_shift"] if shifted else [])
        self.assertEqual(
            self.route(device, app, key, modifiers),
            [{"key_code": key, "modifiers": output, "repeat": False}],
        )

    def test_gui_shortcuts_and_redo_on_both_control_and_shift_sides(self):
        for (device, control), app in itertools.product(INPUTS, (GUI, *BROWSERS)):
            for key in ("z", "a", "f", "n"):
                with self.subTest(device=device, control=control, app=app, key=key):
                    self.assert_command(device, app, key, [control])
            for shift in ("left_shift", "right_shift"):
                self.assert_command(device, app, "z", [control, shift], shifted=True)
            if device == VOYAGER:
                self.assert_command(device, app, "k", [control])

    def test_browser_tabs_only_in_the_four_exact_browser_apps(self):
        for (device, control), app in itertools.product(INPUTS, BROWSERS):
            for key in ("t", "w"):
                self.assert_command(device, app, key, [control])
            for shift in ("left_shift", "right_shift"):
                self.assert_command(device, app, "t", [control, shift], shifted=True)
        for (device, control), app in itertools.product(
            INPUTS, (GUI, *TERMINALS, "com.google.Chrome.other", "org.mozilla.firefoxx")
        ):
            for key, extra in (("t", []), ("t", ["left_shift"]), ("w", [])):
                self.assert_native(device, app, key, [control, *extra])

    def test_terminal_control_is_preserved_except_for_explicit_paste(self):
        for (device, control), app in itertools.product(INPUTS, TERMINALS):
            for key in ("c", "z", "a", "f", "n", "t", "w", "x", "r"):
                self.assert_native(device, app, key, [control])
            if device == VOYAGER:
                self.assert_native(device, app, "k", [control])
            for key in ("z", "t"):
                for shift in ("left_shift", "right_shift"):
                    self.assert_native(device, app, key, [control, shift])
            self.assert_command(device, app, "v", [control])

    def test_paste_is_once_per_press_everywhere_on_both_keyboards(self):
        for (device, control), app in itertools.product(INPUTS, (GUI, *BROWSERS)):
            self.assert_command(device, app, "v", [control])

    def test_cut_and_browser_only_reload_on_both_control_sides(self):
        for device, control in INPUTS:
            for app in (GUI, *BROWSERS, "com.example.OtherGUI"):
                self.assert_command(device, app, "x", [control])
                if device == VOYAGER:
                    self.assert_native(device, app, "c", [control])
            for app in BROWSERS:
                self.assert_command(device, app, "r", [control])
            for app in (
                GUI,
                *TERMINALS,
                "com.google.Chrome.other",
                "org.mozilla.firefoxx",
            ):
                self.assert_native(device, app, "r", [control])

    def test_cut_reload_preserve_width_presets_in_every_app(self):
        for app, option, command in itertools.product(
            (GUI, *BROWSERS, *TERMINALS),
            ("left_option", "right_option"),
            ("left_command", "right_command"),
        ):
            for device, modifiers in (
                (BUILT_IN, ["right_control", option]),
                (VOYAGER, [command, option]),
            ):
                self.assertEqual(
                    self.route(device, app, "r", modifiers),
                    [
                        {
                            "key_code": "f19",
                            "modifiers": ["left_control", "left_command"],
                            "repeat": False,
                        }
                    ],
                )

    def test_builtin_physical_control_and_other_devices_are_not_app_remapped(self):
        other = {"vendor_id": 1000, "product_id": 2000, "is_keyboard": True}
        voyager_pointer = {**VOYAGER, "is_keyboard": False}
        for device, control in (
            (BUILT_IN, "left_control"),
            (other, "left_control"),
            (other, "right_control"),
            (voyager_pointer, "left_control"),
        ):
            for key in ("z", "a", "f", "k", "n", "v", "t", "w", "x", "r"):
                self.assert_native(device, BROWSERS[0], key, [control])
            for key in ("z", "t"):
                self.assert_native(device, BROWSERS[0], key, [control, "left_shift"])

    def test_unassigned_inputs_native_command_and_extra_modifiers_are_untouched(self):
        for device, control in INPUTS:
            for key in ("b", "e", "p", "return_or_enter", "tab", "q"):
                self.assert_native(device, BROWSERS[0], key, [control])
            self.assert_native(device, BROWSERS[0], "tab", [control, "left_shift"])
            self.assert_native(
                device, BROWSERS[0], "return_or_enter", [control, "left_shift"]
            )
            keys = ("z", "a", "f", "n", "v", "t", "w", "x", "r")
            if device == VOYAGER:
                keys += ("k",)
            for key in keys:
                self.assert_native(device, GUI, key, [])
                for command in ("left_command", "right_command"):
                    self.assert_native(device, BROWSERS[0], key, [command])
                    self.assert_native(device, BROWSERS[0], key, [control, command])
                for option in ("left_option", "right_option"):
                    if device == BUILT_IN and key in ("f", "r"):
                        self.assertEqual(
                            self.route(device, BROWSERS[0], key, [control, option]),
                            [
                                {
                                    "key_code": "f20" if key == "f" else "f19",
                                    "modifiers": ["left_control", "left_command"],
                                    "repeat": False,
                                }
                            ],
                        )
                    else:
                        self.assert_native(device, BROWSERS[0], key, [control, option])
            for key, shift in itertools.product(
                ("a", "f", "n", "v", "w", "x", "r"), ("left_shift", "right_shift")
            ):
                self.assert_native(device, BROWSERS[0], key, [control, shift])

    def test_caps_k_remains_wm_focus_in_every_app_without_a_duplicate_app_rule(self):
        for app in (GUI, *BROWSERS, *TERMINALS):
            self.assertEqual(
                self.route(BUILT_IN, app, "k", ["right_control"]),
                [{"key_code": "f15", "modifiers": ["left_control", "left_command"]}],
            )
        self.assertNotIn(
            "k", [m["from"]["key_code"] for m in self.rules[14]["manipulators"]]
        )

    def test_new_rules_have_only_exact_scoped_app_routes(self):
        for rule, device, control, count in (
            (self.rules[14], BUILT_IN, "right_control", 10),
            (self.rules[15], VOYAGER, "control", 12),
        ):
            self.assertEqual(len(rule["manipulators"]), count)
            seen = set()
            for m in rule["manipulators"]:
                key = m["from"]["key_code"]
                modifiers = m["from"]["modifiers"]
                self.assertEqual(modifiers["optional"], [])
                self.assertIn(modifiers["mandatory"], ([control], [control, "shift"]))
                signature = (key, tuple(modifiers["mandatory"]))
                self.assertNotIn(signature, seen)
                seen.add(signature)
                self.assertEqual(
                    m["conditions"][0],
                    {"type": "device_if", "identifiers": [device]},
                )
                self.assertEqual(m["type"], "basic")
                self.assertEqual(len(m["to"]), 1)
                self.assertEqual(set(m["to"][0]), {"key_code", "modifiers", "repeat"})
                self.assertEqual(m["to"][0]["key_code"], key)
                self.assertIs(m["to"][0]["repeat"], False)
                if key == "v":
                    self.assertEqual(len(m["conditions"]), 1)
                else:
                    expected_apps = BROWSERS if key in ("t", "w", "r") else TERMINALS
                    condition = m["conditions"][1]
                    self.assertEqual(len(m["conditions"]), 2)
                    self.assertEqual(
                        condition["type"],
                        (
                            "frontmost_application_if"
                            if key in ("t", "w", "r")
                            else "frontmost_application_unless"
                        ),
                    )
                    self.assertEqual(
                        condition["bundle_identifiers"],
                        ["^" + app.replace(".", r"\.") + "$" for app in expected_apps],
                    )

    def test_app_conditions_never_apply_to_wm_rules(self):
        for rule in self.rules[:14]:
            if rule is self.rules[1]:
                continue
            for m in rule["manipulators"]:
                self.assertEqual(len(m["conditions"]), 1)
                self.assertEqual(m["conditions"][0]["type"], "device_if")


if __name__ == "__main__":
    unittest.main()
