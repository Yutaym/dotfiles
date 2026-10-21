# Claude Code 設定まとめ

`claude_config/` の設定内容。Windows / Linux / macOS で共通の設定を使う。`CLAUDE.md`（グローバルルール）・`settings.json`・`keybindings.json`・スキルは `~/.claude` へシンボリックリンクで配置し、環境ごとに値が変わる `local-paths.md` だけはコピーで配置する。

## ファイル構成

```text
claude_config/
├── CLAUDE.md            # ~/.claude/CLAUDE.md にリンク（全プロジェクト共通のグローバルルール）
├── settings.json        # ~/.claude/settings.json にリンク（ユーザー設定）
├── keybindings.json     # ~/.claude/keybindings.json にリンク（キーバインド）
├── local-paths.md       # ~/.claude/local-paths.md にコピー（環境固有のパス。CLAUDE.md から読み込む）
├── statusline.sh        # statusLine から呼ぶ。node を探して statusline.mjs を実行する
├── statusline.mjs       # ステータスラインの表示（使用リミット・コンテキスト使用率・モデル）
├── subagent-statusline.mjs # エージェント一覧のサブエージェントの行（トークン数・直近の増え・ctx・経過時間）
├── install_claude.ps1   # インストーラー（Windows）
├── install_claude.sh    # インストーラー（Linux / macOS）
└── skills/
    ├── session-generate/ # ~/.claude/skills/session-generate にリンク（新しいタブで別セッションを起動して作業を頼むスキル）
    │   ├── SKILL.md
    │   └── scripts/
    ├── session-order/    # ~/.claude/skills/session-order にリンク（動いている別セッションを選んで作業を頼むスキル）
    │   └── SKILL.md
    ├── session-overview/ # ~/.claude/skills/session-overview にリンク（同じマシンのセッションを一覧にして要約するスキル）
    │   ├── SKILL.md
    │   └── scripts/
    ├── ssh-generate/     # ~/.claude/skills/ssh-generate にリンク（~/.ssh/config の接続先を選んで新しいタブで ssh するスキル）
    │   ├── SKILL.md
    │   └── scripts/
    ├── sync-vaults/      # ~/.claude/skills/sync-vaults にリンク（vault の同期スキル）
    │   └── SKILL.md
    └── window-generate/  # ~/.claude/skills/window-generate にリンク（新しいタブでシェルを開いて移動するスキル）
        ├── SKILL.md
        └── scripts/
```

シェル側の関連設定:

