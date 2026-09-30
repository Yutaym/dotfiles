# PowerShell のプロファイルのコピーを行う (Windows 向け)
# プロファイル (profile.ps1) は PowerShell 7 (pwsh) 用の全ホスト共通の場所 (Documents\PowerShell) に配置する
# -SkipAutoInstall を付けると powershell_auto_install.ps1 によるツールの自動インストールを行わない
param(
    [switch]$SkipAutoInstall
)
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot

# ---------------------------------------------------------------
# 1. PowerShell 7 の確認 (自動インストールはしない)
# ---------------------------------------------------------------
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCmd) {
    Write-Host "[ok] pwsh is installed: $($pwshCmd.Source)"
} else {
    Write-Warning 'pwsh (PowerShell 7) is not installed. 以下のコマンドでインストールしてください'
    Write-Host '    winget install --id Microsoft.PowerShell -e'
}

# ---------------------------------------------------------------
# 2. プロファイルのコピー
# ---------------------------------------------------------------
# Windows PowerShell 5.1 から実行しても pwsh 用の場所に置けるよう、$PROFILE ではなく自前で組み立てる
$documentsDir = [Environment]::GetFolderPath('MyDocuments')
$src = Join-Path $ScriptDir 'profile.ps1'
$dst = Join-Path $documentsDir 'PowerShell\profile.ps1'
$srcContent = [IO.File]::ReadAllText($src)

# プロファイルは ~\dotfiles\powershell_config 配下を読み込む前提のため、
# dotfiles が別の場所にある場合は読み込み先を書き換えたものをコピーする
$defaultDir = Join-Path $env:USERPROFILE 'dotfiles\powershell_config'
if ($ScriptDir.TrimEnd('\') -ne $defaultDir) {
    $srcContent = $srcContent.Replace('$env:USERPROFILE "dotfiles\powershell_config\', "`"$ScriptDir`" `"")
}

# 既存ファイルが異なる内容なら、タイムスタンプ付きでバックアップしてから上書きする
$dstDir = Split-Path -Path $dst
if (-not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    Write-Host "[mkdir] $dstDir"
}
if ((Test-Path $dst) -and ([IO.File]::ReadAllText($dst) -ceq $srcContent)) {
    Write-Host "[skip] $dst is up to date"
} else {
    if (Test-Path $dst) {
        $backup = "$dst.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item -Path $dst -Destination $backup
        Write-Host "[backup] $dst -> $backup"
    }
    [IO.File]::WriteAllText($dst, $srcContent)
    Write-Host "[copy] $src -> $dst"
}

# 旧方式の Microsoft.PowerShell_profile.ps1 が残っていると設定が二重に読み込まれるため警告する (削除は手動)
$oldProfile = Join-Path $documentsDir 'PowerShell\Microsoft.PowerShell_profile.ps1'
if ((Test-Path $oldProfile) -and (Select-String -Path $oldProfile -Pattern 'powershell_main\.ps1' -Quiet)) {
    Write-Warning "$oldProfile でも powershell_main.ps1 を読み込んでいるため、設定が二重に読み込まれます。不要であれば削除してください"
}

# ---------------------------------------------------------------
# 2.5. WSL に USERPROFILE を渡す (WSLENV に USERPROFILE/p を追加)
# ---------------------------------------------------------------
# /p を付けると WSL 側では /mnt/c/Users/<名前> の形に変換される。
# zsh の設定 (zshrc_env.sh) が、これを使って VS Code の code コマンドのパスを組み立てる
$wslenv = [Environment]::GetEnvironmentVariable('WSLENV', 'User')
$wslenvItems = @(if ($wslenv) { $wslenv -split ':' | Where-Object { $_ } })
if ($wslenvItems | Where-Object { $_ -match '^USERPROFILE(/|$)' }) {
    Write-Host "[skip] WSLENV already contains USERPROFILE: $wslenv"
} else {
    $newWslenv = (@($wslenvItems) + 'USERPROFILE/p') -join ':'
    [Environment]::SetEnvironmentVariable('WSLENV', $newWslenv, 'User')
    Write-Host "[set] WSLENV (User) = $newWslenv (新しく開いたターミナルから反映)"
}

# ---------------------------------------------------------------
# 3. 未インストールのプログラム・モジュールを自動インストール
# ---------------------------------------------------------------
if ($SkipAutoInstall) {
    Write-Host '[skip] auto install (-SkipAutoInstall)'
} else {
    . (Join-Path $ScriptDir 'powershell_auto_install.ps1')
}

# ---------------------------------------------------------------
# 4. デフォルトシェルの確認 (pwsh でなければ変更手順を提案する。変更自体は手動)
# ---------------------------------------------------------------
# Windows ではターミナル起動時のシェルが Windows Terminal の既定プロファイルで決まるため、それを確認する
$wtSettingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)
$wtSettings = $wtSettingsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $wtSettings) {
    Write-Host '[skip] Windows Terminal settings not found'
} else {
    try {
        # settings.json はコメント付き JSON のため、Windows PowerShell 5.1 では読めないことがある
        $wt = Get-Content -Path $wtSettings -Raw | ConvertFrom-Json
        $profiles = if ($wt.profiles.list) { $wt.profiles.list } else { $wt.profiles }
        $default = $profiles | Where-Object { $_.guid -eq $wt.defaultProfile } | Select-Object -First 1
        $isPwsh = $default -and (
            $default.source -eq 'Windows.Terminal.PowershellCore' -or
            "$($default.commandline)" -match 'pwsh(\.exe)?'
        )
        if ($isPwsh) {
            Write-Host "[skip] default profile is already PowerShell 7: $($default.name)"
        } else {
            $defaultName = if ($default) { $default.name } else { 'unknown' }
            Write-Host "[info] default profile of Windows Terminal is $defaultName (not PowerShell 7)"
            Write-Host '[info] 既定のシェルを PowerShell 7 に変更する場合は、以下の手順を手動で行ってください'
            Write-Host '    Windows Terminal の [設定] > [スタートアップ] > [既定のプロファイル] で "PowerShell" を選択'
        }
    } catch {
        Write-Warning "Windows Terminal の設定を読み込めませんでした: $wtSettings"
    }
}

Write-Host '[done]'
