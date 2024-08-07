
mkdir %LOCALAPPDATA%\nvim
mklink /D %LOCALAPPDATA%\nvim\lua %CD%\neovim_config\lua
mklink %LOCALAPPDATA%\nvim\init.lua %CD%\neovim_config\init.lua

mkdir %HOMEPATH%\.vim
mklink /D %HOMEPATH%\.vim\config %CD%\vim_config\config
mklink %HOMEPATH%\_vimrc %CD%\vim_config\.vimrc
mklink %HOMEPATH%\.vim\environment.vim %CD%\vim_config\environment_Window.vim
