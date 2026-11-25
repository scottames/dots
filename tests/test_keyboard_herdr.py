"""Check Herdr navigation ownership without applying config or sending input."""

import json
import tomllib
import unittest
from pathlib import Path

CONFIG = Path(__file__).resolve().parents[1] / "home/private_dot_config"
DIRECTIONS = {"h": "left", "j": "down", "k": "up", "l": "right"}


class HerdrKeyboardTests(unittest.TestCase):
    def setUp(self):
        self.herdr = tomllib.loads((CONFIG / "herdr/config.base.toml").read_text())[
            "keys"
        ]
        self.app = json.loads((CONFIG / "herdr-app/keys.json").read_text())
        self.global_keys = self.app["global"]
        omniwm = tomllib.loads((CONFIG / "omniwm/settings.toml").read_text())
        self.wm = {h["id"]: h["binding"] for h in omniwm["hotkeys"]}

    def test_tabs_and_spaces_keep_letter_and_arrow_aliases(self):
        for letter, direction, herdr_action, app_action in (
            ("h", "left", "previous_tab", "tab.prev"),
            ("l", "right", "next_tab", "tab.next"),
            ("j", "down", "next_workspace", "space.next"),
            ("k", "up", "previous_workspace", "space.prev"),
        ):
            with self.subTest(direction=direction):
                self.assertEqual(
                    set(self.herdr[herdr_action]),
                    {f"ctrl+alt+{letter}", f"ctrl+alt+{direction}"},
                )
                for key in (letter, direction):
                    self.assertEqual(self.global_keys[f"ctrl-alt-{key}"], app_action)

    def test_panes_add_option_and_keep_prefix_aliases(self):
        for letter, direction in DIRECTIONS.items():
            with self.subTest(direction=direction):
                self.assertEqual(
                    set(self.herdr[f"focus_pane_{direction}"]),
                    {
                        f"prefix+{letter}",
                        f"prefix+{direction}",
                        f"ctrl+alt+shift+{letter}",
                        f"ctrl+alt+shift+{direction}",
                    },
                )
                for key in (letter, direction):
                    self.assertEqual(
                        self.global_keys[f"ctrl-alt-shift-{key}"],
                        f"pane.go:{direction}",
                    )
                    for section in self.app.values():
                        self.assertNotIn(f"ctrl-shift-{key}", section)

    def test_agents_use_brackets_without_shift(self):
        for bracket, herdr_action, app_action in (
            ("[", "previous_agent", "agent.prev"),
            ("]", "next_agent", "agent.next"),
        ):
            with self.subTest(bracket=bracket):
                self.assertEqual(self.herdr[herdr_action], f"ctrl+alt+{bracket}")
                self.assertEqual(self.global_keys[f"ctrl-alt-{bracket}"], app_action)

    def test_unused_wm_actions_are_unassigned_not_repurposed(self):
        for action in (
            "switchWorkspace.next",
            "switchWorkspace.previous",
            "focus.down",
            "focus.up",
            "moveWindowToWorkspaceUp",
            "moveWindowToWorkspaceDown",
            "move.left",
            "move.right",
            "move.down",
            "move.up",
        ):
            with self.subTest(action=action):
                self.assertEqual(self.wm[action], "Unassigned")

    def test_wm_does_not_claim_app_or_option_editing_arrows(self):
        for direction in DIRECTIONS.values():
            for modifiers in (
                "Option",
                "Option+Shift",
                "Control+Option",
                "Control+Option+Shift",
            ):
                with self.subTest(direction=direction, modifiers=modifiers):
                    self.assertNotIn(
                        f"{modifiers}+{direction.title()} Arrow", self.wm.values()
                    )

    def test_option_word_editing_and_command_option_panes_are_preserved(self):
        for direction, sequence in (("left", "\x1bb"), ("right", "\x1bf")):
            self.assertEqual(
                self.app["terminal"][f"alt-{direction}"], f"send:{sequence}"
            )
        for direction in DIRECTIONS.values():
            self.assertEqual(
                self.global_keys[f"cmd-alt-{direction}"], f"pane.go:{direction}"
            )
            self.assertEqual(
                self.global_keys[f"cmd-alt-shift-{direction}"], f"pane.swap:{direction}"
            )
        ghostty = (CONFIG / "ghostty/config.tmpl").read_text()
        self.assertNotIn("macos-option-as-alt", ghostty)
        for direction in ("left", "right"):
            self.assertIn(f"keybind = ctrl+alt+{direction}=unbind", ghostty)


if __name__ == "__main__":
    unittest.main()
