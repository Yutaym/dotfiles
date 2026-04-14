if (-not $env:path.Split(';').Contains('.')) {
    $env:path += ";."
}

$condaPath = Join-Path $env:USERPROFILE "miniconda3\Scripts\conda.exe"
#!! Contents within this block are managed by 'conda init' !!
If (Test-Path $condaPath) {
    (& $condaPath "shell.powershell" "hook") | Out-String | ? { $_ } | Invoke-Expression
}

# Remove-Item Env:ANTHROPIC_AUTH_TOKEN  -ErrorAction SilentlyContinue
# Remove-Item Env:ANTHROPIC_BASE_URL    -ErrorAction SilentlyContinue
# Write-Host "[Claude] Backend: Anthropic API (default)" -ForegroundColor Cyan

$powershellProfile = Join-Path $PSScriptRoot "powershell_profile.ps1"
$powershellAlias = Join-Path $PSScriptRoot "powershell_alias.ps1"
$powershellComplete = Join-Path $PSScriptRoot "powershell_complete.ps1"
$powershellFunction = Join-Path $PSScriptRoot "powershell_function.ps1"
# $powershellProfile = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_profile.ps1"
# $powershellAlias = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_alias.ps1"
# $powershellComplete = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_complete.ps1"
# $powershellFunction = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_function.ps1"
if (Test-Path $powershellProfile) {
    . $powershellProfile
}
if (Test-Path $powershellAlias) {
    . $powershellAlias
}
if (Test-Path $powershellComplete) {
    . $powershellComplete
}
if (Test-Path $powershellFunction) {
    . $powershellFunction
}

# $powershellProfile = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_main.ps1"
# if (Test-Path $powershellMain) {
#     . $powershellMain
# }
