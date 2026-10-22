---
name: sync-dotfiles
description: dotfiles（~/dotfiles）を同期する。このマシンの変更を内容ごとに分けてコミットし、pull --rebase / push してから、ssh の接続先（Home_Mac_1・Home_Desktop_PC_1_win など）の ~/dotfiles を pull し、Claude の設定のリンクを張り直す。「dotfiles を同期して」「dotfiles を push して」「接続先も pull して」「変更を push して接続先に反映して」などと言われたときに使う。
argument-hint: "[local | remote]（省略時は両方）[接続先 ...]"
---

# sync-dotfiles

dotfiles（`~/dotfiles`）の変更をコミットして push し、ssh の接続先でも pull して、同じ状態にそろえる。
2026/10/22 に、何度も手で行っていた手順をまとめた。

- 引数 `local` ならこのマシンの「1.」だけ、`remote` なら接続先の「2.」だけを行う。省略時は両方。
- 接続先が書かれていれば、その接続先だけを更新する。

## 1. このマシンの変更をコミットして push する

1. `git -C ~/dotfiles status --short` と `git diff --stat` で、変更を確かめる。変更がなければ「2.」へ。
2. 変更の中身を読み、**内容ごとにコミットを分ける**（スキルごと、tmux の設定、zsh の設定など）。ほかのセッションが作業中のファイル（そのセッションがまだ編集している途中のもの）が混ざっていれば、そのファイルはコミットせず、ユーザーに伝える。
3. コミットする前に確かめる。
   - **改行コード:** HEAD が LF のファイルが CRLF になっていないか（Windows で Python の `write_text` で書き換えると CRLF になる）。なっていたら LF に戻す。
     ```bash
     uv run --no-project python -c "import subprocess,pathlib;fs=subprocess.run(['git','diff','--name-only'],capture_output=True,text=True).stdout.split()+subprocess.run(['git','ls-files','--others','--exclude-standard'],capture_output=True,text=True).stdout.split();[print('CRLF!',f) for f in fs if pathlib.Path(f).is_file() and b'\r\n' in pathlib.Path(f).read_bytes() and b'\r\n' not in subprocess.run(['git','show','HEAD:'+f],capture_output=True).stdout]"
     ```
     （`~/dotfiles` で実行する）
   - **入れないもの:** `__pycache__` などの一時ファイル（`.gitignore` に入っている）。
   - **実行権限:** 新しい `.sh` は、ほかの `.sh` と同じく `git update-index --chmod=+x <ファイル>` で 100755 にする（Windows では権限が付かないため）。
4. コミットメッセージは、これまでの形に合わせる。
   - 件名: `<分野>: <何をしたか（日本語）>`（例: `skills: session-kill で ...`、`tmux: ...`、`zsh: ...`）
   - 空行のあとに、`- ` で始まる箇条書きで、変えたことと理由を書く。
   - 最後に、システムが指定する帰属の行（`Co-Authored-By:` など）を付ける。
   - **メッセージはファイルに書いてから `git commit -F <ファイル>` で渡す。** ヒアドキュメントを `&& \` でつなぐと、件名の行がシェルのコマンドとして実行されて、件名が抜けることがある（2026/10/22 に起きた）。ファイルはスクラッチパッドに置く。
5. `git pull --rebase` してから `git push` する。
   - コンフリクトが起きたとき、push に失敗したときは、強制 push などで解決しようとせず、状況をユーザーに報告して止める。
6. push したら、`git log --format='%h %s' -<件数>` で、push したコミットを確かめる。

## 2. 接続先を pull する

スクリプトはこの SKILL.md と同じフォルダの `scripts/` にある。

```bash
uv run --no-project python "<このスキルのフォルダ>/scripts/sync-remotes.py" [接続先 ...] [--no-install]
```

- 接続先を省略すると、スクリプトの `DEFAULT_HOSTS`（今は `Home_Mac_1`、`Home_Desktop_PC_1_win`）を更新する。dotfiles を入れた接続先が増えたら、ここに足す。
- 接続先ごとに、シェル（sh 系 / PowerShell）を見分けてから、次を行う。
  1. 未コミットの変更があれば、何もしない（`dirty:`）。接続先の作業を壊さないため。
  2. `git pull --ff-only`。早送りできなければ止める（`failed:`）。
  3. Claude の設定のリンクを張り直す（`install_claude.sh` / `install_claude.ps1`。何度実行してもよい）。新しく作ったリンクがあれば `linked:` に出す。`--no-install` で張り直さない。
- 出力は接続先ごとに 1 行。

  | 行 | 意味 |
  |---|---|
  | `updated: <接続先> <前> -> <今> [linked: ...]` | 更新した |
  | `up-to-date: <接続先> <コミット>` | もう最新だった |
  | `dirty: <接続先> <ファイル>` | 未コミットの変更があるので更新しなかった |
  | `failed: <接続先> <理由>` | 接続できない、早送りできないなど |

- `dirty:` / `failed:` のときは、勝手に直さず（stash・reset・強制 pull などをしない）、内容をユーザーに伝えて、どうするか決めてもらう。
- ssh は `BatchMode=yes` で実行するので、パスワードを聞かれる接続先は `failed:` になる。
- Home_Desktop_PC_1_win では、ssh でコマンドを実行するたびに、PowerShell のプロファイルから「ハンドルが無効です」などの警告が出る。スクリプトは無視する。

## 3. 報告する

- このマシン: push したコミット（ハッシュと件名）、コミットしなかったファイルとその理由。
- 接続先: スクリプトの各行（`updated` / `up-to-date` / `dirty` / `failed`）と、新しくリンクしたスキル。
- dotfiles の変更で、動いているセッションに反映するには起動し直しが要るもの（zsh の設定、tmux の設定など）があれば、そのことも書く。
