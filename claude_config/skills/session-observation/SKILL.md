---
name: session-observation
description: ほかの Claude Code のセッションの状況（状態・場所・何をしているか・最後の動き）を、一定の間隔で画面を描き直して表示し続ける監視画面を開く。tmux / psmux の中ではペインを分割し、それ以外では新しいタブで開く。ssh の接続先のセッションも、長めの間隔で読む。ほかのセッションから止められる。「セッションを監視して」「セッションの様子を表示し続けて」「監視画面を開いて」「監視を止めて」などと言われたときに使う。
effort: low
argument-hint: "[stop] [間隔の秒数]"
---

# session-observation

ほかのセッションの状況を、session-overview の表と同じ列で表示し続ける。
表示はスクリプト（`scripts/observe.py`）が行う。Claude はタイマーを使わずに、監視画面を開くだけにする（更新のたびにトークンを使わず、このセッションも塞がないため）。

## 開く

この SKILL.md と同じフォルダの `scripts/` にある起動用スクリプトを実行する。

- Windows（ネイティブ）:
  ```bash
  pwsh -NoProfile -File "<このスキルのフォルダ>/scripts/launch-observer.ps1" [-Interval 秒] [-RemoteInterval 秒] [-NoRemote] [-Vertical] [-Here]
  ```
- macOS / Linux / WSL:
  ```bash
  sh "<このスキルのフォルダ>/scripts/launch-observer.sh" [-i 秒] [-r 秒] [-n] [-v] [-H]
  ```

| 指定 | .ps1 | .sh | 意味 |
|---|---|---|---|
| このマシンの間隔 | `-Interval` | `-i` | 既定 10 秒 |
| ssh の接続先の間隔 | `-RemoteInterval` | `-r` | 既定 60 秒。ssh は 1 回に 10 秒ほどかかるので長めにする |
| ssh を読まない | `-NoRemote` | `-n` | |
| 上下に分割 | `-Vertical` | `-v` | 既定は左右（横に並べる。2026/10/22 にユーザーが決めた） |
| そのまま実行 | `-Here` | `-H` | 新しいペインやタブを開かず、そのターミナルで動かす |

- tmux / psmux の中では、呼び出し元のウィンドウを `split-window -d -h` で左右に分割する（画面は切り替えない）。場所は「セッション名:ウィンドウ番号」で指定する（psmux は `@ID` / `%ID` を取り違えることがあるため）。
- tmux の外では、新しいタブで開く（Windows Terminal、WezTerm、kitty、iTerm2、macOS のターミナル、GNOME Terminal、Konsole）。開けないターミナルでは、手で実行するコマンドを表示して終了コード 2 で終わるので、それをユーザーに伝える。
- 開いたら、どこに開いたか（スクリプトの `launched:` の行）をユーザーに伝える。

## 監視画面の操作

監視画面にフォーカスがあるとき、表が画面の高さに収まらなければキーでスクロールできる。描き直しは続ける。
- ↑↓（j / k）: 1 行、PgUp / PgDn（b / スペース）: 1 ページ、Home / End（g / G）: 先頭 / 最後
- 収まらないときは、1 行目の右に「12〜30 行目 / 全 45 行」のように今の位置を出す。
- q（または Ctrl+C）で終わる。
- キーは Windows は msvcrt、それ以外は termios で読む。

## 止める

```bash
uv run --no-project python "<このスキルのフォルダ>/scripts/observe.py" --stop
```

（`launch-observer.ps1 -Stop` / `launch-observer.sh -x` でも同じ。）どのセッションからでも止められる。監視は 0.5 秒以内に終わり、tmux のペインやタブも閉じる。監視画面の中で Ctrl+C を押しても止まる。

## 決まりごと

