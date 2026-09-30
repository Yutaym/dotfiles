# aliases
# oh-my-zsh(git / common-aliases プラグインなど)と同じ定義のものはここに書かない。
# ここに書いたものは oh-my-zsh より後に読み込まれるので、同名のエイリアスを上書きする。

# git
alias gs='git status'
alias gc='git clone'
alias gg='git grep'
alias gcma='git checkout master'
alias gfu='git fetch upstream'
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

alias gl='git log --abbrev-commit --no-merges --date=iso'
alias glg='git log --abbrev-commit --no-merges --date=iso --grep'

#vim
alias v='nvim'
alias vi='nvim'

#vscode
alias co='code ./'

#ls
# ls 自体の色付けは oh-my-zsh(lib/theme-and-appearance.zsh)が OS に合わせて設定する
# (GNU は ls --color=tty、macOS は ls -G)。--color は古い macOS の ls に無いのでここでは付けない
alias la='ls -a'
alias ll='ls -lh'
alias lla='ls -alh'
alias lsgr='ls -a | grep -E'

alias lsc='eza --icons --group-directories-first'
alias llc='eza -la --icons --group-directories-first --git'
alias ltc='eza --tree --level=2 --icons'

# シングルクォートにして、定義時ではなく実行時の PATH を表示する
alias lspt='echo $PATH | tr ":" "\n"'


#one commands
alias c='clear'
alias B='./build'
alias lns='ln -snf'
#other commands
alias tree="pwd;find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'"
# clipcopy は oh-my-zsh(lib/clipboard.zsh)の関数で、pbcopy / clip.exe / wl-copy / xclip / xsel などから使えるものを選ぶ
alias pwdc='pwd | tr -d "\n" | clipcopy'
alias gr='grep -E'
alias chx='chmod +x'
#zsh
alias vzsh='nvim ~/.zshrc'
alias szsh='source ~/.zshrc'

alias memodir='cd ~/documents/memo'
