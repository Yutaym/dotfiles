#!/bin/sh
# 新しいターミナルのタブで、ssh で接続した状態を作る (macOS / Linux / WSL 用)
#
# 使い方:
#   sh launch-ssh.sh [-s] [-b] <接続先> [<接続先> ...]
#   接続先は ~/.ssh/config の Host の別名 (または user@host)。複数書くと、1 つずつ別のタブで開く。
#   -s: tmux の中で、専用ウィンドウをペイン分割して並べる (tmux 以外では無視する)
#   -b: tmux の中で、開いたウィンドウに画面を切り替えない (指定しなければ、最後に開いたウィンドウに切り替える)
#
# 起動先の選び方 (session-spawn の launch-session.sh と同じ。上から順に、当てはまった最初のもの):
#   1. tmux の中 ($TMUX がある)                → tmux new-window (-s のときは専用ウィンドウを分割)
#   2. WezTerm ($WEZTERM_PANE)                 → wezterm cli spawn
#   3. kitty ($KITTY_WINDOW_ID)                → kitten @ launch --type=tab (リモート制御が有効なときだけ)
#   4. iTerm2 (TERM_PROGRAM=iTerm.app)         → AppleScript の create tab
#   5. Ghostty 1.3 以降の macOS (TERM_PROGRAM=ghostty) → AppleScript の new tab
#   6. macOS のターミナル (TERM_PROGRAM=Apple_Terminal) → System Events で Cmd+T → do script
#                                                (アクセシビリティの許可がないときは新しいウィンドウ)
#   7. GNOME Terminal ($GNOME_TERMINAL_SCREEN) → gnome-terminal --tab
#   8. Konsole ($KONSOLE_DBUS_SERVICE)         → konsole --new-tab
#   9. WSL の中で Windows Terminal ($WT_SESSION) → wt.exe new-tab で wsl.exe を起動
#   どれにも当てはまらない、または起動に失敗したときは、手で実行するコマンドを表示し、最後に終了コード 2 で終わる。
#
# 新しいタブでは、一時ファイルに書いた起動用スクリプトを sh で実行する。ターミナルごとの引用符の違いを
# 避けるためと、ssh が失敗したときにタブを閉じずにエラーを残すため。

set -eu

SPLIT=0
BACKGROUND=0
while getopts 'sb' opt; do
    case "$opt" in
        s) SPLIT=1 ;;
        b) BACKGROUND=1 ;;
        *) echo "usage: $0 [-s] [-b] target..." >&2; exit 64 ;;
    esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { echo "usage: $0 [-s] [-b] target..." >&2; exit 64; }

# 接続先はコマンドラインにそのまま渡すので、ホスト名に使う文字だけにする
for t in "$@"; do
    case "$t" in
        ''|-*|*[!A-Za-z0-9._@:%-]*) echo "接続先には英数字と . _ @ : % - だけを使ってください: $t" >&2; exit 64 ;;
    esac
done

DIR=$HOME
SPLIT_WINDOW=ssh-sessions
RC=0
# 最後に開いた tmux のウィンドウ (セッション名:ウィンドウ番号)。最後にここへ画面を切り替える
LAST_WINDOW=

have() { command -v "$1" >/dev/null 2>&1; }

# 新しいタブで実行する起動用スクリプトを作る。実行後に自分自身を消す
make_inner() {
    INNER=$(mktemp "${TMPDIR:-/tmp}/ssh-launch.XXXXXX")
    {
        echo '#!/bin/sh'
        echo 'rm -f -- "$0"'
        printf 'printf "\\033]0;%%s\\007" %s\n' "$1"
        # tmux の中では、接続先をペインのオプション @ssh_host に入れ、ステータスバーに 🌐 (接続先) と出す
        printf '[ -n "$TMUX_PANE" ] && tmux set -p -t "$TMUX_PANE" @ssh_host %s 2>/dev/null\n' "$1"
        printf 'ssh %s\n' "$1"
        echo 'rc=$?'
        echo '[ -n "$TMUX_PANE" ] && tmux set -pu -t "$TMUX_PANE" @ssh_host 2>/dev/null'
        echo 'if [ "$rc" -ne 0 ]; then'
        echo '    echo; echo "ssh が終了しました (終了コード $rc)。Enter で閉じます。"; read _'
        echo 'fi'
    } > "$INNER"
    chmod +x "$INNER"
}

launched() {
    echo "launched: $1 / target=$T"
    return 0
}

manual() {
    rm -f -- "$INNER"
    echo "このターミナルでは自動でタブを開けませんでした ($1)。新しいタブで次を実行してください:" >&2
    echo "  ssh $T" >&2
    RC=2
    return 0
}

