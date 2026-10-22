# psmux: 今のウィンドウ以外を閉じる（.tmux.conf の Prefix + X / Ctrl-Shift-x から呼ぶ）
# psmux 3.4.0 の kill-window -a は「ほかのウィンドウ」ではなく今のウィンドウを閉じてしまうので、1 つずつ閉じる
# 使い方: kill_other_windows.ps1 <ソケット名> <セッション名> <残すウィンドウの ID（@N）>
param(
    [Parameter(Mandatory)][string]$Socket,
    [Parameter(Mandatory)][string]$Session,
    [Parameter(Mandatory)][string]$Keep
)

# psmux のウィンドウ ID（@N）はセッションごとに振られて重なるので、全セッションのウィンドウを出してセッション名で絞り、
# 閉じるときも「セッション名:@N」で指定する
psmux -L $Socket list-windows -a -F '#{session_name}|#{window_id}' |
    ForEach-Object {
        $s, $w = $_ -split '\|', 2
        if ($s -eq $Session -and $w -ne $Keep) {
            psmux -L $Socket kill-window -t "${Session}:$w"
        }
    }
