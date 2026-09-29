# Neovim のインストールと設定ファイルのリンクを行う (Windows x64 向け)
# シンボリックリンク作成には「開発者モード」の有効化、または管理者権限での実行が必要
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Neovim'
$NvimBinDir = Join-Path $InstallDir 'bin'
$ConfigHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
$NvimConfigDir = Join-Path $ConfigHome 'nvim'

# ---------------------------------------------------------------
# 1. nvim のインストール (インストール済みならスキップ)
# ---------------------------------------------------------------
$nvimCmd = Get-Command nvim -ErrorAction SilentlyContinue
$nvimExe = Join-Path $NvimBinDir 'nvim.exe'
if ($nvimCmd -or (Test-Path $nvimExe)) {
    $found = if ($nvimCmd) { $nvimCmd.Source } else { $nvimExe }
    Write-Host "[skip] nvim is already installed: $found"
} else {
    Write-Host "[install] nvim -> $InstallDir"
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
    try {
        $zip = Join-Path $tmpDir 'nvim-win64.zip'
        Invoke-WebRequest -Uri 'https://github.com/neovim/neovim/releases/latest/download/nvim-win64.zip' -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $tmpDir
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        Copy-Item -Path (Join-Path $tmpDir 'nvim-win64\*') -Destination $InstallDir -Recurse -Force
    } finally {
        Remove-Item -Path $tmpDir -Recurse -Force
    }
}

# ---------------------------------------------------------------
# 2. PATH の確認 (通っていなければユーザー環境変数 PATH に追記)
# ---------------------------------------------------------------
$pathEntries = $env:Path -split ';' | ForEach-Object { $_.TrimEnd('\') }
if ($pathEntries -contains $NvimBinDir.TrimEnd('\')) {
    Write-Host "[skip] $NvimBinDir is already in PATH"
} elseif (Get-Command nvim -ErrorAction SilentlyContinue) {
    Write-Host "[skip] nvim is available via PATH: $((Get-Command nvim).Source)"
} else {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $userEntries = if ($userPath) { $userPath -split ';' | ForEach-Object { $_.TrimEnd('\') } } else { @() }
    if ($userEntries -contains $NvimBinDir.TrimEnd('\')) {
        Write-Host "[skip] PATH setting already exists in user environment"
    } else {
        $newPath = if ($userPath) { "$userPath;$NvimBinDir" } else { $NvimBinDir }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "[add] PATH setting -> user environment variable"
    }
    $env:Path = "$NvimBinDir;$env:Path"
    Write-Host "[info] 新しいターミナルを開くと PATH が反映されます"
}

# ---------------------------------------------------------------
# 3. 設定ファイルのシンボリックリンク作成
# ---------------------------------------------------------------
New-Item -ItemType Directory -Path $NvimConfigDir -Force | Out-Null

foreach ($name in @('init.lua', 'lua', '.textlintrc.json')) {
    $src = Join-Path $ScriptDir $name
    $dst = Join-Path $NvimConfigDir $name
    # Test-Path はリンク切れのシンボリックリンクを検出できないため Get-Item で確認する
    $item = Get-Item -Path $dst -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
        Write-Host "[skip] $dst -> $src"
        continue
    }
    if ($item) {
        Write-Warning "$dst already exists. skipped."
        continue
    }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "[link] $dst -> $src"
}

Write-Host "[done] nvim version: $((nvim --version | Select-Object -First 1))"
