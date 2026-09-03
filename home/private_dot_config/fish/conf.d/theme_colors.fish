#!/bin/env fish

# Syntax colors for the active theme. The fragment is written by chezmoi and
# re-pointed by theme-set; new shells pick up a switch, existing ones do not.
#
# Name matters: this must sort *after* any `fish_frozen_theme.fish` fish
# regenerates on upgrade, since whichever conf.d file runs last wins.

set -l _theme_colors "$HOME/.config/themes/current/fish.fish"

if test -f $_theme_colors
    source $_theme_colors
end
