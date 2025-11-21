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
        { "<leader>an", group = "Sidekick NES", icon = "󱎓" },
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
        backend = "zellij", -- or "tmux"
        enabled = false,
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
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
      {
        "<c-.>",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle()
        end,
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
        "<leader>ana",
        function()
          require("sidekick.nes").apply()
        end,
        desc = "Sidekick: NES apply",
      },
      {
        "<leader>anc",
        function()
          require("sidekick.nes").clear()
        end,
        desc = "Sidekick: NES clear",
      },
      {
        "<leader>and",
        function()
          require("sidekick.nes").disable()
        end,
        desc = "Sidekick: NES Disable",
      },
      {
        "<leader>ane",
        function()
          require("sidekick.nes").enable(true)
        end,
        desc = "Sidekick: NES enable",
      },
      {
        "<leader>anj",
        function()
          require("sidekick.nes").jump()
        end,
        desc = "Sidekick: NES jump",
      },
      {
        "<leader>ant",
        function()
          require("sidekick.nes").toggle()
        end,
        desc = "Sidekick: NES toggle",
      },
      {
        "<leader>anu",
        function()
          require("sidekick.nes").update()
        end,
        desc = "Sidekick: NES update",
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
