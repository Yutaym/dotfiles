# すべての環境で必須のアプリ (nvm-windows と Node.js の LTS、uv) をインストールする (Windows 向け)
# 入っているものはスキップするので、何度実行してもよい
# nvm use は C:\nvm4w\nodejs にシンボリックリンクを作るため、「開発者モード」の有効化、または管理者権限での実行が必要
$ErrorActionPreference = 'Stop'

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

# nvm-windows
if (Get-Command nvm -ErrorAction SilentlyContinue) {
    Write-Host "[skip] nvm $(nvm version)"
} else {
    winget install --id CoreyButler.NVMforWindows -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget install CoreyButler.NVMforWindows failed ($LASTEXITCODE)" }
    Update-EnvFromRegistry
    Write-Host "[install] nvm $(nvm version)"
}

# Node.js (nvm で使っている node が無ければ LTS を入れて切り替える)
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "[skip] node $(node -v)"
} else {
    nvm install lts
    nvm use lts
    Update-EnvFromRegistry
    Write-Host "[install] node $(node -v)"
}

# uv (公式のインストーラー。~/.local/bin に入れ、ユーザーの PATH に追加する)
if ((Get-Command uv -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.local\bin\uv.exe'))) {
    Write-Host "[skip] uv"
} else {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    if ($LASTEXITCODE -ne 0) { throw "uv install failed ($LASTEXITCODE)" }
    Write-Host "[install] uv"
}

Write-Host "[done] 新しいターミナルを開くと nvm / node / uv が使えます"
