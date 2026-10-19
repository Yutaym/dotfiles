# GitHub Copilot CLI (copilot コマンド) でコマンドの提案 (ghcs)・説明 (ghce) を行う
# 旧 gh copilot 拡張 (gh copilot suggest / explain) は 2025-10 に提供が終わったため、後継の Copilot CLI の非対話モード (-p) を使う
# インストール: npm install -g @github/copilot (Node.js 22 以上)。初回は copilot を起動して /login でログインする
# --allow-tool を付けないので、Copilot にファイルの編集やコマンドの実行はさせない (提案されたコマンドを実行するかは ghcs で確認する)
# https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically
_copilot_prompt() {
    if ! (( $+commands[copilot] )); then
        echo "copilot (GitHub Copilot CLI) が見つかりません。npm install -g @github/copilot でインストールしてください" >&2
        return 1
    fi
    # -s: セッションの情報を出さず回答だけを出力する、--no-ask-user: 聞き返さずに回答させる
    local output
    if ! output="$(copilot -p "$1" -s --no-ask-user)"; then
        echo "copilot が失敗しました。未ログインなら copilot を起動して /login を実行してください" >&2
        return 1
    fi
    print -r -- "$output"
}

# 使い方: ghcs [-t shell|gh|git] <やりたいこと>
# 提案されたコマンドを表示し、y で実行する。実行しなくても履歴に追加するので、↑ で呼び出して編集できる
ghcs() {
    local target="shell" opt OPTARG OPTIND
    while getopts "ht:" opt; do
        case "$opt" in
            h) echo "usage: ghcs [-t shell|gh|git] <やりたいこと>"; return 0 ;;
            t) target="$OPTARG" ;;
            *) return 1 ;;
        esac
    done
    shift "$((OPTIND-1))"

    local kind
    case "$target" in
        gh) kind="a GitHub CLI (gh) command" ;;
        git) kind="a git command" ;;
        shell) kind="a zsh command line on $(uname -s)" ;;
        *) echo "ghcs: -t は shell / gh / git のどれかを指定してください" >&2; return 1 ;;
    esac

    local text="$*"
    if [[ -z "$text" ]]; then
        read -r "text?やりたいことを入力してください: "
        [[ -z "$text" ]] && return 1
    fi

    local output cmd
    output="$(_copilot_prompt "Suggest $kind for the following task. Reply with only the command itself, with no explanation, no Markdown and no code fences. If several commands are needed, join them into one line. Task: $text")" || return 1
    # 指示に反してコードブロックで返ってきた場合に備えて、``` の行と空行を除く
    cmd="$(print -r -- "$output" | grep -v '^[[:space:]]*```' | sed '/^[[:space:]]*$/d')"
    [[ -z "$cmd" ]] && return 1

    printf '\n    \e[36m%s\e[0m\n\n' "$cmd"
    print -s -- "$cmd"
    local answer
    read -r "answer?実行しますか? [y/N] (実行しない場合も ↑ で呼び出せます) "
    if [[ "$answer" == [yY]* ]]; then
        eval -- "$cmd"
    fi
}

# 使い方: ghce <コマンド>
# コマンドの意味を日本語で説明させる
ghce() {
    if [[ $# -eq 0 ]]; then
        echo "usage: ghce <説明してほしいコマンド>" >&2
        return 1
    fi
    _copilot_prompt "Explain in Japanese what the following command does, briefly, part by part. Do not run it. Command: $*"
}


#cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
#peco
function peco-history-selection() {
    # fc -r で新しい順に出す(tac は macOS に無いため使わない)
    BUFFER=$(fc -lnr 1 | awk '!a[$0]++' | peco)
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N peco-history-selection
bindkey '^R' peco-history-selection

function peco-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]* *//' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N peco-cdr
bindkey '^T' peco-cdr

function peco-ghq-look () {
    # .git の更新日時が新しい順に並べる。
    # 更新日時は zsh の zstat で取る(ls --time-style は GNU 専用で macOS では使えないため)
    zmodload -F zsh/stat b:zstat || return
    local -a roots lines
    local -A full st
    local repo rel root
    roots=(${(f)"$(ghq root --all)"})
    for repo in ${(f)"$(ghq list --full-path)"}; do
        st=()
        zstat -H st -- "$repo/.git" 2>/dev/null || continue
        rel=$repo
        for root in $roots; do rel=${rel#$root/}; done
        full[$rel]=$repo
        lines+=("$st[mtime] $rel")
    done
    local selected=$(print -rl -- ${(On)lines} | cut -d' ' -f2- | peco --prompt="cd-ghq >" --query "$LBUFFER")
    if [[ -n "$selected" && -n "$full[$selected]" ]]; then
        BUFFER="cd ${(q)full[$selected]}"
        zle accept-line
    fi
}
zle -N peco-ghq-look
bindkey '^G' peco-ghq-look

mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ファイルの検索と編集
fe() {
  local file
  file=$(find . -type f | fzf) && ${EDITOR:-vim} "$file"
}

# プロセスの検索と終了
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# 通常のClaude (Anthropic API)
function claude-anthropic() {
  unset ANTHROPIC_AUTH_TOKEN
  unset ANTHROPIC_BASE_URL
  export ANTHROPIC_API_KEY="your-actual-api-key"
  echo "→ Anthropic API mode"
  claude "$@"
}

# Ollama経由
# 接続先は CLAUDE_OLLAMA_URL(既定値は zshrc_main.sh で設定)
function claude-ollama() {
  export ANTHROPIC_AUTH_TOKEN=ollama
  export ANTHROPIC_API_KEY=""
  export ANTHROPIC_BASE_URL="${CLAUDE_OLLAMA_URL:-http://localhost:11434}"
  echo "→ Ollama mode"
  claude --model qwen3.5 "$@"
}
