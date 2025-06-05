
$customPromptPath = Join-Path $env:USERPROFILE "dotfiles\powersell\profile.ps1"
if (Test-Path $customPromptPath) {
    . $customPromptPath
}
