"""Check overview and launcher routes without applying config or reading input."""

import json
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class OverviewLauncherTests(unittest.TestCase):
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

    def test_builtin_exact_inputs_outputs_and_no_app_exclusions(self):
        manipulators = self.rules[4]["manipulators"]
        self.assertEqual(len(manipulators), 2)
        for manipulator, key, modifiers, output, output_modifiers in (
            (
                manipulators[0],
                "o",
                ["right_control", "option"],
                "f17",
                ["left_control", "left_command"],
            ),
            (
                manipulators[1],
                "spacebar",
                ["right_control"],
                "spacebar",
                ["left_command"],
            ),
        ):
            with self.subTest(key=key):
                self.assertEqual(
                    manipulator,
                    {
                        "type": "basic",
                        "from": {
                            "key_code": key,
                            "modifiers": {"mandatory": modifiers, "optional": []},
                        },
                        "to": [
                            {
                                "key_code": output,
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

    def test_voyager_overview_is_device_scoped_and_launcher_stays_native(self):
        self.assertEqual(
            self.rules[5]["manipulators"],
            [
                {
                    "type": "basic",
                    "from": {
                        "key_code": "o",
                        "modifiers": {"mandatory": ["left_command"], "optional": []},
                    },
                    "to": [
                        {
                            "key_code": "f17",
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
        for rule in self.rules:
            for manipulator in rule["manipulators"]:
                if manipulator["from"].get("key_code") == "spacebar":
                    self.assertEqual(
                        manipulator["from"]["modifiers"]["mandatory"], ["right_control"]
                    )
                    self.assertEqual(
                        manipulator["conditions"][0]["identifiers"],
                        [{"is_built_in_keyboard": True, "is_keyboard": True}],
                    )

    def test_overview_owns_a_private_output_not_the_old_app_chord(self):
        config = tomllib.loads(
            (ROOT / "home/private_dot_config/omniwm/settings.toml").read_text()
        )
        self.assertTrue(config["overview"]["enabled"])
        bindings = {b["id"]: b["binding"] for b in config["hotkeys"]}
        self.assertEqual(bindings["toggleOverview"], "Control+Command+F17")
        self.assertNotIn("Option+Shift+O", bindings.values())
        self.assertNotIn("Command+Space", bindings.values())


if __name__ == "__main__":
    unittest.main()
