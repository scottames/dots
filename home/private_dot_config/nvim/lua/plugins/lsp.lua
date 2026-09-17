return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = { enabled = false },
      },
    },
  },

  { -- https://github.com/stevearc/conform.nvim
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      -- reference:
      --   https://github.com/folke/dot/blob/1007fc65738ad1f7a3e9c91432430017a6878378/nvim/lua/plugins/lsp.lua#L193
      --   https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatter-options
      formatters_by_ft = {
        bash = { "shfmt" },
        fish = { "fish_indent" },
        json = { "prettier" },
        jsonc = { "prettier" },
        justfile = { "just" },
        markdown = { "protect_gh_alerts", "prettier" },
        ["markdown.mdx"] = { "prettier" },
        lua = { "stylua" },
        sh = { "shfmt" },
        toml = { "taplo" },
        yaml = { "prettier" },
      },
      formatters = {
        -- Protect GitHub-style alert blocks from Prettier reformatting
        -- https://github.com/prettier/prettier/issues/15479
        protect_gh_alerts = {
          meta = {
            url = "https://github.com/prettier/prettier/issues/15479",
            description = "Wrap GitHub-style alert blocks in prettier-ignore comments",
          },
          command = "lua",
          stdin = true,
          args = function()
            return { vim.fn.stdpath("config") .. "/lua/util/protect_gh_alerts.lua" }
          end,
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      { -- https://github.com/haringsrob/nvim_context_vt
        "haringsrob/nvim_context_vt",
        config = true,
      },
      { -- https://github.com/hiphish/rainbow-delimiters.nvim
        "hiphish/rainbow-delimiters.nvim",
      },
      -- not compatible with latest treesitter (required by Lazy)
      -- { -- https://github.com/IndianBoy42/tree-sitter-just
      --   "IndianBoy42/tree-sitter-just",
      --   config = true,
      -- },
    },
    opts = function(_, opts)
      opts.rainbow = {
        enable = true,
        -- list of languages you want to disable the plugin for
        -- disable = { "jsx", "cpp" },
        -- Also highlight non-bracket delimiters like html tags, boolean or
        --   table: lang -> boolean
        extended_mode = true,
        -- Do not enable for files with more than n lines, int
        max_file_lines = nil,
        -- colors = {}, -- table of hex strings
        -- termcolors = {} -- table of colour name strings
      }
      vim.list_extend(opts.ensure_installed, {
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
        "just",
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
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    dependencies = {
      "mason-org/mason-lspconfig.nvim",
    },
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        -- reference: https://mason-registry.dev/registry/list
        "jq-lsp",
        "json-lsp",
        "stylua",
      })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = {
        ["*"] = { "typos" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        fish = { "fish" },
        markdown = { "markdownlint" },
        yaml = { "actionlint", "yamllint" },
        zsh = { "zsh" },
      }
      opts.linters = {
        actionlint = {
          condition = function()
            return string.find(vim.fn.expand("%:p"), ".github/workflows")
          end,
        },
        yamllint = {
          prepend_args = { "-d", "relaxed" },
        },
      }
    end,
  },
}

-- vi: ft=lua
