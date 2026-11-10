---
name: calendar-request
description: Claude に自動で実行させたい作業（依頼）を、Google カレンダーの「Claude」カレンダーに予定として記録する。Home_Mac_1 の vault-jobs（calendar-run）が、その時刻を過ぎた最初の毎時 5 分の回に、予定のタイトルと説明欄を依頼文にして claude -p で実行する。依頼を、会話を知らない Claude が読んでも実行できる文に整え、Mac 側で許可している操作で足りるかを確かめ、内容を確認してもらってから登録する。「Claude カレンダーに依頼を入れて」「〜時に Claude にやらせて」「自動実行の予定を登録して」「この作業をあとで自動でやって」などと言われたときに使う。
argument-hint: "[依頼の内容と日時（例: 明日 9 時に 〜を調べてまとめて）]"
---

# calendar-request

「Claude」カレンダー（Claude 専用。calendarId: `d519a0caeb9dc4d069c9f581db2353d70bd2cbe986d41273fe1d41c587379d2c@group.calendar.google.com`）に、自動で実行する依頼を予定として入れる。
実行の仕組みは `~/vaults/98_Scripts/vault-jobs/vault_jobs/calendar_run.py`（説明は同じフォルダの README.md の「Claude カレンダーの自動実行」）。結果を見るのは calendar-results スキル。

ツールが読み込まれていなければ、ToolSearch で 1 回にまとめて読み込む:
`select:mcp__claude_ai_Google_Calendar__create_event,mcp__claude_ai_Google_Calendar__list_events`
コネクタのツールが `authenticate` だけ、または認証のエラーのときは止め、`/mcp` →「claude.ai Google Calendar」で認証してもらう。

## 実行のされ方（依頼を作るときの前提）

- Home_Mac_1 の cron が**毎時 5 分**に確かめ、開始の時刻を過ぎた未実行の予定を、古い順に 1 回 3 件まで実行する。予定の時刻から最大で約 1 時間遅れる。終日の予定は、その日の 0:00 が開始の時刻。
- 実行する Claude は**この会話を知らない**。ユーザーもその場にいないので、確認が必要なことはせずに結果に書いて終える。
- 作業フォルダは Mac の vault（`/Users/yuta/vaults`）。使える操作は `~/vaults/98_Scripts/vault-jobs/hosts.toml` の `[calendar-run]` で決まる。2026/11/10 の時点では次のとおり:
  - 読む・検索（Read / Grep / Glob）、Web（WebSearch / WebFetch）
  - Google カレンダーの読み取り、Spark MCP の読み取り（メール。アカウントは read-only）
  - 書き込み: `write_dirs`（`30_Projects/claude-calendar/` の下）と、`write_files` に書いたファイルだけ
  - **Bash は使えない**。メールの送信・カレンダーへの書き込み・ほかのマシンの操作もできない。
- 結果は、予定の説明欄（タイトルは `🆕✅` / `🆕❌` になる）と、その日のデイリーノートの「## Claude の自動実行」に自動で書かれる。

## 手順

### 1. 依頼の中身を決める

ユーザーの言葉（と、この会話の流れ）から、次を決める。足りないものだけを聞く（一度にまとめて聞く）。

- **何をするか**: 実行する Claude がそのまま作業できるよう、具体的に書く。
  - 「これ」「さっきの」などは、ファイルのパス・URL・名前に置き換える。経緯が要る作業は、経緯も書く（会話は引き継がれない）。
  - 結果をファイルにも残すなら、その場所を書く（書ける場所は上のとおり）。
- **いつ実行するか**: 日時。言われなければ「今すぐ（次の毎時 5 分の回）」として、今の時刻を開始にする。繰り返し（毎週・毎月など）は RRULE にする。
- **遅れたときどうするか**: 時刻に意味がある作業（「朝のうちに」など）で、遅れたら意味がないときは、説明欄に「遅れたら実行しない」と書く。

### 2. Mac 側の操作で足りるかを確かめる

- 今の許可を `~/vaults/98_Scripts/vault-jobs/hosts.toml` の `[calendar-run]`（`allowed_tools`・`write_dirs`・`write_files`）で確かめる。ファイルがなければ、上の一覧を使う。
- 足りない操作が要るとき（Bash、許可していない場所への書き込み、メールの送信、MSI だけにあるものを使うなど）は、登録する前にユーザーに伝え、次のどれにするか決めてもらう。
  - 依頼を、許可の範囲でできる形に直す（例: 「送る」→「下書きの文を結果に書く」、「〇〇を書き換える」→「書き換える案を結果に書く」）。
  - 許可を足す（`hosts.toml` を直して push する。Mac は 0:00・12:00 の run か git-sync で取り込む）。**許可を足すのはユーザーが決めたときだけ**。
  - 自動実行にしない。

### 3. 予定の形にする

- **タイトル**: 何をするかが分かる短い名前。先頭に `🆕` `✅` `❌` `⏳` を付けない（付いていると実行されない）。
- **時刻**: `startTime` に開始、`endTime` は開始の 30 分後（終日の予定なら `allDay: true`）。`timeZone` は、ユーザーがタイムゾーンを言ったときだけ付ける。
- **説明欄**: 次の形にする（使わない見出しは省く）。

  ```
  ■ 依頼
  （実行する Claude への依頼文。何を・どこまで・結果をどこに）

  ■ 経緯
  （要るときだけ。この会話で分かっていることのうち、作業に要るもの）

  ■ 結果の扱い
  （ファイルに書くならその場所。書かないなら「結果は予定とデイリーノートに書かれるだけでよい」）

  ■ 遅れたとき
  （時刻に意味があるときだけ。例: 予定より 3 時間以上遅れたら実行しない）

  （YYYY/MM/DD に calendar-request で登録した）
  ```

### 4. 確かめてもらってから登録する

- タイトル・日時（繰り返しなら、その決まり）・説明欄の全文・いつ実行されそうか（例: 「11/13 12:05 の回」）を見せ、AskUserQuestion で「登録する / 直す」を聞く。直すと言われたら直して、もう一度見せる。
- 登録は `create_event`（calendarId は上の ID、`useDefaultReminders: false`）。

### 5. 報告する

- 登録した予定（タイトル・日時）と、実行されそうな回を 1〜2 行で伝える。
- 結果は、セッション開始時に未確認の件数として出て、`/calendar-results` で見られることを添える。
- 「今すぐ」の依頼で、次の毎時 5 分を待ちたくないと言われたときだけ、Mac で 1 回実行させる:
  `ssh -o BatchMode=yes Home_Mac_1 'cd ~/vaults/98_Scripts/vault-jobs && PATH=$HOME/.local/bin:/usr/local/bin:$PATH /usr/local/bin/uv run --quiet --script run.py calendar-run'`
  （Home_Mac_1 の上では ssh を付けずに実行する。Mac に届かなければ、次の回を待つと伝える）
