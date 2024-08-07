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

