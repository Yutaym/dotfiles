---
name: spawn-ssh
description: ~/.ssh/config の Host から接続先を選んでもらい、新しいターミナルのタブ（tmux の中では新しいウィンドウ。ペイン分割を指定されたら専用ウィンドウを分割して並べる）で ssh 接続した状態を作る。複数の接続先を一度に開ける。Windows Terminal・macOS のターミナル / iTerm2 / Ghostty・WezTerm・kitty・GNOME Terminal・Konsole・tmux に対応する。「新しいタブで ssh して」「〜に ssh 接続したタブを開いて」「サーバーにつないだウィンドウを作って」などと言われたときに使う。
argument-hint: "[接続先 ...]"
---

# spawn-ssh

`~/.ssh/config` の Host から接続先を選んでもらい、新しいタブで `ssh <接続先>` を実行する。
起動先の判断は session-spawn スキルと同じ（同じ方式でタブ・ウィンドウを開く）。

## 1. 接続先を決める

1. 接続先の候補を一覧にする。スクリプトはこの SKILL.md と同じフォルダの `scripts/` にある。

   ```bash
   uv run --no-project python "<このスキルのフォルダ>/scripts/list-ssh-hosts.py"
   ```

   - `~/.ssh/config` と、そこから `Include` されたファイルの `Host` の別名を、No・Host・HostName・User・Port の表で出す。
   - `Host *` のような `*` `?` `!` を含むパターンは、接続先として選べないので出さない。
   - HostName / User / Port は、その Host ブロックに書かれた値だけを出す（`Host *` などから当たる値は出ない）。
   - `Host` の行のすぐ次の行に `# not suggest` と書かれた Host は出さない（一覧にも選択肢にも入れない）。ほかの位置に書かれた `# not suggest` は印として扱わない。
     ```
     Host gpuMachine_GUI
         # not suggest
     ```
   - 設定ファイルがなければ、その旨をユーザーに伝え、接続先（`user@host` など）を直接聞く。
2. 接続先を選んでもらう。
   - ユーザーが接続先を指定していて、一覧の Host と一致する（大文字・小文字の違いだけなら一覧の表記に直す）なら、確認せずにそれを使う。指定が一覧のどれとも一致しないときは、似た候補を挙げて確認する。`user@host` の形で指定されたときは、一覧になくてもそのまま使ってよい。
   - 指定がなければ、`AskUserQuestion` で選んでもらう（`multiSelect: true` にして、複数選べるようにする）。
     - **選択肢には、候補の数にかかわらず必ず「一覧を表示」を入れる**（`label`: `一覧を表示`、`description`: `接続先の一覧（No・Host・HostName・User・Port）を表示して、もう一度選ぶ`）。選択肢は 4 つまでなので、接続先は 3 つまでになる。
     - 候補が 3 つ以下なら、全部を選択肢にする。
     - 4 つ以上なら、`AskUserQuestion` の前に一覧の表をそのまま返答に書き、選択肢には、ユーザーの言葉に合いそうなもの（なければ表の先頭）を 3 つまで入れる。質問文に「ほかの接続先は Other に No か Host を書いてください（複数ならカンマ区切り）」と書く。
     - 選択肢の `label` は Host の別名、`description` は `User@HostName:Port`（分かる部分だけ）にする。
     - 「一覧を表示」が選ばれたら（ほかの接続先と一緒に選ばれたときも）、接続はせずに一覧の表をそのまま返答に書き、続けて同じ形の `AskUserQuestion` をもう一度出す（選択肢にはまた「一覧を表示」を入れる）。接続先が選ばれるまで、これを繰り返す。
3. ペイン分割の指定（「並べて」「分割して」など）があるかを確かめる。指定がなければ聞かずに、普段の起動（新しいタブ / ウィンドウ）にする。

## 2. 開く

OS に合わせてスクリプトを実行する。接続先を複数並べると、1 つずつ別のタブで開く。

**Windows（ネイティブ）:** PowerShell ツールで実行する。

```powershell
pwsh -NoProfile -File "<このスキルのフォルダ>\scripts\launch-ssh.ps1" [-Split] [-Background] <接続先> [<接続先> ...]
```

**macOS / Linux / WSL:** Bash ツールで実行する。

```bash
sh "<このスキルのフォルダ>/scripts/launch-ssh.sh" [-s] [-b] <接続先> [<接続先> ...]
```

