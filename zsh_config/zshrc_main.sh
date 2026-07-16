export PATH="$HOME/.local/bin:$PATH"

local SCRIPT_DIR=$(cd $(dirname $0) ; pwd)/

#competition
# fpathの追加はoh-my-zsh読み込み(内部でcompinitを実行する)より前に行う必要がある
if [ -e /usr/local/share/zsh-completions ]; then
    fpath=(/usr/local/share/zsh-completions $fpath)
fi

source ${SCRIPT_DIR}/zshrc_ohmyzsh.sh

# compinitはoh-my-zsh側(oh-my-zsh.sh)で既に実行済みのため、ここで再実行しない。
# 二重に実行すると、nvmプラグインがbashcompinit経由で登録した補完が失われる。
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=1
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*:*:cd:*:*' menu select=1
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*' list-colors "${LS_COLORS}"
# Repeated Tab cycles through candidates (including directories).
setopt auto_menu
setopt menu_complete
# Force Tab cycling behavior in completion menus.
bindkey '^I' menu-complete
bindkey '^[[Z' reverse-menu-complete
setopt correct
setopt complete_in_word
setopt auto_pushd
setopt pushd_ignore_dups

#color
autoload -Uz colors
colors

#histry
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

### optioon
setopt print_eight_bit
setopt auto_cd
setopt no_beep
setopt nolistbeep
setopt auto_pushd
setopt IGNOREEOF
setopt no_flow_control

setopt extended_glob
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars "_-./;@"
zstyle ':zle:*' word-style unspecified

export EDITOR="vim"

source ${SCRIPT_DIR}/zshrc_function.sh
source ${SCRIPT_DIR}/zshrc_alias.sh
source ${SCRIPT_DIR}/zshrc_prompt.sh
