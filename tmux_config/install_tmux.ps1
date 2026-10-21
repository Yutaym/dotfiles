# tmux (psmux) の設定ファイルのリンクを行う (Windows 向け)
# シンボリックリンク作成には管理者権限での実行が必要 (開発者モードで一般ユーザーが作ったリンクは、Windows のバージョンによっては「信頼されていないマウントポイント」として読めない)
# psmux は ~/.psmux.conf → ~/.psmuxrc → ~/.tmux.conf → ~/.config/psmux/psmux.conf の順に探し、最初に見つけたものだけを読む
# プラグインは ppm で管理する (ppm だけをここで入れ、プラグイン本体は psmux の中で Prefix + I で入れる)
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot

# ---------------------------------------------------------------
# 1. psmux の確認 (自動インストールはしない)
# ---------------------------------------------------------------
$psmuxCmd = Get-Command psmux -ErrorAction SilentlyContinue
if ($psmuxCmd) {
    Write-Host "[ok] psmux is installed: $($psmuxCmd.Source)"
} else {
    Write-Warning 'psmux is not installed. 以下のコマンドでインストールしてから再実行してください'
    Write-Host '    winget install --id marlocarlo.psmux -e'
}

# ---------------------------------------------------------------
# 2. 設定ファイルのシンボリックリンク作成
# ---------------------------------------------------------------
$src = Join-Path $ScriptDir '.tmux.conf'
$dst = Join-Path $HOME '.psmux.conf'
# Test-Path はリンク切れのシンボリックリンクを検出できないため Get-Item で確認する
$item = Get-Item -Path $dst -Force -ErrorAction SilentlyContinue
if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
    Write-Host "[skip] $dst -> $src"
} elseif ($item) {
    Write-Warning "$dst already exists. skipped."
} else {
    New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null
    Write-Host "[link] $dst -> $src"
}

# ---------------------------------------------------------------
# 3. ppm (psmux plugin manager) の確認 (なければ psmux-plugins から取り出して置く)
# ---------------------------------------------------------------
$PpmDir = Join-Path $HOME '.psmux\plugins\ppm'
if (Test-Path (Join-Path $PpmDir 'ppm.ps1')) {
    Write-Host "[skip] ppm already exists: $PpmDir"
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "psmux-plugins-$([guid]::NewGuid().ToString('N'))"
    try {
        git clone --depth 1 -q https://github.com/psmux/psmux-plugins.git $tmp
        New-Item -ItemType Directory -Force -Path (Split-Path $PpmDir) | Out-Null
        Copy-Item -Path (Join-Path $tmp 'ppm') -Destination $PpmDir -Recurse
        Write-Host "[install] ppm -> $PpmDir"
        Write-Host '[info] psmux を起動して Prefix (Ctrl-q) + I でプラグインをインストールしてください'
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
} else {
    Write-Warning 'git is not installed. ppm のインストールをスキップしました'
}

if ($psmuxCmd) {
    Write-Host "[done] psmux version: $(psmux -V)"
} else {
    Write-Host '[done]'
}
