return {
    cmd = { "tailwindcss-language-server", "--stdio" },
    filetypes = {
        "html",
        "css",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
    },
    root_markers = {
        "tailwind.config.js",
        "tailwind.config.ts",
        "postcss.config.js",
        ".git",
    },
}
