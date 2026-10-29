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
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        -- Python: sort imports, then format, with ruff only (pyright never formats).
        -- Requested synchronously so both edits land before the write.
        if client and client.name == "ruff" then
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = vim.api.nvim_create_augroup("RuffFormatOnSave_" .. ev.buf, { clear = true }),
                buffer = ev.buf,
                callback = function()
                    local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
                    params.context = { only = { "source.organizeImports.ruff" }, diagnostics = {} }
                    local res = client:request_sync("textDocument/codeAction", params, 1000, ev.buf)
                    for _, action in ipairs(res and res.result or {}) do
                        -- ruff only computes the edit on resolve
                        local resolved = client:request_sync("codeAction/resolve", action, 1000, ev.buf)
                        action = resolved and resolved.result or action
                        if action.edit then
                            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                        end
                    end
                    vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
                end,
            })
        end

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

        -- Show the full diagnostic for the current line in a float, for when
        -- inline virtual_text runs off the right edge of the window.
        vim.keymap.set("n", "<leader>le", vim.diagnostic.open_float,
            vim.tbl_extend("force", opts, { desc = "Line diagnostics (float)" }))
    end,
})
