-- Enable inlay hints globally
vim.lsp.inlay_hint.enable(true)

-- Configure diagnostics
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        source = "if_many",
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
            [vim.diagnostic.severity.INFO] = " ",
        },
    },
    float = {
        border = "rounded",
        source = true,
    },
    severity_sort = true,
})

-- LspAttach autocmd for buffer-local keymaps
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        -- Note: Neovim 0.11 provides these default keymaps:
        -- grn -> vim.lsp.buf.rename()
        -- gra -> vim.lsp.buf.code_action()
        -- grr -> vim.lsp.buf.references()
        -- gri -> vim.lsp.buf.implementation()
        -- gO  -> vim.lsp.buf.document_symbol()
        -- K   -> vim.lsp.buf.hover()
        -- [d / ]d -> diagnostic navigation
        -- <C-S> (insert) -> vim.lsp.buf.signature_help()

        -- Additional keymaps beyond 0.11 defaults
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "<leader>lh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, opts)
    end,
})