| ファイル                                  | 内容                                                                           |
| ----------------------------------------- | ------------------------------------------------------------------------------ |
| `zsh_config/zshrc_main.sh`                | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`、`CLAUDE_OLLAMA_URL` の既定値         |
| `zsh_config/zshrc_function.sh`            | `claude-anthropic` / `claude-ollama`（接続先を切り替えて起動）                 |
| `powershell_config/powershell_main.ps1`   | `CLAUDE_OLLAMA_URL` の既定値                                                   |
| `powershell_config/powershell_function.ps1` | `Use-ClaudeAnthropic` / `Use-ClaudeOllama`（接続先の環境変数だけを切り替える） |
| `powershell_config/powershell_auto_install.ps1` | npm のグローバルパッケージとして `@anthropic-ai/claude-code` を入れる      |

## インストール

```powershell
pwsh ~/dotfiles/claude_config/install_claude.ps1   # Windows
```

```sh
bash ~/dotfiles/claude_config/install_claude.sh    # Linux / macOS
```

以下を行う（済んでいる処理はスキップ）。

1. `~/.claude` が無ければ作る
2. `CLAUDE.md` / `settings.json` / `keybindings.json` を `~/.claude` にシンボリックリンクする
   - すでに同じリンク先へのリンクならスキップ
   - 同名のファイル（またはリンク切れ・別の場所へのリンク）があれば、上書きせずに警告を出してスキップする。置き換えるときは既存のファイルを手で退避・削除してから再実行する
3. `skills/` の下のスキルを、1 つずつ `~/.claude/skills/<スキル名>` にリンクする
   - `~/.claude/skills` には管理対象外のスキルも置くので、フォルダごとではなくスキルごとにリンクする
4. `local-paths.md` を `~/.claude` にコピーする（既にあれば上書きしない）。コピーしたら、この環境に合わせてパスを書き換える

> Windows でシンボリックリンクを作るには、「開発者モード」の有効化か管理者権限での実行が必要。

- Windows 版はリンクの確認に `Test-Path` ではなく `Get-Item -Force` を使う（`Test-Path` はリンク切れのシンボリックリンクを検出できないため）
- `settings.local.json`（`~/.claude` 直下、各プロジェクトの `.claude/` 下）は管理対象外。このリポジトリでも `.claude/settings.json` / `.claude/settings.local.json` は `.gitignore` で除外している

### リンクしたファイルの編集

`~/.claude/CLAUDE.md` などはリンクなので、編集はリンク先（`~/dotfiles/claude_config/` の実体）に対して行い、dotfiles リポジトリでコミットする。Claude Code 自身にも編集させるため、`local-paths.md` に実体のパスを書いてある（[local-paths.md](#local-pathsmd) 参照）。

---

## グローバルルール (CLAUDE.md)

全プロジェクトで読み込まれるユーザーメモリー。内容は次のとおり。

### 言語
返答は常に日本語で行う（ユーザーが英語などで書いた場合も）。

### 返答の正確性
裏付けの深さを 2 段階に分ける。

| 場面                                              | 裏付けの範囲                                                                                                                                                           |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 共通                                              | 参照したドキュメントに書いていないことを推測で答えない。裏付けのない内容には「嘘をついているかもしれない」と明記し、確認できた範囲と未確認の範囲を書く               |
| 通常（指定なし）                                  | トークンを抑える。知識は 1 つの事実につき検索 1〜2 回・情報源 1 つで確認。コード・設定は作業に直接かかわる部分だけ確認。要約・抜粋で足りればページ全体は読まない |
| 「詳細に調べて」「しっかり裏どりして」などの指定 | 返答に含める事実をすべて裏付ける。一次情報を優先し、食い違いや古い可能性があれば複数の情報源で突き合わせ、根拠（URL、ファイルと行番号、コマンド）を添える           |

### Python の環境構築
仮想環境・パッケージ管理は uv で行う（`uv venv` / `uv pip install` / `uv sync` / `uv run`）。`python -m venv`、素の `pip install`、conda で新しく環境を作らない。uv が無ければ公式インストーラー（`curl -LsSf https://astral.sh/uv/install.sh | sh`）で入れる。

### 環境ごとの設定
`@~/.claude/local-paths.md` の行で `local-paths.md` を読み込む（CLAUDE.md の `@パス` によるインポート）。`META_DIR` などの環境固有の値は CLAUDE.md には書かず、こちらに分ける。

### ナレッジベース（META_DIR）
`META_DIR` を、Claude Code が自由に読み書きしてよいメモ置き場として使う。

- 作業中に得た、今後も覚えておくべき内容（環境・好み・手順・調査結果・決定事項など）をトピックごとのフォルダ・ファイルに保存する
- 目次は階層にする: `META_DIR/INDEX.md` にはフォルダ単位の説明だけ、個々のファイルは各フォルダの `INDEX.md` に 1 行で書く
- 調査・解説・動作確認をしたら、返答ごとに保存するかを必ず判断する。保存しなかった場合は理由を一言書く
- 読むときは `META_DIR/INDEX.md` → フォルダの `INDEX.md` → ファイルの順にたどる
- 個人情報・機密情報は `META_DIR/private` の下に置き、外側には所在だけを書く
- `META_DIR` が未定義・存在しない場合は、使う前にユーザーに確認する

### VAULT_DIR / META_DIR の同期
| 対象                                   | 同期方法                                                                                                                  |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `META_DIR`（`VAULT_DIR/90_Meta`）      | git では管理しない（`.gitignore` で除外）。SMB 共有経由でタスクスケジューラが自動同期する。頼まれたときだけ `sync-vaults` スキルで同期 |
| `VAULT_DIR` のそれ以外                 | 編集したら確認を待たずに、作業の区切りで `git add -A` → `commit` → `pull --rebase` → `push`                               |

- コミットメッセージは `Claude: yyyy/MM/dd HH:mm:ss ±HHMM`（`date '+Claude: %Y/%m/%d %H:%M:%S %z'`）。Co-Authored-By などの帰属表示は付けない
- pull のコンフリクトや push の失敗は、強制 push などで解決せずにユーザーに報告する

