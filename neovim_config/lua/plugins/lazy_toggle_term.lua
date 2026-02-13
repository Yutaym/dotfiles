return {
    'akinsho/toggleterm.nvim',
    cond = function() return vim.g.vscode == nil end,
    version = "*",
    keys = {{
        "<Space>t",
        desc = "Toggle Terminal"
    }},
    cmd = {"ToggleTerm"},
        config = function()
            require("toggleterm").setup {
                size = 20,
                -- open_mapping = [[<Space>t]],
                direction = "horizontal",
                start_in_insert = true,
                insert_mappings = true,
                terminal_mappings = true,
                shade_terminals = true,
                shading_factor = 2,
                persist_size = true,
                close_on_exit = true,
                shell = vim.o.shell
            }
            vim.keymap.set("n", "<Space>t", "<cmd>ToggleTerm<CR>", {
                desc = "Toggle Terminal"
            })
            vim.keymap.set("t", "jj", [[<C-\><C-n><cmd>ToggleTerm<CR>]], {
                desc = "Toggle terminal (from terminal mode)"
            })
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
                desc = "Exit terminal mode"
            })
        end
}
