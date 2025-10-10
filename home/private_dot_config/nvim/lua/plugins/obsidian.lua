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
    daily_notes = {
      -- folder = "notes/dailies",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%Y/%m/%Y-%m-%d, %a", -- YYYY/MM/YYYY-MM-DD, ddd
      -- Optional, if you want to change the date format of the default alias of daily notes.
      -- alias_format = "%B %-d, %Y",
      -- Optional, default tags to add to each new daily note created.
      -- default_tags = { "daily-notes" },
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "z.util/templates/journal - daily.md",
    },
    -- Optional, for templates (see below).
    templates = {
      folder = "z.util/templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      -- substitutions = {},
    },
    ui = {
      enable = false,
    },
  },
}
