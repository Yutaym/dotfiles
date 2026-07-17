# oh-my-zsh configuration and external plugins setup
# oh-my-zsh installation and core settings
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_THEME=""
# ZSH_THEME="robbyrussell"

# compaudit(fpath内の各ディレクトリの権限チェック)を無効化して起動を高速化する。
# WSLのマウント越しだと特に遅く、実測で1秒以上かかっていたため。
ZSH_DISABLE_COMPFIX="true"

# nvmプラグインの初期化(nvm.sh読み込み + .nvmrc自動切り替え)を起動時ではなく、
# 実際に nvm/node/npm/npx 等を初めて使ったタイミングまで遅延させる。
# (未設定だと起動のたびに数秒かかる)
zstyle ':omz:plugins:nvm' lazy yes

# oh-my-zsh plugins
plugins=(
    aliases
    alias-finder
    colored-man-pages
    colorize
    command-not-found
    common-aliases
    copybuffer
    copyfile
    dotenv
    direnv
    # autoenv
    cp
    extract
    encode64
    fancy-ctrl-z
    history
    jsontools
    history-substring-search
    # magic-enter
    man
    per-directory-history
    sudo
    universalarchive
    thefuck
    z
    zsh-navigation-tools
    zsh-interactive-cd
	git
    git-auto-fetch
    git-extras
    # gitfast
    git-flow
    github
    gitignore
    git-prompt
    gh
    python
    pip
    uv
    gcloud
	docker
	docker-compose
	node
	npm
    nvm
    deno
    ufw
    systemd
    systemadmin
    rsync
    ssh
    ssh-agent
    mosh
    tmux
    perms
	yarn
	brew
	macos
	vscode
)

# Auto install oh-my-zsh if not already installed
if [ ! -d "$ZSH" ] && [[ -o interactive ]]; then
	if command -v curl >/dev/null 2>&1; then
		echo "Installing oh-my-zsh into $ZSH"
		export RUNZSH=no
		export CHSH=no
		export KEEP_ZSHRC=yes
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		echo "curl is required to install oh-my-zsh" >&2
	fi
fi

# Source oh-my-zsh
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
	source "$ZSH/oh-my-zsh.sh"
fi

# External plugins setup
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# zsh-autosuggestions
_plugin_autosuggestions="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ ! -d "$_plugin_autosuggestions" ] && [[ -o interactive ]]; then
	if command -v git >/dev/null 2>&1; then
		echo "Installing zsh-autosuggestions..."
		git clone https://github.com/zsh-users/zsh-autosuggestions "$_plugin_autosuggestions"
	fi
fi
[ -f "$_plugin_autosuggestions/zsh-autosuggestions.zsh" ] && source "$_plugin_autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting
_plugin_syntax="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ ! -d "$_plugin_syntax" ] && [[ -o interactive ]]; then
	if command -v git >/dev/null 2>&1; then
		echo "Installing zsh-syntax-highlighting..."
		git clone https://github.com/zsh-users/zsh-syntax-highlighting "$_plugin_syntax"
	fi
fi
[ -f "$_plugin_syntax/zsh-syntax-highlighting.zsh" ] && source "$_plugin_syntax/zsh-syntax-highlighting.zsh"

# fzf
_fzf_home="${FZF_HOME:-$HOME/.fzf}"
if [ ! -d "$_fzf_home" ] && [[ -o interactive ]]; then
	if command -v git >/dev/null 2>&1; then
		echo "Installing fzf..."
		git clone --depth 1 https://github.com/junegunn/fzf.git "$_fzf_home"
	fi
fi
[ -f "$_fzf_home/shell/completion.zsh" ] && source "$_fzf_home/shell/completion.zsh"
[ -f "$_fzf_home/shell/key-bindings.zsh" ] && source "$_fzf_home/shell/key-bindings.zsh"
