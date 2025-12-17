-- General
vim.opt.number = true                  -- show absolute line numbers
vim.opt.relativenumber = false         -- keep relative numbers off by default
vim.opt.mouse = "a"                    -- enable mouse support everywhere
vim.opt.clipboard = "unnamedplus"      -- sync with system clipboard
vim.opt.autoread = true                -- auto-reload files changed externally
vim.opt.errorbells = false             -- disable audible error bells
vim.opt.visualbell = false             -- disable visual error flash
vim.opt.iskeyword:append("-")          -- Treat dash as part of a word
vim.opt.backspace = "indent,eol,start" -- Normal backspace behavior

-- Persistent undo
vim.opt.undofile = true -- persist undo history to disk
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"

-- Indentation
vim.opt.expandtab = true   -- convert tabs to spaces
vim.opt.shiftwidth = 4     -- indent width for << and >>
vim.opt.tabstop = 4        -- render a tab as 4 spaces
vim.opt.softtabstop = 4    -- edit a tab as 4 spaces
vim.opt.smartindent = true -- smarter auto-indenting on new lines

-- Search
vim.opt.ignorecase = true -- case-insensitive search by default
vim.opt.smartcase = true  -- but respect case if pattern has capitals
vim.opt.hlsearch = false  -- do not highlight all search matches

-- Display
vim.opt.wrap = false          -- keep long lines on one line
vim.opt.signcolumn = "yes"    -- always show sign column
vim.opt.cursorline = true     -- highlight current line
vim.opt.termguicolors = true  -- use truecolor in the terminal
vim.opt.winborder = "rounded" -- New in 0.11: default border for floating windows

-- Scrolling
vim.opt.scrolloff = 8       -- keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8   -- keep 8 columns visible sideways
vim.opt.smoothscroll = true -- enable smooth scrolling

-- Performance
vim.opt.updatetime = 100 -- faster CursorHold and swap updates
vim.opt.timeoutlen = 300 -- shorter mapped sequence timeout


-- Show whitespace characters
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- File handling
vim.opt.fileencoding = "utf-8" -- use UTF-8 for files
vim.opt.backup = false         -- skip creating backup files
vim.opt.swapfile = false       -- disable swap files

-- Splits
vim.opt.splitright = true -- vertical splits open to the right
vim.opt.splitbelow = true -- horizontal splits open below

-- Command mode
vim.opt.wildmenu = true                -- Enable command-line completion menu
vim.opt.wildignorecase = true          -- Case-insensitive tab completion in commands
vim.opt.wildmode = "longest:full,full" -- completion behavior in cmdline
vim.opt.cmdheight = 1                  -- minimal command-line height
vim.opt.inccommand = "split"           -- preview substitute results in split

-- Completion
vim.opt.completeopt = "menu,menuone,noselect" -- better completion menus
vim.opt.pumheight = 10                        -- limit popup menu height

-- UI
vim.opt.laststatus = 3   -- global statusline
vim.opt.showmode = false -- hide -- INSERT -- since statusline shows it

-- Text handling
vim.opt.joinspaces = false                      -- single space after sentences when joining
vim.opt.formatoptions:remove({ "c", "r", "o" }) -- avoid auto-comment on new lines

-- Folding
vim.opt.foldmethod = "expr"                     -- compute folds via expression
vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- Treesitter-powered folds
vim.opt.foldlevel = 99                          -- keep folds open by default