### サブエージェントの名前
- 基本は名前なしで起動する（一度で終わる調べもの・並列の下調べ）
- 名前を付けるのは、あとで SendMessage で続けて頼むとき、役割を分けて長く動かすとき、ユーザーが名前や別ペインでの表示を求めたときだけ。エージェントチームが有効なので、名前付きはチームメイトとして別のペインで起動し、終わっても残る
- 不要になったチームメイトは閉じる（shutdown_request）か、閉じるかどうかを確認する

---

## local-paths.md

環境固有のパスを書くファイル。リポジトリにあるのは自宅 Windows PC 用の内容で、ほかの環境ではコピー後に書き換える。

| 項目        | 値（リポジトリの内容）                                        |
| ----------- | ------------------------------------------------------------- |
| `META_DIR`  | `~/vaults/90_Meta`                                            |
| `VAULT_DIR` | `~/vaults`（git リポジトリ。remote: `origin`、ブランチ: `master`） |

あわせて、`~/.claude` 下のシンボリックリンクと実体の対応（`CLAUDE.md` / `settings.json` / `keybindings.json` → `~/dotfiles/claude_config/`）を書いている。Claude Code がリンクを直接編集しようとして失敗したり、毎回リンク先を調べたりしないように、最初から実体のパスを使うよう指示している。

---

## ユーザー設定 (settings.json)

| キー                                  | 値                                             | 動作                                                                                                         |
| ------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `$schema`                             | SchemaStore の `claude-code-settings.json`     | エディタでの補完・検証用                                                                                     |
| `permissions.allow`                   | `[]`                                           | プロンプトなしで許可するツール。共通の設定では何も許可しない（許可は各プロジェクトの `settings.local.json` に溜まる） |
| `permissions.additionalDirectories`   | `[]`                                           | カレント以外でファイルアクセスを許可するディレクトリ。なし                                                   |
| `alwaysThinkingEnabled`               | `true`                                         | 拡張思考を有効にする。現在は既定で有効なので、`true` は何も変えない（`false` にすると全セッションで無効）    |
| `tui`                                 | `"fullscreen"`                                 | ターミナルの描画方式をフルスクリーンにする（もう一方はクラシック）                                           |
| `theme`                               | `"dark-daltonized"`                            | 配色テーマ（ダークの daltonized 版）                                                                         |
| `feedbackSurveyState`                 | `{ "lastShownTime": ... }`                     | フィードバックアンケートを最後に表示した時刻。Claude Code が自動で書き込むもので、設定リファレンスには載っていない |
| `agentPushNotifEnabled`               | `true`                                         | Claude が必要と判断したときにスマートフォンへプッシュ通知を送る                                              |
| `inputNeededNotifEnabled`             | `true`                                         | Claude がユーザーの入力待ちになったときにプッシュ通知を送る                                                  |
| `effortLevel`                         | `"medium"`                                     | 既定の effort レベル（`low` / `medium` / `high` / `xhigh`）。セッション中は `/effort` で変えられる           |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `"1"`                                     | エージェントチーム（実験的機能）を有効にする                                                                 |
| `teammateMode`                        | `"auto"`                                       | チームメイトの表示方法。tmux の中か、iTerm2 + `it2` CLI のときは分割ペイン、それ以外は同じ画面内（in-process） |

| `statusLine`                          | `sh ~/dotfiles/claude_config/statusline.sh`（60 秒ごと） | 入力欄の下に使用リミットなどを 1 行で出す。下記参照                                                          |
| `subagentStatusLine`                  | `sh ~/dotfiles/claude_config/statusline.sh subagent-statusline.mjs` | エージェント一覧のサブエージェントの行を書き換える。下記参照 |
| `hooks`                               | 10 イベント                                    | iTerm2 の Claude Code 連携（`~/.config/iterm2/cc-status`）を呼ぶ。下記参照                                   |

### フック（hooks）
iTerm2 が `~/.claude/settings.json` に追加した `cc-status` フックを取り込んだもの。次の 10 イベントのすべてで、同じコマンドを実行する（`matcher` は指定していない）。

`Notification`、`PermissionRequest`、`PreToolUse`、`PostToolUse`、`SessionStart`、`SessionEnd`、`Stop`、`StopFailure`、`SubagentStop`、`UserPromptSubmit`

