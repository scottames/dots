# Sourced by ~/.config/fish/conf.d/theme_colors.fish.
#
# Reads the semantic palette, not the theme's ANSI block. Aura's sixteen ANSI
# slots hold four hues, with orange in bright_red and purple in bright_green --
# so `fish_color_error brred` would render errors orange. Hexes sidestep that
# and reach `muted`, `blue` and `pink`, which the ANSI palette cannot express.
#
# Hexes are bare, with no leading `#`: in fish that would start a comment and
# the value would be silently dropped.
#
# Global scope on purpose: it shadows any leftover universal from an old
# `fish_config theme save`.

set -g fish_color_normal {{ substr 1 7 .fg }}
set -g fish_color_command {{ substr 1 7 .accent }}
set -g fish_color_keyword {{ substr 1 7 .red }}
set -g fish_color_quote {{ substr 1 7 .green }}
set -g fish_color_option {{ substr 1 7 .green }}
set -g fish_color_param {{ substr 1 7 .fg }}
set -g fish_color_redirection {{ substr 1 7 .pink }}
set -g fish_color_operator {{ substr 1 7 .cyan }}
set -g fish_color_escape {{ substr 1 7 .orange }}
set -g fish_color_end {{ substr 1 7 .orange }}
set -g fish_color_comment {{ substr 1 7 .muted }}
set -g fish_color_autosuggestion {{ substr 1 7 .fg_dim }}

set -g fish_color_error {{ substr 1 7 .red }}
set -g fish_color_cancel {{ substr 1 7 .red }}
set -g fish_color_status {{ substr 1 7 .red }}

set -g fish_color_cwd {{ substr 1 7 .yellow }}
set -g fish_color_cwd_root {{ substr 1 7 .red }}
set -g fish_color_user {{ substr 1 7 .cyan }}
set -g fish_color_host {{ substr 1 7 .blue }}
set -g fish_color_host_remote {{ substr 1 7 .green }}

set -g fish_color_selection --background={{ substr 1 7 .selection }}
set -g fish_color_search_match --background={{ substr 1 7 .selection }}
set -g fish_color_history_current --bold
set -g fish_color_valid_path --underline

set -g fish_pager_color_completion {{ substr 1 7 .fg }}
set -g fish_pager_color_description {{ substr 1 7 .muted }}
set -g fish_pager_color_prefix {{ substr 1 7 .pink }}
set -g fish_pager_color_progress {{ substr 1 7 .muted }}
set -g fish_pager_color_selected_background --background={{ substr 1 7 .selection }}
