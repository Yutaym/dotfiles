if (has('nvim'))
    call dein#add('roxma/nvim-yarp')
    call dein#add('roxma/vim-hug-neovim-rpc')
endif

" if ((has('nvim')  || has('timers')) && has('python3')) && system('pip3 show neovim') !=# ''
" if (has('nvim')) && system('pip3 show neovim') !=# ''
"     call dein#add('Shougo/deoplete.nvim')
"     call dein#add('Shougo/denite.nvim')
" elseif has('lua')
"     call dein#add('Shougo/neocomplete.vim')
"     call dein#add('Shougo/unite.vim')
" endif

call dein#add('Shougo/neoinclude.vim')
call dein#add('Shougo/neco-vim')
call dein#add('Shougo/neco-syntax')
call dein#add('ujihisa/neco-look')
call dein#add('Shougo/neomru.vim')
call dein#add('scrooloose/nerdtree')
call dein#add('tomtom/tcomment_vim')
call dein#add('tpope/vim-surround')
call dein#add('itchyny/lightline.vim')
call dein#add('itchyny/calendar.vim')
call dein#add('tyru/open-browser.vim')
call dein#add('rhysd/clever-f.vim')
call dein#add('unblevable/quick-scope')
call dein#add('asvetliakov/vim-easymotion')
" call dein#add('yuratomo/w3m.vim')

call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets',{'depends' : ['Shougo/neosnippet.vim']})

call dein#add('Shougo/vimproc.vim',{'build' : 'make'})
call dein#add('Shougo/vimshell.vim',{'depends' : ['Shougo/vimproc.vim']})
call dein#add('thinca/vim-quickrun',{'depends' : ['Shougo/vimproc.vim']})

" " 言語設定
call dein#add('cespare/vim-toml',{'on_ft' : ['toml']})
call dein#add('lervag/vimtex',{'on_ft' : ['tex']})

" "deoplete sorece

" call dein#add('davidhalter/jedi-vim',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('zchee/deoplete-jedi',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('lambdalisue/vim-django-support',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('lambdalisue/vim-pyenv',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('zchee/deoplete-clang',{'on_ft' : ['c','cpp','objective-c']})

" call dein#add('')
" call dein#add('',{})
