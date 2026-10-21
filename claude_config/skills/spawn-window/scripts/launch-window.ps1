# 新しいターミナルのタブ (tmux の中では新しいウィンドウ) で、シェルを開く (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-window.ps1 [-Dir <作業フォルダ>] [-Name <ウィンドウ名>] [-NewWindow] [-Split] [-Background]
#
# 起動先の選び方 (spawn-session の launch-session.ps1 と同じ):
#   1. tmux (psmux など) の中 ($env:TMUX がある) → tmux new-window (-Split のときは専用ウィンドウを分割)
#   2. Windows Terminal がある                    → wt -w 0 new-tab --reloadEnvironment
#   3. どちらもない                                → pwsh / powershell の新しいウィンドウ
#
# tmux の中では、開いたウィンドウに画面を切り替える。-Background を付けると、呼び出し元のウィンドウのまま。
# (Windows Terminal などは、新しいタブが前に出る。-Background は効かない)
# どの起動先でも start-shell.ps1 が Claude のセッション固有の環境変数を消してから、対話のシェルになる。

param(
    [string]$Dir = (Get-Location).Path,
    [string]$Name = '',
    [switch]$NewWindow,
    # tmux の中で、専用ウィンドウをペイン分割して並べる (tmux 以外では無視する)
    [switch]$Split,
    # tmux の中で、開いたウィンドウに画面を切り替えない (tmux 以外では無視する)
    [switch]$Background
)

$ErrorActionPreference = 'Stop'

# ウィンドウ名は tmux の -t に使うので、英数字・ハイフン・アンダースコアだけにする
# (psmux は名前に . を含むと取り違える。wt は ; を区切り記号として扱う)
if ($Name -and $Name -notmatch '^[A-Za-z0-9_-]+$') {
    Write-Error "ウィンドウ名には英数字・ハイフン・アンダースコアだけを使ってください: $Name"
}
$Dir = (Resolve-Path -LiteralPath $Dir).Path
if ($Dir.Contains(';')) {
    Write-Error "フォルダのパスに ; が含まれていると wt で起動できません: $Dir"
}

$Inner = Join-Path $PSScriptRoot 'start-shell.ps1'
$Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$InnerArgs = @('-NoExit', '-File', $Inner, '-Dir', $Dir)
$SplitWindow = 'shells'
$switched = $null

if ($env:TMUX -and (Get-Command tmux -ErrorAction SilentlyContinue)) {
    # 作ったウィンドウは「セッション名:ウィンドウ番号」で覚えて、最後にそこへ切り替える。
    # psmux は -t の @ID / %ID を別のセッションのものとして解決することがあるので使わない
    $sname = & tmux display-message -p '#{session_name}'
    if ($Split) {
        $exists = & tmux list-windows -t $sname -F '#{window_name}' | Where-Object { $_ -eq $SplitWindow }
        if ($exists) {
            # 切り替えるときは -d を付けずに、新しいペインを専用ウィンドウの中で選ばれた状態にする
            $splitArgs = @('split-window', '-t', "${sname}:${SplitWindow}", '-c', $Dir)
            if ($Background) { $splitArgs = @('split-window', '-d', '-t', "${sname}:${SplitWindow}", '-c', $Dir) }
            & tmux @splitArgs $Shell @InnerArgs
            & tmux select-layout -t "${sname}:${SplitWindow}" tiled
            $target = "${sname}:${SplitWindow}"
            $how = 'tmux split-window (専用ウィンドウ)'
        }
        else {
            $target = & tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "${sname}:" -c $Dir -n $SplitWindow $Shell @InnerArgs
            $how = 'tmux new-window (専用ウィンドウを作成)'
        }
    }
    else {
        $tmuxArgs = @('new-window', '-d', '-P', '-F', '#{session_name}:#{window_index}', '-t', "${sname}:", '-c', $Dir)
        if ($Name) { $tmuxArgs += @('-n', $Name) }
        $target = & tmux @tmuxArgs $Shell @InnerArgs
        $how = 'tmux new-window'
    }
    if (-not $Background) {
        & tmux select-window -t $target
        $switched = $target
    }
}
elseif (Get-Command wt -ErrorAction SilentlyContinue) {
    # --reloadEnvironment: 呼び出し元の環境変数ではなく、新しい環境で起動する
    $window = if ($NewWindow) { 'new' } else { '0' }
    $wtArgs = @('-w', $window, 'new-tab', '--reloadEnvironment', '-d', $Dir)
    if ($Name) { $wtArgs += @('--title', $Name, '--suppressApplicationTitle') }
    & wt @wtArgs $Shell @InnerArgs
    $how = 'Windows Terminal (wt new-tab)'
}
else {
    Start-Process -FilePath $Shell -ArgumentList $InnerArgs -WorkingDirectory $Dir
    $how = "$Shell の新しいウィンドウ"
}

Write-Output "launched: $how / dir=$Dir / name=$(if ($Name) { $Name } else { '(自動)' })"
if ($switched) { Write-Output "switched: $switched" }
