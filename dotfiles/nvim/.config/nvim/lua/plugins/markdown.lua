return {
    "OXY2DEV/markview.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
        headings = {
            enable = true,
            shift_width = 0,
            heading_1 = { hl = "markviewHeading1", sign = "", sign_hl = "markviewHeading1Sign" },
            heading_2 = { hl = "markviewHeading2", sign = "", sign_hl = "markviewHeading2Sign" },
            heading_3 = { hl = "markviewHeading3" },
            heading_4 = { hl = "markviewHeading4" },
        },
        code_blocks = {
            enable = true,
            style = "block",  -- "block" adds background, helps contrast
            hl = "markviewCode",
            pad_amount = 2,
        },
        inline_codes = {
            enable = true,
            hl = "markviewInlineCode",
        },
    },
    config = function(_, opts)
        require("markview").setup(opts)

        -- Boost contrast for headings using catppuccin mocha palette
        vim.api.nvim_set_hl(0, "markviewHeading1", { fg = "#cba6f7", bold = true })      -- mauve
        vim.api.nvim_set_hl(0, "markviewHeading2", { fg = "#89b4fa", bold = true })      -- blue
        vim.api.nvim_set_hl(0, "markviewHeading3", { fg = "#94e2d5", bold = true })      -- teal
        vim.api.nvim_set_hl(0, "markviewHeading4", { fg = "#a6e3a1", bold = true })      -- green
        vim.api.nvim_set_hl(0, "markviewCode",       { bg = "#1e1e2e" })                 -- base
        vim.api.nvim_set_hl(0, "markviewInlineCode", { fg = "#f38ba8", bg = "#313244" }) -- red on surface0
    end,
}