```sh
f="$HOME/.config/iterm2/cc-status"; [ -x "$f" ] || exit 0; exec "$f"
```

- `cc-status` が無い（実行できない）環境（Linux・WSL・Windows）では、何もせずに `exit 0` で終わる。設定ファイルを全環境で共通にするため

### ステータスライン（statusLine）
Claude Code が stdin に渡す JSON から、次の形で 1 行に出す（`statusline.mjs`）。

```text
5h 60% ~22:42 ⚠  21:52 │ 週 47% ~10/22 21:00 │ ctx 17% │ cache 52m │ med │ Opus 5.5
```

- `5h` / `週`: プランの 5 時間枠・週の上限の使用率（`rate_limits.five_hour` / `seven_day`）と、`~` の後がリセットされる時刻。Pro / Max のみで、セッションの最初の応答が届くまでは出ない
- `⚠  時刻`: 今のペース（使用率 ÷ 枠の経過時間）のままだとリセット前に 100% に届くとき、その予測時刻を赤で出す。枠の経過が 10% 未満のうちは予測しない
- `ctx`: コンテキストの使用率（`context_window.used_percentage`）
- `cache`: プロンプトキャッシュが切れるまでの分数（`prompt_cache.expires_at`）。5 分以下で黄、切れたら灰色の `cache cold`（次の応答でコンテキスト全体を読み直す）。分数を減らすため、`refreshInterval` を 60 秒にしている
- 状態: effort（`low` / `med` / `high` / `xhigh` / `max`）、思考がオフなら `no-think`、fast モードなら `fast`
- 色: 50% 未満は緑、80% 未満は黄、それ以上は赤
- 項目が JSON に無いときは、その項目だけ出さない
- 右揃え: Claude Code が渡す `COLUMNS`（画面の幅）から左に空白を詰めて出す。Claude Code は行頭の空白を詰めるので、先頭に `\x1b[0m` を置いている。右端の余白は `RIGHT_MARGIN`（既定 4。Claude Code の左の字下げ 2 を含み、右に 2 空く）で調整する
- `statusline.sh` は、`node` が PATH に無いとき（zsh の nvm 遅延読み込みなど）に `~/.nvm/versions/node` の一番新しい node を使う。node は `scripts/install_essentials.*` で入れる
- Windows では Git Bash 経由で実行される（Git Bash が無いと PowerShell で実行され、`sh` が無いので動かない）
- カスタムのステータスラインを入れると、フッターのキーのヒント（`esc to interrupt` など）の多くが出なくなる

### サブエージェントの行（subagentStatusLine）
入力欄の下のエージェント一覧で、サブエージェントの行を次の形にする（`subagent-statusline.mjs`）。

```text
文字だけの行の表示テスト [Explore] · 29.2k (+1.0k) · ctx 3% · 15s
```

- 進み具合の要約（`label`、無ければ説明。40 桁で … で切る）と種類（`general-purpose` 以外）
- トークン数と、動いている間は直近の refresh での増え（`tokenSamples` の最後の 2 つの差）を緑で
- コンテキスト使用率（`tokenCount ÷ contextWindowSize`）、経過時間。`failed` / `killed` は赤で状態を足す。終わった行は全体を灰色
- 文字だけを左から詰めて並べる。最初は右端まで空白で寄せて ▁▂▄█ のグラフを出していたが、後ろが切れて見えないことがあったのでやめた
- `statusline.sh` は引数でスクリプト名を受け取る（省略時は `statusline.mjs`）
- 名前を付けて起動したエージェント（エージェントチームが有効なときのチームメイト）の行は書き換わらず、既定の表示のまま（2026/10/21 に確認）

