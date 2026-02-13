return {
-- table.insert(pluginlist, {
--     'nvim-lualine/lualine.nvim',
--     version = "*"
-- })
-- table.insert(pluginlist, {
--     'neoclide/coc.nvim',
--     branch = 'master',
--     build = 'npm ci'
-- })
{
    "projekt0n/github-nvim-theme",
    cond = function() return vim.g.vscode == nil end,
    lazy = false,
    priority = 1000,
        config = function()
            require("github-theme").setup({
                options = {
                    -- スタイル設定（置き換え後）
                    styles = {
                        comments = "italic",
                        functions = "italic",
                        keywords = "bold",
                        variables = "bold"
                    },

                    -- サイドバーに暗めの背景を適用するリスト
                    darken = {
                        sidebars = {
                            enable = true,
                            list = {"terminal", "packer", "qf"}
                        }
                    }
                },

                -- colors の代わりに palette/specs で調整可能（省略可能）
                palettes = {},
                specs = {},
                groups = {}
            })
            -- カラースキーム選択
            vim.cmd("colorscheme github_dark_default")
        end
},
{
    "yuki-yano/fzf-preview.vim",
    cond = function() return vim.g.vscode == nil end,
    dependencies = {"junegunn/fzf", "junegunn/fzf.vim"},
    keys = {
        {"<leader>pf", "<cmd>FzfPreviewProjectFiles<CR>", desc = "FZF: Project Files"},
        {"<leader>pb", "<cmd>FzfPreviewBuffers<CR>", desc = "FZF: Buffers"},
        {"<leader>pr", "<cmd>FzfPreviewFromResources<CR>", desc = "FZF: Resources"},
        {"<leader>ld", "<cmd>FzfPreviewDiagnostics<CR>", desc = "FZF: Diagnostics"},
        {"<leader>lr", "<cmd>FzfPreviewLspReferences<CR>", desc = "FZF: LSP References"},
        {"<leader>ldf", "<cmd>FzfPreviewLspDefinition<CR>", desc = "FZF: LSP Definition"},
    },
},
{
    'voldikss/vim-translator',
    cond = function() return vim.g.vscode == nil end,
    cmd = {"TranslateW", "TranslateW --target_lang=en"}
},
{
    'jghauser/mkdir.nvim',
    cond = function() return vim.g.vscode == nil end,
    event = "BufWritePre",
}
-- {
--     'nvimdev/dashboard-nvim',
--     cond = function() return vim.g.vscode == nil end,
--     event = 'VimEnter',
--     config = function()
--         require('dashboard').setup {
--             -- config = {
--             --     header -- type is table def
--             --     week_header = {
--             --       enable  --boolean use a week header
--             --       concat  --concat string after time string line
--             --       append  --table append after time string line
--             --     },
--             --     disable_move  -- boolean default is false disable move key
--             --   }
--         }
--     end,
--     dependencies = {{'nvim-tree/nvim-web-devicons'}}
-- }
}
