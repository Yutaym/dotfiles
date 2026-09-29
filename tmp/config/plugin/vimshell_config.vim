nnoremap <silent> <Space>ss <S-v>:VimShellSendString<CR>
vnoremap <silent> <Space>ss :VimShellSendString<CR>

nnoremap <silent> <Space>sh :vsplit<CR>:VimShell<CR>
nnoremap <silent> <Space>si :VimShellInteractive<CR><ESC>:setlocal wrap<CR>
nnoremap <silent> <Space>sp :VimShellInteractive python<CR><ESC>:setlocal wrap<CR>
nnoremap <silent> <Space>sb :VimShellInteractive bash<CR><ESC>:setlocal wrap<CR>
nnoremap <silent> <Space>sf :VimShellInteractive fish<CR><ESC>:setlocal wrap<CR>

let g:vimshell_prompt = " >> "
let g:vimshell_secondary_prompt = "-- "
let g:vimshell_user_prompt = 'getcwd()'

let g:vimshell_prompt_expr =
\ 'escape(fnamemodify(getcwd(), ":~").">", "\\[]()?! ")." "'
let g:vimshell_prompt_pattern = '^\%(\f\|\\.\)\+> '
