" Plugin key-mappings.
imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
xmap <C-k> <Plug>(neosnippet_expand_target)

" imap <TAB> <Plug>(neosnippet_expand_or_jump)
" smap <TAB> <Plug>(neosnippet_expand_or_jump)
" xmap <TAB> <Plug>(neosnippet_expand_target)

 imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
 \ "\<Plug>(neosnippet_expand_or_jump)"
 \: pumvisible() ? "\<C-n>" : "\<TAB>"
 smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
  \ "\<Plug>(neosnippet_expand_or_jump)"
   \: "\<TAB>"

" " For snippet_complete marker.
" if has('conceal')
"   set conceallevel=2 concealcursor=i
" endif

let g:neosnippet#snippets_directory='~/.vim/bundle/neosnippet-snippets/snippets/,~/.vim/snippets'

