return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        cond = function() return vim.g.vscode == nil end,
        ft = { "markdown" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            render_modes = { "n", "c" },
            heading = {
                enabled = true,
                icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
            },
            code = { enabled = true },
            bullet = { enabled = true },
        },
    },
    {
        "iamcco/markdown-preview.nvim",
        cond = function() return vim.g.vscode == nil end,
        ft = { "markdown" },
        build = "cd app && npm install",
        cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
        keys = {
            { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown: Preview Toggle" },
        },
        init = function()
            vim.g.mkdp_auto_close = 1
            vim.g.mkdp_theme = "dark"
        end,
    },
    {
        "tpope/vim-fugitive",
        cond = function() return vim.g.vscode == nil end,
        cmd = { "Git", "G", "Gread", "Gwrite", "Gdiffsplit", "GBrowse" },
        keys = {
            { "<leader>gs", "<cmd>Git<CR>",            desc = "Git: Status" },
            { "<leader>gd", "<cmd>Gdiffsplit<CR>",     desc = "Git: Diff Split" },
            { "<leader>gb", "<cmd>Git blame<CR>",      desc = "Git: Blame" },
            { "<leader>gl", "<cmd>Git log --oneline<CR>", desc = "Git: Log" },
        },
    },
    {
        "zk-org/zk-nvim",
        cond = function() return vim.g.vscode == nil end,
        cmd = { "ZkNew", "ZkNotes", "ZkTags", "ZkMatch" },
        keys = {
            { "<leader>zn", "<cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", desc = "Zk: New Note" },
            { "<leader>zo", "<cmd>ZkNotes { sort = { 'modified' } }<CR>",         desc = "Zk: Open Notes" },
            { "<leader>zt", "<cmd>ZkTags<CR>",                                    desc = "Zk: Browse Tags" },
            { "<leader>zf", "<cmd>ZkNotes { match = { vim.fn.input('Search: ') } }<CR>", desc = "Zk: Find Notes" },
        },
        config = function()
            require("zk").setup({
                picker = "telescope",
                lsp = {
                    config = {
                        cmd = { "zk", "lsp" },
                        name = "zk",
                    },
                    auto_attach = {
                        enabled = true,
                        filetypes = { "markdown" },
                    },
                },
            })
        end,
    },
}
