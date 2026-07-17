export PATH="$HOME/.local/bin:$PATH"

# PATHの重複を自動的に除去する(pathはPATHと連動するzshの特殊配列、-Uでユニーク化)
typeset -U path

local SCRIPT_DIR=$(cd $(dirname $0) ; pwd)/
source ${SCRIPT_DIR}/zshrc_env.sh


#competition
# fpathの追加はoh-my-zsh読み込み(内部でcompinitを実行する)より前に行う必要がある
if [ -e /usr/local/share/zsh-completions ]; then
    fpath=(/usr/local/share/zsh-completions $fpath)
fi

source ${SCRIPT_DIR}/zshrc_ohmyzsh.sh

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
setopt pushd_ignore_dups
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
source ${SCRIPT_DIR}/zshrc_completion.sh
