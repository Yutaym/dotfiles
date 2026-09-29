call denite#custom#map('insert', '<esc>', '<denite:enter_mode:normal>', 'noremap')
call denite#custom#map('normal', '<esc>', '<denite:quit>', 'noremap')
call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>', 'noremap')
call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>', 'noremap')
call denite#custom#map('insert', '<C-j>', '<denite:do_action:split>', 'noremap')
call denite#custom#map('insert', '<C-k>', '<denite:do_action:vsplit>', 'noremap')

call denite#custom#map('insert', 'jj', '<denite:enter_mode:normal>', 'noremap')


nnoremap <silent> <Space>uu :Denite buffer<CR>
nnoremap <silent> <Space>ub :Denite buffer<CR>
nnoremap <silent> <Space>uf :Denite  -buffer-name=file file<CR>
nnoremap <silent> <Space>uc :Denite file_old<CR>
nnoremap <silent> <Space>ud :Denite file_rec<CR>


