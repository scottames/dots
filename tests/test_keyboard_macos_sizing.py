"""Check the Mac sizing routes without live input."""

import json
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SizingTests(unittest.TestCase):
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
        self.omniwm = tomllib.loads(
            (ROOT / "home/private_dot_config/omniwm/settings.toml").read_text()
        )

    def test_exact_builtin_enter_inputs_outputs_and_no_app_exclusions(self):
        manipulators = self.rules[8]["manipulators"]
        self.assertEqual(len(manipulators), 2)
        for manipulator, modifiers, output_modifiers in (
            (
                manipulators[0],
                ["right_control", "option"],
                ["left_control", "left_command"],
            ),
            (
                manipulators[1],
                ["right_control", "option", "shift"],
                ["left_control", "left_command", "left_shift"],
            ),
        ):
            with self.subTest(modifiers=modifiers):
                self.assertEqual(
                    manipulator,
                    {
                        "type": "basic",
                        "from": {
                            "key_code": "return_or_enter",
                            "modifiers": {"mandatory": modifiers, "optional": []},
                        },
                        "to": [
                            {
                                "key_code": "f18",
                                "modifiers": output_modifiers,
                                "repeat": False,
                            }
                        ],
                        "conditions": [
                            {
                                "type": "device_if",
                                "identifiers": [
                                    {
                                        "is_built_in_keyboard": True,
                                        "is_keyboard": True,
                                    }
                                ],
                            }
                        ],
                    },
                )

    def test_voyager_either_side_modifiers_exact_outputs_and_device_only(self):
        manipulators = self.rules[9]["manipulators"]
        self.assertEqual(len(manipulators), 2)
        for manipulator, modifiers, output_modifiers in (
            (
                manipulators[0],
                ["command", "option"],
                ["left_control", "left_command"],
            ),
            (
                manipulators[1],
                ["command", "option", "shift"],
                ["left_control", "left_command", "left_shift"],
            ),
        ):
            with self.subTest(modifiers=modifiers):
                self.assertEqual(
                    manipulator,
                    {
                        "type": "basic",
                        "from": {
                            "key_code": "return_or_enter",
                            "modifiers": {"mandatory": modifiers, "optional": []},
                        },
                        "to": [
                            {
                                "key_code": "f18",
                                "modifiers": output_modifiers,
                                "repeat": False,
                            }
                        ],
                        "conditions": [
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
                    },
                )

    def test_enter_without_option_and_builtin_command_enter_remain_unassigned(self):
        enter_inputs = [
            m
            for rule in self.rules
            for m in rule["manipulators"]
            if m["from"].get("key_code") in {"return_or_enter", "keypad_enter"}
        ]
        self.assertEqual(
            enter_inputs,
            self.rules[8]["manipulators"] + self.rules[9]["manipulators"],
        )
        for m in enter_inputs:
            self.assertIn("option", m["from"]["modifiers"]["mandatory"])
            identifiers = m["conditions"][0]["identifiers"]
            if identifiers == [{"is_built_in_keyboard": True, "is_keyboard": True}]:
                self.assertIn("right_control", m["from"]["modifiers"]["mandatory"])
            else:
                self.assertEqual(
                    identifiers,
                    [{"vendor_id": 12951, "product_id": 6519, "is_keyboard": True}],
                )

    def test_wm_actions_are_distinct_from_native_fullscreen_and_defaults_unchanged(
        self,
    ):
        bindings = {b["id"]: b["binding"] for b in self.omniwm["hotkeys"]}
        self.assertEqual(
            bindings["toggleContainerFullPrimarySpan"], "Control+Command+F18"
        )
        self.assertEqual(bindings["toggleFullscreen"], "Control+Shift+Command+F18")
        self.assertEqual(bindings["toggleNativeFullscreen"], "Unassigned")
        self.assertNotIn("Option+Return", bindings.values())
        self.assertEqual(self.omniwm["niri"]["defaultContainerPrimarySpan"], 0.5)
        self.assertEqual(self.omniwm["niri"]["resizeStepPercent"], 10)

    def test_builtin_preset_fill_exact_inputs_and_private_outputs(self):
        manipulators = self.rules[10]["manipulators"]
        self.assertEqual(len(manipulators), 2)
        for manipulator, key, output in (
            (manipulators[0], "r", "f19"),
            (manipulators[1], "f", "f20"),
        ):
            with self.subTest(key=key):
                self.assertEqual(
                    manipulator,
                    {
                        "type": "basic",
                        "from": {
                            "key_code": key,
                            "modifiers": {
                                "mandatory": ["right_control", "option"],
                                "optional": [],
                            },
                        },
                        "to": [
                            {
                                "key_code": output,
                                "modifiers": ["left_control", "left_command"],
                                "repeat": False,
                            }
                        ],
                        "conditions": [
                            {
                                "type": "device_if",
                                "identifiers": [
                                    {
                                        "is_built_in_keyboard": True,
                                        "is_keyboard": True,
                                    }
                                ],
                            }
                        ],
                    },
                )
        letter_inputs = [
            m
            for rule in self.rules
            for m in rule["manipulators"]
            if m["from"].get("key_code") in {"f", "r"}
            and any(action["key_code"] in {"f19", "f20"} for action in m["to"])
        ]
        self.assertEqual(letter_inputs, manipulators + self.rules[11]["manipulators"])

    def test_voyager_preset_only_exact_modifiers_device_and_private_output(self):
        self.assertEqual(
            self.rules[11]["manipulators"],
            [
                {
                    "type": "basic",
                    "from": {
                        "key_code": "r",
                        "modifiers": {
                            "mandatory": ["command", "option"],
                            "optional": [],
                        },
                    },
                    "to": [
                        {
                            "key_code": "f19",
                            "modifiers": ["left_control", "left_command"],
                            "repeat": False,
                        }
                    ],
                    "conditions": [
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
                }
            ],
        )

    def test_preset_fill_actions_and_presets_without_changing_height_reset(self):
        bindings = {b["id"]: b["binding"] for b in self.omniwm["hotkeys"]}
        self.assertEqual(bindings["cycleSizeForward"], "Control+Command+F19")
        self.assertEqual(
            bindings["expandContainerToAvailablePrimarySpan"], "Control+Command+F20"
        )
        self.assertEqual(bindings["cycleSizeBackward"], "Option+Comma")
        self.assertEqual(bindings["resetWindowSecondarySpan"], "Control+Option+R")
        self.assertEqual(
            self.omniwm["niri"]["containerPrimarySpanPresets"],
            [1 / 3, 0.5, 2 / 3, 0.75],
        )


if __name__ == "__main__":
    unittest.main()
