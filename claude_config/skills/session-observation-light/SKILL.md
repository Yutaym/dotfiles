---
name: session-observation-light
description: session-observation のコンパクト版。ほかの Claude Code のセッションを、No・色付きの状態・場所（tmux の「セッション:ウィンドウ」だけ。ないときは -）の 3 列だけで表示し続ける細い監視画面を開く。tmux / psmux の中では幅の細いペインを横に分割し、それ以外では新しいタブで開く。ssh の接続先のセッションも出す。「小さい監視画面を開いて」「コンパクトに監視して」「session-observation-light」などと言われたときに使う。
effort: low
argument-hint: "[stop] [間隔の秒数]"
---

# session-observation-light

session-observation と同じ材料・判定で、表の列を **No・状態・場所** の 3 つに絞って表示し続ける（2026/10/30 にユーザーが決めた）。
表示はスクリプト（`scripts/observe_light.py`）が行う。Claude はタイマーを使わずに、監視画面を開くだけにする。

```
[通常版] 16:01:32
No  状態      場所
 3  返事待ち  0:2
 6  busy      0:6
 5  idle      -
```

## 開く

この SKILL.md と同じフォルダの `scripts/` にある起動用スクリプトを実行する。

- Windows（ネイティブ）:
  ```bash
  pwsh -NoProfile -File "<このスキルのフォルダ>/scripts/launch-light.ps1" [-Interval 秒] [-RemoteInterval 秒] [-NoRemote] [-Vertical] [-Size 列数] [-Here]
  ```
- macOS / Linux / WSL:
  ```bash
  sh "<このスキルのフォルダ>/scripts/launch-light.sh" [-i 秒] [-r 秒] [-n] [-v] [-s 列数] [-H]
  ```

| 指定 | .ps1 | .sh | 意味 |
|---|---|---|---|
| このマシンの間隔 | `-Interval` | `-i` | 既定 10 秒 |
| ssh の接続先の間隔 | `-RemoteInterval` | `-r` | 既定 60 秒 |
| ssh を読まない | `-NoRemote` | `-n` | |
| 上下に分割 | `-Vertical` | `-v` | 既定は左右 |
| ペインの大きさ | `-Size` | `-s` | 既定は左右 24 列・上下 12 行（`split-window -l`）。`-l` が使えない tmux 互換ソフトでは、大きさを指定せずに分割し直す |
| そのまま実行 | `-Here` | `-H` | 新しいペインやタブを開かず、そのターミナルで動かす |

- 開き方（tmux の中では呼び出し元のウィンドウを `split-window -d` で分割、外では新しいタブ）は session-observation と同じ。開けないターミナルでは、手で実行するコマンドを表示して終了コード 2 で終わるので、それをユーザーに伝える。
- 開いたら、どこに開いたか（スクリプトの `launched:` の行）をユーザーに伝える。

## 止める

```bash
uv run --no-project python "<このスキルのフォルダ>/scripts/observe_light.py" --stop
```

（`launch-light.ps1 -Stop` / `launch-light.sh -x`、session-observation の `observe.py --stop` でも同じ。）監視画面の中では q か Ctrl+C で止まる。

## 監視画面の操作

操作は session-observation と同じ（処理は observe.py の `handle_key`）。詳しくは session-observation の「監視画面の操作」を参照。
- 行のどこかをクリックするか、No を打って Enter を押すと、そのセッションの tmux のウィンドウに移る（2026/10/30 にユーザーが決めた）。
- 1 行目の左端の `[通常版]` をクリックすると、同じペインのまま session-observation の表示に切り替わり、ペインが広がる（通常版の `[light]` で戻る）。
- ↑↓・ホイール・PgUp/PgDn・Home/End（j / k / b / スペース / g / G）でスクロールできる。

## 決まりごと

- **監視は session-observation と合わせて同時に 1 つだけ動く**（2026/10/30 にユーザーが決めた）。印のファイル（`~/.claude/session-observation/observer.json`）を共用するので、light を開くと session-observation の監視が閉じ、逆も同じ。
- 材料の読み取り・状態の判定・並び（優先度の高い順）・No・ssh の接続先の読み込み・返事待ちの記録（`waiting.log`）は、session-observation の `scripts/observe.py` を import してそのまま使う。決まりは session-observation の SKILL.md を参照。直すときは observe.py（判定は session-overview.py）を直し、light には同じ処理を写さない。
- 列:
  - **No**: session-overview・session-kill と同じ番号（SNo）。
  - **状態**: busy・shell（黄）、idle（緑）、返事待ち（赤の太字。`status` が `waiting` / `requires_action`）、返事待ち?（赤。返答の終わり方からの推定）、そのほかの状態（紫）。1 時間以上動きのない idle は行ごと薄く出す。
  - **場所**: このマシンの tmux の「セッション名:ウィンドウ番号」だけ（例 `0:3`）。tmux の外のセッションは `-`。ssh の接続先のセッションは、その ssh を開いているこのマシンのウィンドウを出す。
- 見出しは切り替えの `[通常版]` と時刻（表が収まらないときはその右に「12-30/45」のような位置、打っている番号）だけにする。読めなかった ssh の接続先は、表の下に「<接続先>: 読めない」「<接続先>: 接続先が古い」と 1 行出す（理由の詳細は session-observation で見る）。
