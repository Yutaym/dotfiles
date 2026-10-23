---
name: session-kill
description: 同じマシンで動いている別の Claude Code のセッション（と、ssh で開いた接続先で session-ssh が起動したセッション）を選んで終了（kill）する。選択肢か「一覧を表示」の表から、クリック・番号・セッション名のどれかで選んでもらってから終了する。複数を一度に選べる。「セッションを kill して」「〜のセッションを止めて」「いらないセッションを終了して」などと言われたときに使う。
effort: low
argument-hint: "[セッション名 または 番号 ...]"
---

# session-kill

同じマシンで動いている別の Claude Code のセッションを選んで、そのプロセスを終了する。ssh で開いた接続先のセッション（session-ssh で起動したものなど）も、ssh で接続先のスクリプトを動かして終了できる。
会話の記録（`~/.claude/projects/` の下）は消えないので、あとで `claude --resume` で開き直せる。

## 1. 一覧を作る

表は **session-overview スキルの表（先頭の列がセッション番号 No）をそのまま使う**。何をしているセッションかが分かるようにして、選び間違いを防ぐため。

1. session-overview スキル（`~/.claude/skills/session-overview/SKILL.md`）の「1. 生きているセッションを調べる」「2. 会話記録から材料を抜き出す」のとおりに、`ListAgents`・`session-overview.py`・（Remote Control のセッションがあれば）`remote-overview.py` を実行する。
2. 「3. 一覧にして報告する」の書き方（No・列・太字・場所・何をしているか・最後の動き・セルを短くする）に従って表を作る。どのセッションを表に入れるか、番号の振り方も session-overview と同じにする。

| No | セッション | 状態 | 場所 | 何をしているか | 最後の動き |
|---|---|---|---|---|---|
| 1 | **claudews-psmux** | idle | claudeWS / tmux 0:4 | psmux の調査（claudews-fd から依頼） | 完了（10/20 14:16） |
| 2 | mac-test | idle | Home_Mac_1:dotfiles / ssh 0:7 | session-ssh を試すために起動 | 記録なし |

session-overview の表との違い:
- **自分のセッション（`ListAgents` の 1 行目に出る名前）は表に入れない。** 番号も振らない。
- 別のマシンのセッションは、`remote-overview.py` で読めたもの（ssh で開いたウィンドウの接続先にあるもの）だけを入れる。ssh で接続先のスクリプトを動かして終了する（「4.」）。クラウドのセッションは終了できないので入れない（session-overview でも入れない）。
- 表の下の「ユーザーが対応したほうがよいもの」の箇条書きは書かない。
- 終了できるセッションが 1 つもなければ、そう伝えて終わる。

## 2. 終了するセッションを選んでもらう

**表と同じ返答の中で `AskUserQuestion` を出さない。** ダイアログが出ている間、その前に書いた表はユーザーに見えない（2026/10/22 に、表のあとにダイアログを出したところ「現在のセッションのリストを表示させてください」と返ってきた。ssh-generate でも同じことが起きた）。

- **引数で指定されていて、表の番号かセッション名とはっきり一致するとき:** 表を出し、聞かずにそれを使う（ダイアログは出さないので、表は見える）。
- **指定がないとき:** 表は出さずに、`AskUserQuestion` で選んでもらう（`multiSelect: true`）。
  - **選択肢には、必ず「一覧を表示」を入れる**（`label`: `一覧を表示`、`description`: `終了できるセッションの一覧（No・状態・場所・何をしているか）を表で表示する`）。選択肢は 4 つまでなので、セッションは 3 つまでになる。
  - セッションの選択肢は、表の先頭から 3 つにする。`label` は `<No>. <セッション名>`、`description` は「状態・何をしているか（短く）・場所」にする。
  - 質問文に「ほかのセッションは『一覧を表示』で確かめるか、Other に番号かセッション名を書いてください（複数ならカンマ区切り。例: `2, 5` / `claudews-psmux`）」と書く。
- **「一覧を表示」が選ばれたとき**（ほかと一緒に選ばれたときも）: 終了はせずに表を出し、**ダイアログは出さずにその返答を終える**。表の下に「終了するセッションの No かセッション名を返信してください（複数ならカンマ区切り。例: `2, 3` / `dotfiles-work`）」と書き、ユーザーの返信で選ぶ。
- 引数の指定が表と一致しなかったときも、表を出して同じように返信してもらう。

答えの読み方:
- 選択肢と Other の両方が来たら、両方を合わせる。
- 各項目は、数字なら表の番号、それ以外ならセッション名として読む（大文字・小文字の違いだけなら表の表記に直す）。
- 表にない番号や名前があれば、それだけを伝えて、もう一度返信してもらう。似た名前があっても決めつけない。

