
## vi は Vim、vim は Neovim を起動する
## インストール先のパスやバージョン (vim90 など) に依存しないよう、PATH → 既定のインストール先の順に探す
## Vim の公式インストーラーは PATH に追加しないため、Program Files\Vim\vim*\vim.exe からバージョンが最も新しいものを使う
$vimExe = Get-Command vim.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $vimExe) {
    $vimExe = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ } |
        ForEach-Object { Get-ChildItem -Path (Join-Path $_ 'Vim\vim*\vim.exe') -ErrorAction SilentlyContinue } |
        Sort-Object { [int]($_.Directory.Name -replace '\D', '') } -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}
if ($vimExe) {
    Set-Alias -Name vi -Value $vimExe
}

$nvimExe = Get-Command nvim.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $nvimExe) {
    $nvimExe = Join-Path $env:ProgramFiles 'Neovim\bin\nvim.exe'
    if (-not (Test-Path $nvimExe)) { $nvimExe = $null }
}
if ($nvimExe) {
    Set-Alias -Name vim -Value $nvimExe
}
Remove-Variable vimExe, nvimExe
function ghcs {
    [CmdletBinding()]
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
    # Create temporary file to store potential command user wants to execute when exiting
    $executeCommandFile = New-TemporaryFile

    # Store original value of GH_* environment variables
    $envGhDebug = $Env:GH_DEBUG
    $envGhHost = $Env:GH_HOST

    try {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        $Env:GH_HOST = $Hostname

        gh copilot suggest -t $Target -s "$executeCommandFile" $Prompt

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
    finally {
        # Clean up temporary file used to store potential command user wants to execute when exiting
        Remove-Item -Path $executeCommandFile

        # Restore GH_* environment variables to their original value
        $Env:GH_DEBUG = $envGhDebug
        $Env:GH_HOST = $envGhHost
    }
}

function ghce {
    [CmdletBinding()]
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [Parameter()]
        [string]$Hostname,

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Prompt
    )
    # Store original value of GH_* environment variables
    $envGhDebug = $Env:GH_DEBUG
    $envGhHost = $Env:GH_HOST

    try {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        $Env:GH_HOST = $Hostname

        gh copilot explain $Prompt
    }
    finally {
        # Restore GH_* environment variables to their original value
        $Env:GH_DEBUG = $envGhDebug
        $Env:GH_HOST = $envGhHost
    }
}
