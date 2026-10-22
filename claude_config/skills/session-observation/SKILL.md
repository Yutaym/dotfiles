---
name: session-observation
description: ほかの Claude Code のセッションの状況（状態・場所・何をしているか・最後の動き）を、一定の間隔で画面を描き直して表示し続ける監視画面を開く。tmux / psmux の中ではペインを分割し、それ以外では新しいタブで開く。ssh の接続先のセッションも、長めの間隔で読む。ほかのセッションから止められる。「セッションを監視して」「セッションの様子を表示し続けて」「監視画面を開いて」「監視を止めて」などと言われたときに使う。
argument-hint: "[stop] [間隔の秒数]"
---

# session-observation

ほかのセッションの状況を、session-overview の表と同じ列で表示し続ける。
表示はスクリプト（`scripts/observe.py`）が行う。Claude はタイマーを使わずに、監視画面を開くだけにする（更新のたびにトークンを使わず、このセッションも塞がないため）。

## 開く

この SKILL.md と同じフォルダの `scripts/` にある起動用スクリプトを実行する。

- Windows（ネイティブ）:
  ```bash
  pwsh -NoProfile -File "<このスキルのフォルダ>/scripts/launch-observer.ps1" [-Interval 秒] [-RemoteInterval 秒] [-NoRemote] [-Horizontal] [-Here]
  ```
- macOS / Linux / WSL:
  ```bash
  sh "<このスキルのフォルダ>/scripts/launch-observer.sh" [-i 秒] [-r 秒] [-n] [-h] [-H]
  ```

| 指定 | .ps1 | .sh | 意味 |
|---|---|---|---|
| このマシンの間隔 | `-Interval` | `-i` | 既定 3 秒 |
| ssh の接続先の間隔 | `-RemoteInterval` | `-r` | 既定 60 秒。ssh は 1 回に 10 秒ほどかかるので長めにする |
| ssh を読まない | `-NoRemote` | `-n` | |
| 左右に分割 | `-Horizontal` | `-h` | 既定は上下（表の幅を広く取るため） |
| そのまま実行 | `-Here` | `-H` | 新しいペインやタブを開かず、そのターミナルで動かす |

- tmux / psmux の中では、呼び出し元のウィンドウを `split-window -d` で分割する（画面は切り替えない）。場所は「セッション名:ウィンドウ番号」で指定する（psmux は `@ID` / `%ID` を取り違えることがあるため）。
- tmux の外では、新しいタブで開く（Windows Terminal、WezTerm、kitty、iTerm2、macOS のターミナル、GNOME Terminal、Konsole）。開けないターミナルでは、手で実行するコマンドを表示して終了コード 2 で終わるので、それをユーザーに伝える。
- 開いたら、どこに開いたか（スクリプトの `launched:` の行）をユーザーに伝える。

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
  - 「返事待ち」は、最後の返答が「？」「ますか」「ください」などで終わっているかで機械的に判断するので、外れることがある。
  - No は起動の早い順に振る。ListAgents の順と違うことがあるので、session-kill で番号を使うときは session-kill の一覧で確かめる。
- 色: busy は黄、idle は緑、返事待ちは赤、そのほかの状態は紫。1 時間以上動きのない idle のセッションは薄く出す。tmux の中のセッションは名前を太字にする。
- ssh の接続先は、このマシンの tmux で `@ssh_host` の付いたペイン（ssh-generate / session-ssh で開いたもの）から探し、接続先で `session-overview.py --json` を実行する。接続先の session-overview.py が古い（`--json` がない）と読めないので、接続先の dotfiles を更新してもらう。読めなかった接続先は、表には入れずに表の下に理由を 1 行出す。
- 材料の読み取りは session-overview の `scripts/session-overview.py` を import して使う。Claude Code の内部形式が変わって項目が取れなくなったら、session-overview.py を直す。
