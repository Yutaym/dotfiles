if (-not $env:path.Split(';').Contains('.')) {
    $env:path += ";."
}

set-alias vi 'C:\Program Files\Vim\vim90\vim.exe'
# set-alias vim 'C:\Program Files\Vim\vim90\vim.exe'
set-alias vim 'C:\Program Files\Neovim\bin\nvim.exe'

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

function prompt {
    $branch = ""
    $gitStatusSymbols = ""
    $cwd = Get-Location
    $isGit = $false

    # 色の設定
    $colorEnv = "Green"
    $colorBranch = "Yellow"
    $colorPath = "Cyan"
    $colorArrow = "Gray"
    $colorStaged = "Green"
    $colorUnstaged = "Red"

    # 仮想環境名を検出（conda or venv）
    $env_name = ""
    if ($env:CONDA_DEFAULT_ENV) {
        $env_name = $env:CONDA_DEFAULT_ENV
    }
    elseif ($env:VIRTUAL_ENV) {
        $env_name = Split-Path -Path $env:VIRTUAL_ENV -Leaf
    }

    # Git チェック
    try {
        git rev-parse --is-inside-work-tree 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $isGit = $true
            $branch = (git rev-parse --abbrev-ref HEAD).Trim()

            $statusLines = git status --porcelain | Where-Object { $_.Length -ge 2 }

            $hasStaged = $false
            $hasUnstaged = $false

            foreach ($line in $statusLines) {
                $indexStatus = $line.Substring(0, 1)
                $workTreeStatus = $line.Substring(1, 1)

                if ($indexStatus -notmatch ' ' -and $indexStatus -ne '?') {
                    $hasStaged = $true
                }
                if ($workTreeStatus -notmatch ' ' -and $workTreeStatus -ne '?') {
                    $hasUnstaged = $true
                }
            }

            if ($hasStaged) {
                $gitStatusSymbols += "+"
            }
            if ($hasUnstaged) {
                $gitStatusSymbols += "*"
            }
        }
    }
    catch {}

    # 仮想環境表示
    if ($env_name) {
        Write-Host -NoNewline "(" -ForegroundColor $colorArrow
        Write-Host -NoNewline "$env_name" -ForegroundColor $colorEnv
        Write-Host -NoNewline ") " -ForegroundColor $colorArrow
    }

    # Git ブランチとステータス
    if ($branch) {
        Write-Host -NoNewline "[" -ForegroundColor $colorArrow
        Write-Host -NoNewline "$branch" -ForegroundColor $colorBranch
        if ($gitStatusSymbols.Contains("+")) {
            Write-Host -NoNewline "+" -ForegroundColor $colorStaged
        }
        if ($gitStatusSymbols.Contains("*")) {
            Write-Host -NoNewline "*" -ForegroundColor $colorUnstaged
        }
        Write-Host -NoNewline "] " -ForegroundColor $colorArrow
    }

    # パスとプロンプト
    Write-Host -NoNewline "$cwd" -ForegroundColor $colorPath
    Write-Host -NoNewline " >>> " -ForegroundColor $colorArrow

    return " "

    # if ($env_name) {
    #     if ($isGit) {
    #         (git branch | select-string "^\*").ToString() | set-variable -name branch
    #         $branch = $branch.trim() -replace "^\* *", ""
    #         "($env_name) [$branch] $(get-location) >>> "
    #     }
    #     else {
    #         "($env_name) $(get-location) >>> "
    #     }

    # }
    # else {
    #     if (git branch) {
    #         (git branch | select-string "^\*").ToString() | set-variable -name branch
    #         $branch = $branch.trim() -replace "^\* *", ""
    #         "[$branch] $(get-location) >>> "
    #     }
    #     else {
    #         " $(get-location) >>> "
    #     }
    # }
}

function Run-AsAdmin() {
    if ($args.count -eq 0) {
        Start-Process -Verb runas powershell
        return
    }
    Start-Process -Verb runas -ArgumentList @('-command', "$($args -join ' ')") powershell
}
Set-Alias -Name:"sudo" -Value:"Run-AsAdmin" -Description:"Start the certain process as administrator" -Option:"None"


