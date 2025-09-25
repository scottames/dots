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
  },
}
