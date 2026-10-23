---
name: ssh-list
description: ~/.ssh/config（と Include したファイル）から ssh の接続先を読み取り、No・Host・HostName・User・Port の表で表示する。接続はしない。読み取りの決まりは ssh-generate と同じ（`*` などのパターンと `# not suggest` の Host は出さない）。「ssh の接続先を一覧にして」「ssh の config を見せて」「どこに ssh できる？」などと言われたときに使う。
effort: low
argument-hint: "[絞り込む文字列]"
---

# ssh-list

`~/.ssh/config` から ssh の接続先を読み取って、表で表示する。接続はしない（接続するのは ssh-generate、接続先で Claude を起動するのは session-ssh）。

## 1. 読み取る

ssh-generate の一覧用のスクリプトを、そのまま使う。読み取りの決まりを ssh-generate・session-ssh と同じにするため、このスキル専用のスクリプトは作らない。

```bash
uv run --no-project python "<このスキルのフォルダ>/../ssh-generate/scripts/list-ssh-hosts.py"
```

読み取りの決まり（ssh-generate の「1. 接続先を決める」と同じ。詳しくはスクリプトの先頭の説明）:

- `~/.ssh/config` と、そこから `Include` されたファイルの `Host` の別名を出す。
- `Host *` のような `*` `?` `!` を含むパターンは出さない。
- HostName / User / Port は、その Host ブロックに書かれた値だけを出す（`Host *` などから当たる値は出ない）。書かれていなければ `-`。
- `Host` の行のすぐ次の行に `# not suggest` と書かれた Host は出さない。
- 設定ファイルがなければ、スクリプトは「ssh の設定ファイルがありません」と出して終了コード 1 で終わる。そのときは、その旨をユーザーに伝える。

## 2. 表示する

- スクリプトの出力を、Markdown の表（No・Host・HostName・User・Port）にして返答に書く。値は書き換えない。
- 絞り込む文字列を指定されたら、Host・HostName・User のどれかにその文字列を含む行だけを出す（大文字・小文字は区別しない）。No は元の番号のままにする。当てはまる行がなければ、そう書いて全体の表を出す。
- 表の下に、全部で何件か（絞り込んだときは「全 N 件中 M 件」）を 1 行で書く。
- 続けて接続したいと言われたら ssh-generate、Claude を起動したいと言われたら session-ssh を使う。そのとき、表の No で指定されたら、同じ表の Host に読み替える。
