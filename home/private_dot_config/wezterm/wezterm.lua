local k = require("keymaps")
local w = require("wezterm")

local c = {}

if w.config_builder then
  c = w.config_builder()
end

c.color_scheme = "Catppuccin Mocha"
c.default_cursor_style = "BlinkingBar"
c.font = w.font("FiraCode Nerd Font Mono")
c.font_size = 13.5
c.hide_tab_bar_if_only_one_tab = true
c.leader = k.leader
c.keys = k.keys
c.tab_bar_at_bottom = true
c.window_decorations = "RESIZE"
c.window_background_opacity = 0.90
c.window_close_confirmation = "AlwaysPrompt"

return c
