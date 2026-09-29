return {
    'akinsho/toggleterm.nvim',
    cond = function() return vim.g.vscode == nil end,
    version = "*",
    keys = {{
        "<leader>t",
        "<cmd>ToggleTerm<CR>",
        desc = "Toggle Terminal"
    }},
    cmd = {"ToggleTerm"},
    config = function()
        require("toggleterm").setup {
            size = 20,
            direction = "horizontal",
            start_in_insert = true,
            insert_mappings = true,
            terminal_mappings = true,
            shade_terminals = true,
            shading_factor = 2,
            persist_size = true,
            close_on_exit = true,
            shell = vim.o.shell,
            -- toggleterm のターミナルだけに設定する（claudecode.nvim など他のターミナルに影響させない）
            -- バッファ名はシェルによって #toggleterm# / ::toggleterm:: と変わるため、名前ではなく on_open で設定する
            on_open = function(term)
                vim.keymap.set("t", "jj", [[<C-\><C-n>]], {
                    buffer = term.bufnr,
                    desc = "Exit terminal mode"
                })
                vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
                    buffer = term.bufnr,
                    desc = "Exit terminal mode"
                })
            end
        }
    end
}
