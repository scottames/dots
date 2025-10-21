return {
  -- https://ampcode.com/
  { -- https://github.com/sourcegraph/amp.nvim
    "sourcegraph/amp.nvim",
    branch = "main",
    opts = { auto_start = false, log_level = "info" },
    keys = {
      {
        "<leader>asa",
        function()
          require("amp").start()
        end,
        desc = "Amp Start",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>as", group = "Start AI Plugin" },
        { "<leader>at", group = "Sidekick Toggle" },
        { "<leader>ata", icon = { icon = " ", color = "red" } },
        { "<leader>atc", icon = { icon = " ", color = "orange" } },
        { "<leader>atg", icon = { icon = " ", color = "blue" } },
        { "<leader>ato", icon = { icon = " ", color = "grey" } },
        { "<leader>atq", icon = { icon = " ", color = "purple" } },
        { "<leader>atr", icon = { icon = " ", color = "cyan" } },
        { "<leader>atx", icon = { icon = " ", color = "grey" } },
      },
    },
  },
  { -- https://github.com/folke/sidekick.nvim
    "folke/sidekick.nvim",
    opts = {
      mux = {
        backend = "zellij",
        enabled = true,
      },
      cli = {
        tools = {
          amp = { cmd = { "amp", "--ide" } },
        },
      },
    },
    keys = {
      -- stylua: ignore
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick: Toggle CLI",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Sidekick: Select CLI",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>ae",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "x", "n" },
        desc = "Sidekick: Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Sidekick: Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Sidekick: Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick: Select Prompt",
      },
      -- direct toggles
      {
        "<leader>atc",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Claude",
      },
      {
        "<leader>atg",
        function()
          require("sidekick.cli").toggle({ name = "gemini", focus = true })
        end,
        desc = "Gemini",
      },
      {
        "<leader>ata",
        function()
          require("sidekick.cli").toggle({ name = "amp", focus = true })
        end,
        desc = "Amp",
      },
      {
        "<leader>ato",
        function()
          require("sidekick.cli").toggle({ name = "opencode", focus = true })
        end,
        desc = "Opencode",
      },
      {
        "<leader>atq",
        function()
          require("sidekick.cli").toggle({ name = "amazon_q", focus = true })
        end,
        desc = "Amazon Q",
      },
      {
        "<leader>atr",
        function()
          require("sidekick.cli").toggle({ name = "crush", focus = true })
        end,
        desc = "Crush",
      },
      {
        "<leader>atx",
        function()
          require("sidekick.cli").toggle({ name = "codex", focus = true })
        end,
        desc = "Codex",
      },
    },
  },
}
