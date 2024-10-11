vim.g.user_toggle_motion_enable = 0

function toggleMotion()
    if vim.g.user_toggle_motion_enable == 0 then
        vim.keymap.set({'n', 'v'}, 'w', '<Plug>CamelCaseMotion_w', {noremap = true, silent = ture})
        vim.keymap.set({'n', 'v'}, 'e', '<Plug>CamelCaseMotion_e', {noremap = true, silent = ture})
        vim.keymap.set({'n', 'v'}, 'b', '<Plug>CamelCaseMotion_b', {noremap = true, silent = ture})
        vim.keymap.set({'o', 'v'}, 'iw', '<Plug>CamelCaseMotion_iw', {noremap = true, silent = ture})
        vim.keymap.set({'o', 'v'}, 'ie', '<Plug>CamelCaseMotion_ie', {noremap = true, silent = ture})
        vim.keymap.set({'o', 'v'}, 'ib', '<Plug>CamelCaseMotion_ib', {noremap = true, silent = ture})
        vim.g.user_toggle_motion_enable = 1
        print("Toggle Motion enable")
    else
        vim.keymap.set({'n', 'v'}, 'w', 'w', {noremap = true, silent = ture})
        vim.keymap.set({'n', 'v'}, 'e', 'e', {noremap = true, silent = ture})
        vim.keymap.set({'n', 'v'}, 'b', 'b', {noremap = true, silent = ture})
        vim.keymap.set({'o', 'v'}, 'iw', 'iw', {noremap = true, silent = ture})
        vim.keymap.set({'o', 'v'}, 'ie', 'ie', {noremap = true, silent = ture})
        vim.keymap.set({'o', 'v'}, 'ib', 'ib', {noremap = true, silent = ture})
        vim.g.user_toggle_motion_enable = 0
        print("Toggle Motion disable")
    end
end

vim.api.nvim_create_user_command( 'ToggleMotion', function() toggleMotion() end, {} )
