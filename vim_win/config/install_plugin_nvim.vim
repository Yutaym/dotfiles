call dein#add('roxma/nvim-yarp')
call dein#add('roxma/vim-hug-neovim-rpc')
" call dein#add('Shougo/deoplete.nvim')
" call dein#add('Shougo/denite.nvim')

call dein#add('neoclide/coc.nvim', {'merged':0, 'rev': 'release'})
call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 })
call dein#add('yuki-yano/fzf-preview.vim', { 'rev': 'release/rpc' })
call dein#add('lambdalisue/fern.vim')

call dein#add('vim-denops/denops.vim')
call dein#add('Shougo/ddc.vim')
call dein#add('neovim/nvim-lspconfig')
call dein#add('prabirshrestha/vim-lsp')
call dein#add('Shougo/ddc-nvim-lsp')
call dein#add('Shougo/pum.vim')
call dein#add('Shougo/ddc-around')
call dein#add('LumaKernel/ddc-file')
call dein#add('Shougo/ddc-matcher_head')
call dein#add('Shougo/ddc-sorter_rank')
call dein#add('Shougo/ddc-converter_remove_overlap')

call dein#add('Shougo/ddu.vim')
call dein#add('Shougo/ddu-ui-ff')
call dein#add('Shougo/ddu-ui-filer')
call dein#add('Shougo/ddu-source-file')
call dein#add('Shougo/ddu-source-file_rec')
call dein#add('shun/ddu-source-rg')
call dein#add('shun/ddu-source-buffer')
call dein#add('Shougo/ddu-source-line')
call dein#add('Shougo/ddu-source-register')
call dein#add('yuki-yano/ddu-filter-fzf')
call dein#add('Shougo/ddu-kind-file')
call dein#add('Shougo/ddu-kind-word')
call dein#add('ryota2357/ddu-column-icon_filename')
call dein#add('Shougo/ddu-commands.vim')

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
call dein#add('easymotion/vim-easymotion')
" call dein#add('yuratomo/w3m.vim')


call dein#add('unblevable/quick-scope')
call dein#add('tpope/vim-fugitive')


call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets',{'depends' : ['Shougo/neosnippet.vim']})

call dein#add('Shougo/vimproc.vim',{'build' : 'make'})
call dein#add('Shougo/vimshell.vim',{'depends' : ['Shougo/vimproc.vim']})
call dein#add('thinca/vim-quickrun',{'depends' : ['Shougo/vimproc.vim']})
" " 言語設定
call dein#add('cespare/vim-toml',{'on_ft' : ['toml']})
call dein#add('lervag/vimtex',{'on_ft' : ['tex']})

" "deoplete sorece

call dein#add('davidhalter/jedi-vim',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('zchee/deoplete-jedi',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('lambdalisue/vim-django-support',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('lambdalisue/vim-pyenv',{'on_ft' : ['python','python3','djangohtml']})
" call dein#add('zchee/deoplete-clang',{'on_ft' : ['c','cpp','objective-c']})

" call dein#add('')
" call dein#add('',{})
