return {
  -- lazy
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  { -- https://github.com/MeanderingProgrammer/markdown.nvim
    "MeanderingProgrammer/markdown.nvim",
    name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = true,
    ft = { "markdown", "txt" },
  },
  { -- https://github.com/hedyhli/markdown-toc.nvim
    "hedyhli/markdown-toc.nvim",
    config = true,
    ft = { "markdown" },
  },

  -- peek line
  { -- https://github.com/nacro90/numb.nvim
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = true,
  },

  -- splitjoin
  { -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-splitjoin.md
    "nvim-mini/mini.splitjoin",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    config = true,
    event = "VeryLazy",
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

  { -- https://www.lazyvim.org/extras/coding/nvim-cmp
    --   adds emoji (below) to completion
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources({
        { name = "lazydev" },
        { name = "nvim_lsp" },
        { name = "path" },
      }, {
        { name = "buffer" },
        { name = "emoji" },
      })
    end,
  },

  { -- https://github.com/Allaman/emoji.nvim
    "allaman/emoji.nvim",
    dependencies = {
      -- util for handling paths
      "nvim-lua/plenary.nvim",
      -- optional for nvim-cmp integration
      "hrsh7th/nvim-cmp",
      -- optional for telescope integration
      -- "nvim-telescope/telescope.nvim",
      -- optional for fzf-lua integration via vim.ui.select
      "ibhagwan/fzf-lua",
    },
    opts = {
      -- default is false, also needed for blink.cmp integration!
      enable_cmp_integration = true,
    },
    config = function(_, opts)
      local emoji = require("emoji")
      emoji.setup(opts)
      -- optional for telescope integration
      -- local ts = require("telescope").load_extension("emoji")
      vim.keymap.set("n", "<leader>se", emoji.insert, { desc = "[S]earch [E]moji" })
    end,
  },
}
