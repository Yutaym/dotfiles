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

# $PROFILE に追加
function Use-ClaudeAnthropic {
    Remove-Item Env:ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    # $env:ANTHROPIC_API_KEY = "your-actual-api-key"
    Write-Host "-> Anthropic API mode"
}

function Use-ClaudeOllama {
    $env:ANTHROPIC_AUTH_TOKEN = "ollama"
    # $env:ANTHROPIC_API_KEY = ""
    $env:ANTHROPIC_BASE_URL = "http://yutapc:11434"
    Write-Host "-> Ollama mode"
}

# PowerShell 7 を winget で最新バージョンに更新する
# 実行中の pwsh 自身を上書きすると使用中ファイルでインストールが止まるため、
# 更新は別ウィンドウの Windows PowerShell (5.1) で行う
function Update-Powershell {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        LogError "winget が見つからないため PowerShell を更新できません"
        return
    }

    # 現在のバージョン (Windows PowerShell 5.1 から実行された場合は pwsh.exe のファイルバージョンを見る)
    $current = $null
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $current = [version]$PSVersionTable.PSVersion.ToString().Split('-')[0]
    } elseif ($pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue) {
        $v = [version]$pwshCmd.Version
        $current = [version]::new($v.Major, $v.Minor, $v.Build)
    }

    # 最新の安定版のバージョン (取得できなくても winget での更新は試みる)
    $latest = $null
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -TimeoutSec 10
        $latest = [version]$release.tag_name.TrimStart('v')
    } catch {
        LogWarn "最新バージョンを取得できませんでした: $($_.Exception.Message)"
    }

    LogInfo "現在のバージョン: $(if ($current) { $current } else { '未インストール' })"
    if ($latest) {
        LogInfo "最新のバージョン: $latest"
        if ($current -and $current -ge $latest) {
            LogSuccess "PowerShell は最新です"
            return
        }
    }

    $action = if ($current) { "upgrade" } else { "install" }
    $wingetCommand = "winget $action --id Microsoft.PowerShell -e --source winget --accept-package-agreements --accept-source-agreements"
    LogInfo "別ウィンドウで更新を開始します: $wingetCommand"
    Start-Process -FilePath "powershell.exe" -ArgumentList @('-NoProfile', '-NoExit', '-Command', $wingetCommand)
    LogWarn "インストールを完了させるため、開いている PowerShell 7 のウィンドウをすべて閉じてください"
}
Set-Alias -Name:"UpdatePowershell" -Value:"Update-Powershell" -Description:"Update PowerShell 7 to the latest version" -Option:"None"
