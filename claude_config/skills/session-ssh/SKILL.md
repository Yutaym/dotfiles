---
name: session-ssh
description: ~/.ssh/config の Host から接続先を選んでもらい、新しいターミナルのタブ（tmux の中では新しいウィンドウ）で ssh 接続して、接続先で Remote Control つきの Claude Code を名前付きで起動する。このマシンのセッションと同じように ListAgents / SendMessage で作業を頼める。「リモートで Claude を起動して」「〜のマシンでセッションを開いて」「ssh 先で Claude を動かして」などと言われたときに使う。
argument-hint: "[接続先] [フォルダ] [作業]"
---

# session-ssh

ssh の接続先（別のマシン）で Claude Code を起動し、このマシンのセッションと同じように `ListAgents` / `SendMessage` で操作できるようにする。
接続先の選び方は ssh-generate、セッション名・作業の頼み方・結果の確かめ方は session-generate と同じにする。
2026/10/22 に、Windows 11 の psmux 3.4.0 から Home_Mac_1（macOS、zsh、tmux あり、Claude Code 2.1.307）で、起動して Remote Control がつながる（`/rc active`）ところまで確認した。

## しくみと前提

- 別のマシンのセッションは、**両方のセッションが Remote Control につながっているときだけ** `ListAgents` に出る（行に `Remote Control` と付く）。メッセージは Anthropic のサーバーを通って届く。出典: https://code.claude.com/docs/en/cross-session-messaging
  - 接続先の Claude は、スクリプトが `claude --name <セッション名> --remote-control` で起動する。
  - **呼び出し元（このセッション）も Remote Control につながっている必要がある。** Claude からは `/remote-control` を実行できない。つながっていなければ、ユーザーにこのセッションで `/rc` を実行してもらう。いつもつなぐなら、`/config` の「Enable Remote Control for all sessions」をオンにするか、`~/.claude/settings.json` に `"remoteControlAtStartup": true` を書く（設定を変えるのはユーザーが決める）。
  - Remote Control は claude.ai のログイン（Pro / Max / Team / Enterprise）が必要で、API キーでは使えない。届くのは自分のセッションどうしなので、両方のマシンで同じアカウントにログインしておく。
- **このマシンのセッションとの違い**:
  - `notify_when_idle` は使えない（同じマシンのセッションだけ）。完了は、相手から SendMessage で返事をもらって知る。
  - 会話記録は接続先のマシンにあるので、session-generate の `session-result.py` では読めない。session-overview は、このスキルで開いたウィンドウ（`@ssh_host` の印がある）を手がかりに、ssh で接続先の記録を読んで要約する（`remote-overview.py`）。画面は、tmux の中なら `tmux capture-pane` で読める。
  - session-kill は、ssh で接続先のスクリプトを動かして終了できる（接続先に session-kill スキルと uv が必要）。入っていなければ、接続先の Claude で `/exit` するか、ウィンドウで Ctrl+C を押す。
- 接続先のシェルは、sh 系（bash / zsh など）と、既定のシェルが PowerShell の Windows（OpenSSH）に対応する。
  - Windows の起動用スクリプト（`launch-session-ssh.ps1`）は、ssh で `$PSVersionTable.PSEdition` を出させて、どちらかを自分で判断する（`-RemoteShell posix|pwsh` で指定もできる）。
  - 2026/10/22 に、Home_Desktop_PC_1_win（Windows、PowerShell 7.6、psmux、Claude Code 2.1.308）で、psmux の中で起動して `ListAgents` に出ることを確認した。
  - macOS / Linux 用の `launch-session-ssh.sh` は、sh 系の接続先だけに対応する。
  - 既定のシェルが cmd.exe の Windows には対応していない。
  - session-overview の `remote-overview.py` は、Windows の接続先の記録も読める（接続先に session-overview スキルと uv が必要）。

## 1. 接続先・フォルダ・セッション名を決める

1. 接続先は ssh-generate スキルの「1. 接続先を決める」と同じ手順で決める（一覧は `<ssh-generate のフォルダ>/scripts/list-ssh-hosts.py`）。ただし、選べるのは 1 つだけにする（`multiSelect: false`）。
2. フォルダは、接続先のパスで指定する（例: `~/dotfiles`）。指定がなければ `~/claudeWS` にする。接続先にフォルダがなければ、スクリプトが作る（指定したフォルダでも作る）。
   - 英数字と `. _ / -`（先頭の `~`）だけを使える。空白を含むパスは使えない。
   - まだ信頼していないフォルダでは、Claude の起動時に信頼の確認が出る（`~/claudeWS` も、接続先ごとに最初の 1 回だけ出る）。ホームフォルダ（`~`）は信頼が保存されず毎回出るので、ユーザーに言われない限り `~` は使わない。
