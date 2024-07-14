return {
  -- tmux integration
  { -- https://github.com/numToStr/Navigator.nvim
    "numToStr/Navigator.nvim",
    event = "VeryLazy",
    config = true,
    -- keys set in keymaps.lua
    enabled = os.getenv("TMUX") ~= nil, -- see also config/keymaps#10
  },

  -- prettier folding
  { -- https://github.com/anuvyklack/pretty-fold.nvim
    "anuvyklack/pretty-fold.nvim",
    config = true,
    event = "VeryLazy",
  },

  -- even better %
  { -- https://github.com/andymass/vim-matchup
    "andymass/vim-matchup",
    event = "BufReadPost",
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
    end,
  },

  -- which-key
  { -- https://github.com/folke/which-key.nvim
    "folke/which-key.nvim",
    opts = function(_, opts)
      require("which-key").add({
        {
          mode = { "n", "v" },
          -- { "<leader>gd", group = "diff" },
          { "<leader>i", group = "insert" },
          { "<leader>m", group = "markdown/mm" },
          { "<leader>t", group = "toggle" },
          { "<leader>z", group = "zen/focus" },
        },
      })
      opts.plugins = {
        spelling = true,
        presets = {
          operators = false,
        },
      }
    end,
  },

  -- file explorer
  { -- https://github.com/nvim-tree/nvim-tree.lua
    "kyazdani42/nvim-tree.lua",
    dependencies = {
      "b0o/nvim-tree-preview.lua", -- https://github.com/b0o/nvim-tree-preview.lua
      "nvim-lua/plenary.nvim",
    },
    config = true,
    keys = {
      {
        "<leader>3",
        function()
          -- require("neo-tree.command").execute({ action = "focus" })
          require("nvim-tree.api").tree.toggle()
        end,
        desc = "nvim-tree (root dir)",
      },
    },
    opts = {
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
      },
      on_attach = function(bufnr)
        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        local preview = require("nvim-tree-preview")
        local api = require("nvim-tree.api")

        api.config.mappings.default_on_attach(bufnr)

        vim.keymap.set("n", "Z", preview.watch, opts("Preview (Watch)"))
        vim.keymap.set("n", "<Esc>", preview.unwatch, opts("Close Preview/Unwatch"))

        -- Smart tab behavior: Only preview files, expand/collapse directories
        vim.keymap.set("n", "<Tab>", function()
          local ok, node = pcall(api.tree.get_node_under_cursor)
          if ok and node then
            if node.type == "directory" then
              api.node.open.edit()
            else
              preview.node(node, { toggle_focus = true })
            end
          end
        end, opts("Preview"))
      end,
    },
  },
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  -- {
  --   "nvim-neo-tree/neo-tree.nvim",
  --   keys = {
  --     {
  --       "<leader>3",
  --       function()
  --         require("neo-tree.command").execute({ action = "focus" })
  --       end,
  --       desc = "NeoTree (root dir)",
  --     },
  --   },
  --   opts = {
  --     filesystem = {
  --       follow_current_file = true,
  --       hijack_netrw_behavior = "open_current",
  --       -- show hidden
  --       filtered_items = {
  --         visible = true,
  --         hide_dotfiles = false,
  --         hide_gitignored = true,
  --       },
  --     },
  --   },
  -- },

  -- buffer remove (additional keys)
  {
    "echasnovski/mini.bufremove",
    keys = {
      {
        "<S-w>",
        function()
          require("mini.bufremove").delete(0, false)
        end,
        desc = "Delete Buffer",
      },
    },
  },

  -- diff viewer
  { -- https://github.com/sindrets/diffview.nvim
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    cmd = { "DiffviewOpen" },
    keys = {
      { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diff Open" },
      { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diff Close" },
      { "<leader>gds", "<cmd>DiffviewOpen -uno<cr>", desc = "Diff (Staged)" },
    },
  },

  -- link to browser
  {
    "ruifm/gitlinker.nvim",
    config = true,
    dependencies = "nvim-lua/plenary.nvim",
    keys = {
      { "<leader>gy", '<cmd>lua require"gitlinker".get_repo_url()<cr>', desc = "Yank Repo Url" },
      {
        "<leader>gB",
        function()
          require("gitlinker").get_repo_url({ action_callback = require("gitlinker.actions").open_in_browser })
        end,
        desc = "Open Browser (Repo)",
      },
      {
        "<leader>gb",
        function()
          require("gitlinker").get_buf_range_url(
            "n",
            { action_callback = require("gitlinker.actions").open_in_browser }
          )
        end,
        desc = "Open Browser (Range)",
      },
      {
        "<leader>gb",
        function()
          require("gitlinker").get_buf_range_url(
            "v",
            { action_callback = require("gitlinker.actions").open_in_browser }
          )
        end,
        mode = { "v" },
        desc = "Open Browser (Range)",
      },
    },
    opts = {
      -- -- defaults
      -- opts = {
      --   -- adds current line nr in the url for normal mode
      --   add_current_line_on_normal_mode = true,
      --   -- callback for what to do with the url
      --   action_callback = require("gitlinker.actions").copy_to_clipboard,
      --   -- print the url after performing the action
      --   print_url = true,
      -- },
      -- override the default mappings
      mappings = nil,
    },
  },

  -- zen + focus mode
  { -- https://github.com/Pocco81/true-zen.nvim
    -- alt: folke/zen-mode.nvim
    "Pocco81/true-zen.nvim",
    config = true,
    keys = {
      { "<leader>zn", ":TZNarrow<CR>", desc = "Narrow" },
      { "<leader>zn", ":'<,'>TZNarrow<CR>", mode = "v", desc = "Narrow" },
      { "<leader>zf", ":TZFocus<CR>", desc = "Focus" },
      { "<leader>zm", ":TZMinimalist<CR>", desc = "Minimalist" },
      { "<leader>za", ":TZAtaraxis<CR>", desc = "Ataraxis" },
    },
  },

  -- no neck pain!
  { -- https://github.com/shortcuts/no-neck-pain.nvim
    "shortcuts/no-neck-pain.nvim",
    config = true,
    version = "*",
    keys = {
      { "<leader>zN", ":NoNeckPain<CR>", desc = "No Neck Pain" },
    },
  },

  -- move windows
  { -- https://github.com/sindrets/winshift.nvim
    "sindrets/winshift.nvim",
    config = true,
    keys = {
      { "<leader>wm", ":WinShift<CR>", desc = "Move" },
      { "<C-W>m", ":WinShift<CR>", desc = "Move Window" },
      { "<leader>wx", ":WinShift swap<CR>", desc = "Swap" },
      { "<C-W>X", ":WinShift swap<CR>", desc = "Swap Window" },
    },
  },

  -- better escape
  { -- https://github.com/max397574/better-escape.nvim
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = true,
    opts = {
      mapping = { "jk", "kj" }, -- a table with mappings to use
      timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
      clear_empty_lines = false, -- clear line after escaping if there is only whitespace
    },
  },

  -- peek line
  { -- https://github.com/nacro90/numb.nvim
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = true,
  },

  -- stay in place
  { -- https://github.com/gbprod/stay-in-place.nvim
    "gbprod/stay-in-place.nvim",
    config = true,
    keys = {
      ">",
      "<",
      "=",
      ">>",
      "<<",
      "==",
      ">",
      "<",
      "=",
    },
  },

  -- Move & Duplicate Blocks
  { -- https://github.com/booperlv/nvim-gomove
    "booperlv/nvim-gomove",
    opts = {
      map_defaults = false, -- use keys defined below (better lazy loading)
      -- whether or not to reindent lines moved vertically (true/false)
      -- reindent = true,
      -- whether or not to undojoin same direction moves (true/false)
      -- undojoin = true,
      -- whether to not to move past end column when moving blocks horizontally, (true/false)
      -- move_past_end_col = false,
    },
    keys = {
      -- TODO: something better? 🤔
      -- { mode = { "n" }, "<S-h>", "<Plug>GoNSMLeft", desc = "Move Left" },
      -- { mode = { "n" }, "<S-j>", "<Plug>GoNSMDown", desc = "Move Down" },
      -- { mode = { "n" }, "<S-k>", "<Plug>GoNSMUp", desc = "Move Up" },
      -- { mode = { "n" }, "<S-l>", "<Plug>GoNSMRight", desc = "Move Right" },

      { mode = { "n" }, "<A-H>", "<Plug>GoNSDLeft", desc = "Duplicate Left" },
      { mode = { "n" }, "<A-J>", "<Plug>GoNSDDown", desc = "Duplicate Down" },
      { mode = { "n" }, "<A-K>", "<Plug>GoNSDUp", desc = "Duplicate Up" },
      { mode = { "n" }, "<A-L>", "<Plug>GoNSDRight", desc = "Duplicate Right" },

      -- TODO: something better? 🤔
      -- { mode = { "x" }, "<S-h>", "<Plug>GoVSMLeft", desc = "Move Left" },
      -- { mode = { "x" }, "<S-j>", "<Plug>GoVSMDown", desc = "Move Down" },
      -- { mode = { "x" }, "<S-k>", "<Plug>GoVSMUp", desc = "Move Up" },
      -- { mode = { "x" }, "<S-l>", "<Plug>GoVSMRight", desc = "Move Right" },

      { mode = { "x" }, "<A-H>", "<Plug>GoVSDLeft", desc = "Duplicate Left" },
      { mode = { "x" }, "<A-J>", "<Plug>GoVSDDown", desc = "Duplicate Down" },
      { mode = { "x" }, "<A-K>", "<Plug>GoVSDUp", desc = "Duplicate Up" },
      { mode = { "x" }, "<A-L>", "<Plug>GoVSDRight", desc = "Duplicate Right" },
    },
  },

  -- easier switching between 'soft' and 'hard' line wrapping in NeoVim
  { -- https://github.com/andrewferrier/wrapping.nvim
    "andrewferrier/wrapping.nvim",
    config = true,
    ft = {
      "asciidoc",
      "gitcommit",
      "latex",
      "mail",
      "markdown",
      "rst",
      "tex",
      "text",
      "txt",
    },
    opts = {
      create_keymappings = false,
    },
    keys = {
      -- {
      --   "[ow",
      --   function()
      --     require("wrapping").soft_wrap_mode()
      --   end,
      --   desc = "Soft Wrap Mode",
      -- },
      -- {
      --   "]ow",
      --   function()
      --     require("wrapping").hard_wrap_mode()
      --   end,
      --   desc = "Hard Wrap Mode",
      -- },
      {
        "<leader>tw",
        function()
          require("wrapping").toggle_wrap_mode()
        end,
        desc = "Wrap Mode",
      },
    },
  },

  -- better comment boxes
  {
    "LudoPinelli/comment-box.nvim",
    keys = {
      -- left aligned fixed size box with left aligned text
      { mode = { "n" }, "<Leader>ib", "<Cmd>lua require('comment-box').lbox()<CR>", desc = "Box Left-Aligned" },
      { mode = { "v" }, "<Leader>ib", "<Cmd>lua require('comment-box').lbox()<CR>", desc = "Box Left-Aligned" },

      -- centered adapted box with centered text
      { mode = { "n" }, "<Leader>ic", "<Cmd>lua require('comment-box').accbox()<CR>", desc = "Box Centered" },
      { mode = { "v" }, "<Leader>ic", "<Cmd>lua require('comment-box').accbox()<CR>", desc = "Box Centered" },

      -- centered line
      { mode = { "n" }, "<Leader>il", "<Cmd>lua require('comment-box').cline()<CR>", desc = "Centered Line" },
      { mode = { "i" }, "<M-l>", "<Cmd>lua require('comment-box').cline()<CR>", desc = "Centered Line" },
    },
    init = function()
      require("which-key").add({
        { "<leader>i", group = "insert" },
      })
    end,
  },

  -- splitjoin
  { -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-splitjoin.md
    "echasnovski/mini.splitjoin",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    config = true,
    event = "VeryLazy",
  },
}
