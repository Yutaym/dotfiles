if (-not $env:path.Split(';').Contains('.')) {
    $env:path += ";."
}

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
        $age = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        $needsRefresh = $age.TotalDays -gt $script:CompletionCacheMaxAgeDays
    }

    if ($needsRefresh) {
        try {
            & $Generator | Out-File -FilePath $cacheFile -Encoding utf8
        } catch {
            Write-Warning "補完キャッシュの生成に失敗しました: $Name"
        }
    }

    if (Test-Path $cacheFile) {
        Invoke-Expression -Command (Get-Content $cacheFile -Raw)
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
    Import-CachedCompletion -Name "conda-hook" -Generator { & (Join-Path $env:USERPROFILE "miniconda3\Scripts\conda.exe") "shell.powershell" "hook" }
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
