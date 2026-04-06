# ================================================================
# PowerShell Prompt  (Microsoft.PowerShell_profile.ps1)
# ================================================================

if ($PSVersionTable.PSVersion.Major -ge 6) {
    $ESC = "`e"
} else {
    $ESC = [char]27
}

$RESET = "${ESC}[0m"
$BOLD  = "${ESC}[1m"
$F1    = "${ESC}[31m"
$F2    = "${ESC}[32m"
$F3    = "${ESC}[33m"
$F4    = "${ESC}[34m"
$F6    = "${ESC}[36m"
$F7    = "${ESC}[37m"

function Get-GitInfo {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) { return "" }

        $status   = git status --porcelain 2>$null
        $staged   = ($status | Where-Object { $_ -match "^[MADRC]" })
        $unstaged = ($status | Where-Object { $_ -match "^.[MADRC?]" })

        $indicator = ""
        if ($staged)   { $indicator += "${F3}!" }
        if ($unstaged) { $indicator += "${F1}+" }

        if ($branch -eq "HEAD") {
            $branch = git rev-parse --short HEAD 2>$null
            return "[${F1}detached:${branch}${indicator}${F2}]${RESET}"
        }
        return "[${F2}${branch}${indicator}${F2}]${RESET}"
    } catch {
        return ""
    }
}

function Get-PythonEnvInfo {
    if ($env:VIRTUAL_ENV) {
        $name = Split-Path $env:VIRTUAL_ENV -Leaf
        return "(${F2}venv:${name}${RESET})"
    } elseif ($env:CONDA_DEFAULT_ENV) {
        return "(${F2}conda:$($env:CONDA_DEFAULT_ENV)${RESET})"
    }
    return ""
}

$script:_cmdStartTime = $null

if (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$command)
        $script:_cmdStartTime = [System.Diagnostics.Stopwatch]::StartNew()
        return $true
    }
}

function prompt {
    # ★ 絶対最初：$? と $LASTEXITCODE を退避
    $lastSuccess = $?
    $lastCode    = $LASTEXITCODE

    # 実行時間
    $elapsed = 0
    if ($script:_cmdStartTime -ne $null -and $script:_cmdStartTime.IsRunning) {
        $script:_cmdStartTime.Stop()
        $elapsed = [int]$script:_cmdStartTime.Elapsed.TotalSeconds
        $script:_cmdStartTime = $null
    }

    # ── ステータス判定 ─────────────────────────────────────────
    # $? を主軸にして判定
    # ┌─────────────────────┬──────────────────────────────────────┐
    # │ 成功                 │ $? = true  かつ $LASTEXITCODE = 0   │
    # │ 外部コマンド失敗     │ $? = false かつ $LASTEXITCODE != 0  │
    # │ 内部/NotFound失敗   │ $? = false かつ $LASTEXITCODE = 0   │
    # └─────────────────────┴──────────────────────────────────────┘
    if ($lastSuccess) {
        # 成功
        $isSuccess   = $true
        $displayCode = ""
    } elseif ($lastCode -ne 0) {
        # 外部コマンド失敗：具体的なコードを表示
        $isSuccess   = $false
        $displayCode = "$lastCode"
    } else {
        # コマンドが見つからない / PowerShell内部エラー：コード不明
        $isSuccess   = $false
        $displayCode = "!"
    }

    # ステータス文字列（zsh と同じロジック）
    if ($isSuccess) {
        if ($elapsed -ge 3) {
            $statusStr = "${F2}${elapsed}s${RESET} "
        } else {
            $statusStr = "${F2}${RESET}"
        }
    } else {
        $statusStr = "${F1}E${displayCode}|${elapsed}s${RESET} "
    }

    # 右端に日時
    $datetime    = "[$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')]"
    $windowWidth = $Host.UI.RawUI.WindowSize.Width
    $rightCol    = $windowWidth - $datetime.Length + 1
    Write-Host "${ESC}[s${ESC}[${rightCol}G${F2}${datetime}${RESET}${ESC}[u" -NoNewline

    # 1行目
    Write-Host "${F4}PS:${RESET}" -NoNewline

    $pyEnv = Get-PythonEnvInfo
    if ($pyEnv) {
        Write-Host " ${pyEnv}" -NoNewline
    }

    Write-Host " ${BOLD}${F3}$env:USERNAME@$env:COMPUTERNAME${RESET}" -NoNewline

    $git = Get-GitInfo   # ← ここで $LASTEXITCODE が汚染されるが退避済みなので問題なし
    if ($git) {
        Write-Host " ${git}" -NoNewline
    }

    $path = (Get-Location).Path.Replace($env:USERPROFILE, "~")
    Write-Host " ${BOLD}${F6}${path}${RESET}" -NoNewline

    Write-Host " ${statusStr}"

    # 2行目
    Write-Host "${F7}->${RESET}" -NoNewline

    # ★ 絶対最後：次回のために $LASTEXITCODE をリセット
    $global:LASTEXITCODE = 0

    return " "
}

$global:LASTEXITCODE = 0
