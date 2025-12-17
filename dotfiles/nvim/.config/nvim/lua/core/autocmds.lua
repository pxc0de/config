-- Autocommands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
augroup("highlight_yank", { clear = true })
autocmd("TextYankPost", {
  group = "highlight_yank",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Resize splits on window resize
augroup("resize_splits", { clear = true })
autocmd("VimResized", {
  group = "resize_splits",
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})
