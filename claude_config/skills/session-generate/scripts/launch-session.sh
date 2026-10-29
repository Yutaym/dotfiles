#!/bin/sh
# 新しいターミナルのタブで、独立した Claude Code のセッションを起動する (macOS / Linux / WSL 用)
#
# 使い方:
#   sh launch-session.sh [-d <作業フォルダ>] [-n <セッション名>] [-m <モデル>] [-e <effort>] [-s] [-w] [-W <worktree>] [-L <台帳>] [-T <作業の ID>]
#   -m / -e: claude --model / --effort に渡す (省略すると Claude Code の既定)。モデルは opus などの短い名前を使う
#   -s: tmux の中で、専用ウィンドウをペイン分割して並べる (tmux 以外では無視する)
#   -w: tmux の中で、起動したウィンドウに画面を切り替える (頼む作業がないとき用。tmux 以外では無視する)
#   -W: claude --worktree <名前> で、git の worktree を作ってそこで起動する
#   -L / -T: session-initialize の台帳。起動したセッションに CC_LEDGER / CC_TASK_ID / CC_PARENT_ADDR を設定する
#            (-L を省略すると、呼び出し元の CC_LEDGER を引き継ぐ。CC_PARENT_ADDR は呼び出し元の受信口)
#
# 起動先の選び方 (上から順に、当てはまった最初のもの):
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
# 避けるためと、どの起動先でも Claude のセッション固有の環境変数を確実に消すため。

set -eu

DIR=$(pwd)
DIRSET=0
NAME=''
SPLIT=0
SWITCH=0
MODEL=''
EFFORT=''
WORKTREE=''
LEDGER=${CC_LEDGER:-}
TASKID=''
while getopts 'd:n:m:e:swW:L:T:' opt; do
    case "$opt" in
        d) DIR=$OPTARG; DIRSET=1 ;;
        n) NAME=$OPTARG ;;
        m) MODEL=$OPTARG ;;
        e) EFFORT=$OPTARG ;;
        s) SPLIT=1 ;;
        w) SWITCH=1 ;;
        W) WORKTREE=$OPTARG ;;
        L) LEDGER=$OPTARG ;;
        T) TASKID=$OPTARG ;;
        *) echo "usage: $0 [-d dir] [-n name] [-m model] [-e effort] [-s] [-w] [-W worktree] [-L ledger] [-T task-id]" >&2; exit 64 ;;
    esac
done

# セッション名は SendMessage の宛先になるので、英数字・ハイフン・アンダースコアだけにする
case "$NAME" in
    *[!A-Za-z0-9_-]*) echo "セッション名には英数字・ハイフン・アンダースコアだけを使ってください: $NAME" >&2; exit 64 ;;
esac
# モデルと effort は起動用スクリプトにそのまま書くので、使える文字を絞る
case "$MODEL" in
    -*|*[!A-Za-z0-9._-]*) echo "-m には英数字と . _ - だけを使ってください (例: opus, claude-opus-5-5): $MODEL" >&2; exit 64 ;;
esac
case "$EFFORT" in
    ''|low|medium|high|xhigh|max) ;;
    *) echo "-e は low / medium / high / xhigh / max のどれかにしてください: $EFFORT" >&2; exit 64 ;;
esac
case "$WORKTREE" in
    -*|*[!A-Za-z0-9._-]*) echo "-W には英数字と . _ - だけを使ってください: $WORKTREE" >&2; exit 64 ;;
esac
case "$TASKID" in
    *[!A-Za-z0-9_-]*) echo "-T には英数字・ハイフン・アンダースコアだけを使ってください: $TASKID" >&2; exit 64 ;;
esac
# claude に渡すオプション (セッション名・モデル・effort・worktree)
CLAUDE_OPTS="${NAME:+ -n $NAME}${MODEL:+ --model $MODEL}${EFFORT:+ --effort $EFFORT}${WORKTREE:+ --worktree $WORKTREE}"
# 起動用スクリプトに書くときの引用 ('...' で囲み、中の ' を逃がす)
quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
# フォルダの指定がなく、今のフォルダがホームなら ~/claudeWS にする
# (ホームは信頼の確認が保存されず、起動のたびに聞かれるため)。それ以外は今のフォルダを引き継ぐ
if [ "$DIRSET" = 0 ] && [ "$(pwd -P)" = "$(cd "$HOME" && pwd -P)" ]; then
    DIR=$HOME/claudeWS
fi
# フォルダがなければ作る
if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
    echo "created: $DIR"
fi
DIR=$(cd "$DIR" && pwd)

