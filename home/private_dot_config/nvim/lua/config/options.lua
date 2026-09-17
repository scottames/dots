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
opt.tabstop = 2
opt.textwidth = 80
opt.shiftwidth = 2
opt.expandtab = true
opt.smarttab = true
-- opt.autoindent = true
-- opt.smartindent = true
-- opt.breakindent = true

-- Herdr forwards OSC 52 copies to its client, but does not support clipboard queries.
-- NVIM_CLIPBOARD=osc52 opts into copy + cached paste without any native reads.
local herdr = vim.env.HERDR_ENV == "1"
local osc52_only = vim.env.NVIM_CLIPBOARD == "osc52"
  or (not herdr and (vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil))
if herdr or osc52_only then
  opt.clipboard:append("unnamedplus")
  local cached = { { "" }, "v" }
  local osc52_copy = require("vim.ui.clipboard.osc52").copy("+")
  local paste_command
  if not osc52_only then
    if vim.fn.has("mac") == 1 then
      paste_command = { "pbpaste" }
    elseif vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
      paste_command = { "wl-paste", "--no-newline" }
    elseif vim.env.DISPLAY and vim.fn.executable("xsel") == 1 then
      paste_command = { "xsel", "--output", "--clipboard" }
    elseif vim.env.DISPLAY and vim.fn.executable("xclip") == 1 then
      paste_command = { "xclip", "-selection", "clipboard", "-o" }
    end
  end

  local function copy(lines, regtype)
    cached = { vim.deepcopy(lines), regtype }
    osc52_copy(lines)
  end

  local function paste()
    -- In remote herdr this is still the server's clipboard; use terminal paste
    -- for client clipboard contents. Bound reads so wl-paste cannot freeze Nvim.
    if paste_command then
      local ok, result = pcall(function()
        return vim.system(paste_command, { text = true }):wait(250)
      end)
      if ok and result.code == 0 then
        local lines = vim.split(result.stdout, "\n", { plain = true })
        if not vim.deep_equal(lines, cached[1]) then
          local regtype = "v"
          if #lines > 1 and lines[#lines] == "" then
            -- Nvim consumes the trailing empty item as the final newline.
            regtype = "V"
          end
          cached = { lines, regtype }
        end
      end
    end
    return cached
  end

  -- Herdr only forwards the standard clipboard, so both registers use it.
  vim.g.clipboard = {
    name = "OSC 52 with cached/native paste",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- title

vim.o.titlestring = " ❐ %t %r %m"
vim.o.titleold = '%{fnamemodify(getcwd(), ":t")}'
vim.o.title = true
vim.o.titlelen = 70

-- vi: ft=lua
