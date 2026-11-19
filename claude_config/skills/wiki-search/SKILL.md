---
name: wiki-search
description: ナレッジベース（WIKI_DIR、既定 ~/vaults/90_Wiki）と vault のノートから、関係する記録を探す手順と検索スクリプト。90_Wiki のファイル名・frontmatter（type・tags）・目次の説明・本文と、vault-notes の目次、vault の 90_Wiki 以外のノートを 1 回で探し、候補を点数順に返す。過去の調査・設定・決定・不具合の記録、ユーザーの環境や好み、vault のメモ・会議・日記を探すとき、「90_Wiki を見て」「前に調べた？」「メモを探して」などと言われたとき、または CLAUDE.md の決まりで 90_Wiki を見ると判断したときに使う。
---

# wiki-search

90_Wiki を見るかどうかの判断は、グローバル CLAUDE.md の「ナレッジベース（WIKI_DIR）」に従う。このスキルは、見ると決めたあとの探し方を決める。書き込みは wiki-save スキル。

## 1. まず検索スクリプトで候補を出す

```bash
uv run --no-project python "<このスキルのフォルダ>/scripts/wiki_search.py" <語> [<語> ...] [--type T] [--folder F] [--scope wiki|vault|all] [--limit N] [--any]
```

- 探すもの（既定 `--scope all`）: 90_Wiki の各ファイル（ファイル名・frontmatter の type と tags・最初の見出し・フォルダの INDEX.md の説明・本文）、private/、vault-notes/ の目次の行、vault の 90_Wiki 以外のノート。外すのは `.git`・`.obsidian`・`.trash`・`.sync-*`。
- 語はすべて含むもの（AND）を探す。大文字小文字は区別しない。点数は、ファイル名 > tags > 見出し > 目次の説明 > type > 本文の順に高い。
- 出力は 1 候補 1〜2 行（点数・種類・パス・type・updated・説明、本文の一致した 1 行）。private/ は本文の行を出さない。
- Windows で文字化けするときは `PYTHONIOENCODING=utf-8` を付ける。
- `WIKI_DIR` / `VAULT_DIR` の環境変数があればそれを使う（既定は `~/vaults/90_Wiki`、`~/vaults`）。

語の選び方:
- 製品名・コマンド名・エラー文の要点など、具体的な語を 1〜3 個にする。日本語と英語の両方の言い方を思いつくなら、別々に試すか `--any` で並べる（例: `vim ヴィム --any`）。
- 種類がはっきりしていれば `--type`（research / troubleshooting / setup / rule / record）で絞る。例: 不具合なら `--type troubleshooting`、決まりなら `--type rule`。
- 話題のフォルダが分かっていれば `--folder`（claude-code・terminal・machines など）で絞る。
- vault のメモ・会議・日記だけを探すなら `--scope vault`、90_Wiki だけなら `--scope wiki`。

## 2. 候補を読む

- 点数の高い順に、必要なファイルだけを開く。1 回の検索で開くのは、まず上位 1〜3 件。
- 長いファイルは、先頭の frontmatter と「結論」「要点」の節を先に読み、要る節だけを読む（Read の offset・limit、または Grep で節を探す）。
- `updated` が古いもの・価格や「時点」のある情報は、そのまま事実として答えず、必要なら確かめ直す。
- private/ のファイルは、作業に要るときだけ開く。中身を返答に写すのは、作業に必要な最小限にする。
- vault-notes の候補（`[[ノート名]]`）は、目次の行なのでパスがない。ノート名で Glob して今の場所を探し、元のノートを読む。vault の 90_Wiki 以外のノートは読むだけにする（CLAUDE.md の決まり）。

## 3. どこで止めるか

- 答えに要る事実がそろったら、それ以上探さない。
- 上位の候補を読んでも関係がなければ、語を変えて 1〜2 回だけ探し直す（言い換え・英語名・`--any`・`--scope` を広げる）。
- それでも見つからなければ、目次をたどる（`WIKI_DIR/INDEX.md` → 関係するフォルダの `INDEX.md`）。それでもなければ「90_Wiki には記録がない」として、調べ直すか、ユーザーに聞く。

## 4. 見つけたあと

- 返答で 90_Wiki の記録を使ったら、そのファイルのパスを添える。
- 記録が古い・まちがっていると分かったら、wiki-save スキルの手順で直す（ユーザーが決めたことは、確かめてから直す）。
