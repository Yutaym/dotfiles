function! s:JapaneseConfig(...)
    source ~/.vim/config/function/japaneseconfig_contents.vim
endfunction
command! -nargs=? -complete=command JapaneseConfig call <SID>JapaneseConfig(<f-args>)
