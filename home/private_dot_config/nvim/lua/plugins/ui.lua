return {
  -- IDE-like breadcrumbs
  { -- https://github.com/Bekaboo/dropbar.nvim
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    config = function()
      local dropbar_api = require("dropbar.api")
      vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
      vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
      vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
    end,
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
      ignore = { "NvimTree", "TelescopePrompt" },
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
      { "<c-Left>", "<cmd>ZellijNavigateLeft<cr>", {
        silent = true,
        desc = "navigate left",
      } },
      { "<c-j>", "<cmd>ZellijNavigateDown<cr>", {
        silent = true,
        desc = "navigate down",
      } },
      { "<c-Down>", "<cmd>ZellijNavigateDown<cr>", {
        silent = true,
        desc = "navigate down",
      } },
      { "<c-k>", "<cmd>ZellijNavigateUp<cr>", {
        silent = true,
        desc = "navigate up",
      } },
      { "<c-Up>", "<cmd>ZellijNavigateUp<cr>", {
        silent = true,
        desc = "navigate up",
      } },
      { "<c-l>", "<cmd>ZellijNavigateRight<cr>", {
        silent = true,
        desc = "navigate right",
      } },
      {
        "<c-Right>",
        "<cmd>ZellijNavigateRight<cr>",
        {
          silent = true,
          desc = "navigate right",
        },
      },
    },
    opts = {},
  },
}
