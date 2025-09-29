require "nvchad.mappings"

local map = vim.keymap.set

map("n", "<leader>ss", "<cmd> :wqa <cr>", { desc = "Save and Close all" })
map("n", "<leader>z", "<cmd> :qa <cr>", { desc = "Close all without save" })
map("n", "<C-h>", "<cmd> TmuxNavigateLeft<cr>", { desc = "Window left" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight<cr>", { desc = "Window right" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp<cr>", { desc = "Window up" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown<cr>", { desc = "Window down" })

map("i", "jk", "<ESC>")

-- Apply multiple identation without leaving v mode
map("v", ">", ">gv", { noremap = true, silent = true })
map("v", "<", "<gv", { noremap = true, silent = true })

-- Send delete items to black hole register so does not come back on pressing p
map("n", "d", '"_d', { noremap = true, silent = true })
map("n", "c", '"_c', { noremap = true, silent = true })
-- I like line delete to go to unnamed register so available on pressing p
map("n", "dd", "dd", { noremap = true, silent = true })
