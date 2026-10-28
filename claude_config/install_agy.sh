#!/usr/bin/env bash
# Antigravity CLI（agy）を導入する (Linux / macOS 向け)
# Google の公式インストーラ (https://antigravity.google/download に載っているもの) を一時ファイルに取得し、中身を確認できるようにしてから実行する
# ログインはブラウザが要るので、このスクリプトでは行わない。導入後に対話型の `agy` を 1 回起動して行う
set -euo pipefail

URL="https://antigravity.google/cli/install.sh"

if command -v agy >/dev/null 2>&1; then
    echo "[skip] agy は導入済み: $(command -v agy) ($(agy --version 2>&1 | head -n 1))"
    exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$URL" -o "$tmp/install.sh"
echo "[get] $URL -> $tmp/install.sh ($(wc -c < "$tmp/install.sh") bytes)"

if [ "${1:-}" != "--yes" ]; then
    echo "[info] 実行前に内容を確認できます: less $tmp/install.sh  (別の端末で開く)"
    printf "このインストーラを実行しますか？ [y/N] "
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "[abort] 実行しませんでした"; exit 1; }
fi

bash "$tmp/install.sh"

echo "[done] 端末を開き直して（PATH の反映）、対話型の agy を 1 回起動してブラウザでログインしてください"
echo "       確認: agy -p \"日本の首都を一語で\""