## 3. 確かめる（busy のときだけ）

選ばれたセッションに `busy`（作業中）や `waiting`（返事待ち）のものがあれば、作業の途中で止まることを伝え、`AskUserQuestion` で「終了する / やめる」を 1 回だけ確かめる。すべて `idle` なら確かめずに次へ進む（選んだこと自体を指示とみなす）。

## 4. 終了する

スクリプトはこの SKILL.md と同じフォルダの `scripts/` にある。選んだセッション名を全部並べて実行する。

```bash
uv run --no-project python "<このスキルのフォルダ>/scripts/kill-session.py" <セッション名> [<セッション名> ...]
```

- `~/.claude/sessions/<pid>.json` でセッション名から PID を調べ、そのプロセスが動いていて、名前に `claude`（または `node`）が入ることを確かめてから終了する。PID が別のプロセスに使い回されていれば終了しない。
  - Windows は `taskkill /PID <PID> /T /F`（MCP サーバーなどの子プロセスも一緒に終わる）、それ以外は `SIGTERM`。
  - 自分のセッションは、指定されても終了しない。
- **開いていたウィンドウも閉じる。** どこで動いているかは、claude の親プロセスから判断する。
  - **tmux:** claude の親（ペインのシェル）を `#{pane_pid}` で探し、そのシェルごと終了する。ペインが閉じ、最後のペインならウィンドウも閉じる。`-t` を使わないので、psmux の `@ID` / `%ID` の取り違えは起きない。
  - **ターミナル:** claude の親がシェル（pwsh・bash・zsh など）で、その親がターミナル（Windows Terminal・WezTerm・kitty・iTerm2・GNOME Terminal・Konsole など）なら、シェルごと終了してタブを閉じる。
    - Windows では、先に claude を `taskkill /T /F` で終わらせ、残ったシェルを `TerminateProcess` で**終了コード 0** で終わらせる。Windows Terminal の `closeOnExit` の既定（`automatic`。直接起動したタブでは `graceful`）は、正常終了のときだけタブを閉じるため。`taskkill /F` でシェルを終わらせると終了コード 1 になり、タブが「プロセスが終了しました」と表示して残る（2026/10/21 に確認）。
  - **それ以外**（VS Code の統合ターミナルなど）: claude だけを終了する。
  - ユーザーが「ウィンドウは残して」と言ったときだけ `--keep-window` を付ける（claude だけを終了する）。
- 出力は 1 セッションにつき 1 行。`killed:`（終了した。`where=` が場所、`closed=` が閉じたもの）、`not found:`（動いているプロセスがない）、`skipped:`（claude ではない、自分自身）、`failed:`（終了できなかった）。
- 先に `--dry-run` を付けると、終了せずに、対象と閉じるものだけを表示する。
- `~/.claude/sessions/*.json` は Claude Code の内部形式で、バージョンで変わることがある。読めなくなったらスクリプトを直す。

### 別のマシンのセッション（ssh で開いた接続先にあるもの）

`remote-overview.py` の出力の `# 接続先: <Host>` に書かれた接続先で、同じスクリプトを ssh で動かす。接続先ごとに、そこのセッション名を並べる。

```bash
ssh -o BatchMode=yes <Host> 'exec "$SHELL" -lic "uv run --no-project python ~/.claude/skills/session-kill/scripts/kill-session.py <セッション名> [<セッション名> ...]"'
```

接続先の既定のシェルが PowerShell の Windows なら、次の形にする（どちらかは `ssh -o BatchMode=yes <Host> 'echo $PSVersionTable.PSEdition'` が `Core` / `Desktop` と出るかで判断する）。

```powershell
ssh -o BatchMode=yes <Host> '$env:PYTHONIOENCODING = "utf-8"; uv run --no-project python $HOME/.claude/skills/session-kill/scripts/kill-session.py <セッション名> [<セッション名> ...]'
```

- 接続先にも、このスキル（`~/.claude/skills/session-kill`）と uv が必要。入っていなければ `can't open file ... kill-session.py` と出て終了できない。**そのときは、下の「`/exit` をキー入力で送る」で終了する。**
  - 2026/10/22 の時点で、Home_Desktop_PC_1_win には session-kill スキルが入っていなかった（session-overview は入っていた）。同じ日に接続先で dotfiles を pull して `install_claude.ps1` でリンクを張り直したら入った。
