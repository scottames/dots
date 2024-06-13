return {
  -- alpha | dashboard
  -- { -- https://github.com/goolord/alpha-nvim
  --   "goolord/alpha-nvim",
  --   -- override defaults: https://github.com/LazyVim/LazyVim/blob/40113b2639ef8aa5cf44424ecfcec4dc1123c29a/lua/lazyvim/plugins/ui.lua#L220
  --   -- set 'Find file' to respect hidden=true by default
  --   opts = function(_, dashboard)
  --     table.remove(dashboard.section.buttons.val, 1)
  --     table.insert(
  --       dashboard.section.buttons.val,
  --       1,
  --       dashboard.button("f", " " .. " Find file", ":Telescope find_files hidden=true <CR>")
  --     )
  --   end,
  -- },

  -- statusline
  { -- https://github.com/nvim-lualine/lualine.nvim
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- opts.options.theme = "moonfly" -- muted
      -- opts.options.theme = "codedark" -- flat
      opts.options.theme = "ayu_dark" -- vibrant
      local icons = require("lazyvim.config").icons
      opts.sections.lualine_b = { { "branch", icon = "" } }
      opts.sections.lualine_c = {
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
        -- Disable navic - using barbecue instead (see below)
        -- stylua: ignore
        -- {
        --   function() return require("nvim-navic").get_location() end,
        --   cond = function() return package.loaded["nvim-navic"] and require("nvim-navic").is_available() end,
        -- },
      }
    end,
  },

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
  -- bufferline
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<leader>b<", "<cmd>BufferLineMovePrev<CR>", desc = "Buffer Move Prev" },
      { "<leader>b>", "<cmd>BufferLineMoveNext<CR>", desc = "Buffer Move Next" },
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
    },
  },

  -- buffer / mark / tabpage / colorscheme switcher
  { -- https://github.com/toppair/reach.nvim
    "toppair/reach.nvim",
    config = true,
    opts = {
      notifications = true,
    },
    keys = {
      {
        "<leader>bl",
        function()
          require("reach").buffers()
        end,
        desc = "List",
      },
      {
        "<leader>ut",
        function()
          require("reach").colorschemes()
        end,
        desc = "Toggle Colorscheme",
      },
      -- { "<leader>br", require("reach").buffers, desc = "Reach" },
      -- { "<leader>tt", require("reach").buffers, desc = "Colorscheme" },
      -- function() require('reach').buffers(buffer_options) end
    },
  },

  -- Cycle Buffers
  { -- https://github.com/ghillb/cybu.nvim
    "ghillb/cybu.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim" },
    event = "BufAdd",
    config = function()
      require("cybu").setup({
        display_time = 1000,
      })
    end,
    keys = {
      { "<S-h>", "<Plug>(CybuPrev)" },
      { "<S-l>", "<Plug>(CybuNext)" },
    },
  },

  -- nvim-notify
  {
    "rcarriga/nvim-notify",
    opts = {
      -- https://github.com/LazyVim/LazyVim/issues/511#issuecomment-1493763938
      on_open = function(win)
        vim.api.nvim_win_set_option(win, "winblend", 30)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
    },
  },

  -- minimap
  { -- https://github.com/gorbit99/codewindow.nvim
    "gorbit99/codewindow.nvim",
    config = true,
    init = function()
      require("which-key").register({
        mode = { "n", "v" },
        ["<leader>mm"] = { name = "+minimap" },
      })
    end,
    keys = {
      {
        "<leader>mmo",
        function()
          require("codewindow").open_minimap()
        end,
        desc = "Open minimap",
      },
      {
        "<leader>mmf",
        function()
          require("codewindow").toggle_focus()
        end,
        desc = "Toggle minimap focus",
      },
      {
        "<leader>mmc",
        function()
          require("codewindow").close_minimap()
        end,
        desc = "Close minimap",
      },
      {
        "<leader>mmm",
        function()
          require("codewindow").toggle_minimap()
        end,
        desc = "Toggle minimap",
      },
      {
        "<leader>mmt",
        function()
          require("codewindow").toggle_minimap()
        end,
        desc = "Minimap",
      },
    },
  },

  { -- https://github.com/ellisonleao/glow.nvim
    "ellisonleao/glow.nvim",
    ft = { "markdown" },
    keys = {
      { "<leader>tgo", "<cmd>:Glow<cr>", desc = "Glow Open" },
      { "<leader>tgc", "<cmd>:Glow!<cr>", desc = "Glow Open" },
    },
  },

  -- Edit and review GitHub issues and pull requests from the comfort of your favorite editor
  { -- https://github.com/pwntester/octo.nvim
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = true,
    cmd = { "Octo" },
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

  -- highlight colors
  { -- https://github.com/NvChad/nvim-colorizer.lua
    "NvChad/nvim-colorizer.lua",
    config = true,
    keys = {
      {
        "<leader>to",
        "<cmd>ColorizerToggle<cr>",
        desc = "Colorizer",
      },
    },
  },

  -- Pommodoro clock
  {
    "jackMort/pommodoro-clock.nvim",
    init = function()
      require("which-key").register({
        mode = { "n", "v" },
        ["<leader>tp"] = { name = "+pommodoro" },
      })
    end,
    config = true,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<leader>tpw",
        function()
          require("pommodoro-clock").start("work")
        end,
        desc = "Start Pommodoro",
      },
      {
        "<leader>tps",
        function()
          require("pommodoro-clock").start("short_break")
        end,
        desc = "Short Break",
      },
      {
        "<leader>tpl",
        function()
          require("pommodoro-clock").start("long_break")
        end,
        desc = "Long Break",
      },
      {
        "<leader>tpp",
        function()
          require("pommodoro-clock").toggle_pause()
        end,
        desc = "Toggle Pause",
      },
      {
        "<leader>tpc",
        function()
          require("pommodoro-clock").close()
        end,
        desc = "Close",
      },
    },
  },

  -- yazi
  { -- https://github.com/DreamMaoMao/yazi.nvim
    "DreamMaoMao/yazi.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },

    keys = {
      { "<leader>y", "<cmd>Yazi<CR>", desc = "Yazi (toggle)" },
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

  -- establish good command workflow and quit bad habits
  { -- https://github.com/m4xshen/hardtime.nvim
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    config = true,
    event = "BufAdd",
    keys = {
      { "<leader>ux", "<cmd>Hardtime toggle<CR>", desc = "Toggle Hardtime" },
    },
    opts = {
      disabled_filetypes = { "qf", "lazy", "mason", "neo-tree", "netrw", "NvimTree", "oil", "trouble" },
      disable_mouse = false,
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
}
