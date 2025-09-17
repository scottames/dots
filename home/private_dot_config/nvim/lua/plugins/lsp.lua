local executable = function(bin)
  return function(_)
    local has_bin = vim.fn.executable(bin) == 1
    if not has_bin then
      vim.notify("Missing executable: " .. bin, vim.log.levels.WARN, { title = "LSP required bin missing" })
    end
    return has_bin
  end
end

return {
  { -- https://github.com/stevearc/conform.nvim
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      -- reference:
      --   https://github.com/folke/dot/blob/1007fc65738ad1f7a3e9c91432430017a6878378/nvim/lua/plugins/lsp.lua#L193
      --   https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatter-options
      formatters_by_ft = {
        awk = { "awk" },
        bash = { "shfmt" },
        css = { "stylelint" },
        cue = { "cue_fmt" },
        containerfile = { "dprint" },
        dockerfile = { "dprint" },
        fish = { "fish_indent" },
        hcl = { "terragrunt_hclfmt" },
        json = { { "prettierd_json", "prettier_json" } },
        justfile = { "just" },
        markdown = { "markdownlint", "markdown-toc" },
        ["markdown.mdx"] = { { "prettierd", "prettier" } },
        lua = { "stylua" },
        packer = { "packer_fmt" },
        python = { "auto_optional", "ruff_fix", "ruff_format", "isort" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        sql = { "sqlfluff" },
        terraform = { "terraform_fmt" },
        toml = { "taplo" },
        yaml = { "yamlfmt" },
        zsh = { "beautysh" },
      },
      formatters = {
        beautysh = {
          prepend_args = { "--indent-size", "2" },
        },
        goimports_reviser = {
          command = "goimports-reviser",
          -- prepend_args = { "-rmunused", "-set-alias" },
        },
        markdownlint = {
          prepend_args = { "--disable md013" },
        },
        dprint = {
          condition = function(ctx)
            return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
        -- Because they can only be installed via pip
        auto_optional = {
          condition = executable("auto-optional"),
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
        "alex",
        "buf",
        "buf-language-server",
        "checkmake",
        "commitlint",
        "snyk",
        "typos",
        "woke",
        "actionlint",
        "ansible-lint",
        "bash-debug-adapter",
        "bash-language-server",
        "beautysh",
        "black",
        "buf",
        "buf-language-server",
        "cuelsp",
        "cspell",
        "dockerfile-language-server",
        "dprint",
        "editorconfig-checker",
        -- "flake8", -- ruff instead
        "gitlint",
        "goimports",
        "goimports-reviser",
        "golangci-lint",
        "golangci-lint-langserver",
        "gofumpt",
        "golines",
        -- "gopls",
        "gotests",
        "gotestsum",
        "html-lsp",
        "isort",
        "jq",
        "jq-lsp",
        "json-lsp",
        "json-to-struct",
        "jsonlint",
        "lua-language-server",
        "luacheck",
        "luaformatter",
        "markdownlint",
        "markdown-toc",
        "marksman",
        "mypy",
        "nginx-language-server",
        "prettier",
        "prettierd",
        "pyproject-flake8",
        "pyright",
        "ruff",
        "ruff-lsp",
        "rust-analyzer",
        "rustfmt",
        "semgrep",
        "shellcheck",
        "shellharden",
        "shfmt",
        "sql-formatter",
        "sqlls",
        "sqlfluff",
        "stylua",
        "stylelint",
        "taplo",
        "textlint",
        "tflint",
        "tfsec",
        "yamlfmt",
        "yamllint",
      })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = {
        ["*"] = { "typos", "snyk_iac", "woke" },
        ansible = { "ansible_lint" },
        cue = { "cue" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        fish = { "fish" },
        git = { "commitlint" },
        html = { "tidy" },
        json = { "jsonlint" },
        lua = { "selene", "luacheck" },
        make = { "checkmake" },
        markdown = { "alex", "markdownlint" },
        protobuf = { "buf_lint" },
        python = { "bandit", "blocklint", "ruff", "mypy" },
        sql = { "sqlfluff" },
        systemd = { "systemdlint" },
        terraform = { "tfsec" },
        yaml = { "actionlint", "yamllint" },
        zsh = { "zsh" },
      }
      opts.linters = {
        actionlint = {
          condition = function()
            return string.find(vim.fn.expand("%:p"), ".github/workflows")
          end,
        },
        -- Example of using selene only when a selene.toml file is present
        selene = {
          condition = function(ctx)
            return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        -- Example of using luacheck only when a .luacheckrc file is present
        luacheck = {
          condition = function(ctx)
            return vim.fs.find({ ".luacheckrc" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        yamllint = {
          prepend_args = { "-d", "relaxed" },
        },
        -- Because they can only be installed via pip
        bandit = {
          condition = executable("bandit"),
        },
        blocklint = {
          condition = executable("blocklint"),
        },
        systemdlint = {
          condition = executable("systemdlint"),
        },
        tidy = {
          condition = executable("tidy"),
        },
      }
    end,
  },
}
