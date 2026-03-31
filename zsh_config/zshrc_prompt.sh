# prompt
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
setopt prompt_subst

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{3}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{1}+"
zstyle ':vcs_info:git:*' formats "[%F{2}%c%u%b%f]"
zstyle ':vcs_info:git:*' actionformats '[%b|%a]'
# precmd () { vcs_info }
add-zsh-hook precmd vcs_info

# venv/conda/uv 環境表示関数（uv優先）
function _python_env_info() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "(%F{2}venv:$VIRTUAL_ENV%f)"   # uv/venv → マゼンタ
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    echo "(%F{2}conda:$CONDA_DEFAULT_ENV%f)"   # conda → 黄色
  fi
}


_cmd_start_time=0

preexec() {
  _cmd_start_time=$SECONDS
}

function _exit_status() {
  local code=$?
  local elapsed=$(( SECONDS - _cmd_start_time ))
  if [[ $code -eq 0 ]]; then
    echo -n "%F{2}"   # 成功（緑チェック）
  else
    echo -n "%F{1}x${code}|"  # 失敗（赤×+コード）
  fi
  [[ $elapsed -ge 3 ]] && echo -n "${elapsed}s "  # 3秒以上のみ表示
  echo -n "%f"
}


function _cmd_elapsed() {
}

# PROMPT='%B%F{2}%n@%m%f%b %F{4}[%D %*]%f ${vcs_info_msg_0_}%B%F{7}%~%f%b
# %F{4}->%f '
export VIRTUAL_ENV_DISABLE_PROMPT=1

# PROMPT='%F{4}WSL:%f $(_python_env_info) %B%F{3}%n@%m%f%b %F{5}[%D %*]%f ${vcs_info_msg_0_}%B%F{6}%~%f%b
# %F{7}->%f '
# 左プロンプト（日時を削除）
PROMPT='%F{4}WSL:%f $(_python_env_info) %B%F{3}%n@%m%f%b ${vcs_info_msg_0_} %B%F{6}%~%f%b $(_exit_status)
%F{7}->%f '

# 右プロンプト（日時を右端に表示）
RPROMPT='%F{2}[%D{%Y/%m/%d %H:%M:%S}]%f'

if (which zprof > /dev/null 2>&1) ;then
    zprof
fi
