# PowerShell 設定まとめ

`powershell_config/` の設定内容。Windows の PowerShell 7（pwsh）で使う前提。プロファイルは小さな `profile.ps1` だけをコピーで配置し、そこから dotfiles 内の `powershell_main.ps1` を読み込む。起動を速くするため、外部コマンドが出力する補完・フックのスクリプトはファイルにキャッシュし、posh-git は `git` の補完を使うときまで読み込まない。

## ファイル構成

```text
powershell_config/
├── profile.ps1                  # Documents\PowerShell\profile.ps1 にコピー（powershell_main.ps1 を読み込むだけ）
├── install_powershell.ps1       # インストーラー
├── powershell_main.ps1          # エントリーポイント・補完キャッシュ・conda・各ファイルの読み込み
├── powershell_profile.ps1       # プロンプト
├── powershell_alias.ps1         # エイリアス・GitHub Copilot CLI の関数（ghcs / ghce）
├── powershell_complete.ps1      # PSReadLine のキーバインド・予測・補完
├── powershell_function.ps1      # 関数（管理者実行、ログ出力、Claude の接続先切り替え、pwsh の更新）
└── powershell_auto_install.ps1  # 未インストールのツールを入れる（インストーラーから呼ぶ。起動時には読まない）
```

## インストール

```powershell
pwsh ~/dotfiles/powershell_config/install_powershell.ps1                    # ツールの自動インストールも行う
pwsh ~/dotfiles/powershell_config/install_powershell.ps1 -SkipAutoInstall   # プロファイルの配置だけ
```

以下を行う（済んでいる処理はスキップ）。

1. pwsh（PowerShell 7）が入っているか確認する。無ければ `winget install --id Microsoft.PowerShell -e` を案内するだけで、インストールはしない
2. `profile.ps1` を `Documents\PowerShell\profile.ps1` にコピーする
   - 置き場所は pwsh の「現在のユーザー・全ホスト」用のプロファイル。Windows PowerShell 5.1 から実行しても pwsh 用の場所に置けるように、`$PROFILE` を使わずに `[Environment]::GetFolderPath('MyDocuments')` から組み立てる
   - 既存ファイルと内容が同じならスキップ、異なれば `*.bak.<日時>` にバックアップしてから上書き
   - リポジトリが `~\dotfiles` 以外にある場合は、読み込み先のパスを書き換えてからコピーする
   - 旧方式の `Microsoft.PowerShell_profile.ps1` も `powershell_main.ps1` を読み込んでいたら、設定が二重に読み込まれるので警告する（削除は手動）