- 2026/10/22 に、Home_Desktop_PC_1_win（Windows）の `pcwin-dotfiles` を PowerShell の形で終了し、`killed: pcwin-dotfiles ... where=other` と出て、このマシンのウィンドウも閉じた。ただし、直後の `ListAgents` には `idle` のまま残っていた（Windows では `taskkill /F` で強制終了するので、Remote Control の接続をきちんと閉じられず、サーバー側の状態がすぐには変わらないためだと思われる。確かめてはいない）。そのときは「接続先では終了した。一覧からはしばらくして消えるか offline になるはず」と伝える。
- session-ssh で起動したセッションは、接続先の tmux の中で動いている。claude が終わるとそのペインのコマンドも終わり、接続先の tmux のセッションが閉じ、ssh も終わって、このマシンのウィンドウ（ウィンドウ名がセッション名のもの）も閉じる。
- 2026/10/22 に、Home_Mac_1 の `mac-test` で `--dry-run` が `would kill: mac-test pid=7350 where=other` と出ることを確認した（接続先で claude の親は `zsh -lic` なので `where=other` になる）。続けて実際に終了し、`killed: mac-test ... where=other` と出て、このマシンのウィンドウが閉じ、`ListAgents` からも消えた（offline としても残らなかった）ことを確認した。psmux ではウィンドウが閉じると、後ろのウィンドウの番号が詰まる（0:8 が 0:7 になった）。

#### `/exit` をキー入力で送る（接続先に session-kill がないとき）

`/exit` は Claude からは実行できない（SendMessage で送っても、コマンドとしては動かない）。代わりに、このマシンの tmux（psmux）から、ssh を開いているウィンドウにキー入力として送る。キーは ssh と接続先の tmux を通って、接続先の Claude の入力欄に届く。

1. 送り先のウィンドウを決める。`remote-overview.py` の出力の「ssh を開いているこのマシンのウィンドウ」のうち、**ウィンドウ名がセッション名と同じもの**（session-ssh で開いたもの）だけを使う。なければこの方法は使わず、ユーザーに `/exit` してもらうよう伝える。
2. `tmux capture-pane -p -t <tmux のセッション名>:<ウィンドウ番号>` で画面を見て、次の 2 つを確かめる。どちらかが違えば送らない（入力中の文字に `/exit` がつながったり、作業を途中で止めたりするため）。
   - `ListAgents` の状態が `idle` で、画面に作業中の表示（`✽ ...ing…` など）がない。
   - 入力欄（`>` または `❯` の行）が空である。
3. 送る。`-l` で文字をそのまま送り、Enter は別に送る。`-t` は `セッション名:ウィンドウ番号` で指定する（psmux では `@ID` / `%ID` を使わない）。

   ```bash
   tmux send-keys -t <tmux のセッション名>:<ウィンドウ番号> -l '/exit'
   tmux send-keys -t <tmux のセッション名>:<ウィンドウ番号> Enter
   ```

4. 数秒待ってから、そのウィンドウが閉じたか（`tmux list-windows`）と、`ListAgents` から消えたかを 1 回だけ確かめる。Claude が終わると、接続先の tmux のセッションが閉じ、ssh も終わってウィンドウが閉じるはず。
   - ウィンドウが残っていたら、`capture-pane` で画面を見て、どこで止まっているかを伝える。もう一度は送らない。
- 2026/10/22 に追加した手順で、まだ通しでは確かめていない。初めて使ったときは、うまくいったかをここに書く。

## 5. 確かめて報告する

- `ListAgents` をもう一度実行し、終了したセッションが一覧から消えたかを 1 回だけ確かめる。別のマシンのセッションは、終了しても `offline` として一覧に残ることがある（Remote Control のセッションは、終わったあとも一覧に残るため）。
- 別のマシンのセッションを終了したときは、このマシンの ssh のウィンドウが閉じたかを `tmux list-windows -F '#{session_name}:#{window_index} #{window_name}'` で確かめる。残っていれば、そう伝える。
- **tmux:** `killed:` の行に `(ペインが残っている)` と出たときだけ、`tmux list-windows -F '#{session_name}:#{window_index} #{window_name}'` で番号と名前を確かめてから `kill-window -t <セッション名>:<番号>` で閉じる。psmux では `-t` に `@ID` / `%ID` を使わない（別のウィンドウを閉じることがある）。
- **ターミナル:** Windows Terminal は、終了コード 0 で終わらせればタブが閉じる（`closeOnExit` が既定のとき）。ユーザーが `closeOnExit` を `"never"` にしているとタブは残る。Windows Terminal 以外のターミナルでタブが閉じるかは確かめていないので、残っていたら閉じてもらうよう伝える。
- **それ以外（VS Code など）:** ターミナルのパネルは残る。そう伝える。
- ユーザーには、終了したセッション・閉じたもの（`closed=`）・終了できなかったもの（理由）・開き直す方法（`claude --resume`）を短く報告する。
