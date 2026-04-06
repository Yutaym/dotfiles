# aliases
# git
alias g='git'
alias gs='git status'
alias gb='git branch'
alias gc='git clone'
alias gco='git checkout'
alias gct='git commit -m'
alias gg='git grep'
alias ga='git add'
alias gd='git diff'
alias gcma='git checkout master'
alias gfu='git fetch upstream'
alias gfo='git fetch origin'
alias gmod='git merge origin/develop'
alias gmud='git merge upstream/develop'
alias gmom='git merge origin/master'
alias gcm='git commit -m'
alias gpo='git push origin'
alias gpom='git push origin master'
alias gst='git stash'
alias gsl='git stash list'
alias gsu='git stash -u'
alias gsp='git stash pop'

alias gl='git log --abbrev-commit --no-merges --date=short --date=iso'
alias glg='git log --abbrev-commit --no-merges --date=short --date=iso --grep'
alias glc='git log --abbrev-commit --no-merges --date=short --date=iso origin/html..html'

#vim
alias v='nvim'
alias vi='nvim'
alias nv='nvim'

#vscode
alias codef='code ./'
alias co='code ./'

#ls
alias ls='ls -G --color=auto'
alias la='ls -a --color=auto'
alias ll='ls -lh --color=auto'
alias lla='ls -alh --color=auto'
alias lal='ls -alh --color=auto'
alias lsgr='ls -a  --color=auto | grep -E'

#one commands
alias c='clear'
alias h='history'
alias B='./build'
alias lns='ln -snf'
alias pandoc='/usr/local/bin/pandoc'
#other commands
alias tree="pwd;find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'"
alias pwdc='pwd | tr -d "\n" | pbcopy'
alias gr='grep -E'
alias chx='chmod +x'
#zsh
alias vzsh='nvim ~/.zshrc'
alias szsh='source ~/.zshrc'

ghcs() {
    local FUNCNAME="ghcs"
    local TARGET="shell"
    local GH_DEBUG="$GH_DEBUG"
    local GH_HOST="$GH_HOST"

    __USAGE=$(cat <<'EOF'
Wrapper around `gh copilot suggest` to suggest a command based on a natural language description of the desired output effort.
Supports executing suggested commands if applicable.

USAGE
  ghcs [flags] <prompt>

FLAGS
  -d, --debug           Enable debugging
  -h, --help            Display help usage
      --hostname        The GitHub host to use for authentication
  -t, --target target   Target for suggestion; must be shell, gh, git
                        default: "shell"

EXAMPLES

- Guided experience
  $ ghcs

- Git use cases
  $ ghcs -t git "Undo the most recent local commits"
  $ ghcs -t git "Clean up local branches"
  $ ghcs -t git "Setup LFS for images"

- Working with the GitHub CLI in the terminal
  $ ghcs -t gh "Create pull request"
  $ ghcs -t gh "List pull requests waiting for my review"
  $ ghcs -t gh "Summarize work I have done in issues and pull requests for promotion"

- General use cases
  $ ghcs "Kill processes holding onto deleted files"
  $ ghcs "Test whether there are SSL/TLS issues with github.com"
  $ ghcs "Convert SVG to PNG and resize"
  $ ghcs "Convert MOV to animated PNG"
EOF
)

    local OPT OPTARG OPTIND
    while getopts "dht:-:" OPT; do
        if [ "$OPT" = "-" ]; then
            OPT="${OPTARG%%=*}"
            OPTARG="${OPTARG#"$OPT"}"
            OPTARG="${OPTARG#=}"
        fi

        case "$OPT" in
            debug | d)
                GH_DEBUG=api
                ;;
            help | h)
                echo "$__USAGE"
                return 0
                ;;
            hostname)
                GH_HOST="$OPTARG"
                ;;
            target | t)
                TARGET="$OPTARG"
                ;;
        esac
    done

    shift "$((OPTIND-1))"

    TMPFILE="$(mktemp -t gh-copilotXXXXXX)"
    trap 'rm -f "$TMPFILE"' EXIT
    if GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot suggest -t "$TARGET" "$@" --shell-out "$TMPFILE"; then
        if [ -s "$TMPFILE" ]; then
            FIXED_CMD="$(cat "$TMPFILE")"
            print -s -- "$FIXED_CMD"
            echo
            eval -- "$FIXED_CMD"
        fi
    else
        return 1
    fi
}

ghce() {
    local FUNCNAME="ghce"
    local GH_DEBUG="$GH_DEBUG"
    local GH_HOST="$GH_HOST"

    __USAGE=$(cat <<'EOF'
Wrapper around `gh copilot explain` to explain a given input command in natural language.

USAGE
  ghce [flags] <command>

FLAGS
  -d, --debug      Enable debugging
  -h, --help       Display help usage
      --hostname   The GitHub host to use for authentication

EXAMPLES

# View disk usage, sorted by size
$ ghce 'du -sh | sort -h'

# View git repository history as text graphical representation
$ ghce 'git log --oneline --graph --decorate --all'

# Remove binary objects larger than 50 megabytes from git history
$ ghce 'bfg --strip-blobs-bigger-than 50M'
EOF
)

    local OPT OPTARG OPTIND
    while getopts "dh-:" OPT; do
        if [ "$OPT" = "-" ]; then
            OPT="${OPTARG%%=*}"
            OPTARG="${OPTARG#"$OPT"}"
            OPTARG="${OPTARG#=}"
        fi

        case "$OPT" in
            debug | d)
                GH_DEBUG=api
                ;;
            help | h)
                echo "$__USAGE"
                return 0
                ;;
            hostname)
                GH_HOST="$OPTARG"
                ;;
        esac
    done

    shift "$((OPTIND-1))"

    GH_DEBUG="$GH_DEBUG" GH_HOST="$GH_HOST" gh copilot explain "$@"
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
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
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
    local ghq_roots="$(git config --path --get-all ghq.root)"
    local selected_dir=$(ghq list --full-path | \
        xargs -I{} ls -dl --time-style=+%s {}/.git | sed 's/.*\([0-9]\{10\}\)/\1/' | sort -nr | \
        sed "s,.*\(${ghq_roots/$'\n'/\|}\)/,," | \
        sed 's/\/.git//' | \
        peco --prompt="cd-ghq >" --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd $(ghq list --full-path | grep --color=never -E "/$selected_dir$")"
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
