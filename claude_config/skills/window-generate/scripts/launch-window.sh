#!/bin/sh
# 新しいターミナルのタブ (tmux の中では新しいウィンドウ) で、シェルを開く (macOS / Linux / WSL 用)
#
# 使い方:
#   sh launch-window.sh [-d <作業フォルダ>] [-n <ウィンドウ名>] [-s] [-b]
#   -s: tmux の中で、専用ウィンドウをペイン分割して並べる (tmux 以外では無視する)
#   -b: tmux の中で、開いたウィンドウに画面を切り替えない (指定しなければ切り替える。tmux 以外では無視する)
#
# 起動先の選び方 (session-generate の launch-session.sh と同じ。上から順に、当てはまった最初のもの):
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
#   どれにも当てはまらない、または起動に失敗したときは、手で実行するコマンドを表示して終了コード 2 で終わる。
#
# 新しいタブでは、一時ファイルに書いた起動用スクリプトを sh で実行する。ターミナルごとの引用符の違いを
# 避けるためと、どの起動先でも Claude のセッション固有の環境変数を確実に消すため
# (引き継ぐと、そのシェルで起動した claude が子セッション扱いになり、会話の記録が保存されない)。

set -eu

DIR=$(pwd)
NAME=''
SPLIT=0
BACKGROUND=0
SPLIT_WINDOW=shells
while getopts 'd:n:sb' opt; do
    case "$opt" in
        d) DIR=$OPTARG ;;
        n) NAME=$OPTARG ;;
        s) SPLIT=1 ;;
        b) BACKGROUND=1 ;;
        *) echo "usage: $0 [-d dir] [-n name] [-s] [-b]" >&2; exit 64 ;;
    esac
done

# ウィンドウ名は tmux の -t に使うので、英数字・ハイフン・アンダースコアだけにする (tmux 互換ソフトは . を取り違える)
case "$NAME" in
    *[!A-Za-z0-9_-]*) echo "ウィンドウ名には英数字・ハイフン・アンダースコアだけを使ってください: $NAME" >&2; exit 64 ;;
esac
DIR=$(cd "$DIR" && pwd)

# 新しいタブで実行する起動用スクリプト。実行後に自分自身を消す
INNER=$(mktemp "${TMPDIR:-/tmp}/win-launch.XXXXXX")
{
    echo '#!/bin/sh'
    echo 'rm -f -- "$0"'
    echo 'unset CLAUDECODE CLAUDE_PID CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ID CLAUDE_CODE_SESSION_ATTENDED CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_BRIDGE_SESSION_ID'
    printf 'cd %s || exit 1\n' "'$(printf '%s' "$DIR" | sed "s/'/'\\\\''/g")'"
    echo 'exec "${SHELL:-/bin/sh}" -l'
} > "$INNER"
chmod +x "$INNER"

have() { command -v "$1" >/dev/null 2>&1; }

launched() {
    echo "launched: $1 / dir=$DIR / name=${NAME:-(自動)}"
    exit 0
}

# tmux で作ったウィンドウ ($1 = セッション名:ウィンドウ番号 または セッション名:ウィンドウ名) に画面を切り替える
switch_to() {
    if [ "$BACKGROUND" = 0 ]; then
        tmux select-window -t "$1" && echo "switched: $1"
    fi
    return 0
}

manual() {
    rm -f -- "$INNER"
    echo "このターミナルでは自動でタブを開けませんでした ($1)。新しいタブで次を実行してください:" >&2
    echo "  cd '$DIR'" >&2
    exit 2
}

