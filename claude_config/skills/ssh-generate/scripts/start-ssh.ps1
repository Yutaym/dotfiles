# 新しいタブの中で実行される。ssh で接続し、失敗したときはタブを閉じずにエラーを読めるようにする。
# 接続が切れたとき (終了コード 0 以外) は「Enter で再接続 / q で閉じる」と聞いて、Enter ならもう一度 ssh する
# (スリープ・回線断のあと、接続先の tmux の中で動き続けている Claude につなぎ直すため)。
# session-ssh から呼ばれたとき (-RemoteCommandB64 と -Title がある) は、~/.claude/state/session-ssh/<Title>.json に
# 接続の記録を残す。MSI の再起動などでウィンドウごと消えたら、session-ssh の restore-session-ssh.ps1 が記録から開き直す。
# ssh が終了コード 0 で終わったとき (接続先の claude を終えた・detach した) は、記録を消す。
param(
    [Parameter(Mandatory)][string]$Target,
    # 接続先で実行するコマンド (UTF-8 を Base64 にしたもの)。指定すると ssh -t <接続先> <コマンド> を実行する
    [string]$RemoteCommandB64 = '',
    [string]$Title = ''
)

$Host.UI.RawUI.WindowTitle = if ($Title) { $Title } else { $Target }
# tmux (psmux) の中では、接続先をペインのオプション @ssh_host に入れ、ステータスバーに 🌐 (接続先) と出す
$InTmux = $env:TMUX -and $env:TMUX_PANE -and (Get-Command tmux -ErrorAction SilentlyContinue)

# 接続の記録 (session-ssh で開いたものだけ)
$Record = ''
if ($RemoteCommandB64 -and $Title -match '^[A-Za-z0-9_-]+$') {
    $StateDir = Join-Path $HOME '.claude/state/session-ssh'
    New-Item -ItemType Directory -Force $StateDir | Out-Null
    $Record = Join-Path $StateDir "$Title.json"
    [ordered]@{ Name = $Title; Target = $Target; RemoteCommandB64 = $RemoteCommandB64; Saved = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz') } |
        ConvertTo-Json | Set-Content -Encoding utf8 $Record
}

# 切断に早く気づくように、15 秒ごとに生存確認し、3 回応答がなければ切る (~/.ssh/config の値より先に効く)
$SshOpts = @('-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=3')
$e = [char]27
while ($true) {
    if ($InTmux) { tmux set -p -t $env:TMUX_PANE '@ssh_host' $Target 2>$null }
    if ($RemoteCommandB64) {
        $cmd = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($RemoteCommandB64))
        ssh @SshOpts -t $Target $cmd
    }
    else {
        ssh @SshOpts $Target
    }
    $code = $LASTEXITCODE
    # 接続が切れると、接続先の tmux などがオンにしたマウスの報告・フォーカスの報告・括弧付き貼り付けのモードが残り、
    # マウスを動かすたびに ^[[<35;x;yM のような文字が入力に入る。ここで戻し、もう入った分は読み捨てる
    [Console]::Write("$e[?1000l$e[?1002l$e[?1003l$e[?1005l$e[?1006l$e[?1015l$e[?1004l$e[?2004l")
    try { while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) } } catch {}
    if ($InTmux) { tmux set -pu -t $env:TMUX_PANE '@ssh_host' 2>$null }
    if ($code -eq 0) {
        if ($Record) { Remove-Item -ErrorAction SilentlyContinue $Record }
        break
    }
    Write-Host ""
    Write-Host "ssh が終了しました (終了コード $code、$(Get-Date -Format 'HH:mm:ss'))。"
    Write-Host "Enter で再接続します。q + Enter で閉じます。"
    $ans = [Console]::ReadLine()
    if ($null -eq $ans -or $ans.Trim() -match '^[qQ]') { break }
    Write-Host "再接続します: $Target"
}
