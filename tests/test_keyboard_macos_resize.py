"""Check incremental resize routing without live input."""

import copy
import json
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ResizeTests(unittest.TestCase):
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
        self.resize = self.rules[12]["manipulators"]
        self.voyager = self.rules[13]["manipulators"]
        self.omniwm = tomllib.loads(
            (ROOT / "home/private_dot_config/omniwm/settings.toml").read_text()
        )

    def test_exact_builtin_command_resize_inputs_outputs_and_device_scope(self):
        self.assertEqual(len(self.resize), 4)
        for manipulator, key, output, height in zip(
            self.resize,
            ["hyphen", "equal_sign", "hyphen", "equal_sign"],
            ["f18", "f19", "f18", "f19"],
            [False, False, True, True],
            strict=True,
        ):
            with self.subTest(key=key, height=height):
                self.assertEqual(
                    manipulator,
                    {
                        "type": "basic",
                        "from": {
                            "key_code": key,
                            "modifiers": {
                                "mandatory": ["right_control", "command"]
                                + (["shift"] if height else []),
                                "optional": [],
                            },
                        },
                        "to": [
                            {
                                "key_code": output,
                                "modifiers": [
                                    "left_control",
                                    "left_option",
                                    "left_command",
                                ]
                                + (["left_shift"] if height else []),
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

    def test_voyager_reuses_outputs_with_exact_either_side_modifiers_and_device(self):
        expected = copy.deepcopy(self.resize)
        for m in expected:
            modifiers = m["from"]["modifiers"]["mandatory"]
            m["from"]["modifiers"]["mandatory"] = ["command", "control"] + (
                ["shift"] if "shift" in modifiers else []
            )
            m["conditions"] = [
                {
                    "type": "device_if",
                    "identifiers": [
                        {"vendor_id": 12951, "product_id": 6519, "is_keyboard": True}
                    ],
                }
            ]
        self.assertEqual(self.voyager, expected)

    def test_resize_does_not_claim_option_input_or_builtin_native_editing(self):
        punctuation = [
            m
            for rule in self.rules
            for m in rule["manipulators"]
            if m["from"].get("key_code") in {"hyphen", "equal_sign", "keypad_hyphen"}
        ]
        self.assertEqual(punctuation, self.resize + self.voyager)
        for m in self.resize:
            mandatory = m["from"]["modifiers"]["mandatory"]
            self.assertNotIn("option", mandatory)
            self.assertNotIn("left_control", mandatory)
            self.assertIn("right_control", mandatory)
            self.assertIn("command", mandatory)
            self.assertEqual(m["from"]["modifiers"]["optional"], [])
        for m in self.voyager:
            self.assertNotIn("option", m["from"]["modifiers"]["mandatory"])
            self.assertEqual(m["from"]["modifiers"]["optional"], [])

    def test_private_resize_actions_ten_point_step_and_old_raw_chords_freed(self):
        bindings = {b["id"]: b["binding"] for b in self.omniwm["hotkeys"]}
        self.assertEqual(
            bindings["resizeContainerPrimarySpan.shrink"],
            "Control+Option+Command+F18",
        )
        self.assertEqual(
            bindings["resizeContainerPrimarySpan.grow"],
            "Control+Option+Command+F19",
        )
        self.assertEqual(bindings["resizeWindowSecondarySpan.shrink"], "Hyper+F18")
        self.assertEqual(bindings["resizeWindowSecondarySpan.grow"], "Hyper+F19")
        self.assertEqual(bindings["resizeWindowPrimarySpan.shrink"], "Unassigned")
        self.assertEqual(bindings["resizeWindowPrimarySpan.grow"], "Unassigned")
        self.assertEqual(self.omniwm["niri"]["resizeStepPercent"], 10)
        for chord in (
            "Option+Minus",
            "Option+Equal",
            "Option+Shift+Minus",
            "Option+Shift+Equal",
        ):
            self.assertNotIn(chord, bindings.values())


if __name__ == "__main__":
    unittest.main()
