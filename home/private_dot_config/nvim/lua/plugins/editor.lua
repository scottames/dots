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

  -- peek line
  { -- https://github.com/nacro90/numb.nvim
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = true,
  },

  -- splitjoin
  { -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-splitjoin.md
    "echasnovski/mini.splitjoin",
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
}
