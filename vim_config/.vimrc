inoremap jj <ESC>
nnoremap ; :
nnoremap : ;

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

syntax on
hi Comment ctermfg=3

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

" mapping
nnoremap ; :
nnoremap ;; :!
nnoremap : ;

nnoremap zH zh
nnoremap zJ zj
nnoremap zK zk
nnoremap zL zl

nnoremap zh zH
nnoremap zj zJ
nnoremap zk zK
nnoremap zl zL

" nnoremap <Space>h ^
" nnoremap <Space>l $
nnoremap x "_x
nnoremap X "_X
nnoremap Y y$

nnoremap s <Nop>
nnoremap ss :split<CR>
nnoremap sv :vsplit<CR>
nnoremap sw <C-w>w
nnoremap sh <C-w>h
nnoremap sj <C-w>j
nnoremap sk <C-w>k
nnoremap sl <C-w>l
nnoremap sH <C-w>H
nnoremap sJ <C-w>J
nnoremap sK <C-w>K
nnoremap sL <C-w>L
nnoremap so <C-w>_<C-w>|
nnoremap s= <C-w>=
nnoremap s0 <C-w>=
nnoremap s> <C-w>>
nnoremap s< <C-w><
nnoremap s+ <C-w>+
nnoremap s- <C-w>-
nnoremap s<Right> <C-w>>
nnoremap s<Left> <C-w><
nnoremap s<Up> <C-w>+
nnoremap s<Down> <C-w>-
nnoremap st :tabnew<CR>
nnoremap sn gt
nnoremap sp gT
nnoremap sq :q<CR>

nnoremap sbb :<C-u>enew<CR>
nnoremap sbq :<C-u>bd<CR>
nnoremap sbd :<C-u>bd<CR>
nnoremap sbn :<C-u>bn<CR>
nnoremap sbp :<C-u>bp<CR>

nnoremap sQ :<C-u>bd<CR>
nnoremap sN :<C-u>bn<CR>
nnoremap sP :<C-u>bp<CR>

nnoremap j gj
nnoremap k gk

nnoremap gh ^
nnoremap gl $

nnoremap <silent>sc :<C-u>setlocal spell! spelllang=en_us<CR>:setlocal spell?<CR>

nnoremap <Space> <Nop>

inoremap jj <ESC>
inoremap <C-j> <ESC>
inoremap <C-a> <Home>
inoremap <C-b> <Left>
inoremap <C-d> <Del>
inoremap <C-e> <End>
inoremap <C-f> <Right>
inoremap <C-n> <Down>
inoremap <C-p> <Up>
inoremap <M-b> <S-Left>
inoremap <M-f> <S-Right>
"inoremap <expr> / (getcmdtype() == '/') '\/' : '/'

vnoremap v $h
vnoremap <C-a> <ESC>ggVG
vnoremap aa <ESC>ggVG
vnoremap x "_x
vnoremap X "_X
vnoremap ; :
vnoremap : ;

cnoremap <C-a> <Home>
cnoremap <C-b> <Left>
cnoremap <C-d> <Del>
cnoremap <C-e> <End>
cnoremap <C-f> <Right>
cnoremap <C-n> <Down>
cnoremap <C-p> <Up>
cnoremap <M-b> <S-Left>
cnoremap <M-f> <S-Right>
"cnoremap <expr> / (getcmdtype() == '/') '\/' : '/'
