#!/bin/sh
# observe.py を動かす (macOS / Linux / WSL 用。launch-observer.sh が、分割したペインや新しいタブの中で実行する)
#
# 使い方:
#   sh run-observer.sh [observe.py の引数 ...]
#
# エラーで終わったときは、ペインやタブがすぐ閉じて原因が見えなくなるので、Enter を押すまで待つ。
# 新しいタブのシェルでは uv に PATH が通っていないことがあるので、ログインシェルの PATH に頼らず ~/.local/bin も足す

PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH
HERE=$(cd "$(dirname "$0")" && pwd)

uv run --no-project --with rich python "$HERE/observe.py" "$@"
code=$?
if [ "$code" -ne 0 ]; then
    printf 'observe.py がエラーで終了した (終了コード %s)。Enter で閉じる' "$code"
    read -r _
fi
