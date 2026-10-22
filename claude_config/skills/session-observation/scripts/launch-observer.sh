#!/bin/sh
# session-observation の監視画面を開く (macOS / Linux / WSL 用)
#
# 使い方:
#   sh launch-observer.sh [-i 秒] [-r 秒] [-n] [-v] [-H]
#   sh launch-observer.sh -x
#   -i: このマシンのセッションを読み直す間隔 (既定 10 秒)
#   -r: ssh の接続先を読み直す間隔 (既定 60 秒)
#   -n: ssh の接続先を読まない
#   -v: tmux の中で、上下に分割する (既定は左右。2026/10/22 にユーザーが決めた)
#   -H: 新しいペインやタブを開かず、このターミナルでそのまま実行する
#   -x: 動いている監視を止める (ほかのセッションからも使える)
#
# 開き方 (上から順に、当てはまった最初のもの):
#   1. tmux の中 ($TMUX がある)                → 呼び出し元のウィンドウを tmux split-window -d で分割
#   2. WezTerm ($WEZTERM_PANE)                 → wezterm cli spawn
#   3. kitty ($KITTY_WINDOW_ID)                → kitten @ launch --type=tab (リモート制御が有効なときだけ)
#   4. iTerm2 (TERM_PROGRAM=iTerm.app)         → AppleScript の create tab
#   5. macOS のターミナル (TERM_PROGRAM=Apple_Terminal) → AppleScript の do script (新しいウィンドウ)
#   6. GNOME Terminal ($GNOME_TERMINAL_SCREEN) → gnome-terminal --tab
#   7. Konsole ($KONSOLE_DBUS_SERVICE)         → konsole --new-tab
#   8. WSL の中で Windows Terminal ($WT_SESSION) → wt.exe new-tab で wsl.exe を起動
#   どれにも当てはまらないときは、手で実行するコマンドを表示して終了コード 2 で終わる (-H でそのまま実行もできる)。
#
# 監視は同時に 1 つだけ動く。すでに動いていれば、新しく開いたほうに置き換わり、古いほうは閉じる (observe.py が判断する)。

set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
INTERVAL=10
REMOTE=60
NOREMOTE=''
SPLIT=-h
INPLACE=0
while getopts 'i:r:nvHx' opt; do
    case "$opt" in
        i) INTERVAL=$OPTARG ;;
        r) REMOTE=$OPTARG ;;
        n) NOREMOTE='--no-remote' ;;
        v) SPLIT=-v ;;
        H) INPLACE=1 ;;
        x) exec uv run --no-project python "$HERE/observe.py" --stop ;;
        *) echo "usage: $0 [-i sec] [-r sec] [-n] [-v] [-H] [-x]" >&2; exit 64 ;;
    esac
done
case "$INTERVAL$REMOTE" in
    *[!0-9.]*) echo "間隔には数字を指定してください" >&2; exit 64 ;;
esac

# 新しいペインやタブで実行するコマンド (パスは ' で囲む)
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
CMD="sh $(q "$HERE/run-observer.sh") --interval $INTERVAL --remote-interval $REMOTE $NOREMOTE"

have() { command -v "$1" >/dev/null 2>&1; }
launched() { echo "launched: $1"; exit 0; }
manual() {
    echo "このターミナルでは自動で開けませんでした ($1)。新しいタブで次を実行してください:" >&2
    echo "  $CMD" >&2
    exit 2
}

if [ "$INPLACE" = 1 ]; then
    eval "exec $CMD"
fi

# 1. tmux: 場所は「セッション名:ウィンドウ番号」で指定する (tmux 互換ソフトでも取り違えないように)
if [ -n "${TMUX:-}" ] && have tmux; then
    PANE=${TMUX_PANE:-}
    TARGET=$(tmux display-message -p ${PANE:+-t "$PANE"} '#{session_name}:#{window_index}')
    tmux split-window -d "$SPLIT" -t "$TARGET" -c "$HOME" "$CMD" || manual 'tmux split-window が失敗した'
    launched "tmux split-window $SPLIT ($TARGET)"
fi

# 2. WezTerm
if [ -n "${WEZTERM_PANE:-}" ] && have wezterm; then
    wezterm cli spawn --cwd "$HOME" -- sh -c "$CMD" >/dev/null && launched 'wezterm cli spawn'
    manual 'wezterm cli spawn が失敗した'
fi

# 3. kitty (kitty.conf で allow_remote_control が有効なときだけ動く)
if [ -n "${KITTY_WINDOW_ID:-}" ] && have kitten; then
    kitten @ launch --type=tab --tab-title session-observation --cwd "$HOME" sh -c "$CMD" >/dev/null 2>&1 && launched 'kitten @ launch'
    manual 'kitty のリモート制御が無効 (kitty.conf の allow_remote_control)'
fi

# AppleScript の文字列に入れるので、" と \ をエスケープする
ASCMD=$(printf '%s' "$CMD" | sed 's/\\/\\\\/g; s/"/\\"/g')
case "${TERM_PROGRAM:-}" in
    # 4. iTerm2
    iTerm.app)
        osascript -e "tell application \"iTerm2\" to tell current window to create tab with default profile command \"$ASCMD\"" >/dev/null \
            && launched 'iTerm2 (AppleScript)'
        manual 'iTerm2 の AppleScript が失敗した'
        ;;
    # 5. macOS のターミナル (タブにするにはアクセシビリティの許可が要るので、新しいウィンドウで開く)
    Apple_Terminal)
        osascript -e "tell application \"Terminal\" to do script \"$ASCMD\"" >/dev/null \
            && launched 'Terminal.app (新しいウィンドウ)'
        manual 'Terminal.app の AppleScript が失敗した'
        ;;
esac

# 6. GNOME Terminal
if [ -n "${GNOME_TERMINAL_SCREEN:-}" ] && have gnome-terminal; then
    gnome-terminal --tab --title=session-observation --working-directory="$HOME" -- sh -c "$CMD" && launched 'gnome-terminal --tab'
    manual 'gnome-terminal --tab が失敗した'
fi

# 7. Konsole
if [ -n "${KONSOLE_DBUS_SERVICE:-}" ] && have konsole; then
    konsole --new-tab --workdir "$HOME" -e sh -c "$CMD" >/dev/null 2>&1 &
    launched 'konsole --new-tab'
fi

# 8. WSL の中の Windows Terminal (wt.exe の実行エイリアスは WSL から直接は呼べないので cmd.exe を通す)
if [ -n "${WT_SESSION:-}" ] && [ -n "${WSL_DISTRO_NAME:-}" ] && have cmd.exe; then
    (cd /mnt/c && cmd.exe /c wt.exe -w 0 new-tab --title session-observation wsl.exe -d "$WSL_DISTRO_NAME" --cd "$HOME" -- sh -c "$CMD") \
        && launched 'Windows Terminal (WSL から)'
    manual 'wt.exe を起動できなかった'
fi

manual "対応していないターミナル (TERM_PROGRAM=${TERM_PROGRAM:-なし})"
