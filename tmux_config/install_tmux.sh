#!/usr/bin/env bash
# tmux の設定ファイルのリンクを行う (Linux / macOS 向け)
# 設定ファイルは ~/.config/tmux/tmux.conf に置く (tmux_config 内のリロード・プラグインのパスがこの場所を前提にしている)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_DIR="$HOME/.config/tmux"
TPM_DIR="$TMUX_DIR/.tmux/plugins/tpm"

# ---------------------------------------------------------------
# 1. tmux の確認 (インストールは各パッケージマネージャにゆだねる)
# ---------------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
    echo "[ok] tmux is installed: $(command -v tmux)"
else
    echo "[warn] tmux is not installed. パッケージマネージャ (apt / brew など) でインストールしてください" >&2
fi

# ---------------------------------------------------------------
# 2. 設定ファイルのシンボリックリンク作成
# ---------------------------------------------------------------
mkdir -p "$TMUX_DIR"

src="$SCRIPT_DIR/.tmux.conf"
dst="$TMUX_DIR/tmux.conf"
if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "[skip] $dst -> $src"
elif [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "[warn] $dst already exists. skipped." >&2
else
    ln -s "$src" "$dst"
    echo "[link] $dst -> $src"
fi

# ~/.tmux.conf があると ~/.config/tmux/tmux.conf より優先して読み込まれる
if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    echo "[warn] $HOME/.tmux.conf exists. こちらが優先して読み込まれるため、不要なら削除してください" >&2
fi

# ---------------------------------------------------------------
# 3. TPM (tmux plugin manager) の確認 (なければ clone する)
# ---------------------------------------------------------------
if [ -d "$TPM_DIR" ]; then
    echo "[skip] tpm already exists: $TPM_DIR"
elif command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "[clone] tpm -> $TPM_DIR"
    echo "[info] tmux を起動して Prefix (Ctrl-q) + I でプラグインをインストールしてください"
else
    echo "[warn] git is not installed. tpm の clone をスキップしました" >&2
fi

if command -v tmux >/dev/null 2>&1; then
    echo "[done] tmux version: $(tmux -V)"
else
    echo "[done]"
fi
