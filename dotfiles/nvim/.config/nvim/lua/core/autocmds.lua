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

-- File change detection for external edits
local file_change_group = augroup("file_changes", { clear = true })

autocmd({ "FocusGained", "BufEnter" }, {
  group = file_change_group,
  pattern = "*",
  callback = function()
    vim.cmd("checktime")
  end,
})

autocmd("FileChangedShellPost", {
  group = file_change_group,
  pattern = "*",
  callback = function()
    vim.notify("File reloaded from disk", vim.log.levels.INFO)
  end,
})

-- Python: show a vertical ruler at the line-length limit to keep code PEP 8 friendly
augroup("python_ruler", { clear = true })
autocmd("FileType", {
  group = "python_ruler",
  pattern = "python",
  callback = function()
    vim.opt_local.colorcolumn = "88" -- Black's default; use "79" for strict PEP 8
    vim.opt_local.textwidth = 88     -- wrap/format target matches the ruler
  end,
})
