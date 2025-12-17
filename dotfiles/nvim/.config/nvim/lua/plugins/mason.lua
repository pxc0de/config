return {
    {
        "mason-org/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = {
            ui = {
                border = "rounded",
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        },
    },
    {
        "mason-org/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "mason-org/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    -- Web
                    "ts_ls",
                    "html",
                    "cssls",
                    "tailwindcss",
                    "eslint",
                    -- Python
                    "pyright",
                    "ruff",
                    -- Rust
                    "rust_analyzer",
                    -- Go
                    "gopls",
                    -- C/C++
                    "clangd",
                    -- Lua
                    "lua_ls",
                },
                automatic_installation = true,
            })

            -- Enable LSP servers using native Neovim 0.11 API
            vim.lsp.enable({
                "ts_ls",
                "html",
                "cssls",
                "tailwindcss",
                "eslint",
                "pyright",
                "ruff",
                "rust_analyzer",
                "gopls",
                "clangd",
                "lua_ls",
            })
        end,
    },
}
