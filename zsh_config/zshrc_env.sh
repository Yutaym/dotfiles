# conda初期化はdotfiles(zshrc_main.sh)の遅延ロードに一本化。ここでは何もしない。
# compinitはoh-my-zsh側(zshrc_main.sh -> zshrc_ohmyzsh.sh)で実行されるため、ここでは呼ばない。

export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
export PATH=$PATH:$JAVA_HOME/bin
export PATH=$HOME/bin:$PATH

# WindowsのPATHを丸ごと引き継ぐと(/etc/wsl.confのappendWindowsPath)、遅い9pマウント越しの
# ディレクトリが大量にPATHへ入り、存在しないコマンドの探索のたびに数百ms〜1秒かかっていた。
# appendWindowsPath=falseにした上で、現時点で必要なものだけを明示的に追加する。
# 追加したいものが増えたらここに1行足す。
# WSL上で実行している場合にのみ追加する(WSL_DISTRO_NAME/WSL_INTEROPはWSLが自動設定する
# 環境変数でサブプロセス不要、念のため/proc/versionのmicrosoft文字列もフォールバックで見る)
if [[ -n "$WSL_DISTRO_NAME" ]] || [[ -n "$WSL_INTEROP" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    export PATH="$PATH:/mnt/c/Windows:/mnt/c/Windows/System32"                         # explorer.exe, clip.exe など
    export PATH="$PATH:/mnt/c/Users/yutay/AppData/Local/Programs/Microsoft VS Code/bin" # `code` コマンド
fi

# nvmでグローバルインストールしたautoenvを読み込む。
# ユーザー名・nodeバージョンが環境ごとに異なっても動くよう、
# nvmが入っていなければ何もせず、バージョンは可能な限りnvmのdefaultエイリアスから解決する。
# (nvm.sh自体はここでは読み込まない。npm/node同様のlazy-load方式を崩さないため)
_load_nvm_autoenv() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$nvm_dir/nvm.sh" ]] || return 0

    local default_version script=""
    if [[ -f "$nvm_dir/alias/default" ]]; then
        default_version=$(<"$nvm_dir/alias/default")
        script="$nvm_dir/versions/node/$default_version/lib/node_modules/@hyperupcall/autoenv/activate.sh"
        [[ -f "$script" ]] || script=""
    fi

    # defaultエイリアスが "node"/"stable"/"lts/*" のような間接指定で
    # 直接パスを解決できない場合は、インストール済みバージョンの中から
    # autoenvが入っているものを更新日時が新しい順に探す。
    if [[ -z "$script" ]]; then
        script=$(ls -t "$nvm_dir"/versions/node/*/lib/node_modules/@hyperupcall/autoenv/activate.sh 2>/dev/null | head -n1)
    fi

    [[ -n "$script" && -f "$script" ]] && source "$script"
}
_load_nvm_autoenv
unset -f _load_nvm_autoenv


## condaの遅延ロード
## `conda shell.zsh hook`の生成はPython起動を伴い数百ms〜1秒程度かかるため、
## シェル起動時ではなく実際に`conda`コマンドを初めて呼んだタイミングまで遅延させる。
## macOS/Ubuntu(WSL含む)などインストール先が環境によって異なるため、よくある場所を順に探す。
_find_conda_exe() {
    local candidates=(
        "$HOME/miniconda3/bin/conda"
        "$HOME/anaconda3/bin/conda"
        "$HOME/miniforge3/bin/conda"
        "$HOME/mambaforge/bin/conda"
        "/opt/miniconda3/bin/conda"
        "/opt/anaconda3/bin/conda"
        "/opt/homebrew/Caskroom/miniconda/base/bin/conda"
        "/usr/local/miniconda3/bin/conda"
    )
    local c
    for c in "${candidates[@]}"; do
        if [ -x "$c" ]; then
            echo "$c"
            return 0
        fi
    done
    command -v conda 2>/dev/null
}

_CONDA_EXE_LAZY="$(_find_conda_exe)"
unset -f _find_conda_exe

if [ -n "$_CONDA_EXE_LAZY" ]; then
    conda() {
        unset -f conda
        local __conda_setup
        __conda_setup="$("$_CONDA_EXE_LAZY" 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        elif [ -f "$(dirname "$(dirname "$_CONDA_EXE_LAZY")")/etc/profile.d/conda.sh" ]; then
            . "$(dirname "$(dirname "$_CONDA_EXE_LAZY")")/etc/profile.d/conda.sh"
        else
            export PATH="$(dirname "$_CONDA_EXE_LAZY"):$PATH"
        fi
        unset __conda_setup
        conda "$@"
    }
fi
unset _CONDA_EXE_LAZY
