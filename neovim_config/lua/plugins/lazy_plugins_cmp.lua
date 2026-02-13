return {
    "hrsh7th/nvim-cmp",
    cond = function() return vim.g.vscode == nil end,
    event = "InsertEnter",
    dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline", -- ✅ コマンドライン補完
                    "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "ray-x/lsp_signature.nvim", "onsails/lspkind.nvim"},
    config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-n>"] = cmp.mapping.select_next_item(),
                ["<C-p>"] = cmp.mapping.select_prev_item(),
                ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<CR>"] = cmp.mapping.confirm({
                    select = true
                }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, {"i", "s"}),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, {"i", "s"})
            }),
            sources = cmp.config.sources({{
                name = "nvim_lsp"
            }, {
                name = "luasnip"
            }, {
                name = "buffer"
            }, {
                name = "path"
            }}),
            formatting = {
                format = lspkind.cmp_format({
                    mode = "symbol_text",
                    maxwidth = 50,
                    ellipsis_char = "..."
                })
            }
        })

        -- ✅ コマンドライン補完設定を追加
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({{
                name = "path"
            }, {
                name = "cmdline"
            }})
        })

        cmp.setup.cmdline({"/", "?"}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{
                name = "buffer"
            }}
        })

        -- ✅ LSP Signature のセットアップ
        require("lsp_signature").setup({
            bind = true,
            floating_window = true,
            hint_enable = false,
            handler_opts = {
                border = "single"
            }
        })
    end
}
