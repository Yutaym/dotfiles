# zsh 設定まとめ

`zsh_config/` の設定内容。Linux（Ubuntu / WSL）と macOS で使う前提。oh-my-zsh をベースにし、外部プラグインや fzf は初回起動時に自動でインストールする。起動を速くするため、conda / nvm は遅延ロードにしている。

## ファイル構成

```text
zsh_config/
├── .zshenv              # ~/.zshenv にコピー（グローバル compinit の無効化）
├── .zshrc               # ~/.zshrc にコピー（zshrc_main.sh を読み込むだけ）
├── install_zsh.sh       # インストーラー（Linux / macOS）
├── zshrc_main.sh        # エントリーポイント・履歴・シェルオプション
├── zshrc_env.sh         # 環境変数・PATH・conda の遅延ロード
├── zshrc_ohmyzsh.sh     # oh-my-zsh・外部プラグイン・fzf
├── zshrc_function.sh    # 関数・peco / fzf のキーバインド
├── zshrc_alias.sh       # エイリアス
├── zshrc_prompt.sh      # プロンプト
└── zshrc_completion.sh  # 補完の設定

scripts/
└── zsh_soft_installer.sh  # zsh で使う外部ツールのインストールコマンド集（メモ）
```

## インストール

```sh
bash ~/dotfiles/zsh_config/install_zsh.sh
```

以下を行う（済んでいる処理はスキップ）。

1. zsh がインストールされているか確認（無ければ警告のみ。インストールは apt / brew などで行う）
2. `.zshrc` / `.zshenv` をホームディレクトリへコピー
   - 既存ファイルと内容が同じならスキップ、異なれば `*.bak.<日時>` にバックアップしてから上書き
   - リポジトリが `~/dotfiles` 以外にある場合は、`.zshrc` の読み込み先パスを書き換えてからコピー
3. デフォルトシェルが zsh でなければ、変更手順（`/etc/shells` への追記と `chsh -s`）を表示する。変更自体は手動

