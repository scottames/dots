return {
  -- lazy
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  { -- https://github.com/MeanderingProgrammer/markdown.nvim
    "MeanderingProgrammer/markdown.nvim",
    name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = true,
    ft = { "markdown", "txt" },
    opts = {
      ignore = function()
        -- do not render markdown if any of these dirs
        local home = vim.env.HOME -- or: local home = os.getenv("HOME")
        local excluded_dirs = {
          home .. "/.obsidian",
        }
        local bufpath = vim.api.nvim_buf_get_name(0)
        for _, dir in ipairs(excluded_dirs) do
          if bufpath:find(dir, 1, true) then
            return true
          end
        end
        return true
      end,
      checkbox = {
        -- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'.
        -- There are two special states for unchecked & checked defined in the markdown grammar.

        -- Turn on / off checkbox state rendering.
        enabled = true,
        -- Additional modes to render checkboxes.
        render_modes = false,
        -- Render the bullet point before the checkbox.
        bullet = false,
        -- Padding to add to the left of checkboxes.
        left_pad = 0,
        -- Padding to add to the right of checkboxes.
        right_pad = 1,
        unchecked = {
          -- Replaces '[ ]' of 'task_list_marker_unchecked'.
          icon = "󰄱 ",
          -- Highlight for the unchecked icon.
          highlight = "RenderMarkdownUnchecked",
          -- Highlight for item associated with unchecked checkbox.
          scope_highlight = nil,
        },
        checked = {
          -- Replaces '[x]' of 'task_list_marker_checked'.
          icon = "󰱒 ",
          -- Highlight for the checked icon.
          highlight = "RenderMarkdownChecked",
          -- Highlight for item associated with checked checkbox.
          scope_highlight = nil,
        },
        -- Define custom checkbox states, more involved, not part of the markdown grammar.
        -- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | raw             | matched against the raw text of a 'shortcut_link'           |
        -- | rendered        | replaces the 'raw' value when rendering                     |
        -- | highlight       | highlight for the 'rendered' icon                           |
        -- | scope_highlight | optional highlight for item associated with custom checkbox |
        -- stylua: ignore
        custom = {
            todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo', scope_highlight = nil },
        },
        -- Priority to assign to scope highlight.
        scope_priority = nil,
      },
    },
  },
  { -- https://github.com/hedyhli/markdown-toc.nvim
    "hedyhli/markdown-toc.nvim",
    config = true,
    ft = { "markdown" },
  },

  -- peek line
  { -- https://github.com/nacro90/numb.nvim
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = true,
  },

  -- splitjoin
  { -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-splitjoin.md
    "nvim-mini/mini.splitjoin",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    config = true,
    event = "VeryLazy",
  },

  -- stay in place
  { -- https://github.com/gbprod/stay-in-place.nvim
    "gbprod/stay-in-place.nvim",
    config = true,
    keys = {
      ">",
      "<",
      "=",
      ">>",
      "<<",
      "==",
      ">",
      "<",
      "=",
    },
  },

  { -- https://www.lazyvim.org/extras/coding/nvim-cmp
    --   adds emoji (below) to completion
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources({
        { name = "lazydev" },
        { name = "nvim_lsp" },
        { name = "path" },
      }, {
        { name = "buffer" },
        { name = "emoji" },
      })
    end,
  },

  { -- https://github.com/Allaman/emoji.nvim
    "allaman/emoji.nvim",
    dependencies = {
      -- util for handling paths
      "nvim-lua/plenary.nvim",
      -- optional for nvim-cmp integration
      "hrsh7th/nvim-cmp",
      -- optional for telescope integration
      -- "nvim-telescope/telescope.nvim",
      -- optional for fzf-lua integration via vim.ui.select
      "ibhagwan/fzf-lua",
    },
    opts = {
      -- default is false, also needed for blink.cmp integration!
      enable_cmp_integration = true,
    },
    config = function(_, opts)
      local emoji = require("emoji")
      emoji.setup(opts)
      -- optional for telescope integration
      -- local ts = require("telescope").load_extension("emoji")
      vim.keymap.set("n", "<leader>se", emoji.insert, { desc = "[S]earch [E]moji" })
    end,
  },
}
