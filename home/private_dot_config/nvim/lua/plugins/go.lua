return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Disable golangci-lint-langserver for Go files
      if opts.servers and opts.servers.golangci_lint_langserver then
        opts.servers.golangci_lint_langserver = nil
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Configure Go formatters
      if opts.formatters_by_ft then
        opts.formatters_by_ft.go = {
          "gofumpt",
          "golines",
        }
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      -- Configure Go linters
      if opts.linters_by_ft then
        opts.linters_by_ft.go = {}
      end
    end,
  },
}
