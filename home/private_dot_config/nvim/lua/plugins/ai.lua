return {
  {
    "folke/sidekick.nvim",
    opts = {
      mux = {
        backend = "zellij",
        enabled = true,
      },
    },
  -- stylua: ignore
  keys = {
    {
      "<leader>as",
      function() require("sidekick.cli").select({ filter = { installed = true } }) end,
      desc = "Select CLI",
    },
    -- direct toggles
    {
      "<leader>ac",
      function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>ao",
      function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end,
      desc = "Sidekick Toggle Opencode",
    },
    {
      "<leader>ag",
      function() require("sidekick.cli").toggle({ name = "gemini", focus = true }) end,
      desc = "Sidekick Toggle Gemini",
    },
  },
  },
  {
    "coder/claudecode.nvim",
    config = true,
    enabled = false,
    keys = {
      { "<leader>a", nil, desc = "ai" },
      { "<leader>ac", nil, desc = "claudecode" },
      { "<leader>acc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>acf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>acr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>acC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>acs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>acs",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil" },
      },
    },
  },
  {
    "NickvanDyke/opencode.nvim",
    enabled = false,
    dependencies = { "folke/snacks.nvim" },
    -- stylua: ignore
    keys = {
      { "<leader>ao", nil, desc = "opencode" },
      { '<leader>aot', function() require('opencode').toggle() end, desc = 'Toggle embedded opencode', },
      { '<leader>aoa', function() require('opencode').ask() end, desc = 'Ask opencode', mode = 'n', },
      { '<leader>aoa', function() require('opencode').ask('@selection: ') end, desc = 'Ask opencode about selection', mode = 'v', },
      { '<leader>aop', function() require('opencode').select_prompt() end, desc = 'Select prompt', mode = { 'n', 'v', }, },
      { '<leader>aon', function() require('opencode').command('session_new') end, desc = 'New session', },
      { '<leader>aoy', function() require('opencode').command('messages_copy') end, desc = 'Copy last message', },
      { '<S-C-u>',    function() require('opencode').command('messages_half_page_up') end, desc = 'Scroll messages up', },
      { '<S-C-d>',    function() require('opencode').command('messages_half_page_down') end, desc = 'Scroll messages down', },
    },
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = "*",
    enabled = false,
    opts = {
      -- TODO: add '<leader>ac' AvanteClear keymap
      behaviour = {
        auto_suggestions = false,
        enable_claude_text_editor_tool_mode = os.getenv("ANTHROPIC_API_KEY") ~= nil,
      },
      -- -- add any opts here
      -- -- for example
      -- provider = "openai",
      -- openai = {
      --   endpoint = "https://api.openai.com/v1",
      --   model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
      --   timeout = 30000, -- timeout in milliseconds
      --   temperature = 0, -- adjust if needed
      --   max_tokens = 4096,
      --   -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
      -- },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "nvim-mini/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      -- "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