3. ユーザー環境変数 `WSLENV` に `USERPROFILE/p` を追加する。WSL 側に `$USERPROFILE`（`/mnt/c/Users/<名前>` の形）が渡り、zsh の設定（`zshrc_env.sh`）が VS Code の `code` コマンドのパスを組み立てるのに使う。新しく開いたターミナルから反映される
4. `powershell_auto_install.ps1` でツールを入れる（`-SkipAutoInstall` で省略。[自動インストール](#自動インストール-powershell_auto_installps1) 参照）
5. Windows Terminal の既定のプロファイルが PowerShell 7 か確認する。違えば、[設定] > [スタートアップ] > [既定のプロファイル] で変更する手順を表示する（変更自体は手動）
   - 設定ファイルは Store 版 → Preview 版 → 非 Store 版の順に探す
   - `settings.json` はコメント付き JSON なので、Windows PowerShell 5.1 では読めずに警告になることがある

---

## 読み込み順

| 順  | ファイル                 | 内容                                                                                   |
| --- | ------------------------ | -------------------------------------------------------------------------------------- |
| 1   | `Documents\PowerShell\profile.ps1` | `~\dotfiles\powershell_config\powershell_main.ps1` があれば dot source で読み込む |
| 2   | `powershell_main.ps1`    | PATH への `.` の追加、`CLAUDE_OLLAMA_URL`、補完キャッシュの関数、conda のフック       |
| 3   | `powershell_profile.ps1` | プロンプト                                                                             |
| 4   | `powershell_alias.ps1`   | エイリアス・`ghcs` / `ghce`                                                            |
| 5   | `powershell_complete.ps1` | キーバインド・予測表示・補完（`Import-CachedCompletion` を使うので main より後）     |
| 6   | `powershell_function.ps1` | 関数                                                                                  |

- `powershell_main.ps1` 以降のファイルは `$PSScriptRoot` からの相対パスで読み込むので、リポジトリの場所に依存しない（場所に依存するのは `profile.ps1` の 1 行だけ）
- `profile.ps1` に残っている `conda init` のブロックはコメントアウト済み。conda のフックは `powershell_main.ps1` がキャッシュ経由で読み込む

---

## 基本設定 (powershell_main.ps1)

### 環境変数
| 変数                | 値                                                                                                  |
| ------------------- | --------------------------------------------------------------------------------------------------- |
| `PATH`              | 末尾に `.`（カレントディレクトリ）を追加。含まれていれば追加しない                                  |
| `CLAUDE_OLLAMA_URL` | `http://yutapc:11434`（`Use-ClaudeOllama` の接続先。ユーザー環境変数などで設定済みならその値を使う） |

### 補完・フックのキャッシュ
Windows はプロセスの起動が重く、プロファイルを読むたびに `gh` / `docker` / `uv` / `conda` などを起動して補完スクリプトを生成すると、起動が数秒単位で遅くなる。そのため生成結果をファイルに保存し、起動時はそのファイルを読むだけにする。

| 項目           | 内容                                                                                       |
| -------------- | ------------------------------------------------------------------------------------------ |
| 保存先         | `%LOCALAPPDATA%\dotfiles-pwsh-cache\<名前>.ps1`                                            |
| 再生成         | ファイルが無いとき、または最終更新から 7 日を過ぎたとき                                    |
| 生成に失敗     | 警告を出し、古いキャッシュがあればそれを読み込む                                           |
| 手動で破棄     | `Update-CompletionCache`（フォルダごと削除。次回の起動時に再生成）。ツールを更新したときに使う |

| 関数                                        | 動作                                                                 |
| ------------------------------------------- | -------------------------------------------------------------------- |
| `Import-CachedCompletion -Name -Generator`  | `Generator` の出力をキャッシュし、その内容を `Invoke-Expression` する |
| `Update-CompletionCache`                    | キャッシュを削除する                                                 |

### conda
`~\miniconda3\Scripts\conda.exe` があるときだけ、`conda shell.powershell hook` の出力をキャッシュ経由（名前 `conda-hook`）で読み込む。

---

## プロンプト (powershell_profile.ps1)

zsh の[プロンプト](zsh_config.md#プロンプト-zshrc_promptsh) と同じ見た目にしている。

```text
PS: (venv:myproject) user@HOST [main!+] ~\dotfiles E1|5s       [2026/09/30 12:34:56]
->
```

| 要素                     | 内容                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 環境ラベル               | `PS:`（青）                                                                                                                                |
| Python 環境              | `(venv:<名前>)` または `(conda:<名前>)`。venv を優先。venv の名前は、venv フォルダの親フォルダ名（`myproject\.venv` なら `myproject`）     |
| ユーザー・ホスト         | `$env:USERNAME@$env:COMPUTERNAME`（太字・黄）                                                                                              |
| Git                      | `[<branch><staged><unstaged>]`。ステージ済みは黄の `!`、未ステージ（未追跡を含む）は赤の `+`。detached HEAD は `[detached:<短いハッシュ>]` |
| カレントディレクトリ     | `$env:USERPROFILE` を `~` に置き換えたパス（太字・シアン）                                                                                 |
| 終了ステータス・実行時間 | 失敗時は赤で `E<終了コード>\|<秒>s`。成功時は 3 秒以上かかったときだけ緑で `<秒>s`                                                         |
| 日時                     | 1 行目の右端に `[yyyy/MM/dd HH:mm:ss]`（緑）                                                                                               |

2 行目は `->` だけ。

### 終了ステータスの判定
| 状態                                       | `$?`    | `$LASTEXITCODE` | 表示              |
| ------------------------------------------ | ------- | --------------- | ----------------- |
| 成功                                       | `true`  | —               | （実行時間だけ）  |
| 外部コマンドの失敗                         | `false` | 0 以外          | `E<終了コード>`   |
| コマンドが見つからない・PowerShell 内部のエラー | `false` | 0               | `E!`              |

### 実装メモ
- `prompt` の最初で `$?` と `$LASTEXITCODE` を退避する。後で呼ぶ `git` が `$LASTEXITCODE` を上書きするため
- `prompt` の最後で `$global:LASTEXITCODE = 0` に戻す。戻さないと、外部コマンドが失敗した後、PowerShell のコマンドだけを実行しても前回のコードが残って表示される
- 実行時間は、PSReadLine の `AddToHistoryHandler`（コマンドを確定したときに呼ばれる）でストップウォッチを開始し、`prompt` で止めて測る。PSReadLine が読み込まれていないときは測らない
- 右端の日時は、カーソル位置を保存（`ESC[s`）→ 右端の列へ移動 → 表示 → 復元（`ESC[u`）して書く。ウィンドウの幅は `$Host.UI.RawUI.WindowSize.Width` から取る
- `$env:VIRTUAL_ENV_DISABLE_PROMPT = 0` を設定している。zsh 側（`=1` で venv 標準の表示を消す）とは値が違う

---

## エイリアス (powershell_alias.ps1)

| エイリアス / 関数        | 内容                                                                                                              |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `vi`                     | Vim（`vim.exe`）。見つからなければ定義しない                                                                      |
| `vim`                    | Neovim（`nvim.exe`）。見つからなければ定義しない                                                                  |
| `ghcs [-t shell/gh/git] <やりたいこと>` | GitHub Copilot CLI にコマンドを 1 つ提案させて表示し、`y` で実行する。実行しなくても PSReadLine の履歴に入れるので、`↑` で呼び出して編集できる。引数が無ければ入力を求める |
| `ghce <コマンド>`        | GitHub Copilot CLI にコマンドの意味を日本語で説明させる                                                           |
| `sudo`                   | `RunAsAdmin` の別名（`powershell_function.ps1` で定義。[関数](#関数-powershell_functionps1) 参照）                 |
| `UpdatePowershell`       | `Update-Powershell` の別名                                                                                        |

- `vi` / `vim` の実行ファイルは、インストール先やバージョンに依存しないよう、起動時に次の順で探す
  - Vim: PATH 上の `vim.exe` → `Program Files\Vim\vim*\vim.exe`（`Program Files (x86)` も含め、`vim91` など数字が最も大きいもの）。Vim の公式インストーラーは PATH に追加しないため
  - Neovim: PATH 上の `nvim.exe` → `Program Files\Neovim\bin\nvim.exe`

### GitHub Copilot CLI
以前は `gh copilot` 拡張（`gh copilot suggest` / `explain`）のラッパーだったが、拡張は 2025-10-25 に提供が終わったので、後継の GitHub Copilot CLI（`copilot` コマンド）を呼ぶ形に作り直した。

| 関数                          | 動作                                                                                                         |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `Invoke-CopilotPrompt`        | `copilot -p <プロンプト> -s --no-ask-user`（非対話モード。回答だけを出力し、聞き返さない）を実行して出力を返す |
| `Get-CopilotCommandSuggestion` | 「コマンドだけを 1 行で返す」よう指示して提案させ、` ``` ` の行と空行を除いたコマンドの文字列を返す。`-Target` は `shell`（PowerShell 7）/ `gh` / `git` |

- インストールは `winget install GitHub.Copilot`（[自動インストール](#自動インストール-powershell_auto_installps1) に含めている）。初回は `copilot` を対話で起動して `/login` でログインする
- `--allow-tool` を付けないので、Copilot にファイルの編集やコマンドの実行はさせない。提案されたコマンドを実行するかどうかは、`ghcs` で確認する
- `copilot` が見つからないとき、失敗したとき（終了コードが 0 以外）は、警告を出して何もしない
- npm で入れた `copilot.cmd` には、引数の中の `"` がエスケープされずに渡って引数が途中で切れるので、`.cmd` / `.bat` のときだけ `"` を `'` に置き換えて渡す
- `-Hostname`（`GH_HOST`）と `-Debug`（`GH_DEBUG`）は、`gh` 用のオプションだったので廃止した

参考: [Running GitHub Copilot CLI programmatically](https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/run-cli-programmatically)、[Installing GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli)

---

## キーバインド・補完 (powershell_complete.ps1)

### キーバインド
PSReadLine の割り当てを emacs 風（zsh と同じ操作）にしている。

| キー     | 動作                                     | PSReadLine の関数    |
| -------- | ---------------------------------------- | -------------------- |
| `Ctrl-A` | 行頭へ                                   | `BeginningOfLine`    |
| `Ctrl-E` | 行末へ                                   | `EndOfLine`          |
| `Ctrl-F` | 1 文字右へ                               | `ForwardChar`        |
| `Ctrl-B` | 1 文字左へ                               | `BackwardChar`       |
| `Alt-F`  | 次の単語へ                               | `NextWord`           |
| `Alt-B`  | 前の単語へ                               | `BackwardWord`       |
| `Ctrl-D` | カーソル位置の文字を削除                 | `DeleteChar`         |
| `Ctrl-W` | 前の単語を削除                           | `BackwardKillWord`   |
| `Ctrl-U` | 行頭からカーソルまで削除                 | `BackwardDeleteLine` |
| `Ctrl-K` | カーソルから行末まで削除                 | `ForwardDeleteLine`  |
| `Ctrl-P` | 前の履歴                                 | `PreviousHistory`    |
| `Ctrl-N` | 次の履歴                                 | `NextHistory`        |
| `Tab`    | 補完候補をメニューで選ぶ                 | `MenuComplete`（`git` があれば、下記の posh-git の遅延読み込み付き） |
| `Ctrl-G` | 入力中の行（やりたいことを自然文で書く）を、Copilot CLI が提案したコマンドに置き換える。実行はしない | （スクリプトブロック） |

- `Ctrl-G` は以前、どこにも定義のない `Invoke-CopilotSuggest` を呼んでいて動かなかった。今は `Get-CopilotCommandSuggestion`（[GitHub Copilot CLI](#github-copilot-cli) 参照）を呼ぶ。入力が空なら何もしない

### 予測表示
PSReadLine 2.1.0 以降なら、履歴とプラグインからの予測（`PredictionSource HistoryAndPlugin`）を一覧表示（`ListView`）する。色はインライン予測が濃い灰色、一覧がシアン。

### 外部コマンドの補完
コマンドがあるときだけ、[キャッシュ](#補完フックのキャッシュ) 経由で読み込む。

| コマンド  | 生成コマンド                              |
| --------- | ----------------------------------------- |
| `gh`      | `gh completion -s powershell`             |
| `docker`  | `docker completion powershell`            |
| `kubectl` | `kubectl completion powershell`           |
| `pnpm`    | `pnpm completion pwsh`                    |
| `uv`      | `uv generate-shell-completion powershell` |
| `conda`   | `conda shell.powershell hook`（`powershell_main.ps1`） |

### git（posh-git の遅延読み込み）
posh-git は `Import-Module` に数百 ms かかるので、起動時には読み込まない。`Tab` を押したとき、入力中の行が `git` / `git.exe` で始まっていて、まだ読み込んでいなければ読み込む（入っていなければ `Install-Module posh-git -Scope CurrentUser` で入れる）。

- 「git リポジトリの中なら読み込む」という判定にしないのは、リポジトリの外で `git clone` / `git init` を打つときに補完が効かなくなるため
- プロンプトは自前の `prompt` を使うので、posh-git のプロンプト統合（`Add-PoshGitToProfile`）は使わない

### 自前の補完
公式の補完が無い、または Windows で使えないコマンドに、最小限の補完を `Register-ArgumentCompleter -Native` で登録する。

| コマンド      | 補完の内容                                                                                                                              |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `ssh` / `scp` | `~\.ssh\config` の `Host` を候補にする（ツールチップに `User@Hostname`）。`-` で始まる入力はオプション一覧（日本語の説明付き）         |
| `npm`         | `npm run` / `npm run-script` の次はカレントの `package.json` の `scripts`。それ以外は主なサブコマンド（Windows では `npm completion` が使えないため） |
| `nvm`（nvm-windows） | `use` / `uninstall` の次は `nvm list` のインストール済みバージョン、`install` の次は `latest` / `lts`、`list` / `ls` の次は `available`。それ以外はサブコマンド |

- `ssh` / `scp` の補完は、`Tab` を押すたびに `~\.ssh\config` を読み直す

---

## 関数 (powershell_function.ps1)

| 関数                  | 動作                                                                                                                                    |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `RunAsAdmin [command]`（`sudo`） | 管理者権限で新しいウィンドウを開く。引数があれば、そのコマンドを実行する。開くのは `powershell`（Windows PowerShell 5.1）で、pwsh ではない |
| `LogInfo` / `LogWarn` / `LogError` / `LogSuccess` | `[INFO ]` / `[WARN ]` / `[ERROR]` / `[ OK  ]` を付けて色付きで表示する                                                       |
| `Use-ClaudeAnthropic` | `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` を消して、Claude Code の接続先を Anthropic API に戻す（`claude` は起動しない）           |
| `Use-ClaudeOllama`    | `ANTHROPIC_AUTH_TOKEN=ollama`、`ANTHROPIC_BASE_URL=$env:CLAUDE_OLLAMA_URL`（空なら `http://localhost:11434`）にする（`claude` は起動しない） |
| `Update-Powershell`（`UpdatePowershell`） | PowerShell 7 を winget で最新にする（下記）                                                                                    |

- `Register-ArgumentCompleter -CommandName MyCommand ...` は補完の書き方の見本で、`MyCommand` というコマンドは存在しない
- Claude Code の接続先の切り替えは [Claude Code 設定まとめ](claude_config.md#接続先の切り替えシェル関数) も参照

### Update-Powershell
1. 現在のバージョンを調べる（pwsh から実行したら `$PSVersionTable`、Windows PowerShell 5.1 から実行したら `pwsh.exe` のファイルバージョン）
2. GitHub API（`PowerShell/PowerShell` の最新リリース）から最新の安定版のバージョンを取る。取れなくても更新は試みる
3. 最新なら終了。そうでなければ、別ウィンドウの Windows PowerShell 5.1 で `winget upgrade`（未インストールなら `install`）`--id Microsoft.PowerShell -e` を実行する
4. 開いている PowerShell 7 のウィンドウをすべて閉じるよう案内する

実行中の pwsh 自身を上書きしようとすると、使用中のファイルがあってインストールが止まるため、更新は別のシェル（5.1）で行う。

---

## 自動インストール (powershell_auto_install.ps1)

時間がかかり、使用許諾への同意も伴うので、プロファイルの読み込み時には実行しない。`install_powershell.ps1` から呼ぶか、手動で `. .\powershell_auto_install.ps1` する。

| 対象                          | 方法                                                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------------------------------- |
| `git`                         | winget（`Git.Git`）                                                                                     |
| `uv`                          | winget（`astral-sh.uv`）                                                                                |
| `nvm`                         | winget（`CoreyButler.NVMforWindows`）                                                                   |
| `copilot`（GitHub Copilot CLI） | winget（`GitHub.Copilot`）                                                                            |
| Node.js                       | `nvm` があって `node` が無ければ `nvm install lts` → `nvm use lts`（winget では入れない）               |
| npm                           | `npm install -g npm@latest`                                                                             |
| npm のグローバルパッケージ    | 下記の一覧を `npm install -g` でまとめて入れる                                                          |

- winget のパッケージは、コマンドが既にあればスキップする。winget が無ければ警告だけ出す
- winget で入れた後は、システムとユーザーの `Path` を読み直して、今のセッションに反映する
- npm のグローバルパッケージは毎回 `npm install -g` するので、入っているものも最新に更新される

npm のグローバルパッケージ（2026-07 時点で入っていたもの）:

| 分類       | パッケージ                                                                                                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AI・MCP    | `@anthropic-ai/claude-code`、`@google/gemini-cli`、`@notionhq/notion-mcp-server`、`mcp-markdownify-server`、`openclaw`                                                                                              |
| textlint   | `textlint`、`textlint-filter-rule-comments`、`textlint-filter-rule-whitelist`、`textlint-rule-preset-icsmedia`、`textlint-rule-preset-ja-technical-writing`、`textlint-rule-prh`、`textlint-rule-spellcheck-tech-word` |
| 開発ツール | `@google/clasp`、`deno`、`neovim`、`tree-sitter-cli`、`nb.sh`、`shx`                                                                                                                                                |
| パッケージ管理 | `pnpm`、`yarn`、`uv`                                                                                                                                                                                            |
