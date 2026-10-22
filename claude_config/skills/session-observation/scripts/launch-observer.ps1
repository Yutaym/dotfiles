# session-observation の監視画面を開く (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-observer.ps1 [-Interval 秒] [-RemoteInterval 秒] [-NoRemote] [-Vertical] [-Here]
#   pwsh -NoProfile -File launch-observer.ps1 -Stop
#   -Vertical: tmux の中で、上下に分割する (既定は左右。2026/10/22 にユーザーが決めた)
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
    [double]$Interval = 10,
    [double]$RemoteInterval = 60,
    [switch]$NoRemote,
    [switch]$Vertical,
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
    # 場所は「セッション名:ウィンドウ番号」で指定する。
    # 呼び出し元のウィンドウは、このスクリプトの親プロセスをたどって、ペインの最初のプロセス (pane_pid) に
    # 当たるものから探す。display-message -p は、呼び出し元ではなくユーザーが今見ているウィンドウを返すため
    # (2026/10/22 に、見ていた別のウィンドウを分割してしまった)
    $panes = @{}
    foreach ($line in (& tmux list-panes -a -F "#{pane_pid}`t#{session_name}:#{window_index}")) {
        $panePid, $where = $line -split "`t", 2
        if ($panePid -match '^\d+$') { $panes[[int]$panePid] = $where }
    }
    $parents = @{}
    Get-CimInstance Win32_Process | ForEach-Object { $parents[[int]$_.ProcessId] = [int]$_.ParentProcessId }
    $target = $null
    $cur = $PID
    for ($i = 0; $i -lt 20 -and $cur -and -not $target; $i++) {
        $target = $panes[$cur]
        $cur = $parents[$cur]
    }
    if (-not $target) { $target = & tmux display-message -p '#{session_name}:#{window_index}' }
    $dir = if ($Vertical) { '-v' } else { '-h' }
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
