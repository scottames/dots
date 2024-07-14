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
        -- BEGIN_DEFAULT_ON_ATTACH
        vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, opts("CD"))
        vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts("Open: In Place"))
        vim.keymap.set("n", "<C-k>", api.node.show_info_popup, opts("Info"))
        vim.keymap.set("n", "<C-r>", api.fs.rename_sub, opts("Rename: Omit Filename"))
        vim.keymap.set("n", "<C-t>", api.node.open.tab, opts("Open: New Tab"))
        vim.keymap.set("n", "<C-v>", api.node.open.vertical, opts("Open: Vertical Split"))
        vim.keymap.set("n", "<C-x>", api.node.open.horizontal, opts("Open: Horizontal Split"))
        vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
        vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
        vim.keymap.set("n", "<Tab>", api.node.open.preview, opts("Open Preview"))
        vim.keymap.set("n", ">", api.node.navigate.sibling.next, opts("Next Sibling"))
        vim.keymap.set("n", "<", api.node.navigate.sibling.prev, opts("Previous Sibling"))
        vim.keymap.set("n", ".", api.node.run.cmd, opts("Run Command"))
        vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts("Up"))
        vim.keymap.set("n", "a", api.fs.create, opts("Create File Or Directory"))
        vim.keymap.set("n", "bd", api.marks.bulk.delete, opts("Delete Bookmarked"))
        vim.keymap.set("n", "bt", api.marks.bulk.trash, opts("Trash Bookmarked"))
        vim.keymap.set("n", "bmv", api.marks.bulk.move, opts("Move Bookmarked"))
        vim.keymap.set("n", "B", api.tree.toggle_no_buffer_filter, opts("Toggle Filter: No Buffer"))
        vim.keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
        vim.keymap.set("n", "C", api.tree.toggle_git_clean_filter, opts("Toggle Filter: Git Clean"))
        vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts("Prev Git"))
        vim.keymap.set("n", "]c", api.node.navigate.git.next, opts("Next Git"))
        vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
        vim.keymap.set("n", "D", api.fs.trash, opts("Trash"))
        vim.keymap.set("n", "E", api.tree.expand_all, opts("Expand All"))
        vim.keymap.set("n", "e", api.fs.rename_basename, opts("Rename: Basename"))
        vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts("Next Diagnostic"))
        vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts("Prev Diagnostic"))
        vim.keymap.set("n", "F", api.live_filter.clear, opts("Live Filter: Clear"))
        vim.keymap.set("n", "f", api.live_filter.start, opts("Live Filter: Start"))
        vim.keymap.set("n", "g?", api.tree.toggle_help, opts("Help"))
        vim.keymap.set("n", "gy", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
        vim.keymap.set("n", "ge", api.fs.copy.basename, opts("Copy Basename"))
        vim.keymap.set("n", "H", api.tree.toggle_hidden_filter, opts("Toggle Filter: Dotfiles"))
        vim.keymap.set("n", "I", api.tree.toggle_gitignore_filter, opts("Toggle Filter: Git Ignore"))
        vim.keymap.set("n", "J", api.node.navigate.sibling.last, opts("Last Sibling"))
        vim.keymap.set("n", "K", api.node.navigate.sibling.first, opts("First Sibling"))
        vim.keymap.set("n", "L", api.node.open.toggle_group_empty, opts("Toggle Group Empty"))
        vim.keymap.set("n", "M", api.tree.toggle_no_bookmark_filter, opts("Toggle Filter: No Bookmark"))
        vim.keymap.set("n", "m", api.marks.toggle, opts("Toggle Bookmark"))
        vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
        vim.keymap.set("n", "O", api.node.open.no_window_picker, opts("Open: No Window Picker"))
        vim.keymap.set("n", "p", api.fs.paste, opts("Paste"))
        vim.keymap.set("n", "P", api.node.navigate.parent, opts("Parent Directory"))
        vim.keymap.set("n", "q", api.tree.close, opts("Close"))
        vim.keymap.set("n", "r", api.fs.rename, opts("Rename"))
        vim.keymap.set("n", "R", api.tree.reload, opts("Refresh"))
        vim.keymap.set("n", "s", api.node.run.system, opts("Run System"))
        vim.keymap.set("n", "S", api.tree.search_node, opts("Search"))
        vim.keymap.set("n", "u", api.fs.rename_full, opts("Rename: Full Path"))
        vim.keymap.set("n", "U", api.tree.toggle_custom_filter, opts("Toggle Filter: Hidden"))
        vim.keymap.set("n", "W", api.tree.collapse_all, opts("Collapse"))
        vim.keymap.set("n", "x", api.fs.cut, opts("Cut"))
        vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
        vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))
        vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, opts("Open"))
        vim.keymap.set("n", "<2-RightMouse>", api.tree.change_root_to_node, opts("CD"))
        -- END_DEFAULT_ON_ATTACH

        vim.keymap.set("n", "Z", preview.watch, opts("Preview (Watch)"))
        vim.keymap.set("n", "<Esc>", preview.unwatch, opts("Close Preview/Unwatch"))

        -- Option A: Smart tab behavior: Only preview files, expand/collapse directories (recommended)
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
