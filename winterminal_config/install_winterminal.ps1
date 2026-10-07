# Windows Terminal の settings.json のリンクを行う (Windows 向け)
# シンボリックリンク作成には「開発者モード」の有効化、または管理者権限での実行が必要
# 既存の settings.json が実ファイルの場合は settings.json.bak.<日時> に退避してからリンクする
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'settings.json'
$TerminalDir = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'

if (-not (Test-Path $TerminalDir)) {
    Write-Warning "$TerminalDir not found. Windows Terminal (Store 版) を一度起動してから再実行してください。"
    exit 1
}

$dst = Join-Path $TerminalDir 'settings.json'
# Test-Path はリンク切れのシンボリックリンクを検出できないため Get-Item で確認する
$item = Get-Item -Path $dst -Force -ErrorAction SilentlyContinue
if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
    Write-Host "[skip] $dst -> $src"
} else {
    if ($item) {
        $bak = "$dst.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item -Path $dst -Destination $bak
        Write-Host "[backup] $dst -> $bak"
    }
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "[link] $dst -> $src"
}

Write-Host '[done]'
