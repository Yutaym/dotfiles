#!/bin/sh
# 引数のスクリプト（省略時は statusline.mjs）を node で実行する。settings.json の statusLine / subagentStatusLine から呼ぶ
# zsh の nvm 遅延読み込みなどで node が PATH に無いときは、nvm で入れた一番新しい node を使う
dir=$(dirname "$0")
script="$dir/${1:-statusline.mjs}"
if command -v node >/dev/null 2>&1; then
    exec node "$script"
fi
nvm_dir="${NVM_DIR:-$HOME/.nvm}"
ver=$(ls "$nvm_dir/versions/node" 2>/dev/null | sed -n 's/^v//p' | sort -t . -k1,1n -k2,2n -k3,3n | tail -n 1)
bin="$nvm_dir/versions/node/v$ver/bin/node"
[ -n "$ver" ] && [ -x "$bin" ] && exec "$bin" "$script"
cat >/dev/null
echo "statusline: node が見つかりません"
