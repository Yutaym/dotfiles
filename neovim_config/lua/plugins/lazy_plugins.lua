return {
{
    "kylechui/nvim-surround",
    event = {"BufReadPre", "BufNewFile"},
    config = function()
        local nvim_surround = require("nvim-surround")
        nvim_surround.setup({}) -- デフォルトのまま初期化
        -- ファイルタイプごとの設定
        vim.api.nvim_create_autocmd("FileType", {
            pattern = {"html", "xml", "markdown", "tex", "plaintex"},
            callback = function()
                local ft = vim.bo.filetype
                local custom_surrounds = {
                    -- 🌐 HTML / XML: <tag>...</tag>
                    ["t"] = {
                        add = function()
                            local tag = vim.fn.input("Enter tag: ")
                            return {{"<" .. tag .. ">"}, {"</" .. tag .. ">"}}
                        end,
                        find = "<[^%s>]+.->.-</[^%s>]+.->",
                        delete = "^<[^%s>]+.->().-()</[^%s>]+.->$"
                    },

                    -- 📄 LaTeX: \command{...}
                    ["c"] = {
                        add = function()
                            local cmd = vim.fn.input("Command: \\")
                            return {{"\\" .. cmd .. "{"}, {"}"}}
                        end,
                        find = "\\%a+%b{}",
                        delete = "^(\\%a+){().-()}$"
                    }
                }

                require("nvim-surround").buffer_setup({
                    surrounds = custom_surrounds
                })
            end
        })
    end
},
{
    "numToStr/Comment.nvim",
    cond = function() return vim.g.vscode == nil end,
    dependencies = {"JoosepAlviste/nvim-ts-context-commentstring", {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({
                ensure_installed = {"javascript", "typescript", "tsx", "html", "css", "vue", "lua", "python", "bash",
                                    "json"},
                highlight = {
                    enable = true
                },
                indent = {
                    enable = true
                }
            })
        end
    }},
    event = {"BufReadPre", "BufNewFile"},
    -- event = "VeryLazy",
    config = function()
        -- ts-context-commentstring の設定
        require("ts_context_commentstring").setup({
            enable_autocmd = false
        })
        -- Comment.nvim 本体設定
        require("Comment").setup({
            padding = true,
            sticky = true,
            ignore = "^$",
            mappings = {
                basic = true,
                extra = true
            },
            toggler = {
                line = "gcc",
                block = "gbc"
            },
            opleader = {
                line = "gc",
                block = "gb"
            },
            -- ts-context-commentstring を連携
            pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
        })
    end
},

{
    "vim-scripts/ReplaceWithRegister",
    enabled = false,  -- ⭐ キーマップがコメントアウトされているため無効化
    -- 再度使用する場合はenabled = trueにして、keysで遅延読み込み設定を追加
    init = function()
        -- vim.keymap.set('n', '<Space>r', '<Plug>ReplaceWithRegisterOperator', {
        --     noremap = true,
        --     silent = true
        -- })
        -- vim.keymap.set('n', '<Space>rr', '<Plug>ReplaceWithRegisterLine', {
        --     noremap = true,
        --     silent = true
        -- })
        -- vim.keymap.set({'v', 'x'}, '<Space>r', '<Plug>ReplaceWithRegisterVisual', {
        --     noremap = true,
        --     silent = true
        -- })
    end
},
{
    "vim-scripts/camelcasemotion",
    keys = {
        {"sw", mode = {"n", "v"}},
        {"se", mode = {"n", "v"}},
        {"sb", mode = {"n", "v"}},
        {"isw", mode = {"o", "v"}},
        {"ise", mode = {"o", "v"}},
        {"isb", mode = {"o", "v"}},
        {"<C-w>", mode = {"n", "v"}},
        {"<C-e>", mode = {"n", "v"}},
        {"<C-b>", mode = {"n", "v"}},
        {"i<C-w>", mode = {"o", "v"}},
        {"i<C-e>", mode = {"o", "v"}},
        {"i<C-b>", mode = {"o", "v"}},
    },
    config = function()
        vim.keymap.set({"n", "v"}, "sw", "<Plug>CamelCaseMotion_w", {noremap = true, silent = true})
        vim.keymap.set({"n", "v"}, "se", "<Plug>CamelCaseMotion_e", {noremap = true, silent = true})
        vim.keymap.set({"n", "v"}, "sb", "<Plug>CamelCaseMotion_b", {noremap = true, silent = true})
        vim.keymap.set({"o", "v"}, "isw", "<Plug>CamelCaseMotion_iw", {noremap = true, silent = true})
        vim.keymap.set({"o", "v"}, "ise", "<Plug>CamelCaseMotion_ie", {noremap = true, silent = true})
        vim.keymap.set({"o", "v"}, "isb", "<Plug>CamelCaseMotion_ib", {noremap = true, silent = true})
        vim.keymap.set({"n", "v"}, "<C-w>", "<Plug>CamelCaseMotion_w", {noremap = true, silent = true})
        vim.keymap.set({"n", "v"}, "<C-e>", "<Plug>CamelCaseMotion_e", {noremap = true, silent = true})
        vim.keymap.set({"n", "v"}, "<C-b>", "<Plug>CamelCaseMotion_b", {noremap = true, silent = true})
        vim.keymap.set({"o", "v"}, "i<C-w>", "<Plug>CamelCaseMotion_iw", {noremap = true, silent = true})
        vim.keymap.set({"o", "v"}, "i<C-e>", "<Plug>CamelCaseMotion_ie", {noremap = true, silent = true})
        vim.keymap.set({"o", "v"}, "i<C-b>", "<Plug>CamelCaseMotion_ib", {noremap = true, silent = true})
    end
},
{
    "rhysd/clever-f.vim",
    keys = {
        {"f", mode = {"n", "v", "o"}},
        {"F", mode = {"n", "v", "o"}},
        {"t", mode = {"n", "v", "o"}},
        {"T", mode = {"n", "v", "o"}},
        {",", mode = {"n", "v"}},
        {":", mode = {"n", "v"}},
    },
    config = function()
        -- clever-f の繰り返し操作にカスタムキーを割り当て
        vim.keymap.set({"n", "v"}, ",", "<Plug>(clever-f-repeat-forward)", {
            noremap = true,
            silent = true
        })
        vim.keymap.set({"n", "v"}, ":", "<Plug>(clever-f-repeat-back)", {
            noremap = true,
            silent = true
        })

    end
},
{
    'wellle/targets.vim',
    event = {"BufReadPre", "BufNewFile"}
},
{
    "monaqa/dial.nvim",
    lazy = true,  -- ⭐ 自動読み込みを無効化
    keys = {
        { "<C-a>", mode = { "n", "v", "x" } },
        { "<C-x>", mode = { "n", "v", "x" } },
        { "g<C-a>", mode = { "n", "v", "x" } },
        { "g<C-x>", mode = { "n", "v", "x" } },
    },
    config = function()
        local augend = require("dial.augend")

        require("dial.config").augends:register_group({
            default = {
                augend.constant.new({
                    elements = {"and", "or"},
                    word = true,
                    cyclic = true
                }),
                augend.constant.new({
                    elements = {"yes", "no"},
                    word = true,
                    cyclic = true
                }),
                augend.constant.new({
                    elements = {"on", "off"},
                    word = true,
                    cyclic = true
                }),
                augend.constant.new({
                    elements = {"public", "private", "protected"},
                    word = true,
                    cyclic = true
                }),
                augend.constant.new({
                    elements = {"DEBUG", "INFO", "WARN", "ERROR"},
                    word = true,
                    cyclic = true
                }),
                augend.constant.new({
                    elements = {"debug", "info", "warn", "error"},
                    word = true,
                    cyclic = true
                }),
                augend.date.new({
                    pattern = "%Y/%m/%d",
                    default_kind = "day"
                }),
                augend.integer.alias.decimal,
            }
        })

        -- ⭐ キーマップ設定
        local map = vim.keymap.set
        local dial_map = require("dial.map")

        map("n", "<C-a>", dial_map.inc_normal(), { noremap = true, silent = true })
        map("n", "<C-x>", dial_map.dec_normal(), { noremap = true, silent = true })
        map("v", "<C-a>", dial_map.inc_visual(), { noremap = true, silent = true })
        map("v", "<C-x>", dial_map.dec_visual(), { noremap = true, silent = true })
        map("v", "g<C-a>", dial_map.inc_gvisual(), { noremap = true, silent = true })
        map("v", "g<C-x>", dial_map.dec_gvisual(), { noremap = true, silent = true })
        map("n", "g<C-a>", dial_map.inc_gnormal(), { noremap = true, silent = true })
        map("n", "g<C-x>", dial_map.dec_gnormal(), { noremap = true, silent = true })
    end
},
{
    "haya14busa/vim-edgemotion",
    event = {"BufReadPre", "BufNewFile"},
    init = function()
        vim.keymap.set({"n", "v"}, "gj", "<Plug>(edgemotion-j)", {
            noremap = true,
            silent = true
        })
        vim.keymap.set({"n", "v"}, "gk", "<Plug>(edgemotion-k)", {
            noremap = true,
            silent = true
        })
    end

},

{
    "rapan931/lasterisk.nvim",
    event = {"BufReadPre", "BufNewFile"},
    config = function()
        -- local lasterisk = require("lasterisk")
        -- vim.keymap.set({"n", "x"}, "*", lasterisk.nvim_search_forward)
        -- vim.keymap.set({"n", "x"}, "#", lasterisk.nvim_search_backward)
        -- vim.keymap.set({"n", "x"}, "g*", lasterisk.nvim_search_forward_curpos)
        -- vim.keymap.set({"n", "x"}, "g#", lasterisk.nvim_search_backward_curpos)
    end
},

{
    "kevinhwang91/nvim-hlslens",
    event = {"BufReadPre", "BufNewFile"},
    config = function()
        require("hlslens").setup({
            calm_down = true,
            nearest_only = true,
        })
        local kopts = {
            noremap = true,
            silent = true
        }
        -- n/N による検索時に hlslens をトリガー
        vim.keymap.set("n", "n",
            [[<Cmd>execute("normal! " . v:count1 . "n")<CR><Cmd>lua require("hlslens").start()<CR>]], {
                noremap = true,
                silent = true
            })
        vim.keymap.set("n", "N",
            [[<Cmd>execute("normal! " . v:count1 . "N")<CR><Cmd>lua require("hlslens").start()<CR>]], {
                noremap = true,
                silent = true
            })
        vim.keymap.set("n", "*", [[*<Cmd>lua require("hlslens").start()<CR>]], {
            noremap = true,
            silent = true
        })
        vim.keymap.set("n", "#", [[#<Cmd>lua require("hlslens").start()<CR>]], {
            noremap = true,
            silent = true
        })
        vim.keymap.set("n", "g*", [[g*<Cmd>lua require("hlslens").start()<CR>]], {
            noremap = true,
            silent = true
        })
        vim.keymap.set("n", "g#", [[g#<Cmd>lua require("hlslens").start()<CR>]], {
            noremap = true,
            silent = true
        })
    end
},
{
    'jghauser/mkdir.nvim',
    event = "BufWritePre",
},
{
    'nacro90/numb.nvim',
    event = "CmdlineEnter",
    config = function()
        require('numb').setup({
            show_numbers = true,
            show_cursorline = true,
            hide_relativenumbers = true,
            number_only = false,
            centered_peeking = true,
        })
    end
},
{
    "ysmb-wtsg/in-and-out.nvim",
    keys = {{
        "<C-CR>",
        function()
            require("in-and-out").in_and_out()
        end,
        mode = "i"
    }}
}
}
