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
