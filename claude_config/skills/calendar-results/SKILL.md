---
name: calendar-results
description: Google カレンダーの「Claude」カレンダーの予定を Home_Mac_1 が自動で実行した結果（vault-jobs の calendar-run）を、claude.ai の Google カレンダーコネクタで読んで見せ、見せた予定の未確認の印（🆕）を外す。「自動実行の結果を見せて」「Claude カレンダーの結果は？」「/calendar-results」などと言われたとき、またはセッション開始時に未確認の件数が表示されてユーザーが中身を知りたいときに使う。
argument-hint: "[all（確認済みも含めて直近の分を見る）]"
effort: low
---

# calendar-results

「Claude」カレンダー（Claude 専用。calendarId は `d519a0caeb9dc4d069c9f581db2353d70bd2cbe986d41273fe1d41c587379d2c@group.calendar.google.com`）の、自動実行の結果を見せる。仕組みは `~/vaults/98_Scripts/vault-jobs/vault_jobs/calendar_run.py`。

- 結果の書かれ方: タイトルの先頭が `🆕✅`（成功・未確認）、`🆕❌`（失敗・未確認）、`✅` / `❌`（確認済み）、`⏳`（実行中）。説明欄の `――――― Claude の実行結果 ―――――` の下が結果。
- ツールが読み込まれていなければ、ToolSearch で 1 回にまとめて読み込む:
  `select:mcp__claude_ai_Google_Calendar__list_events,mcp__claude_ai_Google_Calendar__update_event`
- コネクタのツールが `authenticate` だけ、または認証のエラーのときは止め、`/mcp` →「claude.ai Google Calendar」で認証してもらう。

## 手順

1. `list_events` を、上の calendarId、`startTime` = 30 日前、`endTime` = 明日、`orderBy: startTime` で呼ぶ。
   - 引数が `all` でなければ、タイトルが 🆕 で始まるものだけを見せる。`all` なら直近 7 日のものを全部見せる。
   - 0 件なら「未確認の結果はありません」とだけ書いて終える。
2. 1 件ずつ、日時・✅/❌・タイトル・結果（説明欄の区切りの下）を見せる。長い結果は要点をまとめ、全文が要るか聞かずにまず要約で出す。
   - 失敗（❌）のものは、理由と、次にどうすればよいか（予定を直して入れ直す、など）を添える。
3. 見せた予定の 🆕 を外す: `update_event` でタイトルの先頭の `🆕` だけを消す（`🆕✅ 〇〇` → `✅ 〇〇`）。説明欄など、ほかは変えない。
   - 確認済みにしたことを 1 行で伝える。Home_Mac_1 は 5 分以内に件数を数え直すので、ほかの PC のセッション開始時の表示も消える。
4. 結果を受けて続きの作業が要りそうなら、提案だけする（勝手に始めない）。
