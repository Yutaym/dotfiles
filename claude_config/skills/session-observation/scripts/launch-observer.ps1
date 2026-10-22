# session-observation の監視画面を開く (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-observer.ps1 [-Interval 秒] [-RemoteInterval 秒] [-NoRemote] [-Horizontal] [-Here]
#   pwsh -NoProfile -File launch-observer.ps1 -Stop
#   -Horizontal: tmux の中で、左右に分割する (既定は上下。表の幅を広く取るため)
#   -Here: 新しいペインやタブを開かず、このターミナルでそのまま実行する
#   -Stop: 動いている監視を止める (ほかのセッションからも使える)
#
# 開き方:
#   1. tmux (psmux など) の中 ($env:TMUX がある) → 呼び出し元のウィンドウを tmux split-window -d で分割
#   2. Windows Terminal がある                    → wt -w 0 new-tab
#   3. どちらもない                                → pwsh / powershell の新しいウィンドウ
#
# 監視は同時に 1 つだけ動く。すでに動いていれば、新しく開いたほうに置き換わり、古いほうは閉じる (observe.py が判断する)。

param(
    [double]$Interval = 3,
    [double]$RemoteInterval = 60,
    [switch]$NoRemote,
    [switch]$Horizontal,
    [switch]$Here,
    [switch]$Stop
)

$ErrorActionPreference = 'Stop'

if ($Stop) {
    & uv run --no-project python (Join-Path $PSScriptRoot 'observe.py') --stop
    exit $LASTEXITCODE
}

$Runner = Join-Path $PSScriptRoot 'run-observer.ps1'
$Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$RunArgs = @('-NoProfile', '-File', $Runner, '-Interval', $Interval, '-RemoteInterval', $RemoteInterval)
if ($NoRemote) { $RunArgs += '-NoRemote' }

if ($Here) {
    & $Shell @RunArgs
    exit $LASTEXITCODE
}

if ($env:TMUX -and (Get-Command tmux -ErrorAction SilentlyContinue)) {
    # psmux は -t の @ID / %ID を別のセッションのものとして解決することがあるので、
    # 場所は「セッション名:ウィンドウ番号」で指定する
    $target = & tmux display-message -p '#{session_name}:#{window_index}'
    $dir = if ($Horizontal) { '-h' } else { '-v' }
    & tmux split-window -d $dir -t $target -c $HOME $Shell @RunArgs
    $how = "tmux split-window $dir ($target)"
}
elseif (Get-Command wt -ErrorAction SilentlyContinue) {
    & wt -w 0 new-tab --title session-observation -d $HOME $Shell @RunArgs
    $how = 'Windows Terminal (wt new-tab)'
}
else {
    Start-Process -FilePath $Shell -ArgumentList $RunArgs -WorkingDirectory $HOME
    $how = "$Shell の新しいウィンドウ"
}

Write-Output "launched: $how"
