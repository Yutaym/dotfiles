#!/usr/bin/env bash
# すべての環境で必須のアプリ (nvm と Node.js の LTS、uv) をインストールする (Linux / macOS 向け)
# 入っているものはスキップするので、何度実行してもよい
set -euo pipefail

NVM_VERSION="v0.40.8"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*)
        echo "[error] Windows では install_essentials.ps1 を使ってください" >&2
        exit 1
        ;;
esac

if ! command -v curl >/dev/null 2>&1; then
    echo "[error] curl が必要です" >&2
    exit 1
fi

# nvm
# PROFILE=/dev/null で .zshrc などに読み込み行を足さない (zsh は zsh_config の oh-my-zsh の nvm プラグインが遅延読み込みする)
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "[skip] nvm ($NVM_DIR)"
else
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
    echo "[install] nvm $NVM_VERSION ($NVM_DIR)"
fi

# Node.js (nvm の default が無ければ LTS を入れて default にする)
# nvm.sh は未定義の変数を参照するため、set -u を外して読み込む
set +u
. "$NVM_DIR/nvm.sh"
if [ "$(nvm version default)" != "N/A" ]; then
    echo "[skip] node $(nvm version default) (nvm default)"
else
    nvm install --lts
    nvm alias default 'lts/*'
    echo "[install] node $(nvm version default) (nvm default)"
fi
set -u

# uv (公式のインストーラー。~/.local/bin に入れ、シェルの設定に PATH を追加する)
if command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]; then
    echo "[skip] uv"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "[install] uv"
fi

echo "[done] 新しいシェルを開くと nvm / node / uv が使えます"