launch_one() {
    T=$1
    make_inner "$T"

    # 1. tmux: 作るときは -d を付けて画面をそのままにし、全部開いてから最後のウィンドウに切り替える。
    #    ウィンドウ名に . を含む接続先 (IP アドレスなど) は -t で取り違えるので、番号で覚えておく。
    #    -s のときは専用ウィンドウ (名前が ssh-sessions のもの) に並べる。なければ作り、あれば分割して均等に並べ直す。
    #    場所は「セッション名:ウィンドウ名」で指定する (tmux 互換ソフトでも取り違えないように)
    if [ -n "${TMUX:-}" ] && have tmux; then
        if [ "$SPLIT" = 1 ]; then
            PANE=${TMUX_PANE:-}
            SNAME=$(tmux display-message -p ${PANE:+-t "$PANE"} '#{session_name}')
            if tmux list-windows -t "$SNAME" -F '#{window_name}' | grep -qx "$SPLIT_WINDOW"; then
                tmux split-window -d -t "$SNAME:$SPLIT_WINDOW" -c "$DIR" "sh '$INNER'" || { manual 'tmux split-window が失敗した'; return; }
                tmux select-layout -t "$SNAME:$SPLIT_WINDOW" tiled
                LAST_WINDOW="$SNAME:$SPLIT_WINDOW"
                launched 'tmux split-window (専用ウィンドウ)'; return
            fi
            LAST_WINDOW=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "$SNAME:" -c "$DIR" -n "$SPLIT_WINDOW" "sh '$INNER'") \
                && { launched 'tmux new-window (専用ウィンドウを作成)'; return; }
            manual 'tmux new-window が失敗した'; return
        fi
        LAST_WINDOW=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -c "$DIR" -n "$T" "sh '$INNER'") && { launched 'tmux new-window'; return; }
        manual 'tmux new-window が失敗した'; return
    fi

    # 2. WezTerm
    if [ -n "${WEZTERM_PANE:-}" ] && have wezterm; then
        wezterm cli spawn --cwd "$DIR" -- sh "$INNER" >/dev/null && { launched 'wezterm cli spawn'; return; }
        manual 'wezterm cli spawn が失敗した'; return
    fi

    # 3. kitty (kitty.conf で allow_remote_control が有効なときだけ動く)
    if [ -n "${KITTY_WINDOW_ID:-}" ] && have kitten; then
        kitten @ launch --type=tab --tab-title "$T" --cwd "$DIR" sh "$INNER" >/dev/null 2>&1 && { launched 'kitten @ launch'; return; }
        manual 'kitty のリモート制御が無効 (kitty.conf の allow_remote_control)'; return
    fi

    case "${TERM_PROGRAM:-}" in
        # 4. iTerm2
        iTerm.app)
            osascript -e 'tell application "iTerm2" to tell current window to create tab with default profile command "sh '"$INNER"'"' >/dev/null \
                && { launched 'iTerm2 (AppleScript)'; return; }
            manual 'iTerm2 の AppleScript が失敗した'; return
            ;;
        # 5. Ghostty (macOS, 1.3 以降)
        ghostty)
            if [ "$(uname)" = Darwin ]; then
                osascript >/dev/null <<EOF && { launched 'Ghostty (AppleScript)'; return; }
tell application "Ghostty"
    set cfg to new surface configuration
    set initial working directory of cfg to "$DIR"
    set command of cfg to "sh $INNER"
    new tab in front window with configuration cfg
end tell
EOF
            fi
            manual 'Ghostty のタブを開けなかった (macOS の 1.3 以降だけ対応)'; return
            ;;
        # 6. macOS のターミナル
        Apple_Terminal)
            if osascript >/dev/null 2>&1 <<EOF
tell application "Terminal" to activate
tell application "System Events" to keystroke "t" using command down
delay 0.5
tell application "Terminal" to do script "sh $INNER" in front window
EOF
            then
                launched 'Terminal.app (新しいタブ)'; return
            fi
            # アクセシビリティの許可がないと Cmd+T を送れないので、新しいウィンドウで開く
            osascript -e 'tell application "Terminal" to do script "sh '"$INNER"'"' >/dev/null \
                && { launched 'Terminal.app (新しいウィンドウ。タブにするにはアクセシビリティの許可が必要)'; return; }
            manual 'Terminal.app の AppleScript が失敗した'; return
            ;;
    esac

    # 7. GNOME Terminal
    if [ -n "${GNOME_TERMINAL_SCREEN:-}" ] && have gnome-terminal; then
        gnome-terminal --tab --title="$T" --working-directory="$DIR" -- sh "$INNER" && { launched 'gnome-terminal --tab'; return; }
        manual 'gnome-terminal --tab が失敗した'; return
    fi

    # 8. Konsole
    if [ -n "${KONSOLE_DBUS_SERVICE:-}" ] && have konsole; then
        konsole --new-tab --workdir "$DIR" -e sh "$INNER" >/dev/null 2>&1 &
        launched 'konsole --new-tab'; return
    fi

    # 9. WSL の中の Windows Terminal (wt.exe の実行エイリアスは WSL から直接は呼べないので cmd.exe を通す)
    if [ -n "${WT_SESSION:-}" ] && [ -n "${WSL_DISTRO_NAME:-}" ] && have cmd.exe; then
        (cd /mnt/c && cmd.exe /c wt.exe -w 0 new-tab --title "$T" --suppressApplicationTitle wsl.exe -d "$WSL_DISTRO_NAME" --cd "$DIR" -- sh "$INNER") \
            && { launched 'Windows Terminal (WSL から)'; return; }
        manual 'wt.exe を起動できなかった'; return
    fi

    manual "対応していないターミナル (TERM_PROGRAM=${TERM_PROGRAM:-なし})"
}

for t in "$@"; do
    launch_one "$t"
    # 続けて開くときは、前のタブが開くのを少し待つ
    [ $# -gt 1 ] && sleep 0.5
done

if [ -n "$LAST_WINDOW" ] && [ "$BACKGROUND" = 0 ]; then
    tmux select-window -t "$LAST_WINDOW" && echo "switched: $LAST_WINDOW"
fi
exit "$RC"
