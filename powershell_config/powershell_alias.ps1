
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

## GitHub Copilot CLI (copilot コマンド) でコマンドの提案 (ghcs)・説明 (ghce) を行う
## 旧 gh copilot 拡張 (gh copilot suggest / explain) は 2025-10 に提供が終わったため、後継の Copilot CLI の非対話モード (-p) を使う
## インストール: winget install GitHub.Copilot (初回は copilot を起動して /login でログインする)
## --allow-tool を付けないので、Copilot にファイルの編集やコマンドの実行はさせない (提案されたコマンドを実行するかは ghcs で確認する)
## https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically
function Invoke-CopilotPrompt {
    param(
        [Parameter(Mandatory)][string]$Prompt
    )
    $copilotCmd = Get-Command copilot -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $copilotCmd) {
        Write-Warning 'copilot (GitHub Copilot CLI) が見つかりません。winget install GitHub.Copilot でインストールしてください'
        return
    }
    # npm で入れた copilot.cmd には、引数の中の " がエスケープされずに渡り、引数が途中で切れるため ' に置き換える
    if ($copilotCmd.Extension -in @('.cmd', '.bat')) {
        $Prompt = $Prompt.Replace('"', "'")
    }
    # -s: セッションの情報を出さず回答だけを出力する、--no-ask-user: 聞き返さずに回答させる
    $output = & $copilotCmd.Source -p $Prompt -s --no-ask-user
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "copilot が失敗しました (終了コード $LASTEXITCODE)。未ログインなら copilot を起動して /login を実行してください"
        return
    }
    $output
}

## 自然文からコマンドを 1 つ提案させ、コマンドの文字列だけを返す (ghcs と Ctrl+G で使う)
function Get-CopilotCommandSuggestion {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [ValidateSet('gh', 'git', 'shell')][string]$Target = 'shell'
    )
    $kind = switch ($Target) {
        'gh' { 'a GitHub CLI (gh) command' }
        'git' { 'a git command' }
        default { 'a PowerShell 7 command line on Windows' }
    }
    # copilot が .cmd の場合に引数が崩れないよう、プロンプトは 1 行にする
    $instruction = "Suggest $kind for the following task. Reply with only the command itself, with no explanation, no Markdown and no code fences. If several commands are needed, join them into one line. Task: $Prompt"
    $output = Invoke-CopilotPrompt -Prompt $instruction
    if (-not $output) {
        return
    }
    # 指示に反してコードブロックで返ってきた場合に備えて、``` の行と空行を除く
    $lines = @($output | Where-Object { $_ -notmatch '^\s*```' -and $_.Trim() })
    ($lines -join "`n").Trim()
}

## 使い方: ghcs [-t shell|gh|git] <やりたいこと>
## 提案されたコマンドを表示し、y で実行する。実行しなくても履歴に追加するので、↑ で呼び出して編集できる
function ghcs {
    param(
        [ValidateSet('gh', 'git', 'shell')]
        [Alias('t')]
        [string]$Target = 'shell',

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Prompt
    )
    $text = "$Prompt".Trim()
    if (-not $text) {
        $text = (Read-Host 'やりたいことを入力してください').Trim()
        if (-not $text) {
            return
        }
    }

    $command = Get-CopilotCommandSuggestion -Prompt $text -Target $Target
    if (-not $command) {
        return
    }
    Write-Host "`n    $command`n" -ForegroundColor Cyan

    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($command)
    $answer = Read-Host '実行しますか? [y/N] (実行しない場合も ↑ で呼び出せます)'
    if ($answer -match '^[yY]') {
        Invoke-Expression $command
    }
}

## 使い方: ghce <コマンド>
## コマンドの意味を日本語で説明させる
function ghce {
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Command
    )
    $text = "$Command".Trim()
    if (-not $text) {
        Write-Warning '使い方: ghce <説明してほしいコマンド>'
        return
    }
    Invoke-CopilotPrompt -Prompt "Explain in Japanese what the following command does, briefly, part by part. Do not run it. Command: $text"
}
