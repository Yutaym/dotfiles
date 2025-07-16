# Dotfiles 側のプロファイルファイルのパス
$sourceProfilePath = Join-Path $env:USERPROFILE "dotfiles\powersell\Microsoft.PowerShell_profile.ps1"
$targetProfilePath = $PROFILE

$profileDir = Split-Path -Path $targetProfilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $targetProfilePath)) {
    New-Item -ItemType File -Path $targetProfilePath -Force | Out-Null
}

if (Test-Path $sourceProfilePath) {
    Copy-Item -Path $sourceProfilePath -Destination $targetProfilePath -Force
    Write-Host "プロファイルが $targetProfilePath にコピーされました。" -ForegroundColor Green
} else {
    Write-Host "元ファイルが見つかりません: $sourceProfilePath" -ForegroundColor Red
}
