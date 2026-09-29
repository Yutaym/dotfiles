
#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
# If (Test-Path "C:\Users\yutay\miniconda3\Scripts\conda.exe") {
#     (& "C:\Users\yutay\miniconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
# }
#endregion

$powershellMain = Join-Path $env:USERPROFILE "dotfiles\powershell_config\powershell_main.ps1"
if (Test-Path $powershellMain) {
    . $powershellMain
}
