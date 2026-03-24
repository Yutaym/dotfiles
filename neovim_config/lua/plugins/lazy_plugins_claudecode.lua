return {
    {
        "coder/claudecode.nvim",
        cond = function() return vim.g.vscode == nil end,
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "folke/snacks.nvim",
        },
        opts = {
            provider = "snacks",
            track_selection = true,
            git_repo_cwd = true,
            split_side = "right",
            split_width_percentage = 0.4,
            snacks_win_opts = {
                height = 15,
                enter = true,
            },
        },
        keys = {
            { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude Codeを切り替え" },
            { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claudeにフォーカス" },
            { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "セッションを再開" },
            { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "会話を継続" },
            { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "モデルを選択" },
            { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "現在ファイルを追加" },
            { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "選択範囲を送信" },
            { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "変更を承認" },
            { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "変更を拒否" },
        },
    },
}
