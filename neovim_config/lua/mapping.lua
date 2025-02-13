vim.keymap.set('i', 'jj', '<ESC>', {
    noremap = true
})
vim.keymap.set({'n', 'x'}, ';', ':', {
    noremap = true
})
-- vim.keymap.set({'n', 'v'}, ':', ',', {noremap = true})
-- vim.keymap.set({'n', 'v'}, ',', ';', {noremap = true})

vim.keymap.set({'n'}, 'gl', '$', {
    noremap = true,
    silent = true
})
vim.keymap.set({'x'}, 'gl', '$h', {
    noremap = true,
    silent = true
})
vim.keymap.set({'n'}, 'gh', '^', {
    noremap = true,
    silent = true
})
vim.keymap.set({'x'}, 'gh', '^', {
    noremap = true,
    silent = true
})
-- vim.keymap.set({'n', 'v'}, 'j', 'gj', {noremap = true, silent = true})
-- vim.keymap.set({'n', 'v'}, 'k', 'gk', {noremap = true, silent = true})
-- vim.keymap.set({'n', 'v'}, 'gj', '10j', {noremap = true, silent = true})
-- vim.keymap.set({'n', 'v'}, 'gk', '10k', {noremap = true, silent = true})
vim.keymap.set({'n', 'x'}, '<Down>', 'g<Down>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'n', 'x'}, '<Up>', 'g<Up>', {
    noremap = true,
    silent = true
})

vim.keymap.set({'n', 'x'}, 'H', '10h', {
    noremap = true,
    silent = true
})
vim.keymap.set({'n', 'x'}, 'J', '10j', {
    noremap = true,
    silent = true
})
vim.keymap.set({'n', 'x'}, 'K', '10k', {
    noremap = true,
    silent = true
})
vim.keymap.set({'n', 'x'}, 'L', '10l', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'x', 'c'}, '<Ctrl-C>', '<ESC>', {
    noremap = true
})

vim.keymap.set('n', '<ESC><ESC>', ':nohlsearch<CR><ESC>', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'q;', 'q:', {
    noremap = true
})
vim.keymap.set('n', 'x', '"_x', {
    noremap = true,
    silent = true
})
vim.keymap.set('n', 'X', '"_X', {
    noremap = true,
    silent = true
})
vim.keymap.set('n', 'Y', 'y$', {
    noremap = true,
    silent = true
})
vim.keymap.set('n', 'U', '<C-r>', {
    noremap = true,
    silent = true
})

vim.keymap.set('i', '<C-u>', '<ESC>ui', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-j>', '<ESC>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-a>', '<Home>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-b>', '<Left>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-d>', '<Del>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-e>', '<End>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-f>', '<Right>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-n>', '<Down>', {
    noremap = true,
    silent = true
})
vim.keymap.set({'i', 'c'}, '<C-p>', '<Up>', {
    noremap = true,
    silent = true
})

-- vim.keymap.set('v', '<C-a>', '<ESC>ggVG', {
--     noremap = true
-- })
vim.keymap.set('v', 'sa', '<ESC>ggVG', {
    noremap = true
})
-- vim.keymap.set("n", "sw", 'yiw:%s/<C-r><C-r>"//g<Left><Left>')

vim.keymap.set('n', '<Space>', '<Leader>', {
    noremap = true,
    silent = true
})

