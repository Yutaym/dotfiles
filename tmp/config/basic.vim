set nocompatible

set fenc=utf-8

set autoread

set hidden

set nowritebackup
set nobackup
set virtualedit=block
set backspace=indent,eol,start
set ambiwidth=double
set wildmenu
set wildmode=longest:full,full
set virtualedit=onemore
set visualbell

"検索
set ignorecase
set smartcase
set wrapscan
set incsearch
set hlsearch

" 表示設定
set noerrorbells
set shellslash
set showmatch 
set matchtime=1
set cinoptions+=:0
set cmdheight=1
set laststatus=2
set showcmd
set display=lastline
set cursorline
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
set history=100

set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set smartindent
set autoindent

set guioptions+=a
if !has("nvim")
    set clipboard+=unnamed
endif
if has("nvim")
    set clipboard=unnamed
endif

set showmatch
set noswapfile
set nofoldenable
set title
set number
nnoremap <Esc><Esc> :nohlsearch<CR><ESC>
set iskeyword-=_

set whichwrap=b,s,h,l,<,>,[,],~
set mouse=a

set wrap
set conceallevel=0

set foldmethod=marker

" HTML/XML閉じタグ自動補完
augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

if has("autocmd")
  augroup redhat
    " In text files, always limit the width of text to 78 characters
    autocmd BufRead *.txt set tw=78
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
  augroup END
endif
