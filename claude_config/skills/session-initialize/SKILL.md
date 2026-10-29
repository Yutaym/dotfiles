---
name: session-initialize
description: 今のウィンドウのセッションを振り分け役（session-main-<ホスト名>）にする。以降の入力を作業ごとに分けて、サブセッション（新しいウィンドウの Claude Code）か名前なしのサブエージェントに頼み、台帳に記録する。サブセッションの返答は Hook で台帳に集まり、次の入力のときに届く。終わるときはサブセッションをまとめて閉じる。「session-initialize」「このウィンドウをメインにして」「ここから作業を振り分けて」などと言われたときに使う。
effort: medium
argument-hint: "[最初に頼む作業]"
---

# session-initialize

今のセッションを振り分け役（以下「メイン」）にする。メインは自分では作業せず、入力を作業ごとに分けて、サブセッションかサブエージェントに頼む。
設計の経緯と決めたことは `~/vaults/90_Meta/research/session-initialize-design-review.md` にある（2026/10/29 にユーザーが決めた）。

## しくみ

- **台帳:** `~/.claude/session-ledger/<メインのセッション ID>.jsonl`。1 行 1 件の出来事（`dispatch` 頼んだ / `report` 返答 / `state` 状態の変化）を追記していく。読み書きは同梱の `scripts/ledger.mjs` で行う。
- **サブセッションへ渡す変数:** session-generate の起動スクリプトに `-Ledger <台帳>` / `-TaskId <ID>`（sh は `-L` / `-T`）を渡すと、起動したセッションに次を設定する。孫のセッションにも `CC_LEDGER` が引き継がれる。
  - `CC_LEDGER`: 台帳のパス
  - `CC_TASK_ID`: 台帳の作業の ID（`t001` など）
  - `CC_PARENT_ADDR`: 起動したセッションの受信口のアドレス（`uds:...`）。名前が重なっても届く宛先。
- **返答の届き方（案 A）:** サブセッションの Stop Hook（`hooks/session-ledger.mjs stop`）が、ターンの最後の返答を `report` として台帳に追記する。メインの UserPromptSubmit Hook（同 `prompt`）が、まだ読んでいない報告を次の入力のときに渡す。モデルは呼ばないので、使用量は増えない。メインはそれまで自分からは動かない。
- 頼んだ作業の完了は、`notify_when_idle` でも受け取る（すぐ知りたいとき）。

スクリプトは `node "<このスキルのフォルダ>/scripts/ledger.mjs" <コマンド>` で実行する（以下 `ledger.mjs` と書く）。

## 1. メインにする

1. `ledger.mjs whoami` で、このセッションの名前・受信口・ホスト名を調べる。
2. 名前が `session-main-<ホスト名を小文字にしたもの>`（例: `session-main-msi`）でなければ、ユーザーに次の 1 行を入力してもらい、ターンを終える。Claude からは `/rename` を実行できない（tmux で自分のペインに打ち込むのも auto mode が止める）。
   ```
   /rename session-main-<ホスト名>
   ```
   ユーザーが入力したら、もう一度 `ledger.mjs whoami` で名前が変わったことを確かめる。
   - ホスト名を付けるのは、Remote Control でほかのマシンのセッションも同じ一覧に出て、名前が重なるのを避けるため。
3. `ledger.mjs init` で台帳を作る。次の入力から、Hook が振り分け役であることと未読の報告を渡すようになる。
4. session-observation スキルで、監視画面のペインを開く（tmux の外では新しいタブ）。
5. ユーザーに、準備ができたことと、台帳のパスを伝える。引数に最初の作業があれば、「2.」に進む。

## 2. 入力を振り分ける

入力を作業ごとに分け、それぞれを次の表で振り分ける。メインは自分ではコマンドの実行やファイルの読み書きをしない（台帳と起動のスクリプト、ListAgents / SendMessage は除く）。

| 作業 | 頼む先 |
|---|---|
| 検索だけ・小さな作業（コマンドを数個実行する、ファイルを少し読むなど） | 名前なしのサブエージェント（`Agent` ツール。モデルと effort は CLAUDE.md の「モデルと effort の使い分け」どおり。検索だけなら `haiku`） |
| やり取りが要る作業・長い作業・ユーザーがそこで直接続けたい作業 | サブセッション（新しいウィンドウ） |
| すでに頼んだ作業の続きや関係する作業 | 同じサブセッション（`SendMessage`。CLAUDE.md の「別のセッションに頼んだ作業」） |

