-- EXAMPLE
local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local util = require "lspconfig/util"

-- Front end servers
local servers = { "html", "cssls", "ts_ls" }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

-- Python servers
local python_servers = { "pyright", "ruff" }
for _, lsp in ipairs(python_servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
    filetypes = { "python" },
  }
end

-- Golang servers
lspconfig.gopls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = util.root_pattern("gowork", "go.mod", ".git"),
  settings = {
    gopls = {
      completeUnimported = true, -- automatically add import lines
      usePlaceholders = true, -- use placeholder for signatures
      analyses = {
        unusedparams = true, -- warning for unused params
      },
    },
  },
}

-- Terraform server
lspconfig.terraformls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "tf", "tfvars", "terraform" },
}
