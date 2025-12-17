return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        lazy = false,
        opts = {
            flavour = "mocha", -- latte, frappe, macchiato, mocha
            transparent_background = true,
            term_colors = true,
            integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                mason = true,
                which_key = true,
                indent_blankline = {
                    enabled = true,
                    scope_color = "lavender",
                },
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin")
        end,
    },
}
