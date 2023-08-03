return {

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      { -- https://github.com/mrjones2014/nvim-ts-rainbow
        "mrjones2014/nvim-ts-rainbow",
      },
      { -- https://github.com/haringsrob/nvim_context_vt
        "haringsrob/nvim_context_vt",
        config = true,
      },
      { -- https://github.com/nvim-treesitter/nvim-treesitter-context
        "nvim-treesitter/nvim-treesitter-context",
        config = true,
      },
    },
    opts = function(_, opts)
      local ensure_installed = {
        "bash",
        "css",
        "dockerfile",
        "fish",
        "gitignore",
        "go",
        "hcl",
        "html",
        "javascript",
        "json",
        "json5",
        "jsonc",
        "kdl",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      }
      opts.ensure_installed = require("util").merge_table(opts.ensure_installed, ensure_installed)
      opts.rainbow = {
        enable = true,
        -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
        extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
        max_file_lines = nil, -- Do not enable for files with more than n lines, int
        -- colors = {}, -- table of hex strings
        -- termcolors = {} -- table of colour name strings
      }
    end,
  },
}
