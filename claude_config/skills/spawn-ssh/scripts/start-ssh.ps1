# 新しいタブの中で実行される。ssh で接続し、失敗したときはタブを閉じずにエラーを読めるようにする。
param(
    [Parameter(Mandatory)][string]$Target
)

$Host.UI.RawUI.WindowTitle = $Target
# tmux (psmux) の中では、接続先をペインのオプション @ssh_host に入れ、ステータスバーに 🌐 (接続先) と出す
$InTmux = $env:TMUX -and $env:TMUX_PANE -and (Get-Command tmux -ErrorAction SilentlyContinue)
if ($InTmux) { tmux set -p -t $env:TMUX_PANE '@ssh_host' $Target 2>$null }
ssh $Target
$code = $LASTEXITCODE
if ($InTmux) { tmux set -pu -t $env:TMUX_PANE '@ssh_host' 2>$null }
if ($code -ne 0) {
    Write-Host ""
    Write-Host "ssh が終了しました (終了コード $code)。Enter で閉じます。"
    [void][Console]::ReadLine()
}
