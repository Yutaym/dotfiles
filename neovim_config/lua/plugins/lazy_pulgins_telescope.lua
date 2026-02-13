return {
    "nvim-telescope/telescope.nvim",
    cond = function() return vim.g.vscode == nil end,
    tag = "0.1.6",
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons",

    -- 🔍 高速検索エンジン fzf-native
                    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
            return vim.fn.executable("make") == 1
        end
    }, -- 📜 Undo 履歴表示
    "debugloop/telescope-undo.nvim"},
    cmd = "Telescope",
        keys = {{
            "<leader>ff",
            "<cmd>Telescope find_files<CR>",
            desc = "Find Files"
        }, {
            "<leader>fg",
            "<cmd>Telescope live_grep<CR>",
            desc = "Live Grep"
        }, {
            "<leader>fb",
            "<cmd>Telescope buffers<CR>",
            desc = "Buffers"
        }, {
            "<leader>fh",
            "<cmd>Telescope help_tags<CR>",
            desc = "Help Tags"
        }, {
            "<leader>fr",
            "<cmd>Telescope lsp_references<CR>",
            desc = "LSP References"
        }, {
            "<leader>fd",
            "<cmd>Telescope lsp_definitions<CR>",
            desc = "LSP Definitions"
        }, {
            "<leader>D",
            "<cmd>Telescope diagnostics<CR>",
            desc = "Workspace Diagnostics"
        }, -- 📜 Undo 履歴ツリー
        {
            "<leader>fu",
            "<cmd>Telescope undo<CR>",
            desc = "Undo Tree"
        }, -- 🔧 Git 管理ファイル一覧
        {
            "<leader>gs",
            "<cmd>Telescope git_status<CR>",
            desc = "Git Status"
        }, {
            "<leader>gf",
            "<cmd>Telescope git_files<CR>",
            desc = "Git Files"
        }},
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    layout_strategy = "horizontal",
                    layout_config = {
                        prompt_position = "top"
                    },
                    sorting_strategy = "ascending",
                    winblend = 0
                },
                extensions = {
                    fzf = {
                        fuzzy = true, -- 曖昧検索を有効にする
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case" -- 賢い大文字小文字無視
                    },
                    undo = {
                        use_delta = true,
                        side_by_side = true,
                        layout_strategy = "vertical",
                        layout_config = {
                            preview_height = 0.8
                        }
                    }
                }
            })

            -- 🔌 拡張機能を読み込む
            telescope.load_extension("fzf")
            telescope.load_extension("undo")
        end
}
