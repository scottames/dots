return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  event = {
    --   -- If you want to use the home shortcut '~' here you need to call
    --      'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    "BufReadPre "
      .. vim.fn.expand("~")
      .. "/.obsidian/this/*.md",
    "BufNewFile " .. vim.fn.expand("~") .. "/.obsidian/this/*.md",
  },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    workspaces = {
      {
        name = "this",
        path = "~/.obsidian/this",
      },
    },
    callbacks = {
      enter_note = function(note)
        vim.keymap.set("n", "<leader>ch", "<cmd>Obsidian toggle_checkbox<cr>", {
          buffer = note.bufnr,
          desc = "Toggle checkbox",
        })
      end,
    },
    daily_notes = {
      -- alias_format = "%B %-d, %Y",
      -- folder = "notes/dailies",
      date_format = "%Y/%m/%Y-%m-%d, %a", -- YYYY/MM/YYYY-MM-DD, ddd
      -- default_tags = { "daily-notes" },
      template = "z.util/templates/journal - daily.md",
    },
    templates = {
      folder = "z.util/templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      -- substitutions = {},
    },
    ui = { enable = false },
  },
}
