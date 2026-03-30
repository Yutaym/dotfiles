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
    # $env:VIRTUAL_ENV_PROMPT
    $env:VIRTUAL_ENV_PROMPT_NAME = ""
    if ($env:VIRTUAL_ENV) {
        # $env:VIRTUAL_ENV = Split-Path -Path $env:VIRTUAL_ENV -Leaf
        # $env:VIRTUAL_ENV = Split-Path -Path $env:VIRTUAL_ENV -Leaf
        $promptenv = Split-Path -Path $env:VIRTUAL_ENV -Leaf
        $env:VIRTUAL_ENV_PROMPT_NAME = "venv:$env:VIRTUAL_ENV_PROMPT"
    }
    elseif ($env:CONDA_DEFAULT_ENV) {
        $env:VIRTUAL_ENV = $env:CONDA_DEFAULT_ENV
        $env:VIRTUAL_ENV_PROMPT_NAME = "conda:$env:CONDA_DEFAULT_ENV"
    }
    else {
        $env:VIRTUAL_ENV = ""
    }
    $env:VIRTUAL_ENV_DISABLE_PROMPT = $true


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
    #$env:VIRTUAL_ENV_PROMPT
    if ($env:VIRTUAL_ENV_PROMPT_NAME) {
        Write-Host -NoNewline "(" -ForegroundColor $colorArrow
        Write-Host -NoNewline "$env:VIRTUAL_ENV_PROMPT_NAME" -ForegroundColor $colorEnv
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
