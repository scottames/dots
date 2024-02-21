---@type lspconfig.options
local servers = {
  -- reference: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
  bashls = {},
  bufls = {},
  cssls = {},
  dagger = {},
  dockerls = {},
  golangci_lint_ls = {},
  gopls = {},
  html = {},
  -- https://lazyvim.github.io/plugins/extras/lang.json#nvim-lspconfig
  jsonls = {
    -- lazy-load schemastore when needed
    on_new_config = function(new_config)
      new_config.settings.json.schemas = new_config.settings.json.schemas or {}
      vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = {
      json = {
        format = { enable = true },
        validate = { enable = true },
      },
    },
  },
  marksman = {},
  pyright = {},
  rust_analyzer = {},
  sqlls = {},
  taplo = {},
  terraformls = {},
  tflint = {},
  tsserver = {},
  -- yamlls = {}, # TODO: reduce the noise!
  lua_ls = {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        completion = { callSnippet = "Replace" },
      },
    },
  },
}

local on_attach = function(client, bufnr)
  if client.server_capabilities["documentSymbolProvider"] then
    require("nvim-navic").attach(client, bufnr)
  end
end

local executable = function(bin)
  return function(_)
    local has_bin = vim.fn.executable(bin) == 1
    if not has_bin then
      vim.notify = require("notify")
      vim.notify(
        "(" .. tostring(has_bin) .. ")missing executable: " .. bin,
        vim.log.levels.WARN,
        { title = "LSP required bin missing" }
      )
    end
    return has_bin
  end
end

for server, _ in pairs(servers) do
  servers[server]["on_attach"] = on_attach
end

vim.lsp.set_log_level("off")

return {
  {
    "b0o/SchemaStore.nvim",
    version = false, -- last release is way too old
  },
  {
    "neovim/nvim-lspconfig",
    version = false,
    ---@class PluginLspOpts
    opts = {
      servers = servers,
    },
    -- Example - add additional keymaps
    -- https://github.com/LazyVim/LazyVim/issues/93#issuecomment-1399453860
    -- init = function()
    --   local keys = require("lazyvim.plugins.lsp.keymaps").get()
    --   -- change a keymap
    --   keys[#keys + 1] = { "K", "<cmd>echo 'hello'<cr>" }
    --   -- disable a keymap
    --   keys[#keys + 1] = { "K", false }
    --   -- add a keymap
    --   keys[#keys + 1] = { "H", "<cmd>echo 'hello'<cr>" }
    -- end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      local ensure_installed = {
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
        "gopls",
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
        "yamlfmt",
        "yamllint",
      }
      opts.ensure_installed = require("util").merge_table(opts.ensure_installed, ensure_installed)
    end,
  }, -- formatters
  -- TODO: merge _by_ft into one table and call function in conform/lint to get the appropriate table
  {
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
        go = { "goimports-reviser", "gofumpt", "golines" },
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
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        ["*"] = { "typos", "snyk_iac", "woke" },
        ansible = { "ansible_lint" },
        cue = { "cue" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        fish = { "fish" },
        git = { "commitlint" },
        go = { "golangcilint" },
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
      },
      linters = {
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
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    enabled = false,
  },
  { -- https://github.com/ThePrimeagen/refactoring.nvim
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    config = true,
    keys = {
      {
        mode = { "v" },
        "<leader>cR",
        function()
          require("refactoring").select_refactor()
        end,
        desc = "Refactor",
      },
    },
  },
}
