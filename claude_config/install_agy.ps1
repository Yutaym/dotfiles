# Antigravity CLI (agy) を導入する (Windows 向け)
# Google の公式インストーラ (https://antigravity.google/download に載っているもの) を一時ファイルに取得し、確認してから実行する
# インストーラはユーザーの PATH (レジストリ) に %LOCALAPPDATA%\agy\bin を追加する。開いている端末には反映されないので、端末を開き直す
# ログインはブラウザが要るので、このスクリプトでは行わない。導入後に対話型の agy を 1 回起動して行う
# 使い方: pwsh ./install_agy.ps1 [-Yes]   (-Yes で確認を省く)
param([switch]$Yes)
$ErrorActionPreference = 'Stop'

$Url = 'https://antigravity.google/cli/install.ps1'
$AgyExe = Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe'

if (Test-Path $AgyExe) {
    Write-Host "[skip] agy は導入済み: $AgyExe ($(& $AgyExe --version 2>&1 | Select-Object -First 1))"
    return
}

$Tmp = Join-Path ([IO.Path]::GetTempPath()) "agy-install-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
    $Script = Join-Path $Tmp 'install.ps1'
    Invoke-WebRequest -Uri $Url -OutFile $Script
    Write-Host "[get] $Url -> $Script ($((Get-Item $Script).Length) bytes)"

    if (-not $Yes) {
        Write-Host "[info] 実行前に内容を確認できます: notepad $Script (別の端末で開く)"
        $ans = Read-Host 'このインストーラを実行しますか？ [y/N]'
        if ($ans -notin @('y', 'Y')) { Write-Host '[abort] 実行しませんでした'; return }
    }

    powershell -NoProfile -ExecutionPolicy Bypass -File $Script
} finally {
    Remove-Item -Path $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host '[done] 端末を開き直して (PATH の反映)、対話型の agy を 1 回起動してブラウザでログインしてください'
Write-Host '       確認: agy -p "日本の首都を一語で"'