## input History Plugin
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
# Set-PSReadLineOption -Colors @{ InLinePrediction = [ConsoleColor]::Cyan }
Set-PSReadLineOption -Colors @{
    InLinePrediction = [ConsoleColor]::DarkGray
    ListPrediction   = [ConsoleColor]::Cyan
}

#region conda initialize
#!! Contents within this block are managed by 'conda init' !!
If (Test-Path "C:\Users\yutay\miniconda3\Scripts\conda.exe") {
    (& "C:\Users\yutay\miniconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ? { $_ } | Invoke-Expression
}
#$conda_hook = & "C:\Users\yutay\miniconda3\Scripts\conda.exe" "shell.powershell" "hook"
#if ($conda_hook -ne "") {
#    $conda_hook | Out-String | Invoke-Expression
#} else {
#    Write-Host "Warning: Conda hook is empty. Run 'conda init powershell'."
#}
#endregion



##f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
#Import-Module -Name Microsoft.WinGet.CommandNotFound
##f45873b3-b655-43a6-b217-97c00aa0db58
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Invoke-Expression -Command $(gh completion -s powershell &#124; Out-String)
Invoke-Expression -Command (gh completion -s powershell | Out-String)

function ghcs {
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [Parameter()]
        [string]$Hostname,

        [ValidateSet('gh', 'git', 'shell')]
        [Alias('t')]
        [String]$Target = 'shell',

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string]$Prompt
    )
    begin {
        # Create temporary file to store potential command user wants to execute when exiting
        $executeCommandFile = New-TemporaryFile

        # Store original value of GH_* environment variable
        $envGhDebug = $Env:GH_DEBUG
        $envGhHost = $Env:GH_HOST
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        $Env:GH_HOST = $Hostname

        gh copilot suggest -t $Target -s "$executeCommandFile" $Prompt
    }
    end {
        # Execute command contained within temporary file if it is not empty
        if ($executeCommandFile.Length -gt 0) {
            # Extract command to execute from temporary file
            $executeCommand = (Get-Content -Path $executeCommandFile -Raw).Trim()

            # Insert command into PowerShell up/down arrow key history
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($executeCommand)

            # Insert command into PowerShell history
            $now = Get-Date
            $executeCommandHistoryItem = [PSCustomObject]@{
                CommandLine        = $executeCommand
                ExecutionStatus    = [Management.Automation.Runspaces.PipelineState]::NotStarted
                StartExecutionTime = $now
                EndExecutionTime   = $now.AddSeconds(1)
            }
            Add-History -InputObject $executeCommandHistoryItem

            # Execute command
            Write-Host "`n"
            Invoke-Expression $executeCommand
        }
    }
    clean {
        # Clean up temporary file used to store potential command user wants to execute when exiting
        Remove-Item -Path $executeCommandFile

        # Restore GH_* environment variables to their original value
        $Env:GH_DEBUG = $envGhDebug
    }
}

function ghce {
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [Parameter()]
        [string]$Hostname,

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Prompt
    )
    begin {
        # Store original value of GH_* environment variables
        $envGhDebug = $Env:GH_DEBUG
        $envGhHost = $Env:GH_HOST
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        $Env:GH_HOST = $Hostname

        gh copilot explain $Prompt
    }
    clean {
        # Restore GH_* environment variables to their original value
        $Env:GH_DEBUG = $envGhDebug
        $Env:GH_HOST = $envGhHost
    }
}

function Log-Info { Write-Host "[INFO ] $args" -ForegroundColor Cyan }
function Log-Warn { Write-Host "[WARN ] $args" -ForegroundColor Yellow }
function Log-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Log-Success { Write-Host "[ OK  ] $args" -ForegroundColor Green }

Register-ArgumentCompleter -CommandName MyCommand -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParams)
    "foo", "bar", "baz" | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
