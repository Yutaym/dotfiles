---
name: vault-sync
description: vault（VAULT_DIR、既定 ~/vaults）を同期する。90_Meta（META_DIR、private を含む）を SMB 共有先と双方向同期し、vault 全体（90_Meta 以外）を git で commit / pull --rebase / push する。どのディレクトリで作業していても使える。「vault を同期」「vault を push」「メモを同期」「90_Meta を同期」などと言われたとき、または VAULT_DIR（90_Meta 以外）のファイルを編集した作業の区切りで git の同期に使う。
argument-hint: "[meta | git]（省略時は両方）"
---

# vault-sync

vault の同期は 2 つの部分に分かれていて、互いに独立している（片方が失敗しても、もう片方は行う）。

- **A. 90_Meta の SMB 同期**: 90_Meta は全体が `.gitignore` で除外されているので、git ではなく SMB 共有経由で同期する。
- **B. git の同期**: vault 全体（90_Meta 以外）を GitHub のリモートと同期する。

引数が `meta` なら A だけ、`git` なら B だけを行う。省略時は A → B の順に両方を行う。

## 0. 準備

1. `~/.claude/local-paths.md` を読み、`VAULT_DIR`・`META_DIR`・リモート名・ブランチ名を確認する（既定は `~/vaults`、`~/vaults/90_Meta`、`origin`、`master`）。以下の `VAULT_DIR` はこの値に読み替える。
2. `VAULT_DIR` が存在しない、または git リポジトリでない場合は、何もせずにユーザーに報告する。

## A. 90_Meta の SMB 同期

手順の詳細は vault 内のプロジェクトスキルにまとめてあるので、二重に書かずにそちらに従う。

1. `VAULT_DIR/.claude/skills/sync-vault/SKILL.md` を Read で読む。
   - 見つからない場合（SMB 同期をセットアップしていない端末など）は、A をスキップしたことを報告して B に進む。
2. その「対話でこのスキルが呼ばれたときは…」の確認事項と「手順」（ドライラン → 確認 → 本実行 → 要確認ファイルの整理 → 報告）に従う。
   - Mac / Linux では、同じフォルダの `mac-linux.md` も読む。
   - リモートに接続できないときは、同じスキルの「トラブル時」を確認し、A をスキップしたことを報告して B に進む。

## B. git の同期

`VAULT_DIR` のリポジトリのルートで、以下を順に実行する。

1. 状態を確認する。

   ```bash
   git -C "$VAULT_DIR" status -sb
   ```

   - マージやリベースが途中の状態（`.git/MERGE_HEAD`、`.git/rebase-merge/`、`.git/rebase-apply/` がある）なら、何もせずにユーザーに報告する。
   - `.git/index.lock` がある場合は、Obsidian Git などが実行中の可能性がある。少し待っても残っていればユーザーに報告し、勝手に消さない。

2. 変更があれば commit する。

   ```bash
   git -C "$VAULT_DIR" add -A
   git -C "$VAULT_DIR" commit -m "$(date '+Claude: %Y/%m/%d %H:%M:%S %z')"
   ```

   - コミットメッセージは `Claude: yyyy/MM/dd HH:mm:ss ±HHMM` の形式にし、Co-Authored-By などの帰属表示の行は付けない（グローバル CLAUDE.md のルール）。
   - commit の前に `git status` で、`.gitignore` 対象（90_Meta など）が含まれていないことを確かめる。

3. リモートの変更を取り込む。

   ```bash
   git -C "$VAULT_DIR" pull --rebase origin master
   ```

4. push する。

   ```bash
   git -C "$VAULT_DIR" push origin master
   ```

5. `git status -sb` で、`ahead` も `behind` もない（リモートと一致している）ことを確かめる。

### 失敗したとき

- pull でコンフリクトが起きた場合、または push が拒否された場合は、強制 push や `git reset --hard` などで解決しようとしない。状況（コンフリクトしたファイル、`git status` の出力）をユーザーに報告する。
  - リベース中のコンフリクトを解消するかどうかはユーザーに確認する。中止する場合は `git rebase --abort` で元に戻せる。
  - リベース中のマーカーはマージと向きが逆で、`<<<<<<< HEAD` 側がリモート（ほかの端末）、`>>>>>>>` 側がこの PC のコミット。リベースはコミットを 1 つずつ付け直すので、`git rebase --continue` のあとに次のコミットでまた止まることがある。
  - vault の git の同期方式は rebase にそろえている（PC の Obsidian Git・タスクスケジューラの自動同期・Claude Code）。iPad の Obsidian Git だけは rebase に対応していないため merge になる。
- ネットワークに届かない場合は、ローカルの commit までで止めて報告する（次回の同期で push される）。

## 報告

最後に、次をまとめて報告する。

- A: 実行したか・スキップしたか（理由）、操作件数、整えたファイル、バックアップ先
- B: 作成したコミット（ハッシュとメッセージ）、取り込んだリモートのコミット数、push の結果、最終的な `git status -sb`
