## 未インストールのプログラム・モジュールを自動インストールする処理をまとめるファイル
## 実行のたびに時間がかかる/EULA同意を伴うため、profile読み込み時には自動実行しない。
## 新しい環境をセットアップする際に手動で ". .\powershell_auto_install.ps1" するか、
## init_powershell_config.ps1 などのセットアップ手順から呼び出す想定。

## Winget経由でコマンドが無ければインストールする
function Install-CommandIfMissing {
    param(
        [Parameter(Mandatory)][string]$CommandName,
        [Parameter(Mandatory)][string]$WingetId
    )

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "[SKIP] $CommandName は既にインストール済みです" -ForegroundColor DarkGray
        return
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget が見つからないため $CommandName をインストールできません"
        return
    }

    Write-Host "[INSTALL] $CommandName ($WingetId) をインストールします" -ForegroundColor Cyan
    winget install --id $WingetId -e --source winget --accept-package-agreements --accept-source-agreements

    # 直前のwinget installでPATHが更新されている場合があるため、現在のセッションに反映する
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

Install-CommandIfMissing -CommandName git -WingetId "Git.Git"
Install-CommandIfMissing -CommandName uv -WingetId "astral-sh.uv"
Install-CommandIfMissing -CommandName nvm -WingetId "CoreyButler.NVMforWindows"

## Node.js本体はnvmで管理する(winget等での直接インストールは行わない)
if ((Get-Command nvm -ErrorAction SilentlyContinue) -and -not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[INSTALL] nvmでNode.js(LTS)をインストールします" -ForegroundColor Cyan
    nvm install lts
    nvm use lts
}

## npm自体を最新化してから、この環境で使っているグローバルパッケージを揃える
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "[UPDATE] npmを最新版に更新します" -ForegroundColor Cyan
    npm install -g npm@latest

    # 2026-07時点で AppData\Roaming\npm\node_modules に入っていたグローバルパッケージ一覧
    $npmGlobalPackages = @(
        "@anthropic-ai/claude-code",
        "@google/clasp",
        "@google/gemini-cli",
        "@notionhq/notion-mcp-server",
        "deno",
        "mcp-markdownify-server",
        "nb.sh",
        "neovim",
        "openclaw",
        "pnpm",
        "shx",
        "textlint",
        "textlint-filter-rule-comments",
        "textlint-filter-rule-whitelist",
        "textlint-rule-preset-icsmedia",
        "textlint-rule-preset-ja-technical-writing",
        "textlint-rule-prh",
        "textlint-rule-spellcheck-tech-word",
        "tree-sitter-cli",
        "uv",
        "yarn"
    )

    Write-Host "[INSTALL] npmグローバルパッケージをインストールします" -ForegroundColor Cyan
    npm install -g $npmGlobalPackages
} else {
    Write-Warning "npm が見つからないため、グローバルパッケージのインストールをスキップしました"
}
