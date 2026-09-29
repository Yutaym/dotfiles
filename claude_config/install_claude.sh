#!/usr/bin/env bash
# Claude Code の設定ファイルのリンクを行う (Linux / macOS 向け)
# local-paths.md は環境ごとに編集するためコピーで配置する (settings.local.json などは管理対象外)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
FILES=(CLAUDE.md settings.json keybindings.json)

mkdir -p "$CLAUDE_DIR"

for name in "${FILES[@]}"; do
    src="$SCRIPT_DIR/$name"
    dst="$CLAUDE_DIR/$name"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "[skip] $dst -> $src"
    elif [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "[warn] $dst already exists. skipped." >&2
    else
        ln -s "$src" "$dst"
        echo "[link] $dst -> $src"
    fi
done

# local-paths.md は環境ごとに編集するためリンクではなくコピーする (既存なら上書きしない)
src="$SCRIPT_DIR/local-paths.md"
dst="$CLAUDE_DIR/local-paths.md"
if [ -e "$dst" ]; then
    echo "[skip] $dst already exists"
else
    cp "$src" "$dst"
    echo "[copy] $src -> $dst"
    echo "[info] 必要に応じて ~/.claude/local-paths.md のパス (META_DIR など) をこの環境向けに編集してください"
fi

echo "[done]"
