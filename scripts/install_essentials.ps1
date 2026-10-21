# すべての環境で必須のアプリ (git、nvm-windows と Node.js の LTS、npm のグローバルパッケージ、uv、GitHub Copilot CLI) をインストールする (Windows 向け)
# 入っているものはスキップするので、何度実行してもよい
# nvm use は NVM_SYMLINK (C:\nvm4w\nodejs など) にシンボリックリンクを作るため、「開発者モード」の有効化、または管理者権限での実行が必要
$ErrorActionPreference = 'Stop'

# Copilot CLI を npm で入れるときの要件に合わせて、これより古い node は LTS に入れ替える
$MinNodeMajor = 22
$NpmPackagesFile = Join-Path $PSScriptRoot 'npm_global_packages.txt'

# インストーラーがレジストリに書いた環境変数を、このプロセスに読み込み直す
function Update-EnvFromRegistry {
    foreach ($name in @('NVM_HOME', 'NVM_SYMLINK')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if (-not $value) { $value = [Environment]::GetEnvironmentVariable($name, 'Machine') }
        if ($value) { Set-Item -Path "Env:$name" -Value $value }
    }
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = [Environment]::ExpandEnvironmentVariables("$machine;$user")
}

# コマンドが無ければ winget で入れる
function Install-WingetIfMissing {
    param(
        [Parameter(Mandatory)][string]$CommandName,
        [Parameter(Mandatory)][string]$WingetId
    )
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "[skip] $CommandName"
        return
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget が見つからないため $CommandName ($WingetId) をインストールできません"
    }
    winget install --id $WingetId -e --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget install $WingetId failed ($LASTEXITCODE)" }
    Update-EnvFromRegistry
    Write-Host "[install] $CommandName ($WingetId)"
}

# 今使っている node のメジャーバージョン (無ければ 0)
function Get-NodeMajor {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { return 0 }
    return [int]((node -v).TrimStart('v').Split('.')[0])
}

# git
Install-WingetIfMissing -CommandName git -WingetId 'Git.Git'

# nvm-windows
Install-WingetIfMissing -CommandName nvm -WingetId 'CoreyButler.NVMforWindows'

# Node.js (node が無いか古ければ、nvm で LTS を入れて切り替える)
$nodeMajor = Get-NodeMajor
if ($nodeMajor -ge $MinNodeMajor) {
    Write-Host "[skip] node $(node -v)"
} else {
    if ($nodeMajor -gt 0) { Write-Host "[info] node $(node -v) は $MinNodeMajor より古いため、LTS に切り替えます" }
    nvm install lts
    nvm use lts
    Update-EnvFromRegistry
    if ((Get-NodeMajor) -lt $MinNodeMajor) {
        throw "nvm use lts で node を切り替えられませんでした。開発者モードを有効にするか、管理者権限で再実行してください"
    }
    Write-Host "[install] node $(node -v)"
}

# npm のグローバルパッケージ (nvm の node に、入っていないものだけを入れる)
$nodeSource = (Get-Command node).Source
if (-not $env:NVM_SYMLINK -or -not $nodeSource.StartsWith($env:NVM_SYMLINK, [StringComparison]::OrdinalIgnoreCase)) {
    Write-Warning "node ($nodeSource) が nvm ($env:NVM_SYMLINK) のものではないため、npm のグローバルパッケージのインストールをスキップしました"
} else {
    $specs = Get-Content -Path $NpmPackagesFile -Encoding UTF8 |
        ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
        Where-Object { $_ }
    $installed = @((npm ls -g --depth=0 --json | ConvertFrom-Json).dependencies.PSObject.Properties.Name)
    $missing = @($specs | Where-Object {
        $name = if ($_ -like 'github:*') { ($_ -split '/')[-1] } else { $_ }
        $installed -notcontains $name
    })
    if ($missing.Count -eq 0) {
        Write-Host "[skip] npm global packages ($($specs.Count))"
    } else {
        npm install -g @missing
        if ($LASTEXITCODE -ne 0) { throw "npm install -g failed ($LASTEXITCODE)" }
        Write-Host "[install] npm global packages: $($missing -join ', ')"
    }
}

# uv (公式のインストーラー。~/.local/bin に入れ、ユーザーの PATH に追加する)
if ((Get-Command uv -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.local\bin\uv.exe'))) {
    Write-Host "[skip] uv"
} else {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    if ($LASTEXITCODE -ne 0) { throw "uv install failed ($LASTEXITCODE)" }
    Write-Host "[install] uv"
}

# GitHub Copilot CLI (ghcs / ghce / Ctrl+G で使う。初回は copilot を起動して /login でログインする)
Install-WingetIfMissing -CommandName copilot -WingetId 'GitHub.Copilot'

Write-Host "[done] 新しいターミナルを開くと git / nvm / node / uv / copilot が使えます"
