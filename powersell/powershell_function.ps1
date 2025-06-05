function RunAsAdmin() {
    if ($args.count -eq 0) {
        Start-Process -Verb runas powershell
        return
    }
    Start-Process -Verb runas -ArgumentList @('-command', "$($args -join ' ')") powershell
}
Set-Alias -Name:"sudo" -Value:"RunAsAdmin" -Description:"Start the certain process as administrator" -Option:"None"


function LogInfo { Write-Host "[INFO ] $args" -ForegroundColor Cyan }
function LogWarn { Write-Host "[WARN ] $args" -ForegroundColor Yellow }
function LogError { Write-Host "[ERROR] $args" -ForegroundColor Red }
function LogSuccess { Write-Host "[ OK  ] $args" -ForegroundColor Green }

Register-ArgumentCompleter -CommandName MyCommand -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParams)
    "foo", "bar", "baz" | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