迷うときは、ユーザーに聞く。

### サブエージェントに頼むとき

1. `Agent` ツールで起動する（`name` は付けない。`run_in_background: true`）。
2. 返ってきた ID で記録する: `ledger.mjs add subagent <agentId> <頼んだことの要約>`
3. 結果が届いたら、`ledger.mjs state <ID> done <結果の要約>` で記録し、ユーザーに要点を伝える。

### サブセッションに頼むとき

1. セッション名を決める（session-generate の「1. 起動する」と同じ決め方。例: `dotfiles-fix-hook`）。
2. 記録して ID を受け取る: `ledger.mjs add session <セッション名> <頼んだことの要約> --cwd <作業フォルダ> [--worktree <名前>]`
3. session-generate の起動スクリプトで起動する。モデルと effort は session-generate の「モデルと effort を決める」で決める。
   ```powershell
   pwsh -NoProfile -File "<session-generate のフォルダ>\scripts\launch-session.ps1" [-Dir "<作業フォルダ>"] -Name <セッション名> -Ledger "<台帳のパス>" -TaskId <ID> [-Model <モデル>] [-Effort <effort>] [-Worktree <名前>]
   ```
   macOS / Linux は `sh "<session-generate のフォルダ>/scripts/launch-session.sh" ... -n <セッション名> -L "<台帳のパス>" -T <ID> [-W <名前>]`。
   - **worktree:** 同じリポジトリで、ほかのサブセッションもコードを書いているときは、`-Worktree <作業を表す名前>` を付けて作業場所を分ける（`claude --worktree`）。読むだけの作業には付けない。
4. `ListAgents` で起動したことを確かめ、`SendMessage` で頼む（`notify_when_idle: true`）。文面は session-generate の「2. 作業を頼む」に従い、次も書き添える。
   - 「あなたは session-initialize のサブセッション（作業 `<ID>`）。検索は名前なしの haiku のサブエージェントで行う。さらにセッションを起動して頼むときは session-generate を使い、起動の前に `ledger.mjs add` で台帳に記録して `-TaskId` を渡す（台帳は `CC_LEDGER` で自動で引き継がれる）。」
   - 「終わったら、結論の要約を SendMessage で `<メインの受信口のアドレス>` に送る。」（アドレスは `ledger.mjs whoami` の `addr=`。同じ名前のセッションがあっても届く）
5. 返事・idle の通知・Hook の未読の報告が来たら、`ledger.mjs state <ID> <done|waiting|failed> <要約>` で記録し、ユーザーに要点を伝える。`waiting` はユーザーへの質問で止まっているとき。

### ssh 先で頼むとき

session-ssh で起動したセッションは、台帳のファイルに書けない（別のマシンにあるため）ので、Hook の報告は届かない。`ledger.mjs add session <名前> ...` で記録だけして、返事は SendMessage で `session-main-<ホスト名>` 宛てに送るよう頼む（受信口のアドレスはマシンをまたいで使えない）。

## 3. 状況を見る

- `ledger.mjs list` で、作業ごとの今の状態を表で出す（`--all` で閉じたものも出す）。
- 中身まで知りたいときは、session-overview スキルを使う。

## 4. まとめて閉じる

1. `ledger.mjs open-sessions` で、まだ閉じていないサブセッションの名前を出す。
2. 一覧をユーザーに見せて、閉じてよいか確かめる（作業中のセッションがあれば、そのことも書く）。
3. session-kill スキルのスクリプトで閉じる。
   ```bash
   uv run --no-project python "<session-kill のフォルダ>/scripts/kill-session.py" <名前> [<名前> ...]
   ```
4. 閉じたものを `ledger.mjs state <ID> killed` で記録する。
5. 監視画面を開いていれば、session-observation の「止める」で止める。

## 決まりごと

- 台帳と `~/.claude/sessions/*.json`（名前と受信口を調べるのに使う）は、Claude Code の内部形式に頼る部分がある。読めなくなったらスクリプトを直す。
- サブセッションの Stop Hook は、1 ターンに何度か走ることがある（ほかの Stop Hook が止めたとき）。メインの Hook は、送り手ごとに最新の報告だけを渡す。
- 試作（2026/10/29）。動かしながら直す。
