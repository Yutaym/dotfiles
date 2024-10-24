-- replace config
vim.keymap.set('n', '<Space>r', '<Plug>ReplaceWithRegisterOperator', {noremap = true, silent = true})
vim.keymap.set('n', '<Space>rr', '<Plug>ReplaceWithRegisterLine', {noremap = true, silent = true})
vim.keymap.set({'v', 'x'}, '<Space>r', '<Plug>ReplaceWithRegisterVisual', {noremap = true, silent = true})

-- clever-f config
vim.keymap.set({'n', 'v'}, ',', '<Plug>(clever-f-repeat-forward)', {noremap = true, silent = true})
vim.keymap.set({'n', 'v'}, ':', '<Plug>(clever-f-repeat-back)', {noremap = true, silent = true})
-- edgemotion
vim.keymap.set({'n', 'v'}, 'gj', '<Plug>(edgemotion-j)', {noremap = true, silent = true})
vim.keymap.set({'n', 'v'}, 'gk', '<Plug>(edgemotion-k)', {noremap = true, silent = true})

-- dial increment
vim.keymap.set({'n', 'v'}, '<C-a>', '<Plug>(dial-increment)', {noremap = true, silent = true})
vim.keymap.set({'n', 'v'}, '<C-d>', '<Plug>(dial-decrement)', {noremap = true, silent = true})
vim.keymap.set({'n', 'v'}, 'g<C-a>', 'g<Plug>(dial-increment)', {noremap = true, silent = true})
vim.keymap.set({'n', 'v'}, 'g<C-a>', 'g<Plug>(dial-decrement)', {noremap = true, silent = true})

-- hlslens
require('hlslens').setup()
local kopts = {noremap = true, silent = true}
vim.api.nvim_set_keymap('n', 'n',
    [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', 'N',
    [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', '<Leader>l', '<Cmd>noh<CR>', kopts)

