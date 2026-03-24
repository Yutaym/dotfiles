vim.g.mapleader = " "

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

-- 一時的なリマップを適用する関数
-- local function enable_gj_mode()
--     -- `j` を `gj` にリマップ
--     vim.keymap.set("n", "j", "gj", {
--         noremap = true,
--         silent = true,
--         buffer = true
--     })
--     -- `k` を `gk` にリマップ
--     vim.keymap.set("n", "k", "gk", {
--         noremap = true,
--         silent = true,
--         buffer = true
--     })
--     -- 他のキーを押したら元に戻す
--     vim.defer_fn(function()
--         pcall(vim.keymap.del, "n", "j", {
--             buffer = true
--         }) -- 一時リマップを削除
--         pcall(vim.keymap.del, "n", "k", {
--             buffer = true
--         })
--     end, 1000) -- 1秒後にリセット
-- end

-- -- `gj` の動作 + 一時的なリマップ
-- local function gj_with_auto_repeat()
--     vim.cmd("normal! gj") -- `gj` を実行
--     enable_gj_mode() -- `j` を `gj` にする
-- end

-- -- `gk` の動作 + 一時的なリマップ
-- local function gk_with_auto_repeat()
--     vim.cmd("normal! gk") -- `gk` を実行
--     enable_gj_mode() -- `k` を `gk` にする
-- end

-- -- `gj` と `gk` のキー設定
-- vim.keymap.set("n", "gj", gj_with_auto_repeat, {
--     noremap = true,
--     silent = true
-- })
-- vim.keymap.set("n", "gk", gk_with_auto_repeat, {
--     noremap = true,
--     silent = true
-- })

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

vim.keymap.set('n', 'gW', 'gw', {
    noremap = true,
    silent = true
})
-- vim.keymap.set('n', '<C-w>', ',w', {
--     noremap = true,
--     silent = true
-- })

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
vim.keymap.set({'v', 'x'}, 'ga', '<ESC>ggVG', {
    noremap = true
})
-- vim.keymap.set("n", "sw", 'yiw:%s/<C-r><C-r>"//g<Left><Left>')

-- vim.keymap.set('n', '<Space>', '<Leader>', {
--     noremap = true,
--     silent = true
-- })


vim.keymap.set({'o', 'x'}, 'i<space>', 'iw', {
    noremap = true,
    silent = true
})

vim.keymap.set({'n', 'v'}, 's', '<Nop>', {
    noremap = true,
    silent = true
})

-- 共通マッピング
vim.keymap.set('n', 'ss', '/', {
    noremap = true
})
vim.keymap.set("x", "ss", vim.g.vscode and 'y:%s/<C-V>//g<Left><Left>' or 'y:%s/<C-r><C-r>"//g<Left><Left>')
vim.keymap.set("v", "ss", vim.g.vscode and 'y:%s/<C-V>//g<Left><Left>' or 'y:%s/<C-r><C-r>"//g<Left><Left>')
vim.keymap.set('n', 'sr', ':s/', {
    noremap = true
})
vim.keymap.set('n', 'sa', ':%s/', {
    noremap = true,
    silent = true
})

-- ---------------------------------------------------
-- VSCode/Vim 条件分岐マッピング
vim.keymap.set('n', 'cd', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("editor.action.rename")')
end or function()
    -- VSCode環境では使用しない
end, {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'gw', vim.g.vscode and '<Nop>' or '<C-w>', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sd', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.splitEditorUp")')
end or ':split<CR>', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sv', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.splitEditorRight")')
end or ':vsplit<CR>', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sw', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.focusNextGroup")')
end or '<C-w>w', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sh', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.navigateLeft")')
end or '<C-w>h', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sj', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.navigateDown")')
end or '<C-w>j', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sk', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.navigateUp")')
end or '<C-w>k', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'sl', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.navigateRight")')
end or '<C-w>l', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', 'so', vim.g.vscode and function()
    vim.cmd('call VSCodeNotify("workbench.action.toggleMaximizeEditorGroup")')
end or '<C-w>_<C-w>|', {
    noremap = true,
    silent = true
})

-- VSCode専用
if vim.g.vscode then
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
    -- Vim専用
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

    -- ターミナルモードでのマッピング
    vim.keymap.set('t', '<C-[>', '<C-\\><C-n>', {
        noremap = true
    })
end

-- ---------------------------------------------------
vim.keymap.set('n', '<leader>q', 'atest<Esc>', {
    noremap = true,
    silent = true
})
