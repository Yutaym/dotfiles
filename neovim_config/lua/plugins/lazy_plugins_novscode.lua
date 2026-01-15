local pluginlist = {}
if (vim.g.vscode == nil) then
    -- table.insert(pluginlist, {
    --     'nvim-lualine/lualine.nvim',
    --     version = "*"
    -- })
    -- table.insert(pluginlist, {
    --     'neoclide/coc.nvim',
    --     branch = 'master',
    --     build = 'npm ci'
    -- })
    table.insert(pluginlist, {
        "projekt0n/github-nvim-theme",
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
    })
    table.insert(pluginlist, {
        "yuki-yano/fzf-preview.vim",
        dependencies = {"junegunn/fzf", -- FZF バイナリ本体
        "junegunn/fzf.vim" -- Vim-FZF 連携
        },
        event = "VeryLazy", -- 起動を遅延（必要に応じて調整）
        init = function()
            -- 検索キーの例（任意でカスタマイズ）
            vim.keymap.set("n", "<leader>pf", "<cmd>FzfPreviewProjectFiles<CR>", {
                desc = "FZF: Project Files"
            })
            vim.keymap.set("n", "<leader>pb", "<cmd>FzfPreviewBuffers<CR>", {
                desc = "FZF: Buffers"
            })
            vim.keymap.set("n", "<leader>pr", "<cmd>FzfPreviewFromResources<CR>", {
                desc = "FZF: Resources"
            })
            vim.keymap.set("n", "<leader>ld", "<cmd>FzfPreviewDiagnostics<CR>", {
                desc = "FZF: Diagnostics"
            })
            vim.keymap.set("n", "<leader>lr", "<cmd>FzfPreviewLspReferences<CR>", {
                desc = "FZF: LSP References"
            })
            vim.keymap.set("n", "<leader>ldf", "<cmd>FzfPreviewLspDefinition<CR>", {
                desc = "FZF: LSP Definition"
            })
        end
    })
    table.insert(pluginlist, {
        'voldikss/vim-translator',
        cmd = {"TranslateW", "TranslateW --target_lang=en"}
    })
    table.insert(pluginlist, {
        'jghauser/mkdir.nvim',
    })
    -- table.insert(pluginlist, {
    --     'nvimdev/dashboard-nvim',
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
    -- })

end
return pluginlist