- **監視は同時に 1 つだけ動く。** 起動すると `~/.claude/session-observation/observer.json` に自分の印を書く。新しい監視を開くと印が書き換わり、古い監視は自分で終わる。`--stop` はこのファイルを消す。
- 表の列と、表に入れる・入れないの決まりは session-overview に合わせる。違うところ:
  - 生きているかどうかは `ListAgents` ではなく、`~/.claude/sessions/*.json` の `pid` のプロセスが動いているか（Windows では開始時刻 `procStart` も一致するか）で判断する（session-overview.py の `is_alive`）。状態（busy / idle）は同じファイルの `status` を使う。
  - 「何をしているか」は LLM で要約しない。自動で付いたタイトルと最後の依頼をそのまま短く出す。タイトルがセッション名と同じときは、最後の依頼を出す。
  - 「返事待ち」は 2 種類に分ける（2026/10/22 にユーザーが決めた）。
    - **返事待ち**（赤の太字）: `sessions/*.json` の `status` が `waiting` / `requires_action`。確かな返事待ち。
    - **返事待ち?**（赤）: idle で、最後の返答の終わりが「？」「?」「ますか」「ですか」「でしょうか」か、返事を求める「〜ください」（教えて・選んで・決めて・知らせて・返信して・回答して・指示して・返事を・回答を・指示を など）で終わるもの。返答の終わり方からの推定なので、外れることがある。「確認してください」「実行してください」のような作業のお願いは、返事が要らないので入れない。最後の会話から 24 時間を過ぎたものも入れない（7 日前の「…確認してください。」が返事待ちになっていた）。
    - ssh の接続先の返答は切り詰めて送られるので、JSON の `lastReply.tail`（切り詰めていない最後の 100 文字）で判断する。
  - **返事待ちの記録:** 返事待ち・返事待ち? と判定したら、`~/.claude/session-observation/waiting.log` に 1 行書く（時刻・鍵・セッション・種類・判断の材料・最後の会話の時刻・返答の最後の 80 文字。タブ区切り）。同じセッションの同じ返答は 1 回だけ。ユーザーに「返事待ちの記録を見て」「また誤判定が出た」などと言われたら、このファイルを読み、いつ・どのセッションが・どんな終わり方で返事待ちになったかを表にして伝える。誤判定なら、`session-overview.py` の `QUESTION_RE`（判定は session-overview と共通。`observe.py` はそれを呼ぶ）の直し方を提案する。
  - **並びは優先度の高い順**（2026/10/22 にユーザーが決めた）: 返事待ち → 返事待ち? → busy → そのほかの状態 → idle（最近動いたものから）→ 1 時間以上動きのない idle。同じ組の中は最近動いたものから並べる。
  - **No は、session-overview・session-kill と同じ番号**（2026/10/22 にユーザーが決めた）。並びとは関係なく、セッションごとに決まっていて、終わるまで変わらない（session-overview の「No」を参照）。並びが優先度の順なので、表の No は順番どおりにはならない。
- 色: busy は黄、idle は緑、返事待ちは赤、そのほかの状態は紫。1 時間以上動きのない idle のセッションは薄く出す。tmux の中のセッションは名前を太字にする。
- ssh の接続先は、このマシンの tmux で `@ssh_host` の付いたペイン（ssh-generate / session-ssh で開いたもの）から探し、接続先で `session-overview.py --json` を実行する。接続先の session-overview.py が古い（`--json` がない）と読めないので、接続先の dotfiles を更新してもらう。読めなかった接続先は、表には入れずに表の下に理由を 1 行出す。
  - **ssh の接続先は、Remote Control につながっているセッションだけを出す**（session-overview に合わせる。2026/10/22 にユーザーが決めた）。見分けには `sessions/*.json` の `bridgeSessionId` を使う（JSON の `remoteControl`）。名前を付けずに Remote Control につないだセッションは、ListAgents では自動で付いた別の名前（例 `macbookpro-velvety-owl`）で出るので、session-overview の表と名前が合わないことがある。
  - このマシンのセッションは、Remote Control につながっているかにかかわらず全部出す。
- 材料の読み取りは session-overview の `scripts/session-overview.py` を import して使う。Claude Code の内部形式が変わって項目が取れなくなったら、session-overview.py を直す。