参考: [Customize your status line](https://code.claude.com/docs/en/statusline)

### 補足
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` は zsh 側（`zshrc_main.sh`）でも export しているが、`settings.json` の `env` で設定しているので PowerShell や VS Code 拡張から起動したときも有効になる
- エージェントチームが有効だと、Claude が名前を付けて起動したサブエージェントはチームメイトとして起動する。サブエージェントに戻したいときは `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` を `0` にする
- 分割ペインは VS Code の統合ターミナルや Windows Terminal では使えないので、Windows では `auto` でも in-process 表示になる
- `/config` で変えた設定（テーマなど）は `~/.claude/settings.json` に書き込まれる。リンク先の実体が書き換わるので、`git diff` で確認してからコミットする

参考: [Settings reference](https://code.claude.com/docs/en/settings-reference)、[Agent teams](https://code.claude.com/docs/en/agent-teams)

---

## キーバインド (keybindings.json)

`Chat` コンテキスト（プロンプト入力欄）の `Enter` を改行にし、送信は修飾キー付きの `Enter` で行う。

| キー          | 動作                       | アクション      |
| ------------- | -------------------------- | --------------- |
| `Enter`       | 改行                       | `chat:newline`  |
| `Shift-Enter` | 送信                       | `chat:submit`   |
| `Alt-Enter`   | 送信                       | `chat:submit`   |
| `Ctrl-Enter`  | 送信                       | `chat:submit`   |

- Windows Terminal は `Alt-Enter` を全画面切り替えに使うので、Windows Terminal では `Shift-Enter` か `Ctrl-Enter` を使う

参考: [Keybindings](https://code.claude.com/docs/en/keybindings)

---

## スキル (skills/)

### sync-vaults
vault（`VAULT_DIR`、既定 `~/vaults`）を同期するユーザースキル。どのディレクトリで作業していても `/sync-vaults` で呼べる。「vault を同期」「メモを同期」などと言われたとき、または `VAULT_DIR` を編集した作業の区切りで、Claude が自動で使う。

```text
/sync-vaults          # A → B の両方
/sync-vaults meta     # A だけ
/sync-vaults git      # B だけ
```

| 部分                  | 内容                                                                                                                                                                         |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0. 準備               | `~/.claude/local-paths.md` から `VAULT_DIR`・`META_DIR`・リモート・ブランチを読む。`VAULT_DIR` が無い・git リポジトリでなければ中止                                         |
| A. 90_Meta の SMB 同期 | 手順は vault 内のプロジェクトスキル `VAULT_DIR/.claude/skills/sync-vaults/SKILL.md`（古い端末では `sync-vault`）を Read で読んで従う（ドライラン → 確認 → 本実行 → 要確認ファイルの整理）。見つからない・接続できなければスキップして B へ |
| B. git の同期         | `status` で確認 → 変更があれば `add -A` / `commit` → `pull --rebase origin master` → `push origin master` → `status -sb` で ahead / behind が無いことを確認               |

- A と B は独立していて、片方が失敗してももう片方は行う
- プロジェクトスキルはこのスキルと同じ名前（`sync-vaults`）なので、スキルとして呼ぶとグローバル版（このスキル）が優先される。そのため、スキルとして呼ばずに Read で読む
- マージ・リベースの途中（`.git/MERGE_HEAD`、`.git/rebase-merge/` など）なら何もせずに報告する。`.git/index.lock` は Obsidian Git などの実行中の可能性があるので、勝手に消さない
- コンフリクトや push の拒否は、強制 push や `git reset --hard` で解決せずに報告する。リベース中のマーカーはマージと逆で、`<<<<<<< HEAD` 側がリモート（ほかの端末）、`>>>>>>>` 側がこの PC のコミット
- vault の git の同期方式は rebase にそろえている（PC の Obsidian Git・タスクスケジューラ・Claude Code）。iPad の Obsidian Git だけは rebase に対応していないので merge になる
- ネットワークに届かなければ、ローカルの commit までで止める

最後に、A（実行 / スキップの理由、操作件数、バックアップ先）と B（作成したコミット、取り込んだコミット数、push の結果、最終的な `git status -sb`）を報告する。

### session-generate
新しいターミナルのタブ（tmux の中では新しいウィンドウ。ペイン分割を指定されたら専用ウィンドウ `cc-sessions` を分割して並べる。どちらも画面は元のウィンドウのまま）で独立した Claude Code のセッションを起動し、`SendMessage` で作業を頼み、終わったら結果を確認して報告するユーザースキル。「新しいタブでセッションを開いて」「別のセッションに〜を頼んで」などと言われたときに、Claude が自動で使う。

```text
/session-generate [作業フォルダ] [セッション名] [頼む作業]
```

| ファイル                     | 内容                                                                                                                                    |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/launch-session.ps1` | Windows 用。tmux の中なら `tmux new-window`（`-Split` のときは専用ウィンドウを分割）、Windows Terminal があれば `wt -w 0 new-tab --reloadEnvironment`、なければ新しいウィンドウで起動 |
| `scripts/start-claude.ps1`   | Windows の新しいタブの中で実行。Claude のセッション固有の環境変数を消してから `claude -n <名前>` を起動                                  |
| `scripts/launch-session.sh`  | macOS / Linux / WSL 用。tmux → WezTerm → kitty → iTerm2 → Ghostty → ターミナル → GNOME Terminal → Konsole → WSL の Windows Terminal の順に判断 |
| `scripts/session-result.py`  | セッション名から会話の記録（`~/.claude/projects/*/<セッションID>.jsonl`）を探し、最後の返答を表示                                       |

- Claude のツールから `claude` をそのまま起動すると、`CLAUDE_CODE_CHILD_SESSION` などを引き継いで子セッション扱いになり、会話の記録が保存されない。そのため、変数を消してから起動する
- `wt` はコマンドの中の `;` を区切り記号として扱う（引用符の中でも分割される）ので、`-Command "...; claude"` ではなく `-File` でスクリプトを渡す
- tmux の中では、頼む作業が指定されていないときだけ、起動したウィンドウに画面を切り替える（`-Switch`、sh は `-w`）。作業を頼むときは呼び出し元のウィンドウのまま
- 動作を確認したのは Windows Terminal と tmux（WSL）だけ。ほかのターミナルは公式ドキュメントで構文を確認しただけ（SKILL.md の「ターミナルごとの対応」）

### ssh-generate
`~/.ssh/config` の Host から接続先を選んでもらい、新しいターミナルのタブ（tmux の中では新しいウィンドウ。ペイン分割を指定されたら専用ウィンドウ `ssh-sessions` を分割して並べる）で ssh 接続した状態を作るユーザースキル。複数の接続先を一度に開ける。「新しいタブで ssh して」「〜に ssh 接続したタブを開いて」などと言われたときに、Claude が自動で使う。

```text
/ssh-generate [接続先 ...]
```

| ファイル                    | 内容                                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------------------ |
| `scripts/list-ssh-hosts.py` | `~/.ssh/config`（`Include` 先も含む）の Host の別名を No・Host・HostName・User・Port の表で出す。`*` `?` `!` を含むパターンは除く |
| `scripts/launch-ssh.ps1`    | Windows 用。起動先の判断は session-generate の `launch-session.ps1` と同じ                                 |
| `scripts/start-ssh.ps1`     | Windows の新しいタブの中で `ssh <接続先>` を実行。失敗したときはエラーを残して Enter を待つ              |
| `scripts/launch-ssh.sh`     | macOS / Linux / WSL 用。起動先の判断は session-generate の `launch-session.sh` と同じ                       |

- 接続先は、指定がなければ `AskUserQuestion`（複数選択）で選んでもらう。候補が 5 つ以上なら一覧の表を出し、選択肢にないものは Other に書いてもらう
- tmux の中では、既定で開いたウィンドウ（複数なら最後のもの）に画面を切り替える。`-Background`（sh は `-b`）で切り替えない。ウィンドウは `new-window -P` で受け取った番号で指定する（psmux は `.` を含む名前を `-t` で取り違えるため）
- 動作を確認したのは psmux（Windows）だけ。Windows Terminal はタブが開くところまで。ほかのターミナルは session-generate と同じ方法を使っているだけで未確認

### window-generate
新しいターミナルのタブ（tmux の中では新しいウィンドウ。ペイン分割を指定されたら専用ウィンドウ `shells` を分割して並べる）でシェルを開き、指定したフォルダに移った状態を作るユーザースキル。Claude Code は起動しない。「新しいウィンドウを作って」「〜のフォルダでウィンドウを開いて移動して」などと言われたときに、Claude が自動で使う。

```text
/window-generate [作業フォルダ] [ウィンドウ名]
```

| ファイル                    | 内容                                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------------------ |
| `scripts/launch-window.ps1` | Windows 用。起動先の判断は session-generate の `launch-session.ps1` と同じ                                 |
| `scripts/start-shell.ps1`   | Windows の新しいタブの中で `pwsh -NoExit -File` で実行。Claude の環境変数を消してフォルダに移る          |
| `scripts/launch-window.sh`  | macOS / Linux / WSL 用。session-generate の `launch-session.sh` をもとに、claude の代わりにログインシェルを開く |

- tmux の中では、既定で開いたウィンドウに画面を切り替える（session-generate は切り替えない）。`-Background`（sh は `-b`）で切り替えない
- Claude の中から開いたシェルは Claude のセッション固有の環境変数を引き継ぎ、そこで `claude` を起動すると子セッション扱いになるので、どの起動先でも消してからシェルを渡す
- 動作を確認したのは psmux（Windows）だけ（切り替え、フォルダ、プロファイルの読み込み、変数の削除、`-Background`、`-Split` 2 回）

### session-order
同じマシンで動いている別の Claude Code のセッションに、SendMessage で作業を頼むユーザースキル。セッションは起動しない（起動から頼むときは session-generate）。「〜のセッションに〜を頼んで」などと言われたときに、Claude が自動で使う。

```text
/session-order [セッション名] [頼む内容]
```

- セッション名がなければ、`ListAgents` の一覧から `AskUserQuestion` で選んでもらう。候補が 5 つ以上なら一覧の表を出し、選択肢にないものは Other に書いてもらう
- 頼む内容がなければ、宛先を決めたあとに「次のメッセージに書いてください」と返して待ち、次のメッセージを頼む内容として送る（長い文や複数行を書きやすくするため、選択式にはしない）
- 送るときは `notify_when_idle` を付け、通知が来たら相手の返事か会話記録の最後の返答（session-generate の `session-result.py`）を要約して報告する

### session-overview
同じマシンで動いている Claude Code のセッションを一覧にし、それぞれが何をしているかを会話記録から要約するユーザースキル。相手のセッションには何も送らない。「セッションの一覧を出して」「今どのセッションが何をしているか」などと言われたときに、Claude が自動で使う。

```text
/session-overview [セッション名 ...]
```

| 手順 | 内容 |
| ---- | ---- |
| 1 | `ListAgents` で動いているセッションと状態（busy / idle）を調べる |
| 2 | `scripts/session-overview.py` で、`~/.claude/sessions/*.json` からセッション ID を、`~/.claude/projects/*/<ID>.jsonl` から依頼（ユーザー / 別セッション）・タイトル・最後の返答を抜き出す |
| 3 | セッション・状態・フォルダ・何をしているか・最後の動き（作業中 / 完了 / 返事待ち / 記録なし）の表にまとめる |

- 会話記録と `sessions/*.json` は内部形式なので、Claude Code の更新で読めなくなることがある

---

## 接続先の切り替え（シェル関数）

Anthropic API と、自宅 PC の Ollama（Anthropic 互換 API）を切り替えて Claude Code を使うための関数。

| シェル     | 関数                  | 動作                                                                                                                                  |
| ---------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| zsh        | `claude-anthropic`    | `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` を消し、`ANTHROPIC_API_KEY` を設定して `claude` を起動（キーはプレースホルダーのままなので要書き換え） |
| zsh        | `claude-ollama`       | `ANTHROPIC_AUTH_TOKEN=ollama`、`ANTHROPIC_BASE_URL=$CLAUDE_OLLAMA_URL` にして `claude --model qwen3.5` を起動                         |
| PowerShell | `Use-ClaudeAnthropic` | `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` を消すだけ（起動はしない）                                                             |
| PowerShell | `Use-ClaudeOllama`    | `ANTHROPIC_AUTH_TOKEN=ollama`、`ANTHROPIC_BASE_URL=$env:CLAUDE_OLLAMA_URL` にするだけ（起動はしない。モデルは起動時に指定する）      |

- `CLAUDE_OLLAMA_URL` の既定値は `http://yutapc:11434`（`zshrc_main.sh` / `powershell_main.ps1`）。設定済みならその値を使う。zsh で環境ごとに変えるときは `~/.zshrc.local` で上書きする
- `CLAUDE_OLLAMA_URL` が空のときは `http://localhost:11434` に接続する
- zsh の関数は `export` するので、実行したシェルではその後も同じ接続先のままになる。PowerShell の関数も同じで、切り替えたセッションでは以降の `claude` がその接続先を使う
