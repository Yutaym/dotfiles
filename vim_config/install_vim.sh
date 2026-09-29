#!/usr/bin/env bash
# Vim の設定ファイルのリンクを行う (Linux / macOS 向け)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------
# 1. vim の確認 (インストールは各パッケージマネージャにゆだねる)
# ---------------------------------------------------------------
if command -v vim >/dev/null 2>&1; then
    echo "[ok] vim is installed: $(command -v vim)"
else
    echo "[warn] vim is not installed. パッケージマネージャ (apt / brew など) でインストールしてください" >&2
fi

# ---------------------------------------------------------------
# 2. 設定ファイルのシンボリックリンク作成
# ---------------------------------------------------------------
src="$SCRIPT_DIR/.vimrc"
dst="$HOME/.vimrc"
if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "[skip] $dst -> $src"
elif [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "[warn] $dst already exists. skipped." >&2
else
    ln -s "$src" "$dst"
    echo "[link] $dst -> $src"
fi

if command -v vim >/dev/null 2>&1; then
    echo "[done] vim version: $(vim --version | head -n1)"
else
    echo "[done]"
fi
