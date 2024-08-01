let $CACHE = expand('C:/Users/yutay/AppData/Local/nvim/.vim/cache')
let s:dein_dir = $CACHE
if !($CACHE->isdirectory())
  call mkdir($CACHE, 'p')
endif
if &runtimepath !~# '/dein.vim'
  let s:dir = 'dein.vim'->fnamemodify(':p')
  if !(s:dir->isdirectory())
    let s:dir = $CACHE .. '/dein/repos/github.com/Shougo/dein.vim'
    if !(s:dir->isdirectory())
      execute '!git clone https://github.com/Shougo/dein.vim' s:dir
    endif
  endif
  execute 'set runtimepath^='
        \ .. s:dir->fnamemodify(':p')->substitute('[/\\]$', '', '')
endif

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)
  if exists('g:vscode')
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/install_plugin_vscode.vim
  elseif has('nvim')
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/install_plugin_nvim.vim
  else
    source c:/Users/yutay/AppData/Local/nvim/.vim/config/install_plugin.vim
  endif

  " call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif
