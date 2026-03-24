local has_lazygit = vim.fn.executable("lazygit") == 1

local function notify_lazygit_missing()
    vim.notify("lazygit が見つかりません。インストールして PATH を通してください。", vim.log.levels.WARN)
end

return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            -- 大きなファイルを高速に開く
            bigfile = { enabled = true },
            -- バッファ削除を改善
            bufdelete = { enabled = true },
            -- Neovimの起動画面をカスタマイズ
            dashboard = {
                enabled = true,
                sections = {
                    { section = "header" },
                    { section = "keys", gap = 1, padding = 1 },
                    { section = "startup" },
                },
            },
            -- Git統合
            git = {
                enabled = true,
            },
            gitbrowse = {
                enabled = true,
            },

            -- Lazygit統合
            lazygit = {
                enabled = has_lazygit,
            },

            -- 通知システム
            -- notifier = {
            --     enabled = true,
            --     timeout = 3000,
            -- },
            -- クイックファイル
            quickfile = { enabled = true },
            -- ステータスカラム
            statuscolumn = {
                enabled = false,  -- 必要に応じて有効化
            },
            -- カーソル下の単語をハイライト
            words = {
                enabled = true,
            },
            -- Zenモード（集中モード）
            zen = {
                enabled = true,
            },

            -- スタイル設定
            styles = {
                notification = {
                    wo = { wrap = true }
                }
            }
        },
        keys = {
            -- Lazygit
            {
                "<leader>gg",
                function()
                    if has_lazygit then
                        Snacks.lazygit()
                    else
                        notify_lazygit_missing()
                    end
                end,
                desc = "Lazygit",
            },
            {
                "<leader>gf",
                function()
                    if has_lazygit then
                        Snacks.lazygit.log_file()
                    else
                        notify_lazygit_missing()
                    end
                end,
                desc = "Lazygit 現在のファイルの履歴",
            },
            {
                "<leader>gl",
                function()
                    if has_lazygit then
                        Snacks.lazygit.log()
                    else
                        notify_lazygit_missing()
                    end
                end,
                desc = "Lazygit ログ",
            },

            -- Git Browse
            { "<leader>gb", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },

            -- バッファ削除
            { "<leader>bd", function() Snacks.bufdelete() end, desc = "バッファを削除" },
            { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "他のバッファを削除" },

            -- 通知
            { "<leader>un", function() Snacks.notifier.hide() end, desc = "通知を消去" },
            { "<leader>nh", function() Snacks.notifier.show_history() end, desc = "通知履歴" },

            -- Zenモード
            { "<leader>z", function() Snacks.zen() end, desc = "Zenモード切り替え" },
            { "<leader>Z", function() Snacks.zen.zoom() end, desc = "ウィンドウズーム切り替え" },
        },
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- 便利な関数をセットアップ
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd
                end,
            })
        end,
    },
}
