#!/bin/sh
# ssh の接続先で、Remote Control つきの Claude Code を名前付きで起動する (macOS / Linux / WSL 用)
#
# 使い方:
#   sh launch-session-ssh.sh -h <接続先> -n <セッション名> [-d <接続先のフォルダ>] [-T] [-s] [-b]
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
while getopts 'h:n:d:Tsb' opt; do
    case "$opt" in
        h) TARGET=$OPTARG ;;
        n) NAME=$OPTARG ;;
        d) DIR=$OPTARG ;;
        T) NOTMUX=1 ;;
        s) PASS="$PASS -s" ;;
        b) PASS="$PASS -b" ;;
        *) echo "usage: $0 -h target -n name [-d dir] [-T] [-s] [-b]" >&2; exit 64 ;;
    esac
done
[ -n "$TARGET" ] && [ -n "$NAME" ] || { echo "usage: $0 -h target -n name [-d dir] [-T] [-s] [-b]" >&2; exit 64; }

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

CLAUDE="claude --name $NAME --remote-control"
if [ "$NOTMUX" = 1 ]; then
    BODY="mkdir -p $DIR && cd $DIR || exit 1; $CLAUDE"
else
    BODY="mkdir -p $DIR && cd $DIR || exit 1; if command -v tmux >/dev/null 2>&1; then exec tmux new-session -A -s $NAME \"\$SHELL -lic \\\"$CLAUDE\\\"\"; else $CLAUDE; fi"
fi
REMOTE="exec \"\$SHELL\" -lic '$BODY'"

LAUNCHER="$(dirname "$0")/../../ssh-generate/scripts/launch-ssh.sh"
# shellcheck disable=SC2086
exec sh "$LAUNCHER" $PASS -c "$REMOTE" -t "$NAME" "$TARGET"
