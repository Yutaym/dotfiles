
# set-alias sudo Run-AsAdmin()

Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteChar
Set-PSReadLineKeyHandler -Key "Ctrl+w" -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key "Ctrl+u" -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+k" -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+a" -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+e" -Function EndOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardChar
Set-PSReadLineKeyHandler -Key "Ctrl+b" -Function BackwardChar
Set-PSReadLineKeyHandler -Key "Alt+f" -Function NextWord
Set-PSReadLineKeyHandler -Key "Alt+b" -Function BackwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function PreviousHistory
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function NextHistory
Set-PSReadLineKeyHandler -Key Ctrl+g -ScriptBlock {
    $line = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().InputLine
    Invoke-CopilotSuggest $line
}

## input History Plugin
$psReadLineModule = Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

if ($psReadLineModule -and $psReadLineModule.Version -ge [version]'2.1.0') {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -Colors @{
        InLinePrediction = [ConsoleColor]::DarkGray
        ListPrediction   = [ConsoleColor]::Cyan
    }
}


Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command (gh completion -s powershell | Out-String)
}
