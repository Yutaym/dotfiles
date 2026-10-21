#!/usr/bin/env bash
# Neovim のインストールと設定ファイルのリンクを行う (Linux x86_64 向け)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="$HOME/.local"
NVIM_BIN_DIR="$INSTALL_PREFIX/bin"
NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

# ---------------------------------------------------------------
# 1. nvim のインストール (インストール済みならスキップ)
# ---------------------------------------------------------------
if command -v nvim >/dev/null 2>&1 || [ -x "$NVIM_BIN_DIR/nvim" ]; then
    echo "[skip] nvim is already installed: $(command -v nvim || echo "$NVIM_BIN_DIR/nvim")"
else
    echo "[install] nvim -> $INSTALL_PREFIX"
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
    curl -fL -o "$TMP_DIR/nvim.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    tar -C "$TMP_DIR" -xzf "$TMP_DIR/nvim.tar.gz"
    mkdir -p "$INSTALL_PREFIX"
    cp -r "$TMP_DIR"/nvim-linux-x86_64/* "$INSTALL_PREFIX"/
fi

# ---------------------------------------------------------------
# 2. PATH の確認 (通っていなければシェルの rc に追記)
# ---------------------------------------------------------------
case ":$PATH:" in
    *":$NVIM_BIN_DIR:"*)
        echo "[skip] $NVIM_BIN_DIR is already in PATH"
        ;;
    *)
        if command -v nvim >/dev/null 2>&1; then
            echo "[skip] nvim is available via PATH: $(command -v nvim)"
        else
            PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
            for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
                [ -f "$rc" ] || continue
                if grep -qF "$PATH_LINE" "$rc"; then
                    echo "[skip] PATH setting already exists in $rc"
                else
                    printf '\n# Neovim (added by install_nvim.sh)\n%s\n' "$PATH_LINE" >>"$rc"
                    echo "[add] PATH setting -> $rc"
                fi
            done
            export PATH="$NVIM_BIN_DIR:$PATH"
            echo "[info] シェルを再起動するか 'source ~/.zshrc' で PATH を反映してください"
        fi
        ;;
esac

# ---------------------------------------------------------------
# 3. 設定ファイルのシンボリックリンク作成
# ---------------------------------------------------------------
mkdir -p "$NVIM_CONFIG_DIR"

for name in init.lua lua .textlintrc.json; do
    src="$SCRIPT_DIR/$name"
    dst="$NVIM_CONFIG_DIR/$name"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "[skip] $dst -> $src"
        continue
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "[warn] $dst already exists. skipped." >&2
        continue
    fi
    ln -s "$src" "$dst"
    echo "[link] $dst -> $src"
done

echo "[done] nvim version: $(nvim --version | head -n1)"
