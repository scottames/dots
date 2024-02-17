---@type lspconfig.options
local servers = {
  bashls = {},
  cssls = {},
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
        "actionlint",
        "bash-debug-adapter",
        "bash-language-server",
        "beautysh",
        "black",
        "cspell",
        "dockerfile-language-server",
        "editorconfig-checker",
        "flake8",
        "gitlint",
        "goimports",
        "goimports-reviser",
        "golangci-lint",
        "golangci-lint-langserver",
        "gopls",
        "gotests",
        "gotestsum",
        "html-lsp",
        "jq",
        "jq-lsp",
        "json-lsp",
        "json-to-struct",
        "jsonlint",
        "lua-language-server",
        "luacheck",
        "luaformatter",
        "markdownlint",
        "marksman",
        "mypy",
        "nginx-language-server",
        "pyproject-flake8",
        "pyright",
        "rust-analyzer",
        "rustfmt",
        "semgrep",
        "shellcheck",
        "shfmt",
        "sql-formatter",
        "sqlls",
        "stylua",
        "textlint",
        "tflint",
        "yamlfmt",
        "yamllint",
      }
      opts.ensure_installed = require("util").merge_table(opts.ensure_installed, ensure_installed)
    end,
  }, -- formatters
  {
    "nvimtools/none-ls.nvim",
    event = "BufReadPre",
    dependencies = { "mason.nvim" },
    opts = function()
      local nls = require("null-ls")
      return {
        sources = {
          nls.builtins.formatting.beautysh.with({ extra_args = { "--indent-size", "2" } }),
          nls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
          nls.builtins.formatting.fish_indent,
          nls.builtins.formatting.fixjson,
          nls.builtins.formatting.gofumpt,
          nls.builtins.formatting.goimports_reviser,
          nls.builtins.formatting.jq,
          -- nls.builtins.formatting.lua_format, -- causes this list to get all bunched up 😡
          nls.builtins.formatting.markdown_toc,
          nls.builtins.formatting.markdownlint.with({ extra_args = { "--disable md013" } }),
          -- nls.builtins.formatting.mdformat, -- causes checklists and other things to get all wonky :\
          nls.builtins.formatting.prettier.with({
            filetypes = {
              "css",
              "graphql",
              "handlebars",
              "html",
              "javascript",
              "javascriptreact",
              "json",
              "jsonc",
              "less",
              "scss",
              "toml",
              "typescript",
              "typescriptreact",
              "vue",
              -- "yaml",
              ---- markdown formatting lists is all wonky :\
              -- "markdown",
              -- "markdown.mdx",
            },
            extra_args = {
              "--no-semi",
              "--jsx-single-quote",
            },
          }),
          nls.builtins.formatting.rustfmt,
          nls.builtins.formatting.sqlfluff,
          nls.builtins.formatting.shfmt,
          nls.builtins.formatting.stylua,
          -- nls.builtins.formatting.terrafmt, -- causes neovim to freak out about file changed on markdown
          nls.builtins.formatting.terraform_fmt,
          nls.builtins.formatting.tidy,
          nls.builtins.formatting.usort,
          nls.builtins.formatting.yamlfmt, -- actions
          nls.builtins.code_actions.cspell,
          nls.builtins.code_actions.gitsigns,
          nls.builtins.code_actions.gomodifytags,
          nls.builtins.code_actions.shellcheck, --
          nls.builtins.code_actions.refactoring.with({
            extra_filetypes = { "terraform", "hcl" },
          }),
          --
          -- completion
          nls.builtins.completion.luasnip,
          nls.builtins.completion.spell,

          -- diagnostics
          nls.builtins.diagnostics.actionlint,
          nls.builtins.diagnostics.buildifier,
          nls.builtins.diagnostics.cfn_lint,
          nls.builtins.diagnostics.checkmake,
          nls.builtins.diagnostics.commitlint,
          nls.builtins.diagnostics.cspell.with({ extra_filetypes = { "markdown", "text" } }),
          nls.builtins.diagnostics.dotenv_linter, -- diagnostics.editorconfig_checker,
          nls.builtins.diagnostics.fish,
          nls.builtins.diagnostics.flake8,
          nls.builtins.diagnostics.gitlint,
          nls.builtins.diagnostics.golangci_lint,
          nls.builtins.diagnostics.jsonlint,
          nls.builtins.diagnostics.luacheck.with({ extra_args = { "--globals vim lvim" } }),
          nls.builtins.diagnostics.markdownlint.with({ extra_args = { "--disable md013" } }),
          nls.builtins.diagnostics.mypy,
          nls.builtins.diagnostics.protolint,
          nls.builtins.diagnostics.semgrep,
          nls.builtins.diagnostics.shellcheck,
          nls.builtins.diagnostics.tidy,
          nls.builtins.diagnostics.todo_comments,
          nls.builtins.diagnostics.yamllint.with({ extra_args = { "-d relaxed" } }),
          nls.builtins.diagnostics.zsh, -- hover
          nls.builtins.hover.dictionary,
        },
      }
    end,
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
