# conda初期化はdotfiles(zshrc_main.sh)の遅延ロードに一本化。ここでは何もしない。
# compinitはoh-my-zsh側(zshrc_main.sh -> zshrc_ohmyzsh.sh)で実行されるため、ここでは呼ばない。

# JAVA_HOME が未設定なら JDK の場所を求める。
# macOS の /usr/bin/javac は実体へのリンクではないスタブのため、/usr/libexec/java_home を使う。
# JDK が無い環境では何もしない(以前は空の JAVA_HOME から PATH に "/bin" を足していた)。
if [[ -z "$JAVA_HOME" ]]; then
    if [[ "$OSTYPE" == darwin* ]]; then
        [[ -x /usr/libexec/java_home ]] && JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
    elif [[ -x /usr/bin/javac ]]; then
        JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
    fi
fi
if [[ -n "$JAVA_HOME" ]]; then
    export JAVA_HOME
    export PATH=$PATH:$JAVA_HOME/bin
fi
export PATH=$HOME/bin:$PATH

# WindowsのPATHを丸ごと引き継ぐと(/etc/wsl.confのappendWindowsPath)、遅い9pマウント越しの
# ディレクトリが大量にPATHへ入り、存在しないコマンドの探索のたびに数百ms〜1秒かかっていた。
# appendWindowsPath=falseにした上で、現時点で必要なものだけを明示的に追加する。
# 追加したいものが増えたらここに1行足す。
# WSL上で実行している場合にのみ追加する(WSL_DISTRO_NAME/WSL_INTEROPはWSLが自動設定する
# 環境変数でサブプロセス不要、念のため/proc/versionのmicrosoft文字列もフォールバックで見る)
if [[ -n "$WSL_DISTRO_NAME" ]] || [[ -n "$WSL_INTEROP" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    export PATH="$PATH:/mnt/c/Windows:/mnt/c/Windows/System32"                         # explorer.exe, clip.exe など
    # VS Code の `code` コマンド。ユーザー名を書かずに済むよう、Windows 側で WSLENV に USERPROFILE/p を
    # 設定しておき(install_powershell.ps1 が設定する)、WSL に渡される $USERPROFILE(/mnt/c/Users/<名前>)から組み立てる。
    # WSLENV が効かない場合(SSH で WSL に入ったときなど)は /mnt/c/Users/* から探す(10ms 程度)。
    () {
        local -a dirs
        [[ -n "$USERPROFILE" ]] && dirs=("$USERPROFILE/AppData/Local/Programs/Microsoft VS Code/bin"(N/))
        (( $#dirs )) || dirs=(/mnt/c/Users/*/AppData/Local/Programs/"Microsoft VS Code"/bin(N/))
        (( $#dirs )) && export PATH="$PATH:$dirs[1]"
    }
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
    # (N) で一致なしでも "no matches found" エラーにせず空にし、om で更新日時の新しい順に並べる。
    if [[ -z "$script" ]]; then
        local -a candidates
        candidates=("$nvm_dir"/versions/node/*/lib/node_modules/@hyperupcall/autoenv/activate.sh(N.om))
        script="${candidates[1]}"
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
