---
name: chrome-browser-list
description: Claude in Chrome につながっているブラウザを、呼び名（例: Chrome Individual Win Desktop）で見分けて選ぶ。呼び名と deviceId の対応表を使い、今つながっている（稼働している）かを確かめ、表にない新しいブラウザは見分けて名前を付けて登録する。「Win Desktop の Chrome で開いて」「使えるブラウザを一覧にして」「ブラウザを登録して」などと言われたとき、または Claude in Chrome のブラウザを名前で選びたいときに使う。
effort: low
---

# chrome-browser-list

`list_connected_browsers` は `Browser 1` などの通し番号しか返さず、どれがどの Chrome か分からない。対応表（呼び名 ⇔ deviceId）で補う。

## 対応表

- 場所: `~/vaults/90_Meta/private/chrome-browser-list.md`（deviceId を含むので private）。
- 列: 呼び名 / deviceId / 登録日。読む前にファイルを開いて最新を確かめる。

## 手順

mcp__claude-in-chrome__* が未読み込みなら、ToolSearch で `list_connected_browsers`・`select_browser`・`navigate`・`tabs_context_mcp`・`tabs_create_mcp` を 1 回でまとめて読み込む。

### 1. 稼働の確認と突き合わせ

1. `list_connected_browsers` を実行し、`deviceId` の一覧を得る（今つながっている = 稼働しているもの）。
2. 対応表と deviceId で突き合わせ、次の表を出す。

| 呼び名 | 状態 | 一覧の名前 |
|---|---|---|

- 状態: 「稼働中」（一覧にある）/「停止中」（表にあるが一覧にない）。
- 表にない deviceId は「未登録」として別に挙げ、手順 3 に進むか尋ねる。

### 2. 呼び名で選ぶ

1. 指定された呼び名（部分一致でよい。複数に当たるときはユーザーに選んでもらう）の deviceId を表から引く。
2. 手順 1 で稼働中か確かめ、停止中なら選ばずに「今はつながっていない」と報告する。
3. `select_browser` に deviceId を渡す。
4. 選んだあとは、新しいタブを作って作業する（既存のタブは使わない）。

### 3. 未登録のブラウザを登録する

1. 未登録の deviceId を 1 つずつ `select_browser` で選び、`tabs_create_mcp` でタブを作って `navigate` で `https://example.com/?Browser-<一覧の番号>` を開く。
2. どのブラウザ（PC・アプリ・プロファイル）の画面に出たかを、ユーザーにチャットで答えてもらう。ブラウザの中で入力しても Claude には届かない。
3. 答えをもとに、ユーザーに呼び名を確認する（既存の呼び名の形に合わせる: `<Chrome / MS Edge> <Work / Individual> <PC の呼び名>` など）。
4. 対応表に 1 行追記する（呼び名・deviceId・登録日）。取り違え防止のため、保存前に呼び名と deviceId を見せて承認をもらう。
5. 開いたタブは閉じる。

## 注意

- 呼び名は拡張機能に反映されない（一覧は `Browser N` のまま）。表がこのスキルの正。
- deviceId は個人情報として扱い、返答には呼び名だけを書く（ユーザーに求められたときだけ deviceId を出す）。
