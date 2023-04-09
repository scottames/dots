-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = require("util").map
local opts_silent = { silent = true }
local opts_noremap_silent = { noremap = true, silent = true }
local opts_noremap_silent_expr = { noremap = true, silent = true, expr = true }

if os.getenv("TMUX") ~= nil then -- see also, plugins/editor#8
  -- remove the defaults for numToStr/Navigator.nvim
  --   https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua#L31-L36
  pcall(vim.keymap.del, "n", "<A-j>")
  pcall(vim.keymap.del, "n", "<A-k>")
  pcall(vim.keymap.del, "v", "<A-j>")
  pcall(vim.keymap.del, "i", "<A-j>")
  pcall(vim.keymap.del, "v", "<A-k>")
  pcall(vim.keymap.del, "i", "<A-k>")
  vim.keymap.set({ "n", "t" }, "<A-h>", "<CMD>NavigatorLeft<CR>")
  vim.keymap.set({ "n", "t" }, "<A-l>", "<CMD>NavigatorRight<CR>")
  vim.keymap.set({ "n", "t" }, "<A-k>", "<CMD>NavigatorUp<CR>")
  vim.keymap.set({ "n", "t" }, "<A-j>", "<CMD>NavigatorDown<CR>")
  vim.keymap.set({ "n", "t" }, "<A-p>", "<CMD>NavigatorPrevious<CR>")
end

-- Do not save deleted char to register
map("n", "x", '"_x', opts_noremap_silent)

-- Do not copy delete, change, and paste command
map("n", "c", [["_c]], opts_noremap_silent)
map("v", "c", [["_c]], opts_noremap_silent)
map("n", "d", [["_d]], opts_noremap_silent)
map("v", "d", [["_d]], opts_noremap_silent)
-- use `P` to keep register contents, `p` to override

-- Increment/decrement
map("n", "+", "<C-a>")
map("n", "-", "<C-x>")
map("n", "g+", "g<C-a>", { desc = "increment" })
map("n", "g-", "g<C-x>", { desc = "decrement" })

-- fold line
map("n", "J", "mzJ`z")

-- centered navigation
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
-- addionally: (currently makes ctrl+d/u jump back weirdly)
-- map("n", "<C-d>", "<C-d>zz")
-- map("n", "<C-u>", "<C-u>zz")

-- https://crates.io/crates/tmux-sessionizer
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- easier write
-- map("n", "<C-s>", ":w<CR>", {desc = "Write"}) -- save already mapped via LazyVim
map("n", "<C-s><C-a>", ":wa<CR>", { desc = "Write All" })

-- Select all
map("n", "<C-a><C-a>", "gg<S-v>G")

-- Yank all
map("n", "<leader>by", "<cmd>%y+<CR>", { noremap = true, silent = true, desc = "Yank Buffer" })

-- Format
map("n", "<leader>=", vim.lsp.buf.format, { desc = "Format Buffer" })

-- Reopen closed buffer
map("n", "<leader>br", "<cmd>e #<CR>", { noremap = true, silent = true, desc = "Reopen Last" })

-- replace the current word
map("n", "<leader>c/", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace Word (s//)" })

-- make current file executable!
map("n", "<leader>bx", "<cmd>!chmod +x %<CR>", { desc = "chmod +x %", silent = true })

-- Splits
map("n", "<leader>|", "<C-w>v", { desc = "split-window-right", silent = true })
map("n", "<leader>-", "<C-w>s", { desc = "split-window-down", silent = true })
map("n", "<leader>wv", "<C-w>v", { desc = "split-window-right", silent = true })
map("n", "<leader>wo", "<C-w>o", { desc = "delete-other-windows", silent = true })

--  quickfix list | https://neovim.io/doc/user/quickfix.html
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Quickfix Next" })
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "Quickfix Prev" })
map("n", "]l", "<cmd>lnext<CR>zz", { desc = "Quickfix Next Location" })
map("n", "[l", "<cmd>lprev<CR>zz", { desc = "Quickfix Prev Location" })

-- diagnostic
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Diagnostic Prev" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Diagnostic Next" })

-- Because sometimes they don't act the same
map("i", "<C-c>", "<Esc>")

-- Stay in indent mode
map("v", "<", "<gv", opts_silent)
map("v", ">", ">gv", opts_silent)

-- Move selected lines
map("v", "J", ":m '>+1<CR>gv=gv", opts_silent)
map("v", "K", ":m '<-2<CR>gv=gv", opts_silent)

-- https://github.com/sabah1994/dotfiles/blob/354f4eaae7829686ac25c749f452bc1966a2e945/nvim/lua/keyMappings.lua#L10-L58
-- avoid repeating hjkl keys
local avoid_hjkl_id
local function avoid_hjkl(mode, mov_keys)
  for _, key in ipairs(mov_keys) do
    local count = 0
    vim.keymap.set(mode, key, function()
      if count >= 5 then
        avoid_hjkl_id = vim.notify("Hold it Cowboy!", vim.log.levels.WARN, {
          icon = "🤠",
          replace = avoid_hjkl_id,
          keep = function()
            return count >= 5
          end,
        })
      else
        count = count + 1
        -- after 5 seconds decrement
        vim.defer_fn(function()
          count = count - 1
        end, 5000)
        return key
      end
    end, { expr = true })
  end
end

-- Hard mode toggle
HardMode = false
function ToggleHardMode()
  local modes = { "n", "v" }
  local movement_keys = { "h", "j", "k", "l" }
  if HardMode then
    for _, mode in pairs(modes) do
      for _, m_key in pairs(movement_keys) do
        vim.api.nvim_del_keymap(mode, m_key)
      end
    end
    vim.notify("Hard mode OFF", vim.log.levels.INFO, { timeout = 5 })
  else
    for _, mode in pairs(modes) do
      avoid_hjkl(mode, movement_keys)
    end
    vim.notify("Hard mode ON", vim.log.levels.INFO, { timeout = 5 })
  end
  HardMode = not HardMode
end

map("n", "<leader>th", ":lua ToggleHardMode()<CR>", { noremap = true, silent = true, desc = "Hard Mode" })
