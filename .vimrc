"let $PATH = "~/.pyenv/shims:".$PATH
"let g:python3_host_prog = expand('~/.pyenv/shims/python3')
"let g:python3_host_prog = expand('/usr/local/bin/python3')


set shell=/usr/local/bin/zsh

source ~/.vim/config/plugin/dein_config.vim

source ~/.vim/config/basic.vim
source ~/.vim/config/mapping.vim
source ~/.vim/config/color.vim

" if ((has('nvim')  || has('timers')) && has('python3'))
    source ~/.vim/config/plugin/deoplete_config.vim
    source ~/.vim/config/plugin/denite_config.vim
" elseif has('lua')
"     source ~/.vim/config/plugin/neocomplete_config.vim
"     source ~/.vim/config/plugin/unite_config.vim
" endif


source ~/.vim/config/plugin/nerdtree_config.vim
source ~/.vim/config/plugin/tcomment_config.vim
source ~/.vim/config/plugin/vimproc_config.vim
source ~/.vim/config/plugin/vimshell_config.vim
source ~/.vim/config/plugin/neosnippet_config.vim
source ~/.vim/config/plugin/quickrun_config.vim
source ~/.vim/config/plugin/calendar_config.vim
source ~/.vim/config/plugin/openbrowser_config.vim
source ~/.vim/config/plugin/cleverf_config.vim
source ~/.vim/config/plugin/easymotion_config.vim
source ~/.vim/config/plugin/w3m_config.vim

source ~/.vim/config/function/dictionarytranslate.vim
source ~/.vim/config/function/japaneseconfig.vim
source ~/.vim/config/function/spellconfig.vim
source ~/.vim/config/function/scouter.vim

autocmd FileType tex source  ~/.vim/config/filetype/tex/tex_config.vim
autocmd FileType plaintex source  ~/.vim/config/filetype/tex/tex_config.vim
autocmd FileType python source  ~/.vim/config/filetype/python/python_config.vim
autocmd FileType int-python source  ~/.vim/config/filetype/python/python_config.vim
autocmd FileType cpp source  ~/.vim/config/filetype/cpp/cpp_config.vim
autocmd FileType markdown source  ~/.vim/config/filetype/markdown/markdown_config.vim

filetype plugin indent on
