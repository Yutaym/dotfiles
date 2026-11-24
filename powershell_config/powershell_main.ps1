# PWSH_SKIP_PROFILE があるときはプロファイルを読まない（Claude Code の Ctrl+G のラッパー claude-editor.ps1 が、
# psmux の new-window で開く pwsh を速くするために付ける。psmux は -NoProfile を付けられないため）。
if ($env:PWSH_SKIP_PROFILE) { return }

if (-not $env:path.Split(';').Contains('.')) {
    $env:path += ";."
}

# Use-ClaudeOllama の接続先 (自宅 PC の Ollama)。ユーザー環境変数などで設定済みならそちらを優先する
if (-not $env:CLAUDE_OLLAMA_URL) {
    $env:CLAUDE_OLLAMA_URL = "http://yutapc:11434"
}

# Claude Code の Ctrl+G（外部エディタ）用。Claude が起動した nvim にキーが届かない不具合
# （psmux の中。anthropics/claude-code #92757）を避けるため、nvim を別ウィンドウで開くラッパーを使う。
# Mac と共通の settings.json では EDITOR を指定しない（Mac は zshrc の EDITOR を使う）。
$env:EDITOR = 'pwsh -NoProfile -File "' + (Join-Path $env:USERPROFILE 'dotfiles\claude_config\scripts\claude-editor.ps1') + '"'

## 補完/フック系スクリプトのキャッシュ機構
## 外部コマンドの起動はWindowsではプロセス生成コストが大きく、profile読み込みのたびに
## gh/docker/kubectl/pnpm/uv/condaのフックを都度実行すると起動が数秒単位で遅くなる。
## そのため生成結果をファイルにキャッシュし、起動時はファイルを読み込むだけにする。
## ツールを更新した場合などキャッシュを破棄したい場合は Update-CompletionCache を実行する。
$script:CompletionCacheDir = Join-Path $env:LOCALAPPDATA "dotfiles-pwsh-cache"
$script:CompletionCacheMaxAgeDays = 7

function Import-CachedCompletion {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Generator
    )

    if (-not (Test-Path $script:CompletionCacheDir)) {
        New-Item -ItemType Directory -Path $script:CompletionCacheDir -Force | Out-Null
    }
    $cacheFile = Join-Path $script:CompletionCacheDir "$Name.ps1"

    $needsRefresh = $true
    if (Test-Path $cacheFile) {
        $item = Get-Item $cacheFile
        $age = (Get-Date) - $item.LastWriteTime
        ## 生成に失敗して空のキャッシュが残っていたら作り直す
        $needsRefresh = $item.Length -eq 0 -or $age.TotalDays -gt $script:CompletionCacheMaxAgeDays
    }

    if ($needsRefresh) {
        try {
            $output = & $Generator | Out-String
            ## 出力が空のときは書き込まない (空のキャッシュを Invoke-Expression に渡すとエラーになる)
            if ([string]::IsNullOrWhiteSpace($output)) {
                Write-Warning "補完キャッシュの生成結果が空でした: $Name"
            } else {
                $output | Out-File -FilePath $cacheFile -Encoding utf8
            }
        } catch {
            Write-Warning "補完キャッシュの生成に失敗しました: $Name"
        }
    }

    if (Test-Path $cacheFile) {
        $content = Get-Content $cacheFile -Raw
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            Invoke-Expression -Command $content
        }
    }
}

function Update-CompletionCache {
    if (Test-Path $script:CompletionCacheDir) {
        Remove-Item -Path $script:CompletionCacheDir -Recurse -Force
    }
    Write-Host "補完キャッシュを削除しました。次回のシェル起動時に再生成されます。" -ForegroundColor Green
}

$condaPath = Join-Path $env:USERPROFILE "miniconda3\Scripts\conda.exe"
#!! Contents within this block are managed by 'conda init' !!
If (Test-Path $condaPath) {
    ## hook の出力の `conda activate 'base'` は conda.exe を起動して約 1.6 秒かかるため除く（base は自動では有効にしない。
    ## 使うときは `conda activate base` を手で打つ）。2026-11-24 にユーザーが選んだ。
    Import-CachedCompletion -Name "conda-hook" -Generator { & (Join-Path $env:USERPROFILE "miniconda3\Scripts\conda.exe") "shell.powershell" "hook" | Where-Object { $_ -notmatch "^\s*conda activate 'base'\s*$" } }
}

# Remove-Item Env:ANTHROPIC_AUTH_TOKEN  -ErrorAction SilentlyContinue
# Remove-Item Env:ANTHROPIC_BASE_URL    -ErrorAction SilentlyContinue
# Write-Host "[Claude] Backend: Anthropic API (default)" -ForegroundColor Cyan

$powershellProfile = Join-Path $PSScriptRoot "powershell_profile.ps1"
$powershellAlias = Join-Path $PSScriptRoot "powershell_alias.ps1"
$powershellComplete = Join-Path $PSScriptRoot "powershell_complete.ps1"
$powershellFunction = Join-Path $PSScriptRoot "powershell_function.ps1"
# $powershellProfile = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_profile.ps1"
# $powershellAlias = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_alias.ps1"
# $powershellComplete = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_complete.ps1"
# $powershellFunction = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_function.ps1"
if (Test-Path $powershellProfile) {
    . $powershellProfile
}
if (Test-Path $powershellAlias) {
    . $powershellAlias
}
if (Test-Path $powershellComplete) {
    . $powershellComplete
}
if (Test-Path $powershellFunction) {
    . $powershellFunction
}

# $powershellProfile = Join-Path $env:USERPROFILE "dotfiles\powershell\powershell_main.ps1"
# if (Test-Path $powershellMain) {
#     . $powershellMain
# }
