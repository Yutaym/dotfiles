$powershellMain = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_main.ps1"
$powershellProfile = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_profile.ps1"
$powershellAlias = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_alias.ps1"
$powershellComplete = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_complete.ps1"
$powershellFunction = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_function.ps1"
if (Test-Path $powershellMain) {
    . $powershellMain
}
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
