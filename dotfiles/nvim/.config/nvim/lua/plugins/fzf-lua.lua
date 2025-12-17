return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>",     desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>",   desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua help_tags<CR>", desc = "Help tags" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<CR>",  desc = "Recent files" },
      { "<leader>fc", "<cmd>FzfLua commands<CR>",  desc = "Commands" },
      {
        "<leader>fs",
        "<cmd>FzfLua lsp_document_symbols<CR>",
        desc = "Document symbols",
      },
      { "<leader>fw", "<cmd>FzfLua grep_cword<CR>",  desc = "Grep word" },
      {
        "<leader>fd",
        "<cmd>FzfLua diagnostics_document<CR>",
        desc = "Document diagnostics",
      },
      { "<leader>gf", "<cmd>FzfLua git_files<CR>",   desc = "Git files" },
      { "<leader>gc", "<cmd>FzfLua git_commits<CR>", desc = "Git commits" },
      { "<leader>gs", "<cmd>FzfLua git_status<CR>",  desc = "Git status" },
    },
    opts = {
      "default-title",
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.50,
        preview = {
          layout = "flex",
          flip_columns = 120,
        },
      },
      files = {
        fd_opts = [[--color=never --type f --hidden --follow ]]
            .. [[--exclude .git --exclude .idea --exclude .vscode ]]
            .. [[--exclude node_modules --exclude build --exclude dist ]]
            .. [[--exclude yarn.lock --exclude package-lock.json]],
      },
      grep = {
        rg_opts = [[--column --line-number --no-heading --color=always ]]
            .. [[--smart-case --max-columns=4096 ]]
            .. [[--glob=!.git --glob=!.idea --glob=!.vscode ]]
            .. [[--glob=!node_modules --glob=!build --glob=!dist ]]
            .. [[--glob=!yarn.lock --glob=!package-lock.json -e]],
      },
      lsp = {
        symbols = {
          symbol_style = 1,
        },
      },
    },
  },
}
