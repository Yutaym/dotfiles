nnoremap ; :
nnoremap ;; :!
nnoremap : ;
nnoremap q; q:

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


nnoremap j gj
nnoremap k gk

nnoremap gh ^
nnoremap gl $

nnoremap <silent>sc :<C-u>setlocal spell! spelllang=en_us<CR>:setlocal spell?<CR>

nnoremap <Space> <Nop>

inoremap <C-u> <ESC>
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
vnoremap gl $
vnoremap gh ^
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

nnoremap s <Nop>
if exists('g:vscode')
    " inoremap <silent> jj <Cmd>call VSCodeNotify('workbench.action.acceptSelectedQuickOpenItem')<CR>
    " nnoremap <silent> <Space><Space> <Cmd>call VSCodeNotify('workbench.action.showCommands')<CR>
    nnoremap <silent> <Space><Space> <Cmd>call VSCodeNotify('workbench.action.quickOpen')<CR>
    nnoremap <silent> <Space>d <Cmd>call VSCodeNotify('editor.action.goToDeclaration')<CR>
    nnoremap <silent> <Space>e <Cmd>call VSCodeNotify("workbench.action.navigateBack")<CR>
    nnoremap <silent> <Space>h <Cmd>call VSCodeNotify("editor.action.showHover")<CR>
    nnoremap <silent> <Space>c <Cmd>call VSCodeNotify("editor.action.commentLine")<CR>
    nnoremap <silent> <Space>bb <Cmd>call VSCodeNotify("bookmarks.toggle")<CR>
    nnoremap <silent> <Space>bn <Cmd>call VSCodeNotify("bookmarks.jumpToNext")<CR>
    nnoremap <silent> <Space>bp <Cmd>call VSCodeNotify("bookmarks.jumpToPrevious")<CR>
    nnoremap <silent> <Space>t <Cmd>call VSCodeNotify("workbench.action.terminal.toggleTerminal")<CR>
    nnoremap <silent> <Space>m <Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>
    nnoremap <silent> <Space>o <Cmd>call VSCodeNotify("github.copilot.toggleCopilot")<CR>
    nnoremap <silent> <Space>r <Cmd>call VSCodeNotify("editor.action.startFindReplaceAction")<CR>
    nnoremap <silent> <Space>p <Cmd>call VSCodeNotify("markdown-preview-enhanced.openPreviewToTheSide")<CR>

    " nnoremap <silent> ss <Cmd>call VSCodeNotify("editor.action.startFindReplaceAction")<CR>
    nnoremap <silent> ss /
    nnoremap <silent> sa <Cmd>call VSCodeNotify("editor.action.startFindReplaceAction")<CR>
    nnoremap <silent> sd <Cmd>call VSCodeNotify('workbench.action.splitEditorUp')<CR>
    nnoremap <silent> sv <Cmd>call VSCodeNotify('workbench.action.splitEditorRight')<CR>
    nnoremap <silent> sw <Cmd>call VSCodeNotify('workbench.action.focusNextGroup')<CR>
    nnoremap <silent> sh <Cmd>call VSCodeNotify('workbench.action.focusLeftGroup')<CR>
    nnoremap <silent> sj <Cmd>call VSCodeNotify('workbench.action.focusBelowGroup')<CR>
    nnoremap <silent> sk <Cmd>call VSCodeNotify('workbench.action.focusAboveGroup')<CR>
    " nnoremap <silent> sk <Cmd>call VSCodeNotify('workbench.action.focusUpGroup')<CR>
    nnoremap <silent> sl <Cmd>call VSCodeNotify('workbench.action.focusRightGroup')<CR>
    nnoremap <silent> sH <Cmd>call VSCodeNotify('workbench.action.moveEditorToPreviousGroup')<CR>
    nnoremap <silent> sJ <Cmd>call VSCodeNotify('workbench.action.moveEditorToBelowGroup')<CR>
    nnoremap <silent> sK <Cmd>call VSCodeNotify('workbench.action.moveEditorToAboveGroup')<CR>
    nnoremap <silent> sL <Cmd>call VSCodeNotify('workbench.action.moveEditorToNextGroup')<CR>
    nnoremap <silent> so <Cmd>call VSCodeNotify('workbench.action.maximizeEditor')<CR>
    nnoremap <silent> sq <Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>
    nnoremap <silent> sn <Cmd>call VSCodeNotify('workbench.action.nextEditor')<CR>
    nnoremap <silent> sp <Cmd>call VSCodeNotify('workbench.action.previousEditor')<CR>
    nnoremap <silent> st <Cmd>call VSCodeNotify('welcome.showNewFileEntries')<CR>

    vnoremap <silent> <Space><Space> <Cmd>call VSCodeNotify('workbench.action.showCommands')<CR>
    vnoremap <silent> <Space>c <Cmd>call VSCodeNotify("editor.action.commentLine")<CR>

else
    inoremap jj <ESC>
    nnoremap <silent> ss :s/
    nnoremap <silent> sa :%s/
    nnoremap <silent> sd :split<CR>
    nnoremap <silent> sv :vsplit<CR>
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
endif
