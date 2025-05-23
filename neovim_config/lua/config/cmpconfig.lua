-- Lspkindのrequire
local lspkind = require 'lspkind'
-- 補完関係の設定
local cmp = require("cmp")
cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end
    },
    sources = {{
        name = "nvim_lsp"
    }, -- ソース類を設定
    {
        name = 'vsnip'
    }, -- For vsnip users.
    {
        name = "buffer"
    }, {
        name = "path"
    }},
    mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(), -- Ctrl+pで補完欄を一つ上に移動
        ["<C-n>"] = cmp.mapping.select_next_item(), -- Ctrl+nで補完欄を一つ下に移動
        ['<C-l>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ["<C-y>"] = cmp.mapping.confirm({
            select = true
        }) -- Ctrl+yで補完を選択確定
    }),
    experimental = {
        ghost_text = false
    },
    -- Lspkind(アイコン)を設定
    formatting = {
        format = lspkind.cmp_format({
            mode = 'symbol', -- show only symbol annotations
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            ellipsis_char = '...' -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
            -- The function below will be called before any actual modifications from lspkind
            -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
        })
    }
})

cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {{
        name = 'buffer'
    } -- ソース類を設定
    }
})
cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {{
        name = "path"
    } -- ソース類を設定
    }
})