# 1. tmux: 普段は new-window で開く。作るときは -d を付けて、作ったウィンドウを番号で覚え、最後にそこへ切り替える (-b のときは切り替えない)。
#    -s (分割) を指定したときは、専用ウィンドウ (名前が shells のもの) に並べる。
#    呼び出し元と同じ tmux セッションに専用ウィンドウがなければ new-window で作り、あれば分割して均等に並べ直す。
#    専用ウィンドウは名前で見分ける (psmux はウィンドウのユーザーオプションを書式で返さないため)。
#    tmux は呼び出し元ではなく tmux サーバーの環境を使う。サーバーを Claude の中から起動していると
#    Claude の変数が残っているが、起動用スクリプトの unset で消える
if [ -n "${TMUX:-}" ] && have tmux; then
    # 場所は「セッション名:ウィンドウ名 / 番号」で指定する (tmux 互換ソフトでも取り違えないように)
    PANE=${TMUX_PANE:-}
    SNAME=$(tmux display-message -p ${PANE:+-t "$PANE"} '#{session_name}')
    if [ "$SPLIT" = 1 ]; then
        if tmux list-windows -t "$SNAME" -F '#{window_name}' | grep -qx "$SPLIT_WINDOW"; then
            # 切り替えるときは -d を付けずに、新しいペインを専用ウィンドウの中で選ばれた状態にする
            if [ "$BACKGROUND" = 1 ]; then D=-d; else D=; fi
            tmux split-window $D -t "$SNAME:$SPLIT_WINDOW" -c "$DIR" "sh '$INNER'" || manual 'tmux split-window が失敗した'
            tmux select-layout -t "$SNAME:$SPLIT_WINDOW" tiled
            switch_to "$SNAME:$SPLIT_WINDOW"
            launched 'tmux split-window (専用ウィンドウ)'
        fi
        W=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "$SNAME:" -c "$DIR" -n "$SPLIT_WINDOW" "sh '$INNER'") \
            || manual 'tmux new-window が失敗した'
        switch_to "$W"
        launched 'tmux new-window (専用ウィンドウを作成)'
    fi
    W=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "$SNAME:" -c "$DIR" ${NAME:+-n "$NAME"} "sh '$INNER'") \
        || manual 'tmux new-window が失敗した'
    switch_to "$W"
    launched 'tmux new-window'
fi

# 2. WezTerm
if [ -n "${WEZTERM_PANE:-}" ] && have wezterm; then
    wezterm cli spawn --cwd "$DIR" -- sh "$INNER" >/dev/null && launched 'wezterm cli spawn'
    manual 'wezterm cli spawn が失敗した'
fi

# 3. kitty (kitty.conf で allow_remote_control が有効なときだけ動く)
if [ -n "${KITTY_WINDOW_ID:-}" ] && have kitten; then
    kitten @ launch --type=tab --cwd "$DIR" sh "$INNER" >/dev/null 2>&1 && launched 'kitten @ launch'
    manual 'kitty のリモート制御が無効 (kitty.conf の allow_remote_control)'
fi

case "${TERM_PROGRAM:-}" in
    # 4. iTerm2
    iTerm.app)
        osascript -e 'tell application "iTerm2" to tell current window to create tab with default profile command "sh '"$INNER"'"' >/dev/null \
            && launched 'iTerm2 (AppleScript)'
        manual 'iTerm2 の AppleScript が失敗した'
        ;;
    # 5. Ghostty (macOS, 1.3 以降)
    ghostty)
        if [ "$(uname)" = Darwin ]; then
            osascript >/dev/null <<EOF && launched 'Ghostty (AppleScript)'
tell application "Ghostty"
    set cfg to new surface configuration
    set initial working directory of cfg to "$DIR"
    set command of cfg to "sh $INNER"
    new tab in front window with configuration cfg
end tell
EOF
        fi
        manual 'Ghostty のタブを開けなかった (macOS の 1.3 以降だけ対応)'
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
            launched 'Terminal.app (新しいタブ)'
        fi
        # アクセシビリティの許可がないと Cmd+T を送れないので、新しいウィンドウで開く
        osascript -e 'tell application "Terminal" to do script "sh '"$INNER"'"' >/dev/null \
            && launched 'Terminal.app (新しいウィンドウ。タブにするにはアクセシビリティの許可が必要)'
        manual 'Terminal.app の AppleScript が失敗した'
        ;;
esac

# 7. GNOME Terminal
if [ -n "${GNOME_TERMINAL_SCREEN:-}" ] && have gnome-terminal; then
    gnome-terminal --tab --working-directory="$DIR" -- sh "$INNER" && launched 'gnome-terminal --tab'
    manual 'gnome-terminal --tab が失敗した'
fi

# 8. Konsole
if [ -n "${KONSOLE_DBUS_SERVICE:-}" ] && have konsole; then
    konsole --new-tab --workdir "$DIR" -e sh "$INNER" >/dev/null 2>&1 &
    launched 'konsole --new-tab'
fi

# 9. WSL の中の Windows Terminal (wt.exe の実行エイリアスは WSL から直接は呼べないので cmd.exe を通す)
if [ -n "${WT_SESSION:-}" ] && [ -n "${WSL_DISTRO_NAME:-}" ] && have cmd.exe; then
    (cd /mnt/c && cmd.exe /c wt.exe -w 0 new-tab --reloadEnvironment wsl.exe -d "$WSL_DISTRO_NAME" --cd "$DIR" -- sh "$INNER") \
        && launched 'Windows Terminal (WSL から)'
    manual 'wt.exe を起動できなかった'
fi

manual "対応していないターミナル (TERM_PROGRAM=${TERM_PROGRAM:-なし})"
