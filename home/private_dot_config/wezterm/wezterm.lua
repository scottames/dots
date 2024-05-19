local k = require("keymaps")
local w = require("wezterm")

local c = {}

if w.config_builder then
	c = w.config_builder()
end

c.default_cursor_style = "BlinkingBar"
c.default_prog = { "fish", "-l" }
c.font = w.font("FiraCode Nerd Font Mono")
c.font_size = 13.5
c.hide_tab_bar_if_only_one_tab = true
c.leader = k.leader
c.keys = k.keys
c.tab_bar_at_bottom = true
-- c.window_decorations = "NONE"
c.window_background_opacity = 0.90
c.window_close_confirmation = "AlwaysPrompt"

local wayland_display = os.getenv("WAYLAND_DISPLAY")
if wayland_display then
	c.enable_wayland = true
end

local function get_appearance()
	if w.gui then
		return w.gui.get_appearance()
	end
	return "Dark"
end

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

c.color_scheme = scheme_for_appearance(get_appearance())

return c