-- print(vim.env.vscode == nil)
if (vim.g.vscode) then
    print('mode: vscode')
    vim.keymap.set({'n', 'v'}, 's', '<Nop>', {
        noremap = true,
        silent = true
    })

    vim.keymap.set('n', 'ss', '/', {
        noremap = true
    })
    vim.keymap.set("x", "ss", 'y:%s/<C-V>//g<Left><Left>')
    vim.keymap.set('n', 'sr', ':s/', {
        noremap = true
    })
    -- vim.keymap.set('n', 'sa', ':%s/', {noremap = true, silent = true})

    vim.keymap.set('n', 'sa', function()
        vim.cmd('call VSCodeNotify("editor.action.startFindReplaceAction")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sd', function()
        vim.cmd('call VSCodeNotify("workbench.action.splitEditorUp")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sv', function()
        vim.cmd('call VSCodeNotify("workbench.action.splitEditorRight")')
    end, {
        noremap = true,
        silent = true
    })

    vim.keymap.set('n', 'sw', function()
        vim.cmd('call VSCodeNotify("workbench.action.focusNextGroup")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sh', function()
        vim.cmd('call VSCodeNotify("workbench.action.navigateLeft")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sj', function()
        vim.cmd('call VSCodeNotify("workbench.action.navigateDown")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sk', function()
        vim.cmd('call VSCodeNotify("workbench.action.navigateUp")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sl', function()
        vim.cmd('call VSCodeNotify("workbench.action.navigateRight")')
    end, {
        noremap = true,
        silent = true
    })
    -- vim.keymap.set('n', 'sw', '<C-w>w', {noremap = true})
    -- vim.keymap.set('n', 'sh', '<C-w>h', {noremap = true})
    -- vim.keymap.set('n', 'sj', '<C-w>j', {noremap = true})
    -- vim.keymap.set('n', 'sk', '<C-w>k', {noremap = true})
    -- vim.keymap.set('n', 'sl', '<C-w>l', {noremap = true})

    vim.keymap.set('n', 'so', function()
        vim.cmd('call VSCodeNotify("workbench.action.toggleMaximizeEditorGroup")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sq', function()
        vim.cmd('call VSCodeNotify("workbench.action.closeActiveEditor")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sn', function()
        vim.cmd('call VSCodeNotify("workbench.action.nextEditor")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sp', function()
        vim.cmd('call VSCodeNotify("workbench.action.previousEditor")')
    end, {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'st', function()
        vim.cmd('call VSCodeNotify("welcome.showNewFileEntries")')
    end, {
        noremap = true,
        silent = true
    })

else
    print('mode: not vscode')
    vim.keymap.set('n', 's', '<Nop>', {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'ss', '/', {
        noremap = true,
        silent = true
    })
    vim.keymap.set("x", "ss", 'y:%s/<C-r><C-r>"//g<Left><Left>')
    vim.keymap.set('n', 'sr', ':s/', {
        noremap = true,
        silent = true
    })
    vim.keymap.set('n', 'sa', ':%s/', {
        noremap = true,
        silent = true
    })

    -- vim.keymap.set('n', 'sd', function() vim.cmd('split') end, {noremap = true})
    -- vim.keymap.set('n', 'sv', vim.cmd('vsplit'), {noremap = true})
    vim.keymap.set('n', 'sd', ':split<CR>', {
        noremap = true
    })
    vim.keymap.set('n', 'sv', ':vsplit<CR>', {
        noremap = true
    })
    vim.keymap.set('n', 'sw', '<C-w>w', {
        noremap = true
    })
    vim.keymap.set('n', 'sh', '<C-w>h', {
        noremap = true
    })
    vim.keymap.set('n', 'sj', '<C-w>j', {
        noremap = true
    })
    vim.keymap.set('n', 'sk', '<C-w>k', {
        noremap = true
    })
    vim.keymap.set('n', 'sl', '<C-w>l', {
        noremap = true
    })
    vim.keymap.set('n', 'so', '<C-w>_<C-w>|', {
        noremap = true
    })
    vim.keymap.set('n', 's=', '<C-w>=', {
        noremap = true
    })
    vim.keymap.set('n', 's>', '<C-w>>', {
        noremap = true
    })
    vim.keymap.set('n', 's<', '<C-w><', {
        noremap = true
    })
    vim.keymap.set('n', 's+', '<C-w>+', {
        noremap = true
    })
    vim.keymap.set('n', 's-', '<C-w>-', {
        noremap = true
    })
    vim.keymap.set('n', 'at', ':tabnew<CR>', {
        noremap = true
    })
    vim.keymap.set('n', 'sn', 'gt', {
        noremap = true
    })
    vim.keymap.set('n', 'sp', 'gT', {
        noremap = true
    })

    vim.keymap.set('n', 'sbb', ':<C-u>enew<CR>', {
        noremap = true
    })
    vim.keymap.set('n', 'sbq', ':<C-u>bd<CR>', {
        noremap = true
    })
    vim.keymap.set('n', 'sbd', ':<C-u>bd<CR>', {
        noremap = true
    })
    vim.keymap.set('n', 'sbp', ':<C-u>bp<CR>', {
        noremap = true
    })

    vim.keymap.set('i', '(', '()<Left>', {
        noremap = true
    })
    vim.keymap.set('i', '[', '[]<Left>', {
        noremap = true
    })
    vim.keymap.set('i', '{', '{}<Left>', {
        noremap = true
    })
end
