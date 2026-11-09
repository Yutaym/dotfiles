---
name: get-remote
description: Remote Control につながっている Claude Code のセッションを一覧にする。このマシンのセッション（番号 SNo 付き）と、ほかのマシンのセッションを分けて出す。相手のセッションには何も送らない。「/get-remote」「リモートコントロールのセッション一覧を出して」「Remote Control につながっているセッションは？」などと言われたときに使う。
effort: low
---

# get-remote

Remote Control（スマホ・ブラウザなどから操作できる状態）につながっているセッションだけを、短い表で出す。
中身の要約はしない（要約は session-overview スキルの役目）。相手のセッションにメッセージは送らない。

## 1. 材料を集める

1. `ListAgents` を実行する。
2. このマシンのセッション（`tmux ...` や `interactive` の行、このセッション自身を含む）の名前を並べて、次を実行する（スクリプトは session-overview スキルのもの）。

```bash
uv run --no-project python "$HOME/.claude/skills/session-overview/scripts/session-overview.py" <名前1> <名前2> ... --json
```

   - JSON の各要素の `remoteControl`（`sessions/*.json` の `bridgeSessionId` があるか）が `true` のものが、Remote Control につながっているセッション。
   - 番号は `number`、状態は `status`、場所は `location`。

## 2. 表にして報告する

### このマシン（つながっているもの）

`remoteControl` が `true` のセッションだけを、`number` の小さい順に出す。つながっていないものは出さない。

| SNo | セッション | 状態 | 場所 |
|---|---|---|---|

- 状態の書き方・場所の書き方は session-overview スキルの表と同じ（状態は色の絵文字付き、場所は `tmux 0:8` など）。tmux の中のセッション名は太字にする。
- このセッション自身は「（このセッション）」と付けて含める。

### ほかのマシン

`ListAgents` の行のうち `Remote Control` と付くもので、状態が `offline` でないものを出す（`offline` は終わったセッションの名前だけが残ったものなので外す。`cloud` も外す）。

| セッション | 状態 |
|---|---|

- 状態は `ListAgents` の値に、session-overview と同じ色の絵文字を付ける。
- 該当がなければ「ほかのマシンのセッションは見つかりません」と書く。
- このセッションが Remote Control につながっていないと、ほかのマシンのセッションは `ListAgents` に出ない。そのときは、その旨を一言添える。

## 3. 決まり

- 番号の呼び方は CLAUDE.md の「セッション番号の書き方」に従う（本文で番号に触れるときは `SNo3（名前）` の形）。
- 材料に無いこと（相手のマシン名・接続先など）は推測して書かない。
