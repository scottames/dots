-- The active colorscheme is chosen outside neovim: ~/.config/themes/current is
-- a symlink re-pointed by `theme-set`, and the fragment it points at names a
-- genuine upstream port rather than carrying colors. Read at startup, so a
-- switch takes effect on the next launch.
local function active_colorscheme()
  local ok, theme = pcall(dofile, vim.fn.expand("~/.config/themes/current/nvim.lua"))
  if ok and type(theme) == "table" and type(theme.colorscheme) == "string" then
    return theme.colorscheme
  end
  return "aura-dark"
end

local colorscheme = active_colorscheme()
local is_aura = colorscheme:match("^aura") ~= nil

-- mix `fg` into `bg` by `alpha` (0..1)
local function blend(fg, bg, alpha)
  local function channel(i)
    local a = tonumber(fg:sub(i, i + 1), 16)
    local b = tonumber(bg:sub(i, i + 1), 16)
    return math.floor(b + (a - b) * alpha + 0.5)
  end
  return string.format("#%02x%02x%02x", channel(2), channel(4), channel(6))
end

local function lighten(hex, amount)
  return blend("#ffffff", hex, amount)
end

-- Aura's palette, populated once the colorscheme has loaded. Returns the
-- palette plus two derived shades, or nil if aura isn't loaded yet.
local function palette()
  local ok, p = pcall(require, "aura-theme.common.palette")
  if not ok or not p.black then
    return nil
  end
  return p,
    lighten(p.black, 0.06), -- raised: floats, statusline, context
    lighten(p.black, 0.16) -- dim: indent guides, listchars
end

-- Aura only defines base editor, syntax, and treesitter groups, and it runs
-- `hi clear` first -- so everything else falls back to Neovim's defaults, which
-- assume a different background and clash. Fill in the groups LazyVim's UI
-- actually leans on. Read the palette at runtime so all variants work.
local function overrides(args)
  -- aura sets `vim.g.colors_name` and then runs `hi clear`, which wipes it;
  -- plugins that branch on the colorscheme name get nil without this.
  vim.g.colors_name = args.match

  local p, raised, dim = palette()
  if not p then
    return
  end

  for group, hl in pairs({
    -- floats and window chrome
    NormalFloat = { fg = p.white, bg = raised },
    FloatBorder = { fg = p.purple_faded, bg = raised },
    FloatTitle = { fg = p.purple, bg = raised, bold = true },
    FloatFooter = { fg = p.gray, bg = raised },
    WinSeparator = { fg = p.purple_faded },
    WinBar = { fg = p.gray, bold = true },
    WinBarNC = { fg = p.gray },
    StatusLine = { fg = p.white, bg = raised },
    StatusLineNC = { fg = p.gray, bg = raised },
    MsgSeparator = { fg = p.purple_faded },

    -- misc ui
    ColorColumn = { bg = raised },
    CursorColumn = { bg = raised },
    Conceal = { fg = p.gray },
    NonText = { fg = dim },
    Whitespace = { fg = dim },
    QuickFixLine = { bg = p.purple_faded },

    -- diagnostics
    DiagnosticError = { fg = p.red },
    DiagnosticWarn = { fg = p.orange },
    DiagnosticInfo = { fg = p.blue },
    DiagnosticHint = { fg = p.purple },
    DiagnosticOk = { fg = p.green },
    DiagnosticUnderlineError = { undercurl = true, sp = p.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.purple },

    -- lsp (illuminate extra highlights references)
    LspReferenceText = { bg = p.purple_faded },
    LspReferenceRead = { bg = p.purple_faded },
    LspReferenceWrite = { bg = p.purple_faded },
    LspInlayHint = { fg = p.gray, italic = true },

    -- gitsigns and diff signs link to these
    Added = { fg = p.green },
    Changed = { fg = p.orange },
    Removed = { fg = p.red },

    -- indent-blankline / mini-indentscope extras
    IblIndent = { fg = dim },
    IblScope = { fg = p.purple },
    MiniIndentscopeSymbol = { fg = p.purple },

    -- treesitter-context extra
    TreesitterContext = { bg = raised },
    TreesitterContextLineNumber = { fg = p.purple, bg = raised },

    -- aura defines these with `gui=inverse`, so they render as solid bright
    -- slabs. render-markdown links its heading backgrounds straight at them
    -- (H1->DiffText, H2->DiffAdd, H3->DiffChange, H4->DiffDelete, H5->Visual),
    -- so re-casting them as tints fixes headings and diffs in one go.
    DiffAdd = { fg = p.green, bg = blend(p.green, p.black, 0.15) },
    DiffChange = { fg = p.blue, bg = blend(p.blue, p.black, 0.15) },
    DiffDelete = { fg = p.red, bg = blend(p.red, p.black, 0.15) },
    DiffText = { fg = p.orange, bg = blend(p.orange, p.black, 0.3) },
    Visual = { bg = p.purple_faded },
  }) do
    vim.api.nvim_set_hl(0, group, hl)
  end
end

return {
  { -- https://github.com/daltonmenezes/aura-theme
    "daltonmenezes/aura-theme",
    lazy = false,
    priority = 1000,
    -- The neovim port lives in a subdirectory of the monorepo, so lazy.nvim
    -- can't discover `colors/` on its own. `init` runs before any start plugin
    -- loads, so the rtp is ready by the time LazyVim applies the colorscheme.
    init = function(plugin)
      vim.opt.rtp:append(plugin.dir .. "/packages/neovim")

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("aura_overrides", { clear = true }),
        pattern = "aura-*",
        callback = overrides,
      })
    end,
  },

  { -- kept installed so `catppuccin-mocha` resolves when the theme switches
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
  },

  -- aura variants: aura-dark, aura-dark-soft-text, aura-soft-dark, aura-soft-dark-soft-text
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = colorscheme },
  },

  { -- aura ships no lualine theme, and lualine's `auto` fallback derives a
    -- washed out one from an already dark palette (grey on muddy purple, and
    -- an `inactive` identical to `normal`). Build it from the palette instead.
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- aura stays loaded even when it isn't the active scheme, so its palette
      -- is still readable; only build a lualine theme from it when it is.
      if not is_aura then
        return
      end

      local p, raised = palette()
      if not p then
        return
      end

      local function mode(color)
        return {
          a = { fg = p.black, bg = color, gui = "bold" },
          b = { fg = color, bg = raised },
          c = { fg = p.white, bg = raised },
        }
      end

      opts.options = opts.options or {}
      opts.options.theme = {
        normal = mode(p.purple),
        insert = mode(p.green),
        visual = mode(p.pink),
        replace = mode(p.red),
        command = mode(p.orange),
        terminal = mode(p.blue),
        inactive = {
          a = { fg = p.gray, bg = raised, gui = "bold" },
          b = { fg = p.gray, bg = raised },
          c = { fg = p.gray, bg = raised },
        },
      }
    end,
  },
}
