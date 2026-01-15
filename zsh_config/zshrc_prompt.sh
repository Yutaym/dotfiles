# prompt
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{3}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{1}+"
zstyle ':vcs_info:*' formats "%F{2}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }
PROMPT='%B%F{2}%n@%m%f%b %F{4}[%D %*]%f ${vcs_info_msg_0_}%B%F{7}%~%f%b
%F{4}->%f '

if (which zprof > /dev/null 2>&1) ;then
  zprof
fi
