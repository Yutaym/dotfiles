"let $PATH = "~/.pyenv/shims:".$PATH
set shell=/usr/local/bin/zsh
if has('nvim')
    let g:python_host_prog = '~/.pyenv/versions/2.7.15/bin/python'
    "let g:python3_host_prog = '~/.pyenv/versions/py3neovim/bin/python'
    let g:python3_host_prog = '/Users/yuta/.pyenv/versions/anaconda3-2019.10/bin/python'
    let g:ruby_host_prog = '~/.rbenv/versions/2.7.1/bin/neovim-ruby-host'
    let g:node_host_prog = '~/.nodenv/shims/neovim-node-host'
endif

let s:dein_dir = expand('~/.vim/dein')
