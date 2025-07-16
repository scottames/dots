-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = require("util").map
local opts_silent = { silent = true }
local opts_noremap_silent = { noremap = true, silent = true }
local opts_noremap_silent_expr = { noremap = true, silent = true, expr = true }

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

-- Move Lines
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua#L25-L31
map("n", "<A-Down>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-Up>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-Down>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-Up>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- fold line
map("n", "J", "mzJ`z")

-- centered navigation
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
-- currently makes ctrl+d/u jump back weirdly
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

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

-- buffers
map("n", "<S-Left>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-Right>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- replace the current word
map("n", "<leader>c/", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace Word (s//)" })

-- make current file executable!
map("n", "<leader>bx", "<cmd>!chmod +x %<CR>", { desc = "chmod +x %", silent = true })

-- Splits
-- -- navigation
map("n", "<leader>|", "<C-w>v", { desc = "split-window-right", silent = true })
map("n", "<leader>-", "<C-w>s", { desc = "split-window-down", silent = true })
map("n", "<leader>wv", "<C-w>v", { desc = "split-window-right", silent = true })
map("n", "<leader>wo", "<C-w>o", { desc = "delete-other-windows", silent = true })
-- -- resize
map("n", "<M-l>", "<cmd>vertical resize +2<CR>", { desc = "resize-right", silent = true })
map("n", "<M-h>", "<cmd>vertical resize -2<CR>", { desc = "resize-left", silent = true })
map("n", "<M-j>", "<cmd>resize +2<CR>", { desc = "resize-down", silent = true })
map("n", "<M-k>", "<cmd>resize -2<CR>", { desc = "resize-up", silent = true })

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
