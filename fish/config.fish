set -x PATH /usr/local $PATH
set -x PATH ~/scriptfile $PATH

set -gx PYENV_ROOT "$HOME/.pyenv"
set -x PATH $PATH "$PYENV_ROOT/shims"
status --is-interactive; and . (pyenv init - | psub)

source (conda info --root)/etc/fish/conf.d/conda.fish

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval (eval /Users/yuta/.pyenv/versions/anaconda3-5.3.1/bin/conda "shell.fish" "hook" $argv)
# <<< conda initialize <<<

set -x set LC_ALL en_US.UTF-8
