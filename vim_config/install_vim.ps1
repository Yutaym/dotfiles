# Vim の設定ファイルのリンクを行う (Windows 向け)
# シンボリックリンク作成には「開発者モード」の有効化、または管理者権限での実行が必要
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
$VimRootDir = Join-Path $env:ProgramFiles 'Vim'

# Program Files\Vim\vimXX のうち最新版のディレクトリを返す
function Get-VimBinDir {
    if (-not (Test-Path $VimRootDir)) { return $null }
    Get-ChildItem -Path $VimRootDir -Directory -Filter 'vim*' |
        Where-Object { Test-Path (Join-Path $_.FullName 'vim.exe') } |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

# ---------------------------------------------------------------
# 1. vim の確認 (自動インストールはしない)
# ---------------------------------------------------------------
$vimCmd = Get-Command vim -ErrorAction SilentlyContinue
$vimBinDir = Get-VimBinDir
if ($vimCmd -or $vimBinDir) {
    $found = if ($vimCmd) { $vimCmd.Source } else { Join-Path $vimBinDir 'vim.exe' }
    Write-Host "[ok] vim is installed: $found"
} else {
    Write-Warning 'vim is not installed. 以下のコマンドでインストールしてから再実行してください'
    Write-Host '    winget install --id vim.vim -e'
}

# ---------------------------------------------------------------
# 2. PATH の確認 (通っていなければユーザー環境変数 PATH に追記)
# ---------------------------------------------------------------
if (Get-Command vim -ErrorAction SilentlyContinue) {
    Write-Host "[skip] vim is available via PATH: $((Get-Command vim).Source)"
} elseif (-not $vimBinDir) {
    Write-Host '[skip] vim is not installed. PATH setting skipped'
} else {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $userEntries = if ($userPath) { $userPath -split ';' | ForEach-Object { $_.TrimEnd('\') } } else { @() }
    if ($userEntries -contains $vimBinDir.TrimEnd('\')) {
        Write-Host '[skip] PATH setting already exists in user environment'
    } else {
        $newPath = if ($userPath) { "$userPath;$vimBinDir" } else { $vimBinDir }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host '[add] PATH setting -> user environment variable'
    }
    $env:Path = "$vimBinDir;$env:Path"
    Write-Host '[info] 新しいターミナルを開くと PATH が反映されます'
}

# ---------------------------------------------------------------
# 3. 設定ファイルのシンボリックリンク作成
# ---------------------------------------------------------------
# Windows 版 Vim は $HOME\_vimrc を優先して読み込む
$src = Join-Path $ScriptDir '.vimrc'
$dst = Join-Path $HOME '_vimrc'
# Test-Path はリンク切れのシンボリックリンクを検出できないため Get-Item で確認する
$item = Get-Item -Path $dst -Force -ErrorAction SilentlyContinue
if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
    Write-Host "[skip] $dst -> $src"
} elseif ($item) {
    Write-Warning "$dst already exists. skipped."
} else {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "[link] $dst -> $src"
}

if (Get-Command vim -ErrorAction SilentlyContinue) {
    Write-Host "[done] vim version: $((vim --version | Select-Object -First 1))"
} else {
    Write-Host '[done]'
}
