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
        -- Installs these servers and runs vim.lsp.enable() for every installed one
        opts = {
            ensure_installed = {
                -- Web
                "ts_ls",
                "html",
                "cssls",
                "tailwindcss",
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
        },
    },
}
