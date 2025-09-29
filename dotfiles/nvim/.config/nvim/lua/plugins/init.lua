-- Add your plugins here or configure NvChad builtin plugins like nvim tree etc
return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- Uncommented for format on save
    config = function()
      require "configs.conform"
    end,
  },

  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = {
      pickers = {
        -- Find find hidden files and symlinks too on find_files ie <leader>ff
        find_files = {
          follow = true, -- Find symlinks
          hidden = true, -- Find hidden files
          file_ignore_patterns = { -- Dont find these files/dirs
            "node_modules",
            "build",
            "dist",
            "yarn.lock",
            ".git",
            ".idea",
            ".vscode",
            "package-lock.json",
          },
        },
      },
      defaults = {
        vimgrep_arguments = {
          -- This is for live grep using ripgrep i.e. <leader>fw
          -- More here about ripgrep - https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file
          -- For e.g. you can take this configuration out in ripgreprc file
          "rg",
          "--follow", -- Follow symbolic links
          "--hidden", -- Search for hidden files
          "--no-heading", -- Don't group matches by each file
          "--with-filename", -- Print the file path with the matched lines
          "--line-number", -- Show line numbers
          "--column", -- Show column numbers
          -- Smart case search, other option is ignore-case,
          -- but smart case is better because this is similar
          -- to --ignore-case, but disables itself if the pattern contains any uppercase letters
          "--smart-case",
          -- Exclude some patterns from search
          "--glob=!**/.git/*",
          "--glob=!**/.idea/*",
          "--glob=!**/.vscode/*",
          "--glob=!**/build/*",
          "--glob=!**/dist/*",
          "--glob=!**/yarn.lock",
          "--glob=!**/package-lock.json",
        },
      },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    -- See options by running
    opts = {
      filters = {
        dotfiles = false,
        -- show files even if they are git ignored
        git_ignored = false,
      },
      view = {
        side = "left",
        -- This makes sure that longest file/folder width is assumed
        -- which I like but at work I have some really long file names
        -- width = {
        --   max = -1,
        -- },
        width = 50,
      },
    },
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "html-lsp",
        "css-lsp",
        "prettier",
        "pyright",
        "ruff",
        "gopls",
        "terraform-ls",
        "ts_ls",
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "python",
        "go",
        "terraform",
        "typescript",
      },
    },
  },
}
