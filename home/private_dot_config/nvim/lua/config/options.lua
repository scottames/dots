-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

local time = os.date("*t")
local hr = time.hour

if hr > 6 and hr < 20 then
  opt.background = "light"
end
