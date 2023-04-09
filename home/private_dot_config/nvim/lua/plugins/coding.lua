return {
  -- comment
  { "echasnovski/mini.comment", enabled = false },
  { -- https://github.com/numToStr/Comment.nvim
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = true,
  },

  -- auto surround
  { "echasnovski/mini.surround", enabled = false },
  { -- https;//github.com/kylechui/nvim-surround
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = true,
  },

  -- tabout
  {
    "abecodes/tabout.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter", "nvim-cmp" },
    priority = 52, -- default is 50.. ensures tabout loaded after cmp
    config = true,
    opts = {
      tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
      backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
      act_as_tab = true, -- shift content if tab out is not possible
      act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
      default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
      default_shift_tab = "<C-d>", -- reverse shift default action,
      enable_backwards = true, -- well ...
      completion = true, -- if the tabkey is used in a completion pum
      tabouts = {
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = "`", close = "`" },
        { open = "(", close = ")" },
        { open = "[", close = "]" },
        { open = "{", close = "}" },
      },
      ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
      exclude = {}, -- tabout will ignore these filetypes
    },
  },

  -- autopairs
  { "echasnovski/mini.pairs", enabled = false },
  { -- https;//github.com/windwp/nvim-autopairs
    "windwp/nvim-autopairs",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    event = "VeryLazy",
    config = function(_, opts)
      require("nvim-autopairs").setup(opts)
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp_status_ok, cmp = pcall(require, "cmp")
      if not cmp_status_ok then
        return
      end
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({}))
    end,
    opts = {
      check_ts = true, -- treesitter integration
      disable_filetype = { "TelescopePrompt" },

      ts_config = {
        lua = { "string", "source" },
        avascript = { "string", "template_string" },
        ava = false,
      },

      fast_wrap = {
        map = "<M-e>",
        chars = { "{", "[", "(", '"', "'" },
        pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
        offset = 0, -- Offset from pattern match
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghkl",
        check_comma = true,
        highlight = "PmenuSel",
        highlight_grey = "LineNr",
      },
    },
  },

  -- toggle EOL chars
  { -- https://github.com/saifulapm/chartoggle.nvim
    "saifulapm/chartoggle.nvim",
    config = true,
    keys = function()
      local toggle_keys = { ",", ";" } -- which chars should be togglable at the end of any given line
      local keys = {}
      for _, k in ipairs(toggle_keys) do
        table.insert(keys, {
          "<leader>t" .. k,
          function()
            require("chartoggle").toggle(k)
          end,
          desc = "Toggle " .. k,
        })
      end
      return keys
    end,
    opts = { keys = {} }, -- clear the keymaps set by the plugin - use the above instead
  },

  -- better text objects
  {
    "echasnovski/mini.ai",
    keys = { { "[f", desc = "Prev function" }, { "]f", desc = "Next function" } },
    opts = function()
      -- add treesitter jumping
      ---@param capture string
      ---@param start boolean
      ---@param down boolean
      local function jump(capture, start, down)
        local rhs = function()
          local parser = vim.treesitter.get_parser()
          if not parser then
            return vim.notify("No treesitter parser for the current buffer", vim.log.levels.ERROR)
          end

          local query = vim.treesitter.get_query(vim.bo.filetype, "textobjects")
          if not query then
            return vim.notify("No textobjects query for the current buffer", vim.log.levels.ERROR)
          end

          local cursor = vim.api.nvim_win_get_cursor(0)

          ---@type {[1]:number, [2]:number}[]
          local locs = {}
          for _, tree in ipairs(parser:trees()) do
            for capture_id, node, _ in query:iter_captures(tree:root(), 0) do
              if query.captures[capture_id] == capture then
                local range = { node:range() } ---@type number[]
                local row = (start and range[1] or range[3]) + 1
                local col = (start and range[2] or range[4]) + 1
                if down and row > cursor[1] or (not down) and row < cursor[1] then
                  table.insert(locs, { row, col })
                end
              end
            end
          end
          return pcall(vim.api.nvim_win_set_cursor, 0, down and locs[1] or locs[#locs])
        end

        local c = capture:sub(1, 1):lower()
        local lhs = (down and "]" or "[") .. (start and c or c:upper())
        local desc = (down and "Next " or "Prev ") .. (start and "start" or "end") .. " of " .. capture:gsub("%..*", "")
        vim.keymap.set("n", lhs, rhs, { desc = desc })
      end

      for _, capture in ipairs({ "function.outer", "class.outer" }) do
        for _, start in ipairs({ true, false }) do
          for _, down in ipairs({ true, false }) do
            jump(capture, start, down)
          end
        end
      end
    end,
  },

  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cc",
        function()
          require("neogen").generate({})
        end,
        desc = "Neogen Comment",
      },
    },
    opts = { snippet_engine = "luasnip" },
  },

  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },

  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      {
        "<leader>r",
        function()
          require("refactoring").select_refactor()
        end,
        mode = "v",
        noremap = true,
        silent = true,
        expr = false,
      },
    },
    opts = {},
  },

  -- better yank/paste
  {
    "kkharji/sqlite.lua",
    enabled = function()
      return not jit.os:find("Windows")
    end,
  },

  -- Improved Yank and Put functionalities
  { -- https://github.com/gbprod/yanky.nvim
    "gbprod/yanky.nvim",
    -- event = "BufReadPost",  -- load on keys instead
    config = true,
    opts = {
      highlight = {
        timer = 150,
      },
      preserve_cursor_position = {
        enabled = true,
      },
      ring = {
        storage = "sqlite",
      },
    },
    keys = {
      { mode = { "n", "x" }, "y", "<Plug>(YankyYank)", desc = "Yank" },
      { mode = { "n", "x" }, "p", "<Plug>(YankyPutAfter)", desc = "Put After" },
      { mode = { "n", "x" }, "P", "<Plug>(YankyPutBefore)", desc = "Put Before" },
      { mode = { "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", desc = "GPut After" },
      { mode = { "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", desc = "GPut Before" },
      { mode = { "n" }, "<c-n>", "<Plug>(YankyCycleForward)", desc = "Yanky Cycle Forward" },
      { mode = { "n" }, "<c-p>", "<Plug>(YankyCycleBackward)", desc = "Yanky Cycle Backward" },
      { mode = { "n" }, "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Inent After Linewise" },
      { mode = { "n" }, "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Inent After Linewise" },
      { mode = { "n" }, "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Inent Before Linewise" },
      { mode = { "n" }, "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Inent Before Linewise" },
      { mode = { "n" }, ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put Inent After Shift Right" },
      { mode = { "n" }, "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put Indent After Shift Right" },
      { mode = { "n" }, ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Indent Before Shift Right" },
      { mode = { "n" }, "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Indent Before Shift Right" },
      { mode = { "n" }, "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Filter" },
      { mode = { "n" }, "=p", "<Plug>(YankyPutBeforeFilter)", desc = "Put Before Filter" },
      {
        mode = { "n" },
        "<leader>P",
        function()
          require("telescope").extensions.yank_history.yank_history({})
        end,
        desc = "Paste from Yanky",
      },
    },
  },

  -- better increase/descrease
  {
    "monaqa/dial.nvim",
    -- stylua: ignore
    keys = {
      { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
      { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.bool,
          augend.semver.alias.semver,
        },
      })
    end,
  },

  -- copilot
  {
    "zbirenbaum/copilot.lua",
    enabled = false,
    event = "VeryLazy",
    config = true,
  },

  -- Symbols outline (right pane navigation)
  {
    "simrat39/symbols-outline.nvim",
    keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    config = true,
  },

  {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip").filetype_extend("sh", { "shell" })
    end,
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    },
    opts = function()
      local cmp = require("cmp")
      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = function(_, item)
            local icons = require("lazyvim.config").icons.kinds
            if icons[item.kind] then
              item.kind = icons[item.kind] .. item.kind
            end
            return item
          end,
        },
        experimental = {
          ghost_text = {
            hl_group = "LspCodeLens",
          },
        },
      }
    end,
  },
}