# 新しいタブで実行する起動用スクリプト。実行後に自分自身を消す
INNER=$(mktemp "${TMPDIR:-/tmp}/cc-launch.XXXXXX")
{
    echo '#!/bin/sh'
    echo 'rm -f -- "$0"'
    echo 'unset CLAUDECODE CLAUDE_PID CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ID CLAUDE_CODE_SESSION_ATTENDED CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_BRIDGE_SESSION_ID'
    printf 'cd %s || exit 1\n' "'$(printf '%s' "$DIR" | sed "s/'/'\\\\''/g")'"
    # 台帳の変数は、指定があるときだけ設定する (返事の宛先は、名前ではなく呼び出し元の受信口のアドレス)
    echo 'unset CC_LEDGER CC_TASK_ID CC_PARENT_ADDR'
    if [ -n "$LEDGER" ]; then
        printf 'export CC_LEDGER=%s\n' "$(quote "$LEDGER")"
        if [ -n "$TASKID" ]; then printf 'export CC_TASK_ID=%s\n' "$TASKID"; fi
        if [ -n "${CLAUDE_CODE_MESSAGING_SOCKET:-}" ]; then printf 'export CC_PARENT_ADDR=%s\n' "$(quote "uds:$CLAUDE_CODE_MESSAGING_SOCKET")"; fi
    fi
    echo "claude$CLAUDE_OPTS"
    # claude を終了してもタブを閉じずに、ログインシェルを残す
    echo 'exec "${SHELL:-/bin/sh}" -l'
} > "$INNER"
chmod +x "$INNER"

have() { command -v "$1" >/dev/null 2>&1; }

launched() {
    echo "launched: $1 / dir=$DIR / name=${NAME:-(自動)} / model=${MODEL:-(既定)} / effort=${EFFORT:-(既定)}${WORKTREE:+ / worktree=$WORKTREE}${LEDGER:+ / ledger=$LEDGER / task=$TASKID}"
    exit 0
}

# tmux で作ったウィンドウ ($1 = セッション名:ウィンドウ番号 または セッション名:ウィンドウ名) に、-w のときだけ切り替える
switch_to() {
    if [ "$SWITCH" = 1 ] && [ -n "$1" ]; then
        tmux select-window -t "$1" && echo "switched: $1"
    fi
    return 0
}

manual() {
    rm -f -- "$INNER"
    echo "このターミナルでは自動でタブを開けませんでした ($1)。新しいタブで次を実行してください:" >&2
    echo "  cd '$DIR' && env -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_SESSION_ID claude$CLAUDE_OPTS" >&2
    exit 2
}

# 1. tmux: 普段は new-window で起動する。どの場合も -d を付けて作り、-w のときだけ最後にそのウィンドウへ切り替える
#    (ウィンドウは名前ではなく new-window -P で受け取った番号で指定する)。
#    -s (分割) を指定したときは、専用ウィンドウ (名前が cc-sessions のもの) に並べる。
#    呼び出し元と同じ tmux セッションに専用ウィンドウがなければ new-window で作り、あれば分割して均等に並べ直す。
#    専用ウィンドウは名前で見分ける (psmux はウィンドウのユーザーオプションを書式で返さないため)。
#    tmux は呼び出し元ではなく tmux サーバーの環境を使う。サーバーを Claude の中から起動していると
#    Claude の変数が残っているが、起動用スクリプトの unset で消える
if [ -n "${TMUX:-}" ] && have tmux; then
    if [ "$SPLIT" = 1 ]; then
        # 場所は「セッション名:ウィンドウ名」で指定する (tmux 互換ソフトでも取り違えないように)
        PANE=${TMUX_PANE:-}
        SNAME=$(tmux display-message -p ${PANE:+-t "$PANE"} '#{session_name}')
        if tmux list-windows -t "$SNAME" -F '#{window_name}' | grep -qx cc-sessions; then
            tmux split-window -d -t "$SNAME:cc-sessions" -c "$DIR" "sh '$INNER'" || manual 'tmux split-window が失敗した'
            tmux select-layout -t "$SNAME:cc-sessions" tiled
            switch_to "$SNAME:cc-sessions"
            launched 'tmux split-window (専用ウィンドウ)'
        fi
        W=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -t "$SNAME:" -c "$DIR" -n cc-sessions "sh '$INNER'") \
            || manual 'tmux new-window が失敗した'
        switch_to "$W"
        launched 'tmux new-window (専用ウィンドウを作成)'
    fi
    W=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' -c "$DIR" ${NAME:+-n "$NAME"} "sh '$INNER'") \
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
