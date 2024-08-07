
vim.keymap.set('n', '<Space>r', '<Plug>ReplaceWithRegisterOperator', {noremap = true, silent = true})
vim.keymap.set('n', '<Space>rr', '<Plug>ReplaceWithRegisterLine', {noremap = true, silent = true})
vim.keymap.set({'v', 'x'}, '<Space>r', '<Plug>ReplaceWithRegisterVisual', {noremap = true, silent = true})
