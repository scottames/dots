return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "ravenxrz/DAPInstall.nvim",
      },
      {
        "rcarriga/nvim-dap-ui",
      },
    },
    keys = {
      { "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle Breakpoint" },
      { "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", desc = "Step Into" },
      { "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", desc = "Step Over" },
      { "<leader>dO", "<cmd>lua require'dap'.step_out()<cr>", desc = "Step Out" },
      { "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>", desc = "Repl Toggle" },
      { "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>", desc = "Run Last" },
      { "<leader>du", "<cmd>lua require'dapui'.toggle()<cr>", desc = "UI Toggle" },
      { "<leader>dt", "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate DAP" },
    },
    config = function()
      require("which-key").add({
        { "<leader>d", group = "+dap" },
      })

      local dap_status_ok, dap = pcall(require, "dap")
      if not dap_status_ok then
        return
      end

      local dap_ui_status_ok, dapui = pcall(require, "dapui")
      if not dap_ui_status_ok then
        return
      end

      local dap_install_status_ok, dap_install = pcall(require, "dap-install")
      if not dap_install_status_ok then
        return
      end

      dap_install.setup({})

      dap_install.config("python", {})
      dap_install.config("go", {})
      -- add other configs here

      dapui.setup({
        expand_lines = true,
        icons = { expanded = "", collapsed = "", circular = "" },
        mappings = {
          -- Use a table to apply multiple mappings
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.33 },
              { id = "breakpoints", size = 0.17 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 0.33,
            position = "right",
          },
          {
            elements = {
              { id = "repl", size = 0.45 },
              { id = "console", size = 0.55 },
            },
            size = 0.27,
            position = "bottom",
          },
        },
        floating = {
          max_height = 0.9,
          max_width = 0.5, -- Floats will be treated as percentage of your screen.
          border = vim.g.border_chars, -- Border style. Can be 'single', 'double' or 'rounded'
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
      })

      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end

      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end --                                                                                                                                 { id = "console", size = 0.55 },
    end,
    opts = {},
  },
}
