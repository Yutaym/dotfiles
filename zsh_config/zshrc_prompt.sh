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

add_newline() {
  if [[ -z $PS1_NEWLINE_LOGIN ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}

# venv/conda/uv 環境表示関数（uv優先）
function _python_env_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "(%F{2}venv:$(basename $VIRTUAL_ENV)%f)"
    elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        echo "(%F{2}conda:$CONDA_DEFAULT_ENV%f)"
    fi
}

export VIRTUAL_ENV_DISABLE_PROMPT=1

# 実行時間計測
_cmd_start_time=0
preexec() {
    _cmd_start_time=$SECONDS
}

# ★ precmd でまとめて処理（$? の退避が最優先）
precmd() {
    # ① 必ず最初に $? と経過時間を保存
    local last_status=$?
    local elapsed=$(( SECONDS - _cmd_start_time ))
    _cmd_start_time=0   # リセット

    # ② vcs_info を実行（$? が上書きされるが問題ない）
    vcs_info

    # ③ 終了ステータス文字列を変数に組み立てる
    local status_str=""
    if [[ $last_status -eq 0 ]]; then
        status_str="%F{2}"
        [[ $elapsed -ge 3 ]] && elapsed_str="${elapsed}s%f" || elapsed_str="%f"
        _cmd_start_time=$SECONDS
    else
        status_str="%F{1}E${last_status}|"
        elapsed_str="${elapsed}s%f"
        _cmd_start_time=$SECONDS
    fi

    # ⑤ PROMPT から参照する変数にセット
    _status_display="${status_str}${elapsed_str} "
    add_newline
}

# PROMPT は変数参照のみ（関数呼び出しで $? が乱れない）
PROMPT='%F{4}WSL:%f $(_python_env_info) %B%F{3}%n@%m%f%b ${vcs_info_msg_0_} %B%F{6}%~%f%b ${_status_display}
%F{7}->%f '

RPROMPT='%F{2}[%D{%Y/%m/%d %H:%M:%S}]%f'

if (which zprof > /dev/null 2>&1) ;then
    zprof
fi