- 起動先は、session-spawn と同じくスクリプトが環境変数で判断する（下の「ターミナルごとの対応」）。
- **tmux の中（`$TMUX` がある）では、ほかの判断より先に tmux を使う。**
  - 普段は、接続先の名前を付けた新しいウィンドウで開く（`new-window -d`）。
  - **既定では、開いたウィンドウに画面を切り替える。** 全部開いてから、最後に開いたウィンドウ（分割なら `ssh-sessions`）に `select-window` で移る。スクリプトは `switched: <セッション名>:<ウィンドウ番号>` と出す。
    - ユーザーが「後ろで開いて」「画面はそのまま」などと言ったときだけ、`-b`（Windows は `-Background`）を付けて、呼び出し元のウィンドウのままにする。
    - 接続先の名前に `.` が入る（IP アドレスなど）と psmux の `-t` が取り違えるので、ウィンドウは名前ではなく `new-window -P` で受け取った番号で指定する。
  - **ユーザーがペイン分割を指定したときだけ** `-s`（Windows は `-Split`）を付ける。名前が `ssh-sessions` の専用ウィンドウがなければ作り、あれば分割して `select-layout tiled` で並べ直す。
  - psmux では、session-spawn と同じく `-t` に `@ID` / `%ID` を使わず、`-t セッション名:ウィンドウ名` で指定する。
- 新しいタブでは、`start-ssh.ps1`（Windows）または一時ファイルの起動用スクリプトが `ssh <接続先>` を実行する。
  - ssh が 0 以外で終わったとき（接続の失敗、ホスト鍵の拒否など）は、エラーを残したまま「Enter で閉じます」と表示して待つ。正常に切断したときは、そのままタブを閉じる。
  - ホスト鍵の確認・パスワード・パスフレーズの入力は、新しいタブでユーザーが行う。Claude からは答えない。
- 接続先には、英数字と `. _ @ : % -` だけを使える（`wt` が `;` を区切り記号として扱うことと、コマンドへの混入を防ぐため）。それ以外の文字を含むときは、スクリプトが終了コード 64 で止まる。
- 終了コード 2 は、自動でタブを開けなかった接続先があったことを表す。そのときは、表示された `ssh <接続先>` を手で実行するようユーザーに伝える。

## 3. 確かめて報告する

- **tmux の中:** 数秒待ってから `tmux capture-pane -p -t <switched: に出た セッション名:ウィンドウ番号>`（`-b` のときは `<セッション名>:<接続先>`）で、接続できたか（プロンプトが出たか）、パスワードやホスト鍵の確認で止まっているかを 1 回だけ確かめる。分割したときは `-t <セッション名>:ssh-sessions` の各ペインを見る。何度も確認を繰り返さない。
- **それ以外:** タブの中身は見えないので、スクリプトの `launched:` の行を根拠に「開いた」とだけ報告する。接続できたかは確かめられないと書く。
- ユーザーには、開いた接続先と開き方（新しいタブ / ウィンドウ / 分割）と、画面を切り替えたかどうかを短く報告する。

## ターミナルごとの対応

| 環境 | 起動方法 | 確認状況 |
|---|---|---|
| Windows Terminal | `wt -w 0 new-tab --title <接続先> --suppressApplicationTitle pwsh -NoProfile -File start-ssh.ps1 -Target <接続先>` | 2026/10/21 にタブが開くところまで確認（`launched:` が出た）。タブの中身は未確認 |
| tmux の互換（psmux、Windows） | `$env:TMUX` があれば `tmux new-window -d -n <接続先>`。`-Split` のときは専用ウィンドウ `ssh-sessions` を作成 / `split-window` → `select-layout tiled` | 2026/10/21 に確認（新しいウィンドウでホスト鍵の確認が出ること、拒否すると終了コードと「Enter で閉じます」が出て Enter で閉じること、`-Split` で 2 つ開くと専用ウィンドウに 2 ペインで並ぶこと）。既定で開いたウィンドウに切り替わること（`new-window -P -F` で番号を受け取り `select-window`）も確認。`-Split` と `-Background` の切り替えは未確認 |
| tmux（WSL / Linux / macOS） | `tmux new-window -d -c ~ -n <接続先> "sh <起動用スクリプト>"`。`-s` のときは上と同じ | 未確認（session-spawn の同じ処理は WSL の tmux 3.2a で確認済み） |
| Windows で Windows Terminal がない | `Start-Process pwsh`（新しいウィンドウ。タブではない） | 未確認 |
| WezTerm / kitty / iTerm2 / Ghostty / macOS のターミナル / GNOME Terminal / Konsole / WSL の中の Windows Terminal | session-spawn の `launch-session.sh` と同じ方法で、起動用スクリプトを `sh` で実行する | 未確認 |
| 上のどれでもない | 自動では開かない。手で実行する `ssh <接続先>` を表示する | — |

未確認の環境で初めて使って、うまく動かなかったときは、このスキルを直す。
