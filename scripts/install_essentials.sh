#!/usr/bin/env bash
# すべての環境で必須のアプリ (nvm と Node.js の LTS、npm のグローバルパッケージ、uv、GitHub Copilot CLI) をインストールする (Linux / macOS 向け)
# git は sudo が要るのでインストールせず、無ければ警告だけ出す
# 入っているものはスキップするので、何度実行してもよい
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVM_VERSION="v0.40.8"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# Copilot CLI を npm で入れるときの要件に合わせて、これより古い node は LTS に入れ替える
MIN_NODE_MAJOR=22
NPM_PACKAGES_FILE="$SCRIPT_DIR/npm_global_packages.txt"

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

# git (インストールは各パッケージマネージャにゆだねる)
if command -v git >/dev/null 2>&1; then
    echo "[skip] git"
else
    echo "[warn] git is not installed. パッケージマネージャ (apt / brew など) でインストールしてください" >&2
fi

# nvm
# PROFILE=/dev/null で .zshrc などに読み込み行を足さない (zsh は zsh_config の oh-my-zsh の nvm プラグインが遅延読み込みする)
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "[skip] nvm ($NVM_DIR)"
else
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
    echo "[install] nvm $NVM_VERSION ($NVM_DIR)"
fi

# Node.js (nvm の default が無いか古ければ、LTS を入れて default にする)
# nvm.sh は未定義の変数を参照するため、set -u を外して読み込む
set +u
. "$NVM_DIR/nvm.sh"
# default が無いと nvm version は N/A を出して 3 で終わるため、set -e で止まらないようにする
default_version="$(nvm version default || true)"
default_major="${default_version#v}"
default_major="${default_major%%.*}"
if [ "$default_version" != "N/A" ] && [ "$default_major" -ge "$MIN_NODE_MAJOR" ]; then
    echo "[skip] node $default_version (nvm default)"
else
    if [ "$default_version" != "N/A" ]; then
        echo "[info] node $default_version は $MIN_NODE_MAJOR より古いため、LTS に切り替えます"
    fi
    nvm install --lts
    nvm alias default 'lts/*'
    echo "[install] node $(nvm version default) (nvm default)"
fi
# 以降の npm は nvm の default の node で動かす
nvm use default >/dev/null
set -u

# npm のグローバルパッケージ (nvm の node に、入っていないものだけを入れる)
installed="$(npm ls -g --depth=0 --json 2>/dev/null |
    node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(Object.keys(JSON.parse(s||"{}").dependencies||{}).join("\n")))' || true)"
missing=()
total=0
while IFS= read -r spec; do
    spec="${spec%%#*}"
    spec="$(echo "$spec" | tr -d '[:space:]')"
    [ -n "$spec" ] || continue
    total=$((total + 1))
    case "$spec" in
        github:*) name="${spec##*/}" ;;
        *) name="$spec" ;;
    esac
    if ! printf '%s\n' "$installed" | grep -qxF "$name"; then
        missing+=("$spec")
    fi
done <"$NPM_PACKAGES_FILE"
if [ "${#missing[@]}" -eq 0 ]; then
    echo "[skip] npm global packages ($total)"
else
    npm install -g "${missing[@]}"
    echo "[install] npm global packages: ${missing[*]}"
fi

# uv (公式のインストーラー。~/.local/bin に入れ、シェルの設定に PATH を追加する)
if command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]; then
    echo "[skip] uv"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "[install] uv"
fi

# GitHub Copilot CLI (ghcs / ghce で使う。初回は copilot を起動して /login でログインする)
# nvm の node に npm で入れる (Node.js 22 以上が必要)
if command -v copilot >/dev/null 2>&1; then
    echo "[skip] copilot"
else
    npm install -g @github/copilot
    echo "[install] copilot"
fi

echo "[done] 新しい zsh を開くと nvm / node / uv / copilot が使えます (bash では nvm を読み込まないため、node と npm のパッケージは使えません)"