oh-my-zsh・zsh-autosuggestions・zsh-syntax-highlighting・fzf は、zsh の初回起動時に `zshrc_ohmyzsh.sh` が自動でインストールする（[oh-my-zsh](#oh-my-zsh-zshrc_ohmyzshsh) 参照）。

外部依存: `curl`（oh-my-zsh の取得）、`git`（プラグイン・fzf の取得）、`peco`（履歴検索・ディレクトリ移動）、`eza`（`lsc` などのエイリアス）、`ghq`（`^G`）、`thefuck` / `direnv`（同名プラグイン）、`gh`（Copilot 拡張、`ghcs` / `ghce`）。いずれも任意。

---

## 読み込み順

| 順  | ファイル              | 内容                                                                |
| --- | --------------------- | ------------------------------------------------------------------- |
| 1   | `~/.zshenv`           | `skip_global_compinit=1`                                            |
| 2   | `~/.zshrc`            | `zshrc_main.sh` を `source`                                         |
| 3   | `zshrc_main.sh`       | `~/.local/bin` を PATH に追加、`typeset -U path`（PATH の重複除去） |
| 4   | `zshrc_env.sh`        | 環境変数・PATH・conda の遅延ロード                                  |
| 5   | （`zshrc_main.sh`）   | `/usr/local/share/zsh-completions` があれば `fpath` に追加          |
| 6   | `zshrc_ohmyzsh.sh`    | oh-my-zsh（内部で `compinit`）・外部プラグイン・fzf                 |
| 7   | （`zshrc_main.sh`）   | 色・履歴・シェルオプション                                          |
| 8   | `zshrc_function.sh`   | 関数・キーバインド                                                  |
| 9   | `zshrc_alias.sh`      | エイリアス                                                          |
| 10  | `zshrc_prompt.sh`     | プロンプト                                                          |
| 11  | `zshrc_completion.sh` | 補完の設定                                                          |
| 12  | `~/.zshrc.local`      | あれば読み込む。環境ごとの設定（リポジトリ管理外。`CLAUDE_OLLAMA_URL` などホスト名を含むものはここに書く） |

- `fpath` の追加は、`compinit` を実行する oh-my-zsh より前に行う必要がある
- `compinit` は oh-my-zsh の中でだけ実行する。`zshrc_completion.sh` などで再実行すると、nvm プラグインが `bashcompinit` 経由で登録した補完が消える
- 関数・エイリアスは oh-my-zsh より後に読み込むので、oh-my-zsh のプラグインが定義した同名のエイリアスやキーバインドを上書きする

### .zshenv

Ubuntu / Debian の `/etc/zsh/zshrc` は、`~/.zshrc` より先に `compinit` を無条件で実行し、そのときにセキュリティ監査（`compaudit`）も走る。`~/.zshrc` 側で `ZSH_DISABLE_COMPFIX` を設定しても間に合わないので、先に読まれる `~/.zshenv` で `skip_global_compinit=1` を設定して止める。この仕組みが無い macOS などでは何も起きない。

---

## 基本設定 (zshrc_main.sh)

### 履歴
| 設定                    | 値 / 動作                            |
| ----------------------- | ------------------------------------ |
| `HISTFILE`              | `~/.zsh_history`                     |
| `HISTSIZE` / `SAVEHIST` | 100000                               |
| `share_history`         | 複数のシェル間で履歴を共有           |
| `hist_ignore_dups`      | 直前と同じコマンドは記録しない       |
| `hist_ignore_all_dups`  | 重複するコマンドは古い方を削除       |
| `hist_ignore_space`     | 先頭がスペースのコマンドは記録しない |
| `hist_reduce_blanks`    | 余分な空白を詰めて記録               |

### シェルオプション
| オプション               | 動作                                     |
| ------------------------ | ---------------------------------------- |
| `print_eight_bit`        | 日本語のファイル名を表示できるようにする |
| `auto_cd`                | ディレクトリ名だけで `cd`                |
| `no_beep` / `nolistbeep` | ビープ音を鳴らさない                     |
| `auto_pushd`             | `cd` のたびにディレクトリスタックへ積む  |
| `pushd_ignore_dups`      | スタックに重複して積まない               |
| `IGNOREEOF`              | `Ctrl-D` でシェルを終了しない            |
| `no_flow_control`        | `Ctrl-S` / `Ctrl-Q` のフロー制御を無効化 |
| `extended_glob`          | 拡張グロブ（`^`・`~`・`#` など）を有効化 |

### 単語の区切り
- `WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'`
- `select-word-style default` にしたうえで、`zstyle ':zle:*' word-chars "_-./;@"` を区切り文字として扱う。`Ctrl-W` などでパスを 1 階層ずつ消せる

### 環境変数
| 変数                                   | 値    |
| -------------------------------------- | ----- |
| `EDITOR`                               | `vim` |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1`   |

---

## 環境変数・PATH (zshrc_env.sh)

### PATH
| 追加するパス                                | 条件                    |
| ------------------------------------------- | ----------------------- |
| `~/.local/bin`（先頭）                      | 常に（`zshrc_main.sh`） |
| `~/bin`（先頭）                             | 常に                    |
| `$JAVA_HOME/bin`（末尾）                    | JDK が見つかったとき    |
| `/mnt/c/Windows`、`/mnt/c/Windows/System32` | WSL のみ                |
| VS Code の `bin`（`code` コマンド）         | WSL のみ                |

- `JAVA_HOME` が未設定なら、Linux は `/usr/bin/javac` のリンク先から、macOS は `/usr/libexec/java_home` で求める（macOS の `/usr/bin/javac` はリンクではないスタブのため）。JDK が無ければ何もしない
- WSL は `/etc/wsl.conf` で `appendWindowsPath=false` にしている前提。Windows の PATH をすべて引き継ぐと、存在しないコマンドを探すたびに遅い 9p マウントを見に行き、数百 ms〜1 秒かかっていたため。必要なものだけをここで追加する
- WSL かどうかは `WSL_DISTRO_NAME` / `WSL_INTEROP`、なければ `/proc/version` の `microsoft` で判定する
- VS Code のパスは、Windows のユーザー名を書かずに求める
  1. `$USERPROFILE` から組み立てる。Windows 側の環境変数 `WSLENV` に `USERPROFILE/p` を入れておくと、WSL に `$USERPROFILE`（`/mnt/c/Users/<名前>`）が渡される。`WSLENV` は `powershell_config/install_powershell.ps1` が設定する
  2. `$USERPROFILE` が無いとき（SSH で WSL に入ったときなど）は `/mnt/c/Users/*/AppData/Local/Programs/Microsoft VS Code/bin` を探す（10 ms 程度）
  - `cmd.exe /c echo %USERPROFILE%` で求める方法は起動のたびに 100 ms 以上かかるので使わない

### autoenv（nvm 経由）
nvm でグローバルにインストールした `@hyperupcall/autoenv` の `activate.sh` を読み込む。

- nvm が無ければ何もしない
- nvm の `default` エイリアスからバージョンを求める。`lts/*` のように間接指定で解決できない場合は、autoenv が入っているバージョンのうち更新日時が最も新しいものを使う
- `nvm.sh` 自体はここでは読み込まない（nvm の遅延ロードを崩さないため）

### conda の遅延ロード
`conda shell.zsh hook` は Python を起動するので数百 ms〜1 秒かかる。そのため起動時には実行せず、`conda` を初めて呼んだときに初期化する。

- conda 本体は次の順に探す: `~/miniconda3` → `~/anaconda3` → `~/miniforge3` → `~/mambaforge` → `/opt/miniconda3` → `/opt/anaconda3` → `/opt/homebrew/Caskroom/miniconda/base` → `/usr/local/miniconda3` → PATH 上の `conda`
- 見つかった場合だけ、`conda` という名前のスタブ関数を定義する。最初の呼び出しで hook を `eval` し（失敗したら `etc/profile.d/conda.sh`、それもなければ PATH に追加）、そのまま元のコマンドを実行する

---

## oh-my-zsh (zshrc_ohmyzsh.sh)

### 基本設定
| 設定                    | 値 / 動作                                                                                                 |
| ----------------------- | --------------------------------------------------------------------------------------------------------- |
| `ZSH`                   | `~/.oh-my-zsh`（設定済みならその値）                                                                      |
| `ZSH_THEME`             | 空（テーマを使わず、[プロンプト](#プロンプト-zshrc_promptsh) は自前で設定する）                           |
| `ZSH_DISABLE_COMPFIX`   | `true`（`compaudit` を省略。WSL のマウント越しだと 1 秒以上かかっていたため）                             |
| `:omz:plugins:nvm lazy` | `yes`（nvm を `nvm` / `node` / `npm` / `npx` などの初回実行まで読み込まない。未設定だと起動に数秒かかる） |

### 自動インストール
対話シェルで、見つからなければ初回起動時にインストールする。

| 対象                    | インストール先                                | 取得方法                                                                        |
| ----------------------- | --------------------------------------------- | ------------------------------------------------------------------------------- |
| oh-my-zsh               | `$ZSH`                                        | `curl` で公式インストーラーを実行（`RUNZSH=no` / `CHSH=no` / `KEEP_ZSHRC=yes`） |
| zsh-autosuggestions     | `$ZSH_CUSTOM/plugins/zsh-autosuggestions`     | `git clone`                                                                     |
| zsh-syntax-highlighting | `$ZSH_CUSTOM/plugins/zsh-syntax-highlighting` | `git clone`                                                                     |
| fzf                     | `$FZF_HOME`（未設定なら `~/.fzf`）            | `git clone --depth 1`                                                           |

zsh-autosuggestions と zsh-syntax-highlighting は oh-my-zsh の `plugins` には入れず、oh-my-zsh を読み込んだ後に直接 `source` する。fzf は `shell/completion.zsh` と `shell/key-bindings.zsh` を読み込む（キーバインドの一部は後で上書きされる。[fzf の標準キーバインド](#fzf-の標準キーバインド) 参照）。

> **注意**: fzf は `git clone` するだけで、バイナリ（`~/.fzf/bin/fzf`）は入れていない。そのため PATH 上の別の fzf（Ubuntu 22.04 の apt 版は 0.29）が使われ、最新のシェルスクリプトが渡す `--walker` / `--scheme` などのオプションを解釈できない。この状態では `Alt-C` などのウィジェットはエラーになる。`~/.fzf/install --bin` でスクリプトと同じバージョンのバイナリを入れ、`~/.fzf/bin` を PATH の先頭に追加すれば直る。

### プラグイン
| 分類               | プラグイン                                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| エイリアス・補助   | `aliases`、`alias-finder`、`common-aliases`、`colored-man-pages`、`colorize`、`command-not-found`、`man`、`thefuck`                                                 |
| クリップボード     | `copybuffer`（`Ctrl-O` で入力中のコマンドをコピー）、`copyfile`                                                                                                     |
| 環境変数           | `dotenv`、`direnv`                                                                                                                                                  |
| ファイル操作       | `cp`、`extract`、`universalarchive`、`encode64`、`jsontools`、`perms`、`rsync`                                                                                      |
| 履歴・移動         | `history`、`history-substring-search`、`per-directory-history`、`z`、`zsh-navigation-tools`、`zsh-interactive-cd`                                                   |
| 操作               | `fancy-ctrl-z`（`Ctrl-Z` でサスペンドしたジョブに戻る）、`sudo`（`Esc Esc` で先頭に `sudo`。ただし後から読み込む `thefuck` が同じキーを上書きしているので使えない） |
| Git / GitHub       | `git`、`git-auto-fetch`、`git-extras`、`git-flow`、`git-prompt`、`gh`、`gitignore`                                                                        |
| 言語・パッケージ   | `python`、`pip`、`uv`、`node`、`npm`、`nvm`、`deno`、`yarn`                                                                                                         |
| コンテナ・クラウド | `docker`、`docker-compose`、`gcloud`                                                                                                                                |
| システム・リモート | `systemd`、`systemadmin`、`ufw`、`ssh`、`ssh-agent`、`mosh`、`tmux`                                                                                                 |
| OS・エディタ       | `brew`、`macos`、`vscode`                                                                                                                                           |

コメントアウトしているもの: `autoenv`（nvm 経由の autoenv を使うため）、`magic-enter`、`gitfast`、`github`（旧 hub CLI 用で非推奨になり、読み込むと警告が出るため。GitHub CLI の補完は `gh` プラグインで行う）

---

## 関数・キーバインド (zshrc_function.sh)

### キーバインド
自分で設定しているキーバインド。プラグインや zsh 標準のものも含めた全体は [付録: キーバインド一覧](#付録-キーバインド一覧) を参照。

| キー                | 動作                                                                   | 必要なもの    | 上書きしているもの                   |
| ------------------- | ---------------------------------------------------------------------- | ------------- | ------------------------------------ |
| `Ctrl-R`            | 履歴を peco で選んでコマンドラインに入れる（重複を除いて新しい順）     | `peco`        | fzf の履歴検索                       |
| `Ctrl-T`            | 最近移動したディレクトリ（`cdr`）を peco で選んで移動                  | `peco`        | fzf のファイル選択                   |
| `Ctrl-G`            | `ghq` 管理のリポジトリを peco で選んで移動（更新日時が新しい順）       | `peco`、`ghq` | per-directory-history の履歴切り替え |
| `Tab` / `Shift-Tab` | 補完候補を順 / 逆順に切り替え（[補完](#補完-zshrc_completionsh) 参照） | —             | fzf の `**` 補完                     |

- `Ctrl-R` は zsh 組み込みの `fc -lnr 1` で新しい順に並べる（`tac` は macOS に無いため）
- `Ctrl-G` のリポジトリの更新日時は zsh の `zstat`（`zsh/stat` モジュール）で取る（`ls --time-style` は GNU 専用のため）

### fzf の標準キーバインド
`~/.fzf/shell/key-bindings.zsh` と `completion.zsh` が設定するもの。

| キー / 入力  | 動作                                                                                                                                                                                        | この設定での状態                                                                  |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `Ctrl-T`     | カレント以下のファイル・ディレクトリを選び、パスをコマンドラインに挿入（複数選択可）                                                                                                        | peco-cdr に上書きされていて使えない                                               |
| `Ctrl-R`     | 履歴を検索して選んだコマンドを挿入。fzf の画面で `Ctrl-R` を押すと並び順（時系列 / 関連度）を切り替え                                                                                       | peco-history-selection に上書きされていて使えない                                 |
| `Alt-C`      | サブディレクトリを選んで `cd`                                                                                                                                                               | 有効（ただしバイナリが古いとエラー。[oh-my-zsh](#自動インストール) の注意を参照） |
| `**` + `Tab` | 文脈に合わせて fzf で補完する。`vim **<Tab>` はファイル、`cd **<Tab>` はディレクトリ、`ssh **<Tab>` はホスト、`export **<Tab>` / `unset **<Tab>` は環境変数、`unalias **<Tab>` はエイリアス | `Tab` を `menu-complete` に上書きしているので使えない                             |
| `kill <Tab>` | プロセスを fzf で選ぶ（`**` は不要）                                                                                                                                                        | 同上                                                                              |

fzf の画面内での主な操作:

| キー                                                | 動作                       |
| --------------------------------------------------- | -------------------------- |
| `Ctrl-J` / `Ctrl-K`、`Ctrl-N` / `Ctrl-P`、`↓` / `↑` | カーソル移動               |
| `Enter`                                             | 決定                       |
| `Tab` / `Shift-Tab`                                 | 複数選択モードで選択・解除 |
| `Esc` / `Ctrl-C` / `Ctrl-G`                         | キャンセル                 |

検索語の書き方: `'word`（完全一致）、`^word`（前方一致）、`word$`（後方一致）、`!word`（除外）、`a | b`（OR）、スペース区切りで AND。

動作は環境変数で変えられる: `FZF_DEFAULT_OPTS`（全体）、`FZF_CTRL_T_COMMAND` / `FZF_CTRL_T_OPTS`、`FZF_CTRL_R_OPTS`、`FZF_ALT_C_COMMAND` / `FZF_ALT_C_OPTS`、`FZF_COMPLETION_TRIGGER`（`**` を別の文字列にする）。

### 空いているキー
今の設定（プラグイン込み）で何も割り当てられていないキー。

| 種類               | 空いているキー                                                                                                                                                                                |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Ctrl` + 1 キー    | `Ctrl-]`、`Ctrl-^`（多くの端末では `Ctrl-6` / `Ctrl-Shift-6`）                                                                                                                                |
| `Alt` + 小文字     | `Alt-e`、`Alt-i`、`Alt-j`、`Alt-k`、`Alt-o`、`Alt-r`、`Alt-v`                                                                                                                                 |
| `Alt-Shift` + 英字 | `e`、`i`、`j`、`k`、`m`、`r`、`v`、`x`、`y`、`z`（`o` は下記の理由で避ける）                                                                                                                  |
| `Alt` + 記号       | `#`、`%`、`&`、`(`、`)`、`*`、`+`、`:`、`;`、`=`、`@`、`]`、`^`、`` ` ``、`{`、`}`                                                                                                            |
| `Ctrl-X` + キー    | `Ctrl-X` に続けて `Ctrl-A` `Ctrl-C` `Ctrl-D` `Ctrl-G` `Ctrl-L` `Ctrl-P` `Ctrl-Q` `Ctrl-S` `Ctrl-T` `Ctrl-W` `Ctrl-Y` `Ctrl-Z`、または `b` `f` `i` `j` `k` `l` `o` `p` `q` `v` `w` `x` `y` `z` |

- `Ctrl` + 英字は全部使われている。`Ctrl-C`（割り込み）と `Ctrl-\`（強制終了）は端末がシグナルとして処理するので割り当てない。`Ctrl-S` / `Ctrl-Q` は `no_flow_control` で端末から解放しているが、それぞれ履歴の前方検索と `push-line` が割り当てられている
- `Alt-Shift-o`（`Esc O`）と `Alt-[`（`Esc [`）は矢印キーなどの制御シーケンスの先頭と同じなので、割り当てると矢印キーが誤動作する
- `Alt-m` は `copy-prev-shell-word` が割り当てられているうえ、man プラグインの `Esc m a n` の先頭と重なっているので、押すと `KEYTIMEOUT`（0.4 秒）待たされる
- `Alt` 系を使うには、macOS の Terminal / iTerm2 で「Option キーをメタキーとして使う」を有効にする必要がある。Windows Terminal は `Alt-Enter`（全画面）や `Alt-Shift-D` / `Alt-Shift-+` / `Alt-Shift--`（ペイン分割）などを自分で処理するので、zsh には届かない

### cdr
`chpwd_recent_dirs` / `cdr` が `fpath` 上にあれば有効にする。移動履歴は `~/.cache/chpwd-recent-dirs` に最大 1000 件保存する。

### 関数
| 関数                     | 動作                                                                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------- |
| `mkcd <dir>`             | ディレクトリを作成（`mkdir -p`）して移動                                                                    |
| `fe`                     | カレント以下のファイルを fzf で選んで `$EDITOR` で開く                                                      |
| `fkill [signal]`         | プロセスを fzf で選んで（複数可）シグナルを送る。省略時は `9`                                               |
| `ghcs [flags] <prompt>`  | `gh copilot suggest` のラッパー。提案されたコマンドを履歴に追加して実行する。`-t shell/gh/git` で対象を指定 |
| `ghce [flags] <command>` | `gh copilot explain` のラッパー。コマンドの説明を表示                                                       |
| `claude-anthropic`       | Anthropic API で Claude Code を起動（`ANTHROPIC_API_KEY` はプレースホルダーのままなので要書き換え）         |
| `claude-ollama`          | Ollama 経由（モデル `qwen3.5`）で Claude Code を起動。接続先は `CLAUDE_OLLAMA_URL`（未設定なら `http://localhost:11434`）                                  |

---

## エイリアス (zshrc_alias.sh)

自分で定義しているエイリアス。oh-my-zsh（lib とプラグイン）が定義するものも含めた全体は [付録: エイリアス一覧](#付録-エイリアス一覧) を参照。

oh-my-zsh と同じ内容のもの（`g` / `ga` / `gb` / `gco` / `gd` / `gfo` / `h` など）はここには書かず、oh-my-zsh の定義をそのまま使う。ここで定義したものは oh-my-zsh より後に読み込まれるので、同名のエイリアスを上書きする。

### 上書きしている oh-my-zsh のエイリアス
| エイリアス | この設定                  | oh-my-zsh の定義                      | 定義元         |
| ---------- | ------------------------- | ------------------------------------- | -------------- |
| `gc`       | `git clone`               | `git commit --verbose`                | git            |
| `gcm`      | `git commit -m`           | `git checkout $(git_main_branch)`     | git            |
| `gg`       | `git grep`                | `git gui citool`                      | git            |
| `gl`       | `git log ...`             | `git pull`                            | git            |
| `glg`      | `git log ... --grep`      | `git log --stat`                      | git            |
| `gmom`     | `git merge origin/master` | `git merge origin/$(git_main_branch)` | git            |
| `gr`       | `grep -E`                 | `git remote`                          | git            |
| `gst`      | `git stash`               | `git status`                          | git            |
| `gsu`      | `git stash -u`            | `git submodule update`                | git            |
| `la`       | `ls -a`                   | `ls -lAFh`                            | common-aliases |
| `ll`       | `ls -lh`                  | `ls -l`                               | common-aliases |

### Git
| エイリアス | コマンド              | エイリアス | コマンド                     |
| ---------- | --------------------- | ---------- | ---------------------------- |
| `gs`       | `git status`          | `gfu`      | `git fetch upstream`         |
| `gc`       | `git clone`           | `gmod`     | `git merge origin/develop`   |
| `gcma`     | `git checkout master` | `gmud`     | `git merge upstream/develop` |
| `gcm`      | `git commit -m`       | `gmom`     | `git merge origin/master`    |
| `gg`       | `git grep`            | `gpo`      | `git push origin`            |
| `gst`      | `git stash`           | `gpom`     | `git push origin master`     |
| `gsu`      | `git stash -u`        | `gsl`      | `git stash list`             |
| `gsp`      | `git stash pop`       |            |                              |

| エイリアス | コマンド                                         |
| ---------- | ------------------------------------------------ |
| `gl`       | `git log --abbrev-commit --no-merges --date=iso` |
| `glg`      | `gl` + `--grep`（コミットメッセージで検索）      |

### ls
`ls` 自体は oh-my-zsh（`lib/theme-and-appearance.zsh`）が OS に合わせて色付きにする（GNU は `ls --color=tty`、BSD / macOS は `ls -G`）。そのため `la` / `ll` などには `--color` を付けない（古い macOS の `ls` は `--color` を解釈しない）。

| エイリアス       | コマンド                                          |
| ---------------- | ------------------------------------------------- |
| `la`             | `ls -a`                                           |
| `ll`             | `ls -lh`                                          |
| `lla`            | `ls -alh`                                         |
| `lsgr <pattern>` | `ls -a \| grep -E <pattern>`                      |
| `lsc`            | `eza --icons --group-directories-first`           |
| `llc`            | `eza -la --icons --group-directories-first --git` |
| `ltc`            | `eza --tree --level=2 --icons`                    |
| `lspt`           | PATH を 1 行ずつ表示（実行時の PATH）             |

### エディタ・その他
| エイリアス | コマンド                                                                                                                                                         |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `v` / `vi` | `nvim`                                                                                                                                                           |
| `co`       | `code ./`                                                                                                                                                        |
| `c`        | `clear`                                                                                                                                                          |
| `B`        | `./build`                                                                                                                                                        |
| `lns`      | `ln -snf`                                                                                                                                                        |
| `chx`      | `chmod +x`                                                                                                                                                       |
| `gr`       | `grep -E`                                                                                                                                                        |
| `tree`     | `find` と `sed` で木構造を表示（`tree` コマンドがあっても、こちらが優先される）                                                                                  |
| `pwdc`     | カレントディレクトリのパスをコピー（oh-my-zsh の `clipcopy` を使う。macOS は `pbcopy`、WSL は `clip.exe`、Linux は `wl-copy` / `xclip` / `xsel` のどれかが必要） |
| `vzsh`     | `nvim ~/.zshrc`                                                                                                                                                  |
| `szsh`     | `source ~/.zshrc`                                                                                                                                                |
| `memodir`  | `cd ~/documents/memo`                                                                                                                                            |

---

## プロンプト (zshrc_prompt.sh)

```text
WSL: (venv:.venv) user@host [!+main] ~/dotfiles E1|5s
->                                                  [2026/09/30 12:34:56]
```

### 左プロンプト（1 行目）
| 要素                     | 内容                                                                                                                                   |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| 環境ラベル               | `mac` / `WSL` / `ubuntu`（それ以外は `$OSTYPE`）。WSL は `/proc/version` の `microsoft` で判定                                         |
| Python 環境              | `(venv:<名前>)` または `(conda:<名前>)`。venv を優先。venv 標準の表示は `VIRTUAL_ENV_DISABLE_PROMPT=1` で消している                    |
| ユーザー・ホスト         | `user@host`（太字・黄）                                                                                                                |
| Git                      | `vcs_info` で `[<staged><unstaged><branch>]`。ステージ済みは黄の `!`、未ステージは赤の `+`。rebase などの最中は `[<branch>\|<action>]` |
| カレントディレクトリ     | `~` 省略形（太字・シアン）                                                                                                             |
| 終了ステータス・実行時間 | 失敗時は赤で `E<終了コード>\|<秒>s`。成功時は 3 秒以上かかったときだけ緑で `<秒>s`                                                     |

2 行目は `->` だけ。右プロンプトは現在日時（`[YYYY/MM/DD HH:MM:SS]`）。

### 実装メモ
- `preexec` で開始時刻を記録し、`precmd` で経過時間を計算する
- `precmd` では最初に `$?` を退避してから `vcs_info` を呼ぶ（`vcs_info` が `$?` を上書きするため）。`PROMPT` 側は変数を参照するだけにしている
- 2 回目以降のプロンプトの前に空行を入れる（`add_newline`）
- `zprof` が使える（`zmodload zsh/zprof` 済みの）場合は、最後にプロファイル結果を表示する。起動時間を測るときは `.zshrc` の先頭に `zmodload zsh/zprof` を書く

---

## 補完 (zshrc_completion.sh)

| 設定                                   | 動作                                                   |
| -------------------------------------- | ------------------------------------------------------ |
| `matcher-list 'm:{a-z}={A-Z}'`         | 小文字で入力すると大文字にもマッチ                     |
| `menu select=1`                        | 候補が 1 つ以上あればメニュー選択にする（`cd` も同様） |
| `use-cache true`                       | 補完結果をキャッシュ                                   |
| `list-colors "${LS_COLORS}"`           | 候補を `ls` と同じ色で表示                             |
| `auto_menu` / `menu_complete`          | `Tab` を押すたびに候補を順に切り替え                   |
| `bindkey '^I' menu-complete`           | `Tab` で次の候補                                       |
| `bindkey '^[[Z' reverse-menu-complete` | `Shift-Tab` で前の候補                                 |
| `correct`                              | コマンド名のスペルミスを訂正候補として提示             |
| `complete_in_word`                     | カーソル位置で補完                                     |

### nvm
`nvm` のサブコマンド補完に日本語の説明を付ける（`_nvm_custom`）。2 番目の引数（サブコマンド）だけを置き換え、バージョン番号やエイリアス名の補完は nvm 標準の bash 補完（`__nvm`）に任せる。nvm プラグインが補完を登録した後に定義する必要があるので、oh-my-zsh より後に読み込む。

### npm
oh-my-zsh の `npm` プラグインは、読み込み時に PATH 上に `npm` があるかを確認してから補完を登録する。nvm を遅延ロードにしていると、その時点の `npm` は nvm を読み込むためのスタブ関数でしかないため確認に失敗し、補完が登録されない。そのため `npm completion` を使う補完関数をここで無条件に登録する。最初の `Tab` 補完で nvm の遅延ロードが走るので、そのときだけ少し待たされる。

---

## scripts/zsh_soft_installer.sh

zsh 環境で使う外部ツールのインストールコマンドをまとめたメモ。スクリプトとして一括実行するものではなく、必要な部分をコピーして使う。

| 対象        | 方法                                                                            |
| ----------- | ------------------------------------------------------------------------------- |
| eza         | GitHub の最新リリース（x86_64 Linux 用）を `/usr/local/bin` に展開              |
| direnv      | 公式インストールスクリプト                                                      |
| nvm / Node  | nvm v0.39.7 をインストール後、LTS を入れて `default` に設定                     |
| Ollama      | 公式インストールスクリプト                                                      |
| SSH 公開鍵  | `ssh-copy-id` などでサーバーの `authorized_keys` に登録（Windows 版はコメント） |
| Docker      | `get.docker.com` のスクリプト                                                   |
| code-server | 公式インストールスクリプト。`0.0.0.0:18080` で待ち受け、systemd で常駐          |

---

## 付録: キーバインド一覧

WSL（Ubuntu 22.04）で実際にこの設定を読み込み、`bindkey`（emacs キーマップ）の出力を定義元ごとに分けたもの。文字の入力（`self-insert`）は省略している。「備考」の「標準は〜」は、zsh 標準（`zsh -f` で `bindkey -e`）の割り当てを上書きしていることを表す。

後から読み込んだものに上書きされて使えなくなっているキーバインド:

| キー      | 本来の動作                                    | 定義元                | 上書きしたもの                 |
| --------- | --------------------------------------------- | --------------------- | ------------------------------ |
| `Ctrl-T`  | ファイルを選んで挿入（`fzf-file-widget`）     | fzf                   | `peco-cdr`                     |
| `Ctrl-R`  | 履歴検索（`fzf-history-widget`）              | fzf                   | `peco-history-selection`       |
| `Tab`     | `**` 補完（`fzf-completion`）                 | fzf                   | `menu-complete`                |
| `Ctrl-G`  | ディレクトリごとの履歴と全体の履歴を切り替え  | per-directory-history | `peco-ghq-look`                |
| `Esc Esc` | 先頭に `sudo` を付ける（`sudo-command-line`） | sudo                  | `fuck-command-line`（thefuck） |

補完メニューの表示中（`menuselect` キーマップ）は、`Ctrl-O` で候補を確定して次の候補の選択に進む（`accept-and-infer-next-history`、`lib/completion.zsh`）。

### zshrc_function.sh

| キー   | 動作                                   | ウィジェット             | 備考                                         |
| ------ | -------------------------------------- | ------------------------ | -------------------------------------------- |
| Ctrl-G | ghq のリポジトリを peco で選んで移動   | `peco-ghq-look`          | 標準は `send-break`                          |
| Ctrl-R | 履歴を peco で選ぶ                     | `peco-history-selection` | 標準は `history-incremental-search-backward` |
| Ctrl-T | 最近のディレクトリを peco で選んで移動 | `peco-cdr`               | 標準は `transpose-chars`                     |

### zshrc_completion.sh

| キー      | 動作                     | ウィジェット            | 備考                        |
| --------- | ------------------------ | ----------------------- | --------------------------- |
| Tab       | 補完候補を順に切り替え   | `menu-complete`         | 標準は `expand-or-complete` |
| Shift-Tab | 補完候補を逆順に切り替え | `reverse-menu-complete` |                             |

### fzf

| キー  | 動作                                | ウィジェット    | 備考                     |
| ----- | ----------------------------------- | --------------- | ------------------------ |
| Alt-c | サブディレクトリを fzf で選んで移動 | `fzf-cd-widget` | 標準は `capitalize-word` |

### copybuffer

| キー   | 動作                               | ウィジェット | 備考                                  |
| ------ | ---------------------------------- | ------------ | ------------------------------------- |
| Ctrl-O | 入力中の行をクリップボードにコピー | `copybuffer` | 標準は `accept-line-and-down-history` |

### fancy-ctrl-z

| キー   | 動作                                        | ウィジェット   | 備考 |
| ------ | ------------------------------------------- | -------------- | ---- |
| Ctrl-Z | 空行なら `fg`（サスペンドしたジョブに戻る） | `fancy-ctrl-z` |      |

### thefuck

| キー    | 動作                            | ウィジェット        | 備考 |
| ------- | ------------------------------- | ------------------- | ---- |
| Esc Esc | 直前のコマンドを thefuck で修正 | `fuck-command-line` |      |

### npm

| キー  | 動作                                        | ウィジェット                   | 備考 |
| ----- | ------------------------------------------- | ------------------------------ | ---- |
| F2 F2 | `npm install` と `npm uninstall` を切り替え | `npm_toggle_install_uninstall` |      |

### man

| キー      | 動作                          | ウィジェット       | 備考 |
| --------- | ----------------------------- | ------------------ | ---- |
| Esc m a n | 入力中のコマンドの man を開く | `man-command-line` |      |

### history-substring-search

| キー                        | 動作                     | ウィジェット                    | 備考                          |
| --------------------------- | ------------------------ | ------------------------------- | ----------------------------- |
| ↑（アプリケーションモード） | 入力文字列を含む前の履歴 | `history-substring-search-up`   | 標準は `up-line-or-history`   |
| ↓（アプリケーションモード） | 入力文字列を含む次の履歴 | `history-substring-search-down` | 標準は `down-line-or-history` |

### lib/key-bindings.zsh

| キー          | 動作                                 | ウィジェット                    | 備考                          |
| ------------- | ------------------------------------ | ------------------------------- | ----------------------------- |
| Ctrl-X Ctrl-E | 入力中の行を `$EDITOR` で編集        | `edit-command-line`             |                               |
| Alt-l         | 入力を退避して `ls` を実行           | `"^Q ls^J"`                     | 標準は `down-case-word`       |
| Alt-m         | 直前の単語（シェルの単語単位）を複製 | `copy-prev-shell-word`          |                               |
| Alt-w         | リージョンを削除                     | `kill-region`                   | 標準は `copy-region-as-kill`  |
| Space         | 履歴展開してからスペースを入力       | `magic-space`                   |                               |
| Ctrl-→        | 次の単語へ                           | `forward-word`                  |                               |
| Ctrl-←        | 前の単語へ                           | `backward-word`                 |                               |
| Insert        | 上書きモード切り替え                 | `overwrite-mode`                |                               |
| Ctrl-Delete   | 次の単語を削除                       | `kill-word`                     |                               |
| Delete        | カーソル位置の文字を削除             | `delete-char`                   |                               |
| PageUp        | 前の行 / 前の履歴                    | `up-line-or-history`            |                               |
| PageDown      | 次の行 / 次の履歴                    | `down-line-or-history`          |                               |
| ↑             | 入力済みの先頭に一致する前の履歴     | `up-line-or-beginning-search`   | 標準は `up-line-or-history`   |
| ↓             | 入力済みの先頭に一致する次の履歴     | `down-line-or-beginning-search` | 標準は `down-line-or-history` |
| End           | 行末へ                               | `end-of-line`                   |                               |
| Home          | 行頭へ                               | `beginning-of-line`             |                               |

### compinit

| キー          | 動作                           | ウィジェット              | 備考 |
| ------------- | ------------------------------ | ------------------------- | ---- |
| Ctrl-X ?      | 補完のデバッグ情報を出力       | `_complete_debug`         |      |
| Ctrl-X Ctrl-R | 指定した補完関数で補完         | `_read_comp`              |      |
| Ctrl-X a      | エイリアスを展開               | `_expand_alias`           |      |
| Ctrl-X C      | ファイル名を訂正               | `_correct_filename`       |      |
| Ctrl-X c      | 単語を訂正                     | `_correct_word`           |      |
| Ctrl-X d      | 展開候補を一覧表示             | `_list_expansions`        |      |
| Ctrl-X e      | 単語を展開                     | `_expand_word`            |      |
| Ctrl-X h      | 補完のコンテキストを表示       | `_complete_help`          |      |
| Ctrl-X m      | 最近更新したファイルを補完     | `_most_recent_file`       |      |
| Ctrl-X n      | 補完候補の種類を切り替え       | `_next_tags`              |      |
| Ctrl-X t      | tags ファイルから補完          | `_complete_tag`           |      |
| Ctrl-X ~      | bash 風に候補一覧              | `_bash_list-choices`      |      |
| Alt-,         | 履歴の単語で補完（新しい方へ） | `_history-complete-newer` |      |
| Alt-/         | 履歴の単語で補完（古い方へ）   | `_history-complete-older` |      |
| Alt-~         | bash 風に補完                  | `_bash_complete-word`     |      |

### zsh 標準

| キー                             | 動作                                         | ウィジェット                          | 備考             |
| -------------------------------- | -------------------------------------------- | ------------------------------------- | ---------------- |
| Backspace                        | 1 文字前を削除                               | `backward-delete-char`                |                  |
| Ctrl-Space                       | マークを置く                                 | `set-mark-command`                    |                  |
| Ctrl-/（Ctrl-_）                 | 元に戻す                                     | `undo`                                |                  |
| Ctrl-A                           | 行頭へ                                       | `beginning-of-line`                   |                  |
| Ctrl-B                           | 1 文字左へ                                   | `backward-char`                       |                  |
| Ctrl-D                           | カーソル位置を削除（空行なら補完候補一覧）   | `delete-char-or-list`                 |                  |
| Ctrl-E                           | 行末へ                                       | `end-of-line`                         |                  |
| Ctrl-F                           | 1 文字右へ                                   | `forward-char`                        |                  |
| Ctrl-H                           | 1 文字前を削除                               | `backward-delete-char`                |                  |
| Ctrl-J                           | 実行                                         | `accept-line`                         |                  |
| Ctrl-K                           | カーソルから行末まで削除                     | `kill-line`                           |                  |
| Ctrl-L                           | 画面クリア                                   | `clear-screen`                        |                  |
| Enter                            | 実行                                         | `accept-line`                         |                  |
| Ctrl-N                           | 次の行 / 次の履歴                            | `down-line-or-history`                |                  |
| Ctrl-P                           | 前の行 / 前の履歴                            | `up-line-or-history`                  |                  |
| Ctrl-Q                           | 入力中の行を退避（次のコマンド実行後に復元） | `push-line`                           |                  |
| Ctrl-S                           | 履歴を前方インクリメンタル検索               | `history-incremental-search-forward`  |                  |
| Ctrl-U                           | 行全体を削除                                 | `kill-whole-line`                     |                  |
| Ctrl-V                           | 次の 1 文字をそのまま入力                    | `quoted-insert`                       |                  |
| Ctrl-W                           | 前の単語を削除                               | `backward-kill-word`                  |                  |
| Ctrl-Y                           | 貼り付け（kill リングから）                  | `yank`                                |                  |
| Ctrl-X *                         | カーソル位置の単語を展開                     | `expand-word`                         |                  |
| Ctrl-X =                         | カーソル位置の情報を表示                     | `what-cursor-position`                |                  |
| Ctrl-X Ctrl-B                    | 対応する括弧へ                               | `vi-match-bracket`                    |                  |
| Ctrl-X Ctrl-F                    | 次に入力した文字まで移動                     | `vi-find-next-char`                   |                  |
| Ctrl-X Ctrl-J                    | 次の行と結合                                 | `vi-join`                             |                  |
| Ctrl-X Ctrl-K                    | 入力全体を削除                               | `kill-buffer`                         |                  |
| Ctrl-X Ctrl-N                    | 履歴から次のコマンドを推測                   | `infer-next-history`                  |                  |
| Ctrl-X Ctrl-O                    | 上書きモード切り替え                         | `overwrite-mode`                      |                  |
| Ctrl-X Ctrl-U                    | 元に戻す                                     | `undo`                                |                  |
| Ctrl-X Ctrl-V                    | vi コマンドモードへ                          | `vi-cmd-mode`                         |                  |
| Ctrl-X Ctrl-X                    | カーソルとマークを入れ替え                   | `exchange-point-and-mark`             |                  |
| Ctrl-X G                         | 展開結果を一覧表示                           | `list-expand`                         |                  |
| Ctrl-X g                         | 展開結果を一覧表示                           | `list-expand`                         |                  |
| Ctrl-X r                         | 履歴を後方インクリメンタル検索               | `history-incremental-search-backward` |                  |
| Ctrl-X s                         | 履歴を前方インクリメンタル検索               | `history-incremental-search-forward`  |                  |
| Ctrl-X u                         | 元に戻す                                     | `undo`                                |                  |
| Alt-Space                        | 履歴展開（`!!` など）を展開                  | `expand-history`                      |                  |
| Alt-!                            | 履歴展開（`!!` など）を展開                  | `expand-history`                      |                  |
| Alt-"                            | リージョンをクォート                         | `quote-region`                        |                  |
| Alt-$                            | 単語のスペルを訂正                           | `spell-word`                          |                  |
| Alt-'                            | 行全体をクォート                             | `quote-line`                          |                  |
| Alt--                            | 負の数値引数                                 | `neg-argument`                        |                  |
| Alt-.                            | 直前のコマンドの最後の引数を挿入             | `insert-last-word`                    |                  |
| Alt-0                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-1                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-2                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-3                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-4                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-5                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-6                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-7                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-8                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-9                            | 数値引数                                     | `digit-argument`                      |                  |
| Alt-<                            | 入力の先頭 / 履歴の最初                      | `beginning-of-buffer-or-history`      |                  |
| Alt->                            | 入力の末尾 / 履歴の最後                      | `end-of-buffer-or-history`            |                  |
| Alt-?                            | カーソル位置のコマンドの実体を表示           | `which-command`                       |                  |
| Alt-Backspace                    | 前の単語を削除                               | `backward-kill-word`                  |                  |
| Alt-Ctrl-_                       | 直前の単語を複製                             | `copy-prev-word`                      |                  |
| Alt-Ctrl-D                       | 補完候補を一覧表示                           | `list-choices`                        |                  |
| Alt-Ctrl-G                       | 入力を中断                                   | `send-break`                          |                  |
| Alt-Ctrl-H                       | 前の単語を削除                               | `backward-kill-word`                  |                  |
| Alt-Ctrl-I                       | Esc を除いた文字を入力                       | `self-insert-unmeta`                  |                  |
| Alt-Ctrl-J                       | Esc を除いた文字を入力                       | `self-insert-unmeta`                  |                  |
| Alt-Ctrl-L                       | 画面クリア                                   | `clear-screen`                        |                  |
| Alt-Ctrl-M                       | Esc を除いた文字を入力                       | `self-insert-unmeta`                  |                  |
| Alt-_                            | 直前のコマンドの最後の引数を挿入             | `insert-last-word`                    |                  |
| Alt-Shift-a                      | 実行して行を残す                             | `accept-and-hold`                     |                  |
| Alt-a                            | 実行して行を残す                             | `accept-and-hold`                     |                  |
| Alt-Shift-b                      | 前の単語へ                                   | `backward-word`                       |                  |
| Alt-b                            | 前の単語へ                                   | `backward-word`                       |                  |
| Alt-Shift-c                      | 単語の先頭を大文字に                         | `capitalize-word`                     |                  |
| Alt-Shift-d                      | 次の単語を削除                               | `kill-word`                           |                  |
| Alt-d                            | 次の単語を削除                               | `kill-word`                           |                  |
| Alt-Shift-f                      | 次の単語へ                                   | `forward-word`                        |                  |
| Alt-f                            | 次の単語へ                                   | `forward-word`                        |                  |
| Alt-Shift-g                      | `push-line` で退避した行を取り出す           | `get-line`                            |                  |
| Alt-g                            | `push-line` で退避した行を取り出す           | `get-line`                            |                  |
| Alt-Shift-h                      | カーソル位置のコマンドのヘルプ               | `run-help`                            |                  |
| Alt-h                            | カーソル位置のコマンドのヘルプ               | `run-help`                            |                  |
| Alt-Shift-l                      | 単語を小文字に                               | `down-case-word`                      |                  |
| Alt-Shift-n                      | 行頭が一致する履歴を前方検索                 | `history-search-forward`              |                  |
| Alt-n                            | 行頭が一致する履歴を前方検索                 | `history-search-forward`              |                  |
| Alt-Shift-p                      | 行頭が一致する履歴を後方検索                 | `history-search-backward`             |                  |
| Alt-p                            | 行頭が一致する履歴を後方検索                 | `history-search-backward`             |                  |
| Alt-Shift-q                      | 入力中の行を退避（次のコマンド実行後に復元） | `push-line`                           |                  |
| Alt-q                            | 入力中の行を退避（次のコマンド実行後に復元） | `push-line`                           |                  |
| Alt-Shift-s                      | 単語のスペルを訂正                           | `spell-word`                          |                  |
| Alt-s                            | 単語のスペルを訂正                           | `spell-word`                          |                  |
| Alt-Shift-t                      | 単語を入れ替え                               | `transpose-words`                     |                  |
| Alt-t                            | 単語を入れ替え                               | `transpose-words`                     |                  |
| Alt-Shift-u                      | 単語を大文字に                               | `up-case-word`                        |                  |
| Alt-u                            | 単語を大文字に                               | `up-case-word`                        |                  |
| Alt-Shift-w                      | リージョンをコピー                           | `copy-region-as-kill`                 |                  |
| Alt-x                            | ウィジェット名を入力して実行                 | `execute-named-cmd`                   |                  |
| Alt-y                            | 貼り付けを前の kill に置換                   | `yank-pop`                            |                  |
| Alt-z                            | 直前の `execute-named-cmd` を再実行          | `execute-last-named-cmd`              |                  |
| Alt-                             |                                              | 指定した列へ                          | `vi-goto-column` |  |
| （貼り付け開始の制御シーケンス） | 貼り付け（改行で実行されない）               | `bracketed-paste`                     |                  |
| →                                | 1 文字右へ                                   | `forward-char`                        |                  |
| ←                                | 1 文字左へ                                   | `backward-char`                       |                  |
| →（アプリケーションモード）      | 1 文字右へ                                   | `forward-char`                        |                  |
| ←（アプリケーションモード）      | 1 文字左へ                                   | `backward-char`                       |                  |

---

## 付録: エイリアス一覧

WSL（Ubuntu 22.04）で実際にこの設定を読み込み、有効になっているエイリアスを定義元ごとに分けたもの。自分の設定（`zshrc_alias.sh`）の分は [エイリアス](#エイリアス-zshrc_aliassh) を参照。同名のエイリアスは最後に定義したものだけを載せている。種類の「グローバル」はコマンドラインのどこでも展開されるもの（例: `ls G foo` → `ls | grep foo`）、「サフィックス」は拡張子に対して働くもの（例: `foo.tar` と打つと `tar tf foo.tar` になる）。

<details>
<summary><b>lib/directories.zsh</b>（17 個）</summary>

| エイリアス | 展開             | 種類       |
| ---------- | ---------------- | ---------- |
| `...`      | `../..`          | グローバル |
| `....`     | `../../..`       | グローバル |
| `.....`    | `../../../..`    | グローバル |
| `......`   | `../../../../..` | グローバル |
| `-`        | `cd -`           |            |
| `1`        | `cd -1`          |            |
| `2`        | `cd -2`          |            |
| `3`        | `cd -3`          |            |
| `4`        | `cd -4`          |            |
| `5`        | `cd -5`          |            |
| `6`        | `cd -6`          |            |
| `7`        | `cd -7`          |            |
| `8`        | `cd -8`          |            |
| `9`        | `cd -9`          |            |
| `lsa`      | `ls -lah`        |            |
| `md`       | `mkdir -p`       |            |
| `rd`       | `rmdir`          |            |

</details>

<details>
<summary><b>lib/grep.zsh</b>（2 個）</summary>

| エイリアス | 展開      | 種類 |
| ---------- | --------- | ---- |
| `egrep`    | `grep -E` |      |
| `fgrep`    | `grep -F` |      |

</details>

<details>
<summary><b>lib/history.zsh</b>（1 個）</summary>

| エイリアス | 展開          | 種類 |
| ---------- | ------------- | ---- |
| `history`  | `omz_history` |      |

</details>

<details>
<summary><b>lib/misc.zsh</b>（1 個）</summary>

| エイリアス | 展開    | 種類 |
| ---------- | ------- | ---- |
| `_`        | `sudo ` |      |

</details>

<details>
<summary><b>lib/theme-and-appearance.zsh</b>（1 個）</summary>

| エイリアス | 展開             | 種類 |
| ---------- | ---------------- | ---- |
| `ls`       | `ls --color=tty` |      |

</details>

<details>
<summary><b>colorize プラグイン</b>（2 個）</summary>

| エイリアス | 展開            | 種類 |
| ---------- | --------------- | ---- |
| `ccat`     | `colorize_cat`  |      |
| `cless`    | `colorize_less` |      |

</details>

<details>
<summary><b>common-aliases プラグイン</b>（70 個）</summary>

| エイリアス | 展開                                                | 種類         |
| ---------- | --------------------------------------------------- | ------------ |
| `CA`       | `2>&1 \| cat -A`                                    | グローバル   |
| `G`        | `\| grep`                                           | グローバル   |
| `H`        | `\| head`                                           | グローバル   |
| `L`        | `\| less`                                           | グローバル   |
| `LL`       | `2>&1 \| less`                                      | グローバル   |
| `M`        | `\| most`                                           | グローバル   |
| `NE`       | `2> /dev/null`                                      | グローバル   |
| `NUL`      | `> /dev/null 2>&1`                                  | グローバル   |
| `P`        | `2>&1\| pygmentize -l pytb`                         | グローバル   |
| `T`        | `\| tail`                                           | グローバル   |
| `cp`       | `cp -i`                                             |              |
| `dud`      | `du -d 1 -h`                                        |              |
| `duf`      | `du -sh *`                                          |              |
| `fd`       | `find . -type d -name`                              |              |
| `ff`       | `find . -type f -name`                              |              |
| `grep`     | `grep --color`                                      |              |
| `help`     | `man`                                               |              |
| `hgrep`    | `fc -El 0 \| grep`                                  |              |
| `l`        | `ls -lFh`                                           |              |
| `lS`       | `ls -1FSsh`                                         |              |
| `lart`     | `ls -1Fcart`                                        |              |
| `ldot`     | `ls -ld .*`                                         |              |
| `lr`       | `ls -tRFh`                                          |              |
| `lrt`      | `ls -1Fcrt`                                         |              |
| `lsn`      | `ls -1`                                             |              |
| `lsr`      | `ls -lARFh`                                         |              |
| `lt`       | `ls -ltFh`                                          |              |
| `mv`       | `mv -i`                                             |              |
| `p`        | `ps -f`                                             |              |
| `rm`       | `rm -i`                                             |              |
| `sgrep`    | `grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} ` |              |
| `sortnr`   | `sort -n -r`                                        |              |
| `t`        | `tail -f`                                           |              |
| `unexport` | `unset`                                             |              |
| `zshrc`    | `${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc`               |              |
| `TXT`      | `$EDITOR`                                           | サフィックス |
| `ace`      | `unace l`                                           | サフィックス |
| `ape`      | `mplayer`                                           | サフィックス |
| `asc`      | `$EDITOR`                                           | サフィックス |
| `avi`      | `mplayer`                                           | サフィックス |
| `c`        | `$EDITOR`                                           | サフィックス |
| `cc`       | `$EDITOR`                                           | サフィックス |
| `chm`      | `xchm`                                              | サフィックス |
| `cpp`      | `$EDITOR`                                           | サフィックス |
| `cxx`      | `$EDITOR`                                           | サフィックス |
| `djvu`     | `djview`                                            | サフィックス |
| `dvi`      | `xdvi`                                              | サフィックス |
| `flv`      | `mplayer`                                           | サフィックス |
| `h`        | `$EDITOR`                                           | サフィックス |
| `hh`       | `$EDITOR`                                           | サフィックス |
| `inl`      | `$EDITOR`                                           | サフィックス |
| `m4a`      | `mplayer`                                           | サフィックス |
| `mkv`      | `mplayer`                                           | サフィックス |
| `mov`      | `mplayer`                                           | サフィックス |
| `mp3`      | `mplayer`                                           | サフィックス |
| `mpeg`     | `mplayer`                                           | サフィックス |
| `mpg`      | `mplayer`                                           | サフィックス |
| `ogg`      | `mplayer`                                           | サフィックス |
| `ogm`      | `mplayer`                                           | サフィックス |
| `pdf`      | `acroread`                                          | サフィックス |
| `ps`       | `gv`                                                | サフィックス |
| `rar`      | `unrar l`                                           | サフィックス |
| `rm`       | `mplayer`                                           | サフィックス |
| `tar`      | `tar tf`                                            | サフィックス |
| `tar.gz`   | `echo `                                             | サフィックス |
| `tex`      | `$EDITOR`                                           | サフィックス |
| `txt`      | `$EDITOR`                                           | サフィックス |
| `wav`      | `mplayer`                                           | サフィックス |
| `webm`     | `mplayer`                                           | サフィックス |
| `zip`      | `unzip -l`                                          | サフィックス |

</details>

<details>
<summary><b>deno プラグイン</b>（12 個）</summary>

| エイリアス | 展開               | 種類 |
| ---------- | ------------------ | ---- |
| `dc`       | `deno compile`     |      |
| `dca`      | `deno cache`       |      |
| `dck`      | `deno check`       |      |
| `dfmt`     | `deno fmt`         |      |
| `dh`       | `deno help`        |      |
| `dli`      | `deno lint`        |      |
| `drA`      | `deno run -A`      |      |
| `drn`      | `deno run`         |      |
| `drw`      | `deno run --watch` |      |
| `dsv`      | `deno serve`       |      |
| `dts`      | `deno test`        |      |
| `dup`      | `deno upgrade`     |      |

</details>

<details>
<summary><b>docker プラグイン</b>（40 個）</summary>

| エイリアス | 展開                          | 種類 |
| ---------- | ----------------------------- | ---- |
| `dbl`      | `docker build`                |      |
| `dcin`     | `docker container inspect`    |      |
| `dcls`     | `docker container ls`         |      |
| `dclsa`    | `docker container ls -a`      |      |
| `dcprune`  | `docker container prune`      |      |
| `dib`      | `docker image build`          |      |
| `dii`      | `docker image inspect`        |      |
| `dils`     | `docker image ls`             |      |
| `dipru`    | `docker image prune -a`       |      |
| `dipu`     | `docker image push`           |      |
| `dirm`     | `docker image rm`             |      |
| `dit`      | `docker image tag`            |      |
| `dlo`      | `docker container logs`       |      |
| `dnc`      | `docker network create`       |      |
| `dncn`     | `docker network connect`      |      |
| `dndcn`    | `docker network disconnect`   |      |
| `dni`      | `docker network inspect`      |      |
| `dnls`     | `docker network ls`           |      |
| `dnprune`  | `docker network prune`        |      |
| `dnrm`     | `docker network rm`           |      |
| `dpo`      | `docker container port`       |      |
| `dps`      | `docker ps`                   |      |
| `dpsa`     | `docker ps -a`                |      |
| `dpu`      | `docker pull`                 |      |
| `dr`       | `docker container run`        |      |
| `drit`     | `docker container run -it`    |      |
| `drm`      | `docker container rm`         |      |
| `drm!`     | `docker container rm -f`      |      |
| `drs`      | `docker container restart`    |      |
| `dsprune`  | `docker system prune`         |      |
| `dst`      | `docker container start`      |      |
| `dsta`     | `docker stop $(docker ps -q)` |      |
| `dstp`     | `docker container stop`       |      |
| `dsts`     | `docker stats`                |      |
| `dtop`     | `docker top`                  |      |
| `dvi`      | `docker volume inspect`       |      |
| `dvls`     | `docker volume ls`            |      |
| `dvprune`  | `docker volume prune`         |      |
| `dxc`      | `docker container exec`       |      |
| `dxcit`    | `docker container exec -it`   |      |

</details>

<details>
<summary><b>docker-compose プラグイン</b>（18 個）</summary>

| エイリアス  | 展開                              | 種類 |
| ----------- | --------------------------------- | ---- |
| `dcb`       | `docker compose build`            |      |
| `dcdn`      | `docker compose down`             |      |
| `dce`       | `docker compose exec`             |      |
| `dcl`       | `docker compose logs`             |      |
| `dclF`      | `docker compose logs -f --tail 0` |      |
| `dclf`      | `docker compose logs -f`          |      |
| `dco`       | `docker compose`                  |      |
| `dcps`      | `docker compose ps`               |      |
| `dcpull`    | `docker compose pull`             |      |
| `dcr`       | `docker compose run`              |      |
| `dcrestart` | `docker compose restart`          |      |
| `dcrm`      | `docker compose rm`               |      |
| `dcstart`   | `docker compose start`            |      |
| `dcstop`    | `docker compose stop`             |      |
| `dcup`      | `docker compose up`               |      |
| `dcupb`     | `docker compose up --build`       |      |
| `dcupd`     | `docker compose up -d`            |      |
| `dcupdb`    | `docker compose up -d --build`    |      |

</details>

<details>
<summary><b>encode64 プラグイン</b>（3 個）</summary>

| エイリアス | 展開           | 種類 |
| ---------- | -------------- | ---- |
| `d64`      | `decode64`     |      |
| `e64`      | `encode64`     |      |
| `ef64`     | `encodefile64` |      |

</details>

<details>
<summary><b>extract プラグイン</b>（1 個）</summary>

| エイリアス | 展開      | 種類 |
| ---------- | --------- | ---- |
| `x`        | `extract` |      |

</details>

<details>
<summary><b>git プラグイン</b>（191 個）</summary>

| エイリアス             | 展開                                                                                                                            | 種類 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---- |
| `g`                    | `git`                                                                                                                           |      |
| `ga`                   | `git add`                                                                                                                       |      |
| `gaa`                  | `git add --all`                                                                                                                 |      |
| `gam`                  | `git am`                                                                                                                        |      |
| `gama`                 | `git am --abort`                                                                                                                |      |
| `gamc`                 | `git am --continue`                                                                                                             |      |
| `gams`                 | `git am --skip`                                                                                                                 |      |
| `gamscp`               | `git am --show-current-patch`                                                                                                   |      |
| `gap`                  | `git apply`                                                                                                                     |      |
| `gapa`                 | `git add --patch`                                                                                                               |      |
| `gapt`                 | `git apply --3way`                                                                                                              |      |
| `gau`                  | `git add --update`                                                                                                              |      |
| `gav`                  | `git add --verbose`                                                                                                             |      |
| `gb`                   | `git branch`                                                                                                                    |      |
| `gbD`                  | `git branch --delete --force`                                                                                                   |      |
| `gba`                  | `git branch --all`                                                                                                              |      |
| `gbd`                  | `git branch --delete`                                                                                                           |      |
| `gbg`                  | `LANG=C git branch -vv \| grep ": gone\]"`                                                                                      |      |
| `gbgD`                 | `LANG=C git branch --no-color -vv \| grep ": gone\]" \| cut -c 3- \| awk '{print $1}' \| xargs git branch -D`                   |      |
| `gbgd`                 | `LANG=C git branch --no-color -vv \| grep ": gone\]" \| cut -c 3- \| awk '{print $1}' \| xargs git branch -d`                   |      |
| `gbl`                  | `git blame -w`                                                                                                                  |      |
| `gbm`                  | `git branch --move`                                                                                                             |      |
| `gbnm`                 | `git branch --no-merged`                                                                                                        |      |
| `gbr`                  | `git branch --remotes`                                                                                                          |      |
| `gbs`                  | `git bisect`                                                                                                                    |      |
| `gbsb`                 | `git bisect bad`                                                                                                                |      |
| `gbsg`                 | `git bisect good`                                                                                                               |      |
| `gbsn`                 | `git bisect new`                                                                                                                |      |
| `gbso`                 | `git bisect old`                                                                                                                |      |
| `gbsr`                 | `git bisect reset`                                                                                                              |      |
| `gbss`                 | `git bisect start`                                                                                                              |      |
| `gc!`                  | `git commit --verbose --amend`                                                                                                  |      |
| `gcB`                  | `git checkout -B`                                                                                                               |      |
| `gca`                  | `git commit --verbose --all`                                                                                                    |      |
| `gca!`                 | `git commit --verbose --all --amend`                                                                                            |      |
| `gcam`                 | `git commit --all --message`                                                                                                    |      |
| `gcan!`                | `git commit --verbose --all --no-edit --amend`                                                                                  |      |
| `gcann!`               | `git commit --verbose --all --date=now --no-edit --amend`                                                                       |      |
| `gcans!`               | `git commit --verbose --all --signoff --no-edit --amend`                                                                        |      |
| `gcas`                 | `git commit --all --signoff`                                                                                                    |      |
| `gcasm`                | `git commit --all --signoff --message`                                                                                          |      |
| `gcb`                  | `git checkout -b`                                                                                                               |      |
| `gcf`                  | `git config --list`                                                                                                             |      |
| `gcfu`                 | `git commit --fixup`                                                                                                            |      |
| `gcl`                  | `git clone --recurse-submodules`                                                                                                |      |
| `gclean`               | `git clean --interactive -d`                                                                                                    |      |
| `gclf`                 | `git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules`                                        |      |
| `gcmsg`                | `git commit --message`                                                                                                          |      |
| `gcn`                  | `git commit --verbose --no-edit`                                                                                                |      |
| `gcn!`                 | `git commit --verbose --no-edit --amend`                                                                                        |      |
| `gco`                  | `git checkout`                                                                                                                  |      |
| `gcor`                 | `git checkout --recurse-submodules`                                                                                             |      |
| `gcount`               | `git shortlog --summary --numbered`                                                                                             |      |
| `gcp`                  | `git cherry-pick`                                                                                                               |      |
| `gcpa`                 | `git cherry-pick --abort`                                                                                                       |      |
| `gcpc`                 | `git cherry-pick --continue`                                                                                                    |      |
| `gcs`                  | `git commit --gpg-sign`                                                                                                         |      |
| `gcsm`                 | `git commit --signoff --message`                                                                                                |      |
| `gcss`                 | `git commit --gpg-sign --signoff`                                                                                               |      |
| `gcssm`                | `git commit --gpg-sign --signoff --message`                                                                                     |      |
| `gd`                   | `git diff`                                                                                                                      |      |
| `gdca`                 | `git diff --cached`                                                                                                             |      |
| `gdct`                 | `git describe --tags $(git rev-list --tags --max-count=1)`                                                                      |      |
| `gdcw`                 | `git diff --cached --word-diff`                                                                                                 |      |
| `gds`                  | `git diff --staged`                                                                                                             |      |
| `gdt`                  | `git diff-tree --no-commit-id --name-only -r`                                                                                   |      |
| `gdup`                 | `git diff @{upstream}`                                                                                                          |      |
| `gdw`                  | `git diff --word-diff`                                                                                                          |      |
| `gf`                   | `git fetch`                                                                                                                     |      |
| `gfa`                  | `git fetch --all --tags --prune --jobs=10`                                                                                      |      |
| `gfg`                  | `git ls-files \| grep`                                                                                                          |      |
| `gfo`                  | `git fetch origin`                                                                                                              |      |
| `gga`                  | `git gui citool --amend`                                                                                                        |      |
| `ggpull`               | `git pull origin "$(git_current_branch)"`                                                                                       |      |
| `ggpur`                | `ggu`                                                                                                                           |      |
| `ggpush`               | `git push origin "$(git_current_branch)"`                                                                                       |      |
| `ggsup`                | `git branch --set-upstream-to=origin/$(git_current_branch)`                                                                     |      |
| `ghh`                  | `git help`                                                                                                                      |      |
| `gignore`              | `git update-index --assume-unchanged`                                                                                           |      |
| `gignored`             | `git ls-files -v \| grep "^[[:lower:]]"`                                                                                        |      |
| `git-svn-dcommit-push` | `git svn dcommit && git push github $(git_main_branch):svntrunk`                                                                |      |
| `gk`                   | `\gitk --all --branches &!`                                                                                                     |      |
| `gke`                  | `\gitk --all $(git log --walk-reflogs --pretty=%h) &!`                                                                          |      |
| `glgg`                 | `git log --graph`                                                                                                               |      |
| `glgga`                | `git log --graph --decorate --all`                                                                                              |      |
| `glgm`                 | `git log --graph --max-count=10`                                                                                                |      |
| `glgp`                 | `git log --stat --patch`                                                                                                        |      |
| `glo`                  | `git log --oneline --decorate`                                                                                                  |      |
| `glod`                 | `git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"`                        |      |
| `glods`                | `git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short`           |      |
| `glog`                 | `git log --oneline --decorate --graph`                                                                                          |      |
| `gloga`                | `git log --oneline --decorate --graph --all`                                                                                    |      |
| `glol`                 | `git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"`                        |      |
| `glola`                | `git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all`                  |      |
| `glols`                | `git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat`                 |      |
| `glp`                  | `_git_log_prettily`                                                                                                             |      |
| `gluc`                 | `git pull upstream $(git_current_branch)`                                                                                       |      |
| `glum`                 | `git pull upstream $(git_main_branch)`                                                                                          |      |
| `gm`                   | `git merge`                                                                                                                     |      |
| `gma`                  | `git merge --abort`                                                                                                             |      |
| `gmc`                  | `git merge --continue`                                                                                                          |      |
| `gmff`                 | `git merge --ff-only`                                                                                                           |      |
| `gms`                  | `git merge --squash`                                                                                                            |      |
| `gmtl`                 | `git mergetool --no-prompt`                                                                                                     |      |
| `gmtlvim`              | `git mergetool --no-prompt --tool=vimdiff`                                                                                      |      |
| `gmum`                 | `git merge upstream/$(git_main_branch)`                                                                                         |      |
| `gp`                   | `git push`                                                                                                                      |      |
| `gpd`                  | `git push --dry-run`                                                                                                            |      |
| `gpf`                  | `git push --force-with-lease --force-if-includes`                                                                               |      |
| `gpf!`                 | `git push --force`                                                                                                              |      |
| `gpoat`                | `git push origin --all && git push origin --tags`                                                                               |      |
| `gpod`                 | `git push origin --delete`                                                                                                      |      |
| `gpr`                  | `git pull --rebase`                                                                                                             |      |
| `gpra`                 | `git pull --rebase --autostash`                                                                                                 |      |
| `gprav`                | `git pull --rebase --autostash -v`                                                                                              |      |
| `gpristine`            | `git reset --hard && git clean --force -dfx`                                                                                    |      |
| `gprom`                | `git pull --rebase origin $(git_main_branch)`                                                                                   |      |
| `gpromi`               | `git pull --rebase=interactive origin $(git_main_branch)`                                                                       |      |
| `gprum`                | `git pull --rebase upstream $(git_main_branch)`                                                                                 |      |
| `gprumi`               | `git pull --rebase=interactive upstream $(git_main_branch)`                                                                     |      |
| `gprv`                 | `git pull --rebase -v`                                                                                                          |      |
| `gpsup`                | `git push --set-upstream origin $(git_current_branch)`                                                                          |      |
| `gpsupf`               | `git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes`                                   |      |
| `gpu`                  | `git push upstream`                                                                                                             |      |
| `gpv`                  | `git push --verbose`                                                                                                            |      |
| `gra`                  | `git remote add`                                                                                                                |      |
| `grb`                  | `git rebase`                                                                                                                    |      |
| `grba`                 | `git rebase --abort`                                                                                                            |      |
| `grbc`                 | `git rebase --continue`                                                                                                         |      |
| `grbd`                 | `git rebase $(git_develop_branch)`                                                                                              |      |
| `grbi`                 | `git rebase --interactive`                                                                                                      |      |
| `grbm`                 | `git rebase $(git_main_branch)`                                                                                                 |      |
| `grbo`                 | `git rebase --onto`                                                                                                             |      |
| `grbom`                | `git rebase origin/$(git_main_branch)`                                                                                          |      |
| `grbs`                 | `git rebase --skip`                                                                                                             |      |
| `grbum`                | `git rebase upstream/$(git_main_branch)`                                                                                        |      |
| `grev`                 | `git revert`                                                                                                                    |      |
| `greva`                | `git revert --abort`                                                                                                            |      |
| `grevc`                | `git revert --continue`                                                                                                         |      |
| `grf`                  | `git reflog`                                                                                                                    |      |
| `grh`                  | `git reset`                                                                                                                     |      |
| `grhh`                 | `git reset --hard`                                                                                                              |      |
| `grhk`                 | `git reset --keep`                                                                                                              |      |
| `grhs`                 | `git reset --soft`                                                                                                              |      |
| `grm`                  | `git rm`                                                                                                                        |      |
| `grmc`                 | `git rm --cached`                                                                                                               |      |
| `grmv`                 | `git remote rename`                                                                                                             |      |
| `groh`                 | `git reset origin/$(git_current_branch) --hard`                                                                                 |      |
| `grrm`                 | `git remote remove`                                                                                                             |      |
| `grs`                  | `git restore`                                                                                                                   |      |
| `grset`                | `git remote set-url`                                                                                                            |      |
| `grss`                 | `git restore --source`                                                                                                          |      |
| `grst`                 | `git restore --staged`                                                                                                          |      |
| `grt`                  | `cd "$(git rev-parse --show-toplevel \|\| echo .)"`                                                                             |      |
| `gru`                  | `git reset --`                                                                                                                  |      |
| `grup`                 | `git remote update`                                                                                                             |      |
| `grv`                  | `git remote --verbose`                                                                                                          |      |
| `gsb`                  | `git status --short --branch`                                                                                                   |      |
| `gsd`                  | `git svn dcommit`                                                                                                               |      |
| `gsh`                  | `git show`                                                                                                                      |      |
| `gsi`                  | `git submodule init`                                                                                                            |      |
| `gsps`                 | `git show --pretty=short --show-signature`                                                                                      |      |
| `gsr`                  | `git svn rebase`                                                                                                                |      |
| `gss`                  | `git status --short`                                                                                                            |      |
| `gsta`                 | `git stash push`                                                                                                                |      |
| `gstaa`                | `git stash apply`                                                                                                               |      |
| `gstall`               | `git stash --all`                                                                                                               |      |
| `gstc`                 | `git stash clear`                                                                                                               |      |
| `gstd`                 | `git stash drop`                                                                                                                |      |
| `gstl`                 | `git stash list`                                                                                                                |      |
| `gstp`                 | `git stash pop`                                                                                                                 |      |
| `gsts`                 | `git stash show --patch`                                                                                                        |      |
| `gstu`                 | `gsta --include-untracked`                                                                                                      |      |
| `gsw`                  | `git switch`                                                                                                                    |      |
| `gswc`                 | `git switch --create`                                                                                                           |      |
| `gswd`                 | `git switch $(git_develop_branch)`                                                                                              |      |
| `gswm`                 | `git switch $(git_main_branch)`                                                                                                 |      |
| `gta`                  | `git tag --annotate`                                                                                                            |      |
| `gtl`                  | `gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl`                                                              |      |
| `gts`                  | `git tag --sign`                                                                                                                |      |
| `gtv`                  | `git tag \| sort -V`                                                                                                            |      |
| `gunignore`            | `git update-index --no-assume-unchanged`                                                                                        |      |
| `gunwip`               | `git rev-list --max-count=1 --format="%s" HEAD \| grep -q "\--wip--" && git reset HEAD~1`                                       |      |
| `gwch`                 | `git log --patch --abbrev-commit --pretty=medium --raw`                                                                         |      |
| `gwip`                 | `git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"` |      |
| `gwipe`                | `git reset --hard && git clean --force -df`                                                                                     |      |
| `gwt`                  | `git worktree`                                                                                                                  |      |
| `gwta`                 | `git worktree add`                                                                                                              |      |
| `gwtls`                | `git worktree list`                                                                                                             |      |
| `gwtmv`                | `git worktree move`                                                                                                             |      |
| `gwtrm`                | `git worktree remove`                                                                                                           |      |

</details>

<details>
<summary><b>git-flow プラグイン</b>（24 個）</summary>

| エイリアス | 展開                                                         | 種類 |
| ---------- | ------------------------------------------------------------ | ---- |
| `gcd`      | `git checkout $(git config gitflow.branch.develop)`          |      |
| `gch`      | `git checkout $(git config gitflow.prefix.hotfix)`           |      |
| `gcr`      | `git checkout $(git config gitflow.prefix.release)`          |      |
| `gfl`      | `git flow`                                                   |      |
| `gflf`     | `git flow feature`                                           |      |
| `gflff`    | `git flow feature finish`                                    |      |
| `gflffc`   | `git flow feature finish ${$(git_current_branch)#feature/}`  |      |
| `gflfp`    | `git flow feature publish`                                   |      |
| `gflfpc`   | `git flow feature publish ${$(git_current_branch)#feature/}` |      |
| `gflfpll`  | `git flow feature pull`                                      |      |
| `gflfs`    | `git flow feature start`                                     |      |
| `gflh`     | `git flow hotfix`                                            |      |
| `gflhf`    | `git flow hotfix finish`                                     |      |
| `gflhfc`   | `git flow hotfix finish ${$(git_current_branch)#hotfix/}`    |      |
| `gflhp`    | `git flow hotfix publish`                                    |      |
| `gflhpc`   | `git flow hotfix publish ${$(git_current_branch)#hotfix/}`   |      |
| `gflhs`    | `git flow hotfix start`                                      |      |
| `gfli`     | `git flow init`                                              |      |
| `gflr`     | `git flow release`                                           |      |
| `gflrf`    | `git flow release finish`                                    |      |
| `gflrfc`   | `git flow release finish ${$(git_current_branch)#release/}`  |      |
| `gflrp`    | `git flow release publish`                                   |      |
| `gflrpc`   | `git flow release publish ${$(git_current_branch)#release/}` |      |
| `gflrs`    | `git flow release start`                                     |      |

</details>

<details>
<summary><b>history プラグイン</b>（4 個）</summary>

| エイリアス | 展開                 | 種類 |
| ---------- | -------------------- | ---- |
| `h`        | `history`            |      |
| `hl`       | `history \| less`    |      |
| `hs`       | `history \| grep`    |      |
| `hsi`      | `history \| grep -i` |      |

</details>

<details>
<summary><b>macos プラグイン</b>（2 個）</summary>

| エイリアス  | 展開                                                                              | 種類 |
| ----------- | --------------------------------------------------------------------------------- | ---- |
| `hidefiles` | `defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder` |      |
| `showfiles` | `defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder`  |      |

</details>

<details>
<summary><b>npm プラグイン</b>（19 個）</summary>

| エイリアス | 展開                        | 種類 |
| ---------- | --------------------------- | ---- |
| `npmD`     | `npm i -D `                 |      |
| `npmE`     | `PATH="$(npm bin)":"$PATH"` |      |
| `npmF`     | `npm i -f`                  |      |
| `npmI`     | `npm init`                  |      |
| `npmL`     | `npm list`                  |      |
| `npmL0`    | `npm ls --depth=0`          |      |
| `npmO`     | `npm outdated`              |      |
| `npmP`     | `npm publish`               |      |
| `npmR`     | `npm run`                   |      |
| `npmS`     | `npm i -S `                 |      |
| `npmSe`    | `npm search`                |      |
| `npmU`     | `npm update`                |      |
| `npmV`     | `npm -v`                    |      |
| `npmg`     | `npm i -g `                 |      |
| `npmi`     | `npm info`                  |      |
| `npmrb`    | `npm run build`             |      |
| `npmrd`    | `npm run dev`               |      |
| `npmst`    | `npm start`                 |      |
| `npmt`     | `npm test`                  |      |

</details>

<details>
<summary><b>pip プラグイン</b>（8 個）</summary>

| エイリアス | 展開                              | 種類 |
| ---------- | --------------------------------- | ---- |
| `pip`      | `noglob pip`                      |      |
| `pipgi`    | `pip freeze \| grep`              |      |
| `pipi`     | `pip install`                     |      |
| `pipir`    | `pip install -r requirements.txt` |      |
| `piplo`    | `pip list -o`                     |      |
| `pipreq`   | `pip freeze > requirements.txt`   |      |
| `pipu`     | `pip install --upgrade`           |      |
| `pipun`    | `pip uninstall`                   |      |

</details>

<details>
<summary><b>python プラグイン</b>（4 個）</summary>

| エイリアス | 展開                        | 種類 |
| ---------- | --------------------------- | ---- |
| `py`       | `python3`                   |      |
| `pyfind`   | `find . -name "*.py"`       |      |
| `pygrep`   | `grep -nr --include="*.py"` |      |
| `pyserver` | `python3 -m http.server`    |      |

</details>

<details>
<summary><b>rsync プラグイン</b>（4 個）</summary>

| エイリアス          | 展開                                             | 種類 |
| ------------------- | ------------------------------------------------ | ---- |
| `rsync-copy`        | `rsync -avz --progress -h`                       |      |
| `rsync-move`        | `rsync -avz --progress -h --remove-source-files` |      |
| `rsync-synchronize` | `rsync -avzu --delete --progress -h`             |      |
| `rsync-update`      | `rsync -avzu --progress -h`                      |      |

</details>

<details>
<summary><b>systemadmin プラグイン</b>（10 個）</summary>

| エイリアス | 展開                                                                         | 種類 |
| ---------- | ---------------------------------------------------------------------------- | ---- |
| `clr`      | `clear; echo Currently logged in on $TTY, as $USERNAME in directory $PWD.`   |      |
| `hist10`   | `print -l ${(o)history%% *} \| uniq -c \| sort -nr \| head -n 10`            |      |
| `mkdir`    | `mkdir -pv`                                                                  |      |
| `path`     | `print -l $path`                                                             |      |
| `ping`     | `ping -c 5`                                                                  |      |
| `ping6`    | `ping6 -c 5`                                                                 |      |
| `pscpu`    | `ps -e -o pcpu,cpu,nice,state,cputime,args \| sort -k1,1n -nr`               |      |
| `pscpu10`  | `ps -e -o pcpu,cpu,nice,state,cputime,args \| sort -k1,1n -nr \| head -n 10` |      |
| `psmem`    | `ps -e -orss=,args= \| sort -b -k1 -nr`                                      |      |
| `psmem10`  | `ps -e -orss=,args= \| sort -b -k1 -nr \| head -n 10`                        |      |

</details>

<details>
<summary><b>systemd プラグイン</b>（121 個）</summary>

| エイリアス                  | 展開                                     | 種類 |
| --------------------------- | ---------------------------------------- | ---- |
| `sc-add-requires`           | `sudo systemctl add-requires`            |      |
| `sc-add-wants`              | `sudo systemctl add-wants`               |      |
| `sc-cancel`                 | `sudo systemctl cancel`                  |      |
| `sc-cat`                    | `systemctl cat`                          |      |
| `sc-daemon-reexec`          | `sudo systemctl daemon-reexec`           |      |
| `sc-daemon-reload`          | `sudo systemctl daemon-reload`           |      |
| `sc-default`                | `sudo systemctl default`                 |      |
| `sc-disable`                | `sudo systemctl disable`                 |      |
| `sc-disable-now`            | `sc-disable --now`                       |      |
| `sc-edit`                   | `sudo systemctl edit`                    |      |
| `sc-emergency`              | `sudo systemctl emergency`               |      |
| `sc-enable`                 | `sudo systemctl enable`                  |      |
| `sc-enable-now`             | `sc-enable --now`                        |      |
| `sc-failed`                 | `systemctl --failed`                     |      |
| `sc-get-default`            | `systemctl get-default`                  |      |
| `sc-halt`                   | `sudo systemctl halt`                    |      |
| `sc-help`                   | `systemctl help`                         |      |
| `sc-hibernate`              | `systemctl hibernate`                    |      |
| `sc-hybrid-sleep`           | `systemctl hybrid-sleep`                 |      |
| `sc-import-environment`     | `sudo systemctl import-environment`      |      |
| `sc-is-active`              | `systemctl is-active`                    |      |
| `sc-is-enabled`             | `systemctl is-enabled`                   |      |
| `sc-is-failed`              | `systemctl is-failed`                    |      |
| `sc-is-system-running`      | `systemctl is-system-running`            |      |
| `sc-isolate`                | `sudo systemctl isolate`                 |      |
| `sc-kexec`                  | `sudo systemctl kexec`                   |      |
| `sc-kill`                   | `sudo systemctl kill`                    |      |
| `sc-link`                   | `sudo systemctl link`                    |      |
| `sc-list-dependencies`      | `systemctl list-dependencies`            |      |
| `sc-list-jobs`              | `systemctl list-jobs`                    |      |
| `sc-list-machines`          | `sudo systemctl list-machines`           |      |
| `sc-list-sockets`           | `systemctl list-sockets`                 |      |
| `sc-list-timers`            | `systemctl list-timers`                  |      |
| `sc-list-unit-files`        | `systemctl list-unit-files`              |      |
| `sc-list-units`             | `systemctl list-units`                   |      |
| `sc-load`                   | `sudo systemctl load`                    |      |
| `sc-mask`                   | `sudo systemctl mask`                    |      |
| `sc-mask-now`               | `sc-mask --now`                          |      |
| `sc-poweroff`               | `systemctl poweroff`                     |      |
| `sc-preset`                 | `sudo systemctl preset`                  |      |
| `sc-preset-all`             | `sudo systemctl preset-all`              |      |
| `sc-reboot`                 | `systemctl reboot`                       |      |
| `sc-reenable`               | `sudo systemctl reenable`                |      |
| `sc-reload`                 | `sudo systemctl reload`                  |      |
| `sc-reload-or-restart`      | `sudo systemctl reload-or-restart`       |      |
| `sc-rescue`                 | `sudo systemctl rescue`                  |      |
| `sc-reset-failed`           | `sudo systemctl reset-failed`            |      |
| `sc-restart`                | `sudo systemctl restart`                 |      |
| `sc-revert`                 | `sudo systemctl revert`                  |      |
| `sc-set-default`            | `sudo systemctl set-default`             |      |
| `sc-set-environment`        | `sudo systemctl set-environment`         |      |
| `sc-set-property`           | `sudo systemctl set-property`            |      |
| `sc-show`                   | `systemctl show`                         |      |
| `sc-show-environment`       | `systemctl show-environment`             |      |
| `sc-start`                  | `sudo systemctl start`                   |      |
| `sc-status`                 | `systemctl status`                       |      |
| `sc-stop`                   | `sudo systemctl stop`                    |      |
| `sc-suspend`                | `systemctl suspend`                      |      |
| `sc-switch-root`            | `sudo systemctl switch-root`             |      |
| `sc-try-reload-or-restart`  | `sudo systemctl try-reload-or-restart`   |      |
| `sc-try-restart`            | `sudo systemctl try-restart`             |      |
| `sc-unmask`                 | `sudo systemctl unmask`                  |      |
| `sc-unset-environment`      | `sudo systemctl unset-environment`       |      |
| `scu-add-requires`          | `systemctl --user add-requires`          |      |
| `scu-add-wants`             | `systemctl --user add-wants`             |      |
| `scu-cancel`                | `systemctl --user cancel`                |      |
| `scu-cat`                   | `systemctl --user cat`                   |      |
| `scu-daemon-reexec`         | `systemctl --user daemon-reexec`         |      |
| `scu-daemon-reload`         | `systemctl --user daemon-reload`         |      |
| `scu-default`               | `systemctl --user default`               |      |
| `scu-disable`               | `systemctl --user disable`               |      |
| `scu-disable-now`           | `scu-disable --now`                      |      |
| `scu-edit`                  | `systemctl --user edit`                  |      |
| `scu-emergency`             | `systemctl --user emergency`             |      |
| `scu-enable`                | `systemctl --user enable`                |      |
| `scu-enable-now`            | `scu-enable --now`                       |      |
| `scu-failed`                | `systemctl --user --failed`              |      |
| `scu-get-default`           | `systemctl --user get-default`           |      |
| `scu-halt`                  | `systemctl --user halt`                  |      |
| `scu-help`                  | `systemctl --user help`                  |      |
| `scu-import-environment`    | `systemctl --user import-environment`    |      |
| `scu-is-active`             | `systemctl --user is-active`             |      |
| `scu-is-enabled`            | `systemctl --user is-enabled`            |      |
| `scu-is-failed`             | `systemctl --user is-failed`             |      |
| `scu-is-system-running`     | `systemctl --user is-system-running`     |      |
| `scu-isolate`               | `systemctl --user isolate`               |      |
| `scu-kexec`                 | `systemctl --user kexec`                 |      |
| `scu-kill`                  | `systemctl --user kill`                  |      |
| `scu-link`                  | `systemctl --user link`                  |      |
| `scu-list-dependencies`     | `systemctl --user list-dependencies`     |      |
| `scu-list-jobs`             | `systemctl --user list-jobs`             |      |
| `scu-list-machines`         | `systemctl --user list-machines`         |      |
| `scu-list-sockets`          | `systemctl --user list-sockets`          |      |
| `scu-list-timers`           | `systemctl --user list-timers`           |      |
| `scu-list-unit-files`       | `systemctl --user list-unit-files`       |      |
| `scu-list-units`            | `systemctl --user list-units`            |      |
| `scu-load`                  | `systemctl --user load`                  |      |
| `scu-mask`                  | `systemctl --user mask`                  |      |
| `scu-mask-now`              | `scu-mask --now`                         |      |
| `scu-preset`                | `systemctl --user preset`                |      |
| `scu-preset-all`            | `systemctl --user preset-all`            |      |
| `scu-reenable`              | `systemctl --user reenable`              |      |
| `scu-reload`                | `systemctl --user reload`                |      |
| `scu-reload-or-restart`     | `systemctl --user reload-or-restart`     |      |
| `scu-rescue`                | `systemctl --user rescue`                |      |
| `scu-reset-failed`          | `systemctl --user reset-failed`          |      |
| `scu-restart`               | `systemctl --user restart`               |      |
| `scu-revert`                | `systemctl --user revert`                |      |
| `scu-set-default`           | `systemctl --user set-default`           |      |
| `scu-set-environment`       | `systemctl --user set-environment`       |      |
| `scu-set-property`          | `systemctl --user set-property`          |      |
| `scu-show`                  | `systemctl --user show`                  |      |
| `scu-show-environment`      | `systemctl --user show-environment`      |      |
| `scu-start`                 | `systemctl --user start`                 |      |
| `scu-status`                | `systemctl --user status`                |      |
| `scu-stop`                  | `systemctl --user stop`                  |      |
| `scu-switch-root`           | `systemctl --user switch-root`           |      |
| `scu-try-reload-or-restart` | `systemctl --user try-reload-or-restart` |      |
| `scu-try-restart`           | `systemctl --user try-restart`           |      |
| `scu-unmask`                | `systemctl --user unmask`                |      |
| `scu-unset-environment`     | `systemctl --user unset-environment`     |      |

</details>

<details>
<summary><b>tmux プラグイン</b>（5 個）</summary>

| エイリアス | 展開                       | 種類 |
| ---------- | -------------------------- | ---- |
| `tds`      | `_tmux_directory_session`  |      |
| `tksv`     | `tmux kill-server`         |      |
| `tl`       | `tmux list-sessions`       |      |
| `tmux`     | `_zsh_tmux_plugin_run`     |      |
| `tmuxconf` | `$EDITOR $ZSH_TMUX_CONFIG` |      |

</details>

<details>
<summary><b>uv プラグイン</b>（22 個）</summary>

| エイリアス | 展開                                                                                     | 種類 |
| ---------- | ---------------------------------------------------------------------------------------- | ---- |
| `uv`       | `noglob uv`                                                                              |      |
| `uva`      | `uv add`                                                                                 |      |
| `uvexp`    | `uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet` |      |
| `uvi`      | `uv init`                                                                                |      |
| `uvinw`    | `uv init --no-workspace`                                                                 |      |
| `uvl`      | `uv lock`                                                                                |      |
| `uvlr`     | `uv lock --refresh`                                                                      |      |
| `uvlu`     | `uv lock --upgrade`                                                                      |      |
| `uvp`      | `uv pip`                                                                                 |      |
| `uvpi`     | `uv python install`                                                                      |      |
| `uvpl`     | `uv python list`                                                                         |      |
| `uvpp`     | `uv python pin`                                                                          |      |
| `uvpu`     | `uv python uninstall`                                                                    |      |
| `uvpy`     | `uv python`                                                                              |      |
| `uvr`      | `uv run`                                                                                 |      |
| `uvrm`     | `uv remove`                                                                              |      |
| `uvs`      | `uv sync`                                                                                |      |
| `uvsr`     | `uv sync --refresh`                                                                      |      |
| `uvsu`     | `uv sync --upgrade`                                                                      |      |
| `uvtr`     | `uv tree`                                                                                |      |
| `uvup`     | `uv self update`                                                                         |      |
| `uvv`      | `uv venv`                                                                                |      |

</details>

<details>
<summary><b>vscode プラグイン</b>（14 個）</summary>

| エイリアス | 展開                         | 種類 |
| ---------- | ---------------------------- | ---- |
| `vsca`     | `code --add`                 |      |
| `vscd`     | `code --diff`                |      |
| `vscde`    | `code --disable-extensions`  |      |
| `vsced`    | `code --extensions-dir`      |      |
| `vscg`     | `code --goto`                |      |
| `vscie`    | `code --install-extension`   |      |
| `vscl`     | `code --log`                 |      |
| `vscn`     | `code --new-window`          |      |
| `vscp`     | `code --profile`             |      |
| `vscr`     | `code --reuse-window`        |      |
| `vscu`     | `code --user-data-dir`       |      |
| `vscue`    | `code --uninstall-extension` |      |
| `vscv`     | `code --verbose`             |      |
| `vscw`     | `code --wait`                |      |

</details>

<details>
<summary><b>yarn プラグイン</b>（36 個）</summary>

| エイリアス | 展開                                      | 種類 |
| ---------- | ----------------------------------------- | ---- |
| `y`        | `yarn`                                    |      |
| `ya`       | `yarn add`                                |      |
| `yad`      | `yarn add --dev`                          |      |
| `yap`      | `yarn add --peer`                         |      |
| `yb`       | `yarn build`                              |      |
| `ycc`      | `yarn cache clean`                        |      |
| `yd`       | `yarn dev`                                |      |
| `yf`       | `yarn format`                             |      |
| `yga`      | `yarn global add`                         |      |
| `ygls`     | `yarn global list`                        |      |
| `ygrm`     | `yarn global remove`                      |      |
| `ygu`      | `yarn global upgrade`                     |      |
| `yh`       | `yarn help`                               |      |
| `yi`       | `yarn init`                               |      |
| `yifl`     | `yarn install --frozen-lockfile`          |      |
| `yii`      | `yarn install --frozen-lockfile`          |      |
| `yin`      | `yarn install`                            |      |
| `yln`      | `yarn lint`                               |      |
| `ylnf`     | `yarn lint --fix`                         |      |
| `yls`      | `yarn list`                               |      |
| `yout`     | `yarn outdated`                           |      |
| `yp`       | `yarn pack`                               |      |
| `yrm`      | `yarn remove`                             |      |
| `yrun`     | `yarn run`                                |      |
| `ys`       | `yarn serve`                              |      |
| `yst`      | `yarn start`                              |      |
| `yt`       | `yarn test`                               |      |
| `ytc`      | `yarn test --coverage`                    |      |
| `yuca`     | `yarn global upgrade && yarn cache clean` |      |
| `yui`      | `yarn upgrade-interactive`                |      |
| `yuil`     | `yarn upgrade-interactive --latest`       |      |
| `yup`      | `yarn upgrade`                            |      |
| `yv`       | `yarn version`                            |      |
| `yw`       | `yarn workspace`                          |      |
| `yws`      | `yarn workspaces`                         |      |
| `yy`       | `yarn why`                                |      |

</details>

<details>
<summary><b>z プラグイン</b>（1 個）</summary>

| エイリアス | 展開        | 種類 |
| ---------- | ----------- | ---- |
| `z`        | `zshz 2>&1` |      |

</details>

<details>
<summary><b>zsh 標準</b>（1 個）</summary>

| エイリアス      | 展開     | 種類 |
| --------------- | -------- | ---- |
| `which-command` | `whence` |      |

</details>

<details>
<summary><b>zsh-navigation-tools プラグイン</b>（9 個）</summary>

| エイリアス   | 展開          | 種類 |
| ------------ | ------------- | ---- |
| `naliases`   | `n-aliases`   |      |
| `ncd`        | `n-cd`        |      |
| `nenv`       | `n-env`       |      |
| `nfunctions` | `n-functions` |      |
| `nhelp`      | `n-help`      |      |
| `nhistory`   | `n-history`   |      |
| `nkill`      | `n-kill`      |      |
| `noptions`   | `n-options`   |      |
| `npanelize`  | `n-panelize`  |      |

</details>
