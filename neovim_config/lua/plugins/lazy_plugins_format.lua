if vim.g.vscode == nil then
    return {
        "nvimtools/none-ls.nvim",
        dependencies = {"williamboman/mason.nvim", "jay-babu/mason-null-ls.nvim", "nvim-lua/plenary.nvim"},
        event = {"BufReadPre", "BufNewFile"},
        config = function()
            local null_ls = require("null-ls")

            null_ls.setup({
                autostart = true, -- ← 重要：ここが有効になっていることを確認！
                sources = { -- Black Formatter
                null_ls.builtins.formatting.black.with({
                    extra_args = {"--fast"}
                })},

                on_attach = function(client, bufnr)
                    if client.supports_method("textDocument/formatting") then
                        local group = vim.api.nvim_create_augroup("Format", {
                            clear = true
                        })
                        vim.api.nvim_clear_autocmds({
                            group = group,
                            buffer = bufnr
                        })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = group,
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.format({
                                    bufnr = bufnr,
                                    async = true
                                })
                            end
                        })
                    end
                end
            })

            require("mason-null-ls").setup({
                ensure_installed = {"black"},
                automatic_installation = true
            })
        end
    }
else
    return {}
end
