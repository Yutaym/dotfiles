# aliases
# git
alias g='git'
alias gs='git status'
alias gb='git branch'
alias gc= 'git clone'
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
