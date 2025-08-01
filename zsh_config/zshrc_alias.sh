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
alias ls='ls -G'
alias la='ls -a'
alias ll='ls -lh'
alias lla='ls -alh'
alias lsgr='ls -a | grep -E'

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
