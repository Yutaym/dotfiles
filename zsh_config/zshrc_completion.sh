
# compinitはoh-my-zsh側(oh-my-zsh.sh)で既に実行済みのため、ここで再実行しない。
# 二重に実行すると、nvmプラグインがbashcompinit経由で登録した補完が失われる。
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=1
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*:*:cd:*:*' menu select=1
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*' list-colors "${LS_COLORS}"
# Repeated Tab cycles through candidates (including directories).
setopt auto_menu
setopt menu_complete
# Force Tab cycling behavior in completion menus.
bindkey '^I' menu-complete
bindkey '^[[Z' reverse-menu-complete
setopt correct
setopt complete_in_word

# nvmのTab補完に説明文を表示する
# (zshrc_ohmyzsh.sh読み込み後、nvmプラグインがcompleteを登録した後に呼ぶ必要がある)

zstyle ':completion:*:*:nvm:*' verbose yes
zstyle ':completion:*:*:nvm:*:descriptions' format '%F{yellow}-- %d --%f'

_nvm_custom() {
  if (( CURRENT == 2 )); then
    local -a subcmds
    subcmds=(
      'help:ヘルプを表示'
      'install:指定バージョンをダウンロード/インストール'
      'uninstall:指定バージョンをアンインストール'
      'use:PATHを指定バージョンに切り替え'
      'run:指定バージョンでスクリプトを実行'
      'exec:指定バージョンで任意のコマンドを実行'
      'alias:エイリアス一覧の表示/設定'
      'unalias:エイリアスを削除'
      'reinstall-packages:指定バージョンのグローバルパッケージを現在のバージョンに再インストール'
      'current:現在有効なバージョンを表示'
      'list:インストール済みバージョン一覧'
      'ls:インストール済みバージョン一覧 (list と同義)'
      'list-remote:リモートのインストール可能なバージョン一覧'
      'ls-remote:リモートのインストール可能なバージョン一覧 (list-remote と同義)'
      'install-latest-npm:npm自体を最新版に更新'
      'cache:キャッシュディレクトリの表示/削除'
      'deactivate:現在のシェルでのnvmの効果を無効化'
      'unload:シェル関数からnvmをアンロード'
      'version:指定した文字列を単一のローカルバージョンに解決'
      'version-remote:指定した文字列を単一のリモートバージョンに解決'
      'which:インストール済みnodeバージョンのパスを表示'
    )
    _describe -t commands 'nvm command' subcmds && return 0
  fi
  # バージョン番号/エイリアス名の補完は既存のnvm bash補完にそのまま委譲する
  _bash_complete -o default -F __nvm
}
compdef _nvm_custom nvm

# npm補完
# oh-my-zshのnpmプラグインは読み込み時点で `$+commands[npm]` (PATH上の実行ファイルの有無) を
# チェックしてから補完を登録するが、nvmを遅延ロード(lazy)にした状態では読み込み時点で
# npmはまだ「呼ばれて初めてnvmを読み込む」関数スタブに過ぎずPATH上に実体が無いため、
# チェックに失敗して補完が一度も登録されない。そのため実行ファイルの有無を問わずここで登録する。
# (初回のTab補完時にnvmの遅延ロードが走るため、そこだけ一瞬遅くなるのは仕様通り)
_npm_completion() {
  local si=$IFS
  compadd -- $(COMP_CWORD=$((CURRENT-1)) \
               COMP_LINE=$BUFFER \
               COMP_POINT=0 \
               npm completion -- "${words[@]}" \
               2>/dev/null)
  IFS=$si
}
compdef _npm_completion npm
