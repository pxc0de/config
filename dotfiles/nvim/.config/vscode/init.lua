-- set leader key to space
vim.g.mapleader = ' '
-- open this config file with leader op
vim.cmd('nmap <leader>c :e ~/.config/vscode/init.lua<cr>')
-- sync system clipboard with nvim clipboard
vim.opt.clipboard = 'unnamedplus'
-- enable mouse in nvim
vim.opt.mouse = 'a'
-- search ignoring case
vim.opt.ignorecase = true
-- search case sensitive if there is capital letter
vim.opt.smartcase = true
-- find files with leader ff

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- redo
keymap('n', 'U', '<C-r>', opts)
-- find files with leader ff
keymap({'n', 'v'}, '<leader>ff', "<cmd>lua require('vscode').action('workbench.action.quickOpen')<cr>", opts)