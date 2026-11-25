"""Check saved Voyager click routing, not live input, dragging or link opening."""

import itertools
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POINTER = {"vendor_id": 12951, "product_id": 6519, "is_pointing_device": True}
APPS = (
    "app.zen-browser.zen",
    "com.google.Chrome",
    "org.mozilla.firefox",
    "com.apple.Safari",
    "com.mitchellh.ghostty",
    "dev.herdr.app",
    "com.superlogical.rex",
)


class VoyagerClickTests(unittest.TestCase):
    def setUp(self):
        config = json.loads(
            (
                ROOT
                / "home/private_dot_config/private_karabiner/private_karabiner.json"
            ).read_text()
        )
        self.profile = next(p for p in config["profiles"] if p.get("selected"))
        self.pointer_inputs = [
            m
            for rule in self.profile["complex_modifications"]["rules"]
            for m in rule["manipulators"]
            if "pointing_button" in m["from"]
        ]

    def route(self, device, app, button, modifiers):
        """Model the exact saved pointer rule; do not simulate runtime releases."""
        for m in self.pointer_inputs:
            if m["from"]["pointing_button"] != button:
                continue
            if set(m["from"]["modifiers"]["mandatory"]) != set(modifiers):
                continue
            device_condition, app_condition = m["conditions"]
            if not any(
                all(device.get(k) == v for k, v in identity.items())
                for identity in device_condition["identifiers"]
            ):
                continue
            if any(
                re.fullmatch(pattern, app)
                for pattern in app_condition["bundle_identifiers"]
            ):
                return m["to"]
        return [{"pointing_button": button, "modifiers": list(modifiers)}]

    def test_one_exact_left_control_rule_with_no_executable_or_timed_actions(self):
        self.assertEqual(
            self.pointer_inputs,
            [
                {
                    "type": "basic",
                    "from": {
                        "pointing_button": "button1",
                        "modifiers": {
                            "mandatory": ["left_control"],
                            "optional": [],
                        },
                    },
                    "to": [
                        {
                            "pointing_button": "button1",
                            "modifiers": ["left_command"],
                            "repeat": False,
                        }
                    ],
                    "conditions": [
                        {"type": "device_if", "identifiers": [POINTER]},
                        {
                            "type": "frontmost_application_if",
                            "bundle_identifiers": [
                                "^" + app.replace(".", r"\.") + "$" for app in APPS
                            ],
                        },
                    ],
                }
            ],
        )

    def test_left_control_click_translates_in_each_browser_and_terminal_host(self):
        for app in APPS:
            with self.subTest(app=app):
                self.assertEqual(
                    self.route(POINTER, app, "button1", ["left_control"]),
                    [
                        {
                            "pointing_button": "button1",
                            "modifiers": ["left_command"],
                            "repeat": False,
                        }
                    ],
                )

    def test_plain_native_command_right_control_and_extra_modifiers_stay_native(self):
        modifiers = [[], ["right_control"], ["left_command"], ["right_command"]]
        modifiers += [
            ["left_control", extra]
            for extra in (
                "right_control",
                "left_shift",
                "right_shift",
                "left_option",
                "right_option",
                "left_command",
                "right_command",
                "fn",
            )
        ]
        for app, mods in itertools.product(APPS, modifiers):
            self.assertEqual(
                self.route(POINTER, app, "button1", mods),
                [{"pointing_button": "button1", "modifiers": mods}],
            )

    def test_secondary_middle_and_other_buttons_stay_native(self):
        for app, button, mods in itertools.product(
            APPS, ("button2", "button3", "button4", "button5"), ([], ["left_control"])
        ):
            self.assertEqual(
                self.route(POINTER, app, button, mods),
                [{"pointing_button": button, "modifiers": mods}],
            )

    def test_other_pointers_keyboard_interface_and_non_allowlisted_apps_stay_native(
        self,
    ):
        devices = (
            {"is_pointing_device": True, "is_built_in_pointing_device": True},
            {**POINTER, "vendor_id": 1},
            {**POINTER, "product_id": 1},
            {"vendor_id": 12951, "product_id": 6519, "is_keyboard": True},
        )
        for device, app in itertools.product(devices, APPS):
            self.assertEqual(
                self.route(device, app, "button1", ["left_control"]),
                [{"pointing_button": "button1", "modifiers": ["left_control"]}],
            )
        for app in ("com.apple.TextEdit", "com.apple.finder") + tuple(
            variant for name in APPS for variant in (name + ".other", "other." + name)
        ):
            self.assertEqual(
                self.route(POINTER, app, "button1", ["left_control"]),
                [{"pointing_button": "button1", "modifiers": ["left_control"]}],
            )

    def test_only_voyager_pointer_is_explicitly_enabled_without_motion_changes(self):
        self.assertEqual(
            [d for d in self.profile["devices"] if d["identifiers"] == POINTER],
            [{"identifiers": POINTER, "ignore": False}],
        )
        self.assertFalse(
            self.profile.get("ignore_pointing_device_events_by_default") is False
        )


if __name__ == "__main__":
    unittest.main()
