# 新しいターミナルのタブで、ssh で接続した状態を作る (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-ssh.ps1 [-NewWindow] [-Split] [-Background] <接続先> [<接続先> ...]
#   接続先は ~/.ssh/config の Host の別名 (または user@host)。複数書くと、1 つずつ別のタブで開く。
#   tmux の中では、開いたウィンドウ (複数なら最後のもの) に画面を切り替える。-Background を付けると呼び出し元のまま。
#
# 起動先の選び方 (spawn-session の launch-session.ps1 と同じ):
#   1. tmux (psmux など) の中 ($env:TMUX がある) → tmux new-window (-Split のときは専用ウィンドウを分割)
#   2. Windows Terminal がある                    → wt -w 0 new-tab
#   3. どちらもない                                → pwsh / powershell の新しいウィンドウ
#
# どの起動先でも start-ssh.ps1 が ssh を実行する。ssh が失敗したときは、タブを閉じずにエラーを残す。

param(
    [switch]$NewWindow,
    # tmux の中で、専用ウィンドウをペイン分割して並べる (tmux 以外では無視する)
    [switch]$Split,
    # tmux の中で、開いたウィンドウに画面を切り替えない (tmux 以外では無視する)
    [switch]$Background,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Targets
)

$ErrorActionPreference = 'Stop'

# 接続先はコマンドラインにそのまま渡すので、ホスト名に使う文字だけにする
# (wt は ; を区切り記号として扱うので、引数に ; を含めない意味もある)
foreach ($t in $Targets) {
    if ($t -notmatch '^[A-Za-z0-9._@:%-]+$') {
        Write-Error "接続先には英数字と . _ @ : % - だけを使ってください: $t"
    }
}

$Inner = Join-Path $PSScriptRoot 'start-ssh.ps1'
$Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$Dir = $HOME
$SplitWindow = 'ssh-sessions'
# 最後に開いた tmux のウィンドウ (セッション名:ウィンドウ番号)。最後にここへ画面を切り替える
$LastWindow = $null

foreach ($t in $Targets) {
    $InnerArgs = @('-NoProfile', '-File', $Inner, '-Target', $t)

    if ($env:TMUX -and (Get-Command tmux -ErrorAction SilentlyContinue)) {
        # 作るときは -d を付けて画面をそのままにし、全部開いてから最後のウィンドウに切り替える。
        # ウィンドウ名に . を含む接続先 (IP アドレスなど) は -t で取り違えるので、番号で覚えておく。
        # psmux は -t の @ID / %ID を別のセッションのものとして解決することがあるので、
        # 場所は「セッション名:ウィンドウ名」で指定する
        if ($Split) {
            $sname = & tmux display-message -p '#{session_name}'
            $exists = & tmux list-windows -t $sname -F '#{window_name}' | Where-Object { $_ -eq $SplitWindow }
            if ($exists) {
                & tmux split-window -d -t "${sname}:${SplitWindow}" -c $Dir $Shell @InnerArgs
                & tmux select-layout -t "${sname}:${SplitWindow}" tiled
                $LastWindow = "${sname}:${SplitWindow}"
                $how = 'tmux split-window (専用ウィンドウ)'
            }
            else {
                $LastWindow = & tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "${sname}:" -c $Dir -n $SplitWindow $Shell @InnerArgs
                $how = 'tmux new-window (専用ウィンドウを作成)'
            }
        }
        else {
            $LastWindow = & tmux new-window -d -P -F '#{session_name}:#{window_index}' -c $Dir -n $t $Shell @InnerArgs
            $how = 'tmux new-window'
        }
    }
    elseif (Get-Command wt -ErrorAction SilentlyContinue) {
        $window = if ($NewWindow) { 'new' } else { '0' }
        # --suppressApplicationTitle: start-ssh.ps1 や接続先のシェルがタイトルを書き換えても、接続先の名前を残す
        & wt -w $window new-tab --title $t --suppressApplicationTitle -d $Dir $Shell @InnerArgs
        $how = 'Windows Terminal (wt new-tab)'
    }
    else {
        Start-Process -FilePath $Shell -ArgumentList $InnerArgs -WorkingDirectory $Dir
        $how = "$Shell の新しいウィンドウ"
    }
    Write-Output "launched: $how / target=$t"
    # 続けて開くときは、前のタブが開くのを少し待つ
    if ($Targets.Count -gt 1) { Start-Sleep -Milliseconds 500 }
}

if ($LastWindow -and -not $Background) {
    & tmux select-window -t $LastWindow
    Write-Output "switched: $LastWindow"
}