3. セッション名は session-generate と同じ決まりで決める（英数字・`-`・`_` だけ、今の `ListAgents` にない名前）。指定がなければ `<接続先を短くしたもの>-<作業を表す英単語>`（例: `mac-review`）にする。フォルダを指定したときは、作業を表す英単語の代わりにフォルダ名を使ってもよい（例: `~/dotfiles` なら `mac-dotfiles`）。
   - 接続先の tmux のセッション名にも同じ名前を使う。同じ名前ですでに動いていれば、新しく起動せずにそのセッションにつなぎ直す。

## 2. 起動する

**Windows（ネイティブ）:** PowerShell ツールで実行する。

```powershell
pwsh -NoProfile -File "<このスキルのフォルダ>\scripts\launch-session-ssh.ps1" -Target <接続先> -Name <セッション名> [-Dir <接続先のフォルダ>] [-RemoteShell auto|posix|pwsh] [-NoTmux] [-Split] [-Background]
```

**macOS / Linux / WSL:** Bash ツールで実行する。

```bash
sh "<このスキルのフォルダ>/scripts/launch-session-ssh.sh" -h <接続先> -n <セッション名> [-d <接続先のフォルダ>] [-T] [-s] [-b]
```

- タブ・ウィンドウの開き方は ssh-generate の `launch-ssh` スクリプトに任せる（起動先の判断、ペイン分割の `-Split` / `-s`、tmux の扱いは同じ）。ウィンドウの名前はセッション名になる。
- 画面の切り替えは session-generate と同じにする。**頼む作業がないときは切り替え、頼む作業があるときは `-Background`（sh は `-b`）を付けて呼び出し元のままにする。**
- 接続先では、次のように起動する。
  - Windows（PowerShell）の接続先では、`Set-Location <フォルダ>` してから、psmux（`tmux`）があれば `tmux new-session -A -s <名前> 'claude ...'` で起動する。PowerShell のプロファイルを読むので、ssh の接続時にプロファイルの警告（PSReadLine など）が出ることがあるが、害はない。
  - sh 系の接続先では、ログインシェルを対話モード（`$SHELL -lic`）で起動してから claude を実行する。macOS の zsh では、claude が `.zshrc`（oh-my-zsh の nvm プラグインの関数）の中でだけ使えるため。起動時に `can't change option: zle` と出ることがあるが、害はない。
  - 接続先に tmux があれば、セッション名と同じ名前の tmux セッションの中で起動する（`tmux new-session -A`）。ssh が切れても、Claude は動き続ける。tmux を使わないときは `-NoTmux`（sh は `-T`）を付ける。
  - こちらも tmux（psmux）の中だと tmux が二重になる。接続先の tmux を操作するときは、prefix を 2 回押すなど、接続先の設定に合わせる。
- 終了コード 2 は、自動でタブを開けなかったことを表す（sh だけ）。表示された `ssh -t ...` を手で実行するようユーザーに伝える。

## 3. 確かめる

1. 数秒待ってから、tmux の中なら `tmux capture-pane -p -t <ウィンドウ>` で接続先の画面を 1 回だけ見る。
   - `/rc active` と出ていれば、Remote Control につながっている。
   - パスワード・ホスト鍵・フォルダの信頼・Remote Control の初回の確認（`Enable Remote Control?`）で止まっていたら、ユーザーにそのウィンドウで答えてもらう。Claude からは答えない。
2. `ListAgents` で、セッション名の行（`Remote Control` と付く）が出たか確かめる。
   - 出ないときは、このセッションが Remote Control につながっていないことが多い。ユーザーにこのセッションで `/rc` を実行してもらってから、もう一度だけ確かめる。
   - 何度も確認を繰り返さない。

## 4. 作業を頼む・結果を確かめる（頼まれたときだけ）

session-generate の「2. 作業を頼む」と同じ形で `SendMessage` を送る。違うのは次の点だけ。

- `notify_when_idle` は付けない（別のマシンでは使えない）。代わりに「終わったら結論の要約を SendMessage で `<自分の名前>` に送って」と必ず書く。返事は、こちらが Remote Control につながっているときだけ届く。
- 手がかりのパスは、接続先のマシンのパスで書く。
- 結果が届かないときは、tmux の中なら `tmux capture-pane -p -S -300 -t <ウィンドウ>` で接続先の画面を読んで、最後の返答を確かめる。
