-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt

local time = os.date("*t")
local hr = time.hour

if hr >= 24 and hr <= 24 then
  opt.background = "light"
end

-- ui

opt.conceallevel = 2
-- opt.breakindentopt = "sbr"
opt.linebreak = true -- lines wrap at words rather than random characters
opt.synmaxcol = 1024 -- don't syntax highlight long lines
opt.signcolumn = "yes:2"
opt.colorcolumn = "+1" -- Set the colour column to highlight one column after the 'textwidth'
vim.o.cmdheight = 2 -- Set command line height to two lines
vim.o.showbreak = [[↪ ]] -- Options include -> '…', '↳ ', '→','↪ '

-- indentation

opt.wrap = true
opt.wrapmargin = 2
opt.softtabstop = 2
opt.textwidth = 80
opt.shiftwidth = 2
opt.expandtab = true
opt.smarttab = true
-- opt.autoindent = true
-- opt.smartindent = true
-- opt.breakindent = true

-- title

vim.o.titlestring = " ❐ %t %r %m"
vim.o.titleold = '%{fnamemodify(getcwd(), ":t")}'
vim.o.title = true
vim.o.titlelen = 70

-- vi: ft=lua
