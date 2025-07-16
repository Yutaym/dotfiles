set "SCRIPT_PATH=%USERPROFILE%\dotfiles\powersell\init_powershell_config.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"


set-ExecutionPolicy RemoteSigned -Scope CurrentUser

curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe -o "%USERPROFILE%\miniconda.exe"
"%USERPROFILE%\miniconda3\Scripts\conda.exe" init

for /f "tokens=*" %%i in ('powershell -Command "(Invoke-RestMethod -Uri https://api.github.com/repos/coreybutler/nvm-windows/releases/latest).assets | Where-Object { $_.name -eq 'nvm-setup.exe' } | Select-Object -ExpandProperty browser_download_url"') do set "DOWNLOAD_URL=%%i"
set "TEMP_PATH=%TEMP%\nvm-setup.exe"
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_PATH%'"
start /wait "" "%TEMP_PATH%"
del "%TEMP_PATH%"
nvm install latest
nvm use latest
npm install -g textlint
npm install -g npm
npm install -g markdown-pdf                                                              [History]
npm install -g @mermaid-js/mermaid-cli


for /f "tokens=*" %%i in ('powershell -Command "(Invoke-RestMethod -Uri https://api.github.com/repos/neovim/neovim/releases/latest).assets | Where-Object { $_.name -eq 'nvim-win64.msi' } | Select-Object -ExpandProperty browser_download_url"') do set "DOWNLOAD_URL=%%i"
set "TEMP_PATH=%TEMP%\nvim-win64.msi"
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_PATH%'"
start /wait "" "%TEMP_PATH%"
del "%TEMP_PATH%"

endlocal

mkdir %LOCALAPPDATA%\nvim
mklink /D %LOCALAPPDATA%\nvim\lua %CD%\neovim_config\lua
mklink %LOCALAPPDATA%\nvim\init.lua %CD%\neovim_config\init.lua

mkdir %HOMEPATH%\.vim
mklink /D %HOMEPATH%\.vim\config %CD%\vim_config\config
mklink %HOMEPATH%\_vimrc %CD%\vim_config\.vimrc
mklink %HOMEPATH%\.vim\environment.vim %CD%\vim_config\environment_Windows.vim
