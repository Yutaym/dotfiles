"let $PATH = "~/.pyenv/shims:".$PATH

if has('nvim')
    let g:python3_host_prog = 'C:/Users/yutay/miniconda3/envs/neovim/python.exe'
    " let g:ruby_host_prog = '~/.rbenv/versions/2.7.1/bin/neovim-ruby-host'
    " let g:node_host_prog = '~/.nodenv/versions/13.11.0/bin/neovim-node-host'
    let g:loaded_node_provider = 0
endif

source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/dein_config_win.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/basic.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/mapping.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/color.vim

" if ((has('nvim')  || has('timers')) && has('python3'))
if (has('nvim')) && !exists('g:vscode')
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/ddc_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/ddu_config.vim
    " source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/deoplete_config.vim
    " source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/denite_config.vim
elseif has('lua')
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/neocomplete_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/unite_config.vim
endif


"c:/Users/yutay/AppData/Local/nvim
"
" if has('nvim')
"     source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/fzf_preview_config.vim
"     source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/fern_config.vim
" endif

if !exists('g:vscode')
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/nerdtree_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/vimproc_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/quickrun_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/vimshell_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/neosnippet_config.vim
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/openbrowser_config.vim
    if has('nvim')
        source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/fzf_preview_config.vim
        source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/fern_config.vim
    endif
endif
source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/tcomment_config.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/calendar_config.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/cleverf_config.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/easymotion_config.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/plugin/quick-scope_config.vim

source c:/Users/yutay/AppData/Local/nvim/.vim/config/function/dictionarytranslate.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/function/japaneseconfig.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/function/spellconfig.vim
source c:/Users/yutay/AppData/Local/nvim/.vim/config/function/scouter.vim

if !exists('g:vscode')
    autocmd FileType tex source c:/Users/yutay/AppData/Local/nvim/.vim/config/filetype/tex/tex_config.vim
    autocmd FileType plaintex source c:/Users/yutay/AppData/Local/nvim/.vim/config/filetype/tex/tex_config.vim
    autocmd FileType python source c:/Users/yutay/AppData/Local/nvim/.vim/config/filetype/python/python_config.vim
    autocmd FileType int-python source c:/Users/yutay/AppData/Local/nvim/.vim/config/filetype/python/python_config.vim
    autocmd FileType cpp source c:/Users/yutay/AppData/Local/nvim/.vim/config/filetype/cpp/cpp_config.vim
    autocmd FileType markdown source c:/Users/yutay/AppData/Local/nvim/.vim/config/filetype/markdown/markdown_config.vim

    filetype plugin indent on
endif
