# psmux: 今のセッションのウィンドウをメニューに出し、選んだウィンドウを閉じる（.tmux.conf の Prefix + W / Ctrl-Shift-w から呼ぶ）
# psmux 3.4.0 の choose-tree はテンプレート（"kill-window -t '%%'"）を無視するので、display-menu で一覧を作る
# run-shell から呼ぶと TMUX / PSMUX_TARGET_SESSION が今のセッションを指すので、-L や -t は付けない

$items = @()
psmux list-windows -F '#{window_index}|#{window_id}|#{window_active}|#{window_name}' |
    ForEach-Object {
        $index, $id, $active, $name = $_ -split '\|', 4
        $label = "${index}: $name"
        if ($active -eq '1') { $label += ' *' }
        # 番号のキーで選べるようにする。10 以上は先頭の 1 文字がぶつかるので a, b, ... を使う
        # （空のキーを渡すと、引数が消えて名前・キー・コマンドの組がずれるおそれがある）
        $key = if ($index.Length -eq 1) { $index } else { [string][char](([int]$index - 10) % 26 + [int][char]'a') }
        $items += $label, $key, "kill-window -t $id"
    }

if ($items.Count -gt 0) {
    psmux display-menu -T 'kill window' @items
}
