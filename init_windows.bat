mkdir %LOCALAPPDATA%\nvim

mklink /D %LOCALAPPDATA%\nvim\lua %CD%\neovim\lua
mklink %LOCALAPPDATA%\nvim\init.lua %CD%\neovim\init.lua
