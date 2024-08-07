function! s:DictionaryTranslate(...)
    let l:word = a:0 == 0 ? expand('<cword>') : a:1
    call histadd('cmd', 'DictionaryTranslate '  . l:word)
    if l:word ==# '' | return | endif
    let l:gene_path = '~/.vim/dict/gene.txt'
    let l:jpn_to_eng = l:word !~? '^[a-z_]\+$'
    let l:output_option = l:jpn_to_eng ? '-B 1' : '-A 1' " 和英 or 英和

    silent pedit Translate\ Result | wincmd P | %delete " 前の結果が残っていることがあるため
    setlocal buftype=nofile noswapfile modifiable
    silent execute 'read !grep -ihw' l:output_option l:word l:gene_path

    " let l:cmd = "grep -ihw ".l:output_option." ".l:word." ".l:gene_path." "
    " let l:result = g:VimProcExecmd(l:cmd)
    " let l:replaced = substitute(l:result,"\n","\r","g")
    " silent call append(1,l:replaced)
    " silent call append(0,l:cmd)
    " %s/\/\/g

    silent 0delete
    let l:esc = @z
    let @z = ''
    while search("^" . l:word . "$", "Wc") > 0 " 完全一致したものを上部に移動
        silent execute line('.') - l:jpn_to_eng . "delete Z 2"
    endwhile
    silent 0put z
    let @z = l:esc
    silent call append(line('.'), '==')
    silent 1delete
    silent wincmd p
    echo l:word
endfunction
command! -nargs=? -complete=command DictionaryTranslate call <SID>DictionaryTranslate(<f-args>)
