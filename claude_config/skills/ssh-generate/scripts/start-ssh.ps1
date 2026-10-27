# 新しいタブの中で実行される。ssh で接続し、失敗したときはタブを閉じずにエラーを読めるようにする。
param(
    [Parameter(Mandatory)][string]$Target,
    # 接続先で実行するコマンド (UTF-8 を Base64 にしたもの)。指定すると ssh -t <接続先> <コマンド> を実行する
    [string]$RemoteCommandB64 = '',
    [string]$Title = ''
)

$Host.UI.RawUI.WindowTitle = if ($Title) { $Title } else { $Target }
# tmux (psmux) の中では、接続先をペインのオプション @ssh_host に入れ、ステータスバーに 🌐 (接続先) と出す
$InTmux = $env:TMUX -and $env:TMUX_PANE -and (Get-Command tmux -ErrorAction SilentlyContinue)
if ($InTmux) { tmux set -p -t $env:TMUX_PANE '@ssh_host' $Target 2>$null }
if ($RemoteCommandB64) {
    $cmd = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($RemoteCommandB64))
    ssh -t $Target $cmd
}
else {
    ssh $Target
}
$code = $LASTEXITCODE
# 接続が切れると、接続先の tmux などがオンにしたマウスの報告・フォーカスの報告・括弧付き貼り付けのモードが残り、
# マウスを動かすたびに ^[[<35;x;yM のような文字が入力に入る。ここで戻し、もう入った分は読み捨てる
$e = [char]27
[Console]::Write("$e[?1000l$e[?1002l$e[?1003l$e[?1005l$e[?1006l$e[?1015l$e[?1004l$e[?2004l")
try { while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) } } catch {}
if ($InTmux) { tmux set -pu -t $env:TMUX_PANE '@ssh_host' 2>$null }
if ($code -ne 0) {
    Write-Host ""
    Write-Host "ssh が終了しました (終了コード $code)。Enter で閉じます。"
    [void][Console]::ReadLine()
}
