#!/bin/sh
# ssh の接続先で、Remote Control つきの Claude Code を名前付きで起動する (macOS / Linux / WSL 用)
#
# 使い方:
#   sh launch-session-ssh.sh -h <接続先> -n <セッション名> [-d <接続先のフォルダ>] [-m <モデル>] [-e <effort>] [-T] [-s] [-b]
#   -m / -e: 接続先の claude --model / --effort に渡す (省略すると接続先の Claude Code の既定)
#   -T: 接続先で tmux を使わない
#   -s / -b: ssh-generate の launch-ssh.sh と同じ (ペイン分割 / 画面を切り替えない)
#
# 接続先で実行するコマンドの組み立て方は launch-session-ssh.ps1 と同じ (説明はそちらに書いた)。

set -eu

TARGET=
NAME=
DIR='~/claudeWS'
NOTMUX=0
PASS=
MODEL=
EFFORT=
USAGE="usage: $0 -h target -n name [-d dir] [-m model] [-e effort] [-T] [-s] [-b]"
while getopts 'h:n:d:m:e:Tsb' opt; do
    case "$opt" in
        h) TARGET=$OPTARG ;;
        n) NAME=$OPTARG ;;
        d) DIR=$OPTARG ;;
        m) MODEL=$OPTARG ;;
        e) EFFORT=$OPTARG ;;
        T) NOTMUX=1 ;;
        s) PASS="$PASS -s" ;;
        b) PASS="$PASS -b" ;;
        *) echo "$USAGE" >&2; exit 64 ;;
    esac
done
[ -n "$TARGET" ] && [ -n "$NAME" ] || { echo "$USAGE" >&2; exit 64; }

# 名前とフォルダは接続先のコマンドにそのまま埋め込むので、引用符や空白を含めない
case "$NAME" in
    ''|-*|*[!A-Za-z0-9_-]*) echo "セッション名には英数字と _ - だけを使ってください: $NAME" >&2; exit 64 ;;
esac
case "$DIR" in
    \~*) rest=${DIR#\~} ;;
    *) rest=$DIR ;;
esac
case "$rest" in
    *[!A-Za-z0-9._/-]*) echo "フォルダには英数字と . _ / - (先頭の ~) だけを使ってください: $DIR" >&2; exit 64 ;;
esac

case "$MODEL" in
    -*|*[!A-Za-z0-9._-]*) echo "-m には英数字と . _ - だけを使ってください (例: opus, claude-opus-5-5): $MODEL" >&2; exit 64 ;;
esac
case "$EFFORT" in
    ''|low|medium|high|xhigh|max) ;;
    *) echo "-e は low / medium / high / xhigh / max のどれかにしてください: $EFFORT" >&2; exit 64 ;;
esac

CLAUDE="claude --name $NAME --remote-control${MODEL:+ --model $MODEL}${EFFORT:+ --effort $EFFORT}"
if [ "$NOTMUX" = 1 ]; then
    BODY="mkdir -p $DIR && cd $DIR || exit 1; $CLAUDE"
else
    # ペインは対話シェルで起動し、claude はキー入力で打ち込む (Ctrl+Z で tmux ごと閉じないように。理由は .ps1 に書いた)
    BODY="mkdir -p $DIR && cd $DIR || exit 1; if command -v tmux >/dev/null 2>&1; then command tmux has-session -t \"=$NAME\" 2>/dev/null || { command tmux new-session -d -s $NAME && command tmux send-keys -t \"=$NAME:\" \"$CLAUDE; exit\" Enter; }; exec tmux attach -t \"=$NAME\"; else $CLAUDE; fi"
fi
REMOTE="exec \"\$SHELL\" -lic '$BODY'"

LAUNCHER="$(dirname "$0")/../../ssh-generate/scripts/launch-ssh.sh"
# shellcheck disable=SC2086
exec sh "$LAUNCHER" $PASS -c "$REMOTE" -t "$NAME" "$TARGET"
