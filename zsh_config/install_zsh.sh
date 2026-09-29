#!/usr/bin/env bash
# zsh の設定ファイルのコピーを行う (Linux / macOS 向け)
# oh-my-zsh やプラグインは初回起動時に zshrc_ohmyzsh.sh が自動でインストールする
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------
# 1. zsh の確認 (インストールは各パッケージマネージャにゆだねる)
# ---------------------------------------------------------------
if command -v zsh >/dev/null 2>&1; then
    echo "[ok] zsh is installed: $(command -v zsh)"
else
    echo "[warn] zsh is not installed. パッケージマネージャ (apt / brew など) でインストールしてください" >&2
fi

# ---------------------------------------------------------------
# 2. 設定ファイルのコピー
# ---------------------------------------------------------------
# 既存ファイルが異なる内容なら、タイムスタンプ付きでバックアップしてから上書きする
copy_config() {
    local src="$1" dst="$2"
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
        echo "[skip] $dst is up to date"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$backup"
        echo "[backup] $dst -> $backup"
    fi
    cp "$src" "$dst"
    echo "[copy] $src -> $dst"
}

# .zshrc は ~/dotfiles/zsh_config/zshrc_main.sh を読み込む前提のため、
# dotfiles が別の場所にある場合は読み込み先を書き換えたものをコピーする
zshrc_src="$SCRIPT_DIR/.zshrc"
if [ "$SCRIPT_DIR" != "$HOME/dotfiles/zsh_config" ]; then
    zshrc_src="$(mktemp)"
    trap 'rm -f "$zshrc_src"' EXIT
    sed "s|~/dotfiles/zsh_config/|$SCRIPT_DIR/|" "$SCRIPT_DIR/.zshrc" > "$zshrc_src"
fi
copy_config "$zshrc_src" "$HOME/.zshrc"
copy_config "$SCRIPT_DIR/.zshenv" "$HOME/.zshenv"

# ---------------------------------------------------------------
# 3. デフォルトシェルの確認 (zsh でなければ変更手順を提案する。変更自体は手動)
# ---------------------------------------------------------------
# $SHELL はセッション開始時の値のため、ユーザーデータベースから現在の設定を読む
get_login_shell() {
    local user shell=""
    user="$(id -un)"
    if command -v getent >/dev/null 2>&1; then
        shell="$(getent passwd "$user" | cut -d: -f7)"
    elif command -v dscl >/dev/null 2>&1; then
        shell="$(dscl . -read "/Users/$user" UserShell 2>/dev/null | awk '{print $2}')"
    fi
    echo "${shell:-${SHELL:-}}"
}

if command -v zsh >/dev/null 2>&1; then
    zsh_path="$(command -v zsh)"
    login_shell="$(get_login_shell)"
    if [ "$(basename "$login_shell")" = "zsh" ]; then
        echo "[skip] default shell is already zsh: $login_shell"
    else
        # 変更は手動で行う方針のため、ここでは手順の提案だけ行う
        echo "[info] default shell is ${login_shell:-unknown} (not zsh)"
        echo "[info] デフォルトシェルを zsh に変更する場合は、以下のコマンドを手動で実行してください"
        # chsh は /etc/shells に載っているシェルしか受け付けない
        if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
            echo "    echo \"$zsh_path\" | sudo tee -a /etc/shells"
        fi
        echo "    chsh -s \"$zsh_path\""
        echo "[info] 変更は再ログイン後に反映されます"
    fi
fi

echo "[done]"
