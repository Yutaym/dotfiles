# 新しいターミナルのタブで、独立した Claude Code のセッションを起動する (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-session.ps1 -Dir <作業フォルダ> [-Name <セッション名>] [-NewWindow] [-Split] [-Switch] [-Resume <セッションID>] [-Model <モデル>] [-Effort <effort>]
#   -Model / -Effort: claude --model / --effort に渡す (省略すると Claude Code の既定)。モデルは opus などの短い名前を使う
#   -Switch: tmux の中で、起動したウィンドウに画面を切り替える (頼む作業がないとき用。tmux 以外では無視する)
#
# 起動先の選び方:
#   1. tmux (psmux など) の中 ($env:TMUX がある) → tmux new-window (-Split のときは専用ウィンドウを分割)
#   2. Windows Terminal がある                    → wt -w 0 new-tab --reloadEnvironment
#   3. どちらもない                                → pwsh / powershell の新しいウィンドウ
#
# 呼び出し元 (Claude Code の Bash / PowerShell ツール) の環境変数を引き継ぐと、新しいセッションが
# 「子セッション」扱いになり、会話の記録が保存されず、ほかのセッションからも見つけにくくなる。
# そのため、どの起動先でも start-claude.ps1 が Claude のセッション固有の変数を消してから claude を起動する。

param(
    [string]$Dir = (Get-Location).Path,
    [string]$Name = '',
    [switch]$NewWindow,
    # tmux の中で、専用ウィンドウをペイン分割して並べる (tmux 以外では無視する)
    [switch]$Split,
    # tmux の中で、起動したウィンドウに画面を切り替える (tmux 以外では無視する)
    [switch]$Switch,
    # 新しく始めずに、この ID の会話を開く (claude --resume <ID>)
    [string]$Resume = '',
    # モデル (claude --model)。fable / opus / sonnet / haiku の短い名前なら、いつも最新版になる
    [string]$Model = '',
    # effort (claude --effort)
    [ValidateSet('', 'low', 'medium', 'high', 'xhigh', 'max')][string]$Effort = ''
)

$ErrorActionPreference = 'Stop'

# セッション名は SendMessage の宛先になるので、英数字・ハイフン・アンダースコアだけにする
# (wt は ; を区切り記号として扱うので、引数に ; を含めない意味もある)
if ($Name -and $Name -notmatch '^[A-Za-z0-9_-]+$') {
    Write-Error "セッション名には英数字・ハイフン・アンダースコアだけを使ってください: $Name"
}
if ($Resume -and $Resume -notmatch '^[0-9a-fA-F-]+$') {
    Write-Error "-Resume にはセッション ID (UUID) を指定してください: $Resume"
}
if ($Model -and $Model -notmatch '^[A-Za-z0-9._-]+$') {
    Write-Error "-Model には英数字と . _ - だけを使ってください (例: opus, claude-opus-5-5): $Model"
}
# フォルダの指定がなく、今のフォルダがホームなら ~/claudeWS にする
# (ホームは信頼の確認が保存されず、起動のたびに聞かれるため)。それ以外は今のフォルダを引き継ぐ
if (-not $PSBoundParameters.ContainsKey('Dir')) {
    $full = { param($p) [IO.Path]::GetFullPath($p).TrimEnd('\', '/') }
    if ((& $full $Dir) -ieq (& $full $HOME)) { $Dir = Join-Path $HOME 'claudeWS' }
}
# フォルダがなければ作る
if (-not (Test-Path -LiteralPath $Dir)) {
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    Write-Output "created: $Dir"
}
$Dir = (Resolve-Path -LiteralPath $Dir).Path
if ($Dir.Contains(';')) {
    Write-Error "フォルダのパスに ; が含まれていると wt で起動できません: $Dir"
}

$Inner = Join-Path $PSScriptRoot 'start-claude.ps1'
$Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$InnerArgs = @('-NoExit', '-File', $Inner, '-Dir', $Dir)
if ($Name) { $InnerArgs += @('-Name', $Name) }
if ($Resume) { $InnerArgs += @('-Resume', $Resume) }
if ($Model) { $InnerArgs += @('-Model', $Model) }
if ($Effort) { $InnerArgs += @('-Effort', $Effort) }

if ($env:TMUX -and (Get-Command tmux -ErrorAction SilentlyContinue)) {
    # 普段は new-window。どの場合も -d を付けて作り、-Switch のときだけ最後にそのウィンドウへ切り替える。-Split のときは専用ウィンドウ (名前が cc-sessions のもの) に並べる。
    # 呼び出し元と同じセッションに専用ウィンドウがなければ作り、あれば分割して均等に並べ直す。
    # 専用ウィンドウは名前で見分ける (psmux はウィンドウのユーザーオプションを書式で返さないため)。
    # psmux は -t の @ID / %ID を別のセッションのものとして解決することがあるので、
    # 場所は「セッション名:ウィンドウ名」で指定する
    if ($Split) {
        $sname = & tmux display-message -p '#{session_name}'
        $exists = & tmux list-windows -t $sname -F '#{window_name}' | Where-Object { $_ -eq 'cc-sessions' }
        if ($exists) {
            & tmux split-window -d -t "${sname}:cc-sessions" -c $Dir $Shell @InnerArgs
            & tmux select-layout -t "${sname}:cc-sessions" tiled
            $target = "${sname}:cc-sessions"
            $how = 'tmux split-window (専用ウィンドウ)'
        }
        else {
            $target = & tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "${sname}:" -c $Dir -n cc-sessions $Shell @InnerArgs
            $how = 'tmux new-window (専用ウィンドウを作成)'
        }
    }
    else {
        $tmuxArgs = @('new-window', '-d', '-P', '-F', '#{session_name}:#{window_index}', '-c', $Dir)
        if ($Name) { $tmuxArgs += @('-n', $Name) }
        $target = & tmux @tmuxArgs $Shell @InnerArgs
        $how = 'tmux new-window'
    }
    # ウィンドウは名前ではなく番号で指定する (psmux は名前を -t で取り違えることがある)
    if ($Switch -and $target) {
        & tmux select-window -t $target
        $switched = $target
    }
}
elseif (Get-Command wt -ErrorAction SilentlyContinue) {
    # --reloadEnvironment: 呼び出し元の環境変数ではなく、新しい環境で起動する
    $window = if ($NewWindow) { 'new' } else { '0' }
    $wtArgs = @('-w', $window, 'new-tab', '--reloadEnvironment', '-d', $Dir)
    if ($Name) { $wtArgs += @('--title', $Name) }
    & wt @wtArgs $Shell @InnerArgs
    $how = 'Windows Terminal (wt new-tab)'
}
else {
    Start-Process -FilePath $Shell -ArgumentList $InnerArgs -WorkingDirectory $Dir
    $how = "$Shell の新しいウィンドウ"
}

Write-Output "launched: $how / dir=$Dir / name=$(if ($Name) { $Name } else { '(自動)' }) / model=$(if ($Model) { $Model } else { '(既定)' }) / effort=$(if ($Effort) { $Effort } else { '(既定)' })"
if ($switched) { Write-Output "switched: $switched" }
