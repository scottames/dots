return {
  -- A VS Code like winbar for Neovim
  { -- https://github.com/utilyre/barbecue.nvim
    "utilyre/barbecue.nvim",
    version = "*",
    dependencies = {
      "neovim/nvim-lspconfig",
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    event = "VeryLazy",
    config = function(_, opts)
      require("barbecue").setup(opts)
      vim.api.nvim_create_autocmd({
        "WinScrolled",
        "BufWinEnter",
        "CursorHold",
        "InsertLeave",

        -- include these if you have set `show_modified` to `true`
        "BufWritePost",
        "TextChanged",
        "TextChangedI",
      }, {
        group = vim.api.nvim_create_augroup("barbecue#create_autocmd", {}),
        callback = function()
          require("barbecue.ui").update()
        end,
      })
    end,
    opts = {
      ---whether to show/use navic in the winbar
      ---@type boolean
      show_navic = true,
      ---whether to attach navic to language servers automatically
      --https://github.com/utilyre/barbecue.nvim#-recipes
      --see also, lspconfig
      ---@type boolean
      attach_navic = false,
      ---whether to create winbar updater autocmd
      ---@type boolean
      create_autocmd = false,
      ---filetypes not to enable winbar in
      ---@type string[]
      exclude_filetypes = { "gitcommit", "toggleterm" },
      ---`auto` uses your current colorscheme's theme or generates a theme based on it
      ---`string` is the theme name to be used (theme should be located under `barbecue.theme` module)
      ---`barbecue.Theme` is a table that overrides the `auto` theme detection/generation
      ---@type "auto"|string|barbecue.Theme
      theme = "auto",
      symbols = {
        ---modification indicator
        ---@type string
        modified = "●",

        ---truncation indicator
        ---@type string
        ellipsis = "…",

        ---entry separator
        ---@type string
        -- separator = "",
        separator = "",
      },
      ---icons for different context entry kinds
      ---`false` to disable kind icons
      ---@type table<string, string>|false
      kinds = {
        File = "",
        Module = "",
        Namespace = "",
        Package = "",
        Class = "",
        Method = "",
        Property = "",
        Field = "",
        Constructor = "",
        Enum = "",
        Interface = "",
        Function = "",
        Variable = "",
        Constant = "",
        String = "",
        Number = "",
        Boolean = "",
        Array = "",
        Object = "",
        Key = "",
        Null = "",
        EnumMember = "",
        Struct = "",
        Event = "",
        Operator = "",
        TypeParameter = "",
      },
    },
  },

  -- Prismatic line decorations for the adventurous vim user
  { -- https://github.com/mvllow/modes.nvim
    "mvllow/modes.nvim",
    version = "*",
    event = "BufReadPre",
    config = true,
    opts = {
      colors = {
        copy = "#f5c359",
        delete = "#c75c6a",
        insert = "#78ccc5",
        visual = "#9745be",
      },

      -- Set opacity for cursorline and number background
      line_opacity = 0.25,

      -- Enable cursor highlights
      set_cursor = true,

      -- Enable cursorline initially, and disable cursorline for inactive windows
      -- or ignored filetypes
      set_cursorline = true,

      -- Enable line number highlights to match cursorline
      set_number = true,

      -- Disable modes highlights in specified filetypes
      -- Please PR commonly ignored filetypes
      ignore_filetypes = { "NvimTree", "TelescopePrompt" },
    },
  },

  -- virtual text and gutter signs to show available motions.
  { -- https://github.com/tris203/precognition.nvim
    "tris203/precognition.nvim",
    config = true,
    event = "BufAdd",
    keys = {
      {
        "<leader>up",
        function()
          require("precognition").toggle()
        end,
        desc = "Toggle Precognition",
      },
    },
  },

  -- Zellij nav
  { -- https://github.com/swaits/zellij-nav.nvim
    -- alt: https://github.com/numToStr/Navigator.nvim/compare/master...dynamotn:Navigator.nvim:master
    -- requires: https://github.com/hiasr/vim-zellij-navigator
    "swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    keys = {
      { "<c-h>", "<cmd>ZellijNavigateLeft<cr>", {
        silent = true,
        desc = "navigate left",
      } },
      { "<c-j>", "<cmd>ZellijNavigateDown<cr>", {
        silent = true,
        desc = "navigate down",
      } },
      { "<c-k>", "<cmd>ZellijNavigateUp<cr>", {
        silent = true,
        desc = "navigate up",
      } },
      { "<c-l>", "<cmd>ZellijNavigateRight<cr>", {
        silent = true,
        desc = "navigate right",
      } },
    },
    opts = {},
  },
}
