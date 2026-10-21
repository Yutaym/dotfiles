---
name: spawn-window
description: 新しいターミナルのタブ（tmux の中では新しいウィンドウ。ペイン分割を指定されたら専用ウィンドウを分割して並べる）でシェルを開き、指定したフォルダに移った状態を作る。既定では開いたウィンドウに画面を切り替える。Claude Code は起動しない。Windows Terminal・macOS のターミナル / iTerm2 / Ghostty・WezTerm・kitty・GNOME Terminal・Konsole・tmux に対応する。「新しいウィンドウを作って」「新しいタブでシェルを開いて」「〜のフォルダでウィンドウを開いて移動して」などと言われたときに使う。
argument-hint: "[作業フォルダ] [ウィンドウ名]"
---

# spawn-window

新しいタブ（tmux の中では新しいウィンドウ）でシェルを開く。起動先の判断は spawn-session スキルと同じで、違うのは次の点だけ。

- Claude Code ではなく、普段のシェル（Windows は `pwsh`、それ以外は `$SHELL` のログインシェル）を開く。プロファイルも読み込まれる。
- tmux の中では、既定で開いたウィンドウに画面を切り替える（spawn-session は切り替えない）。
- 分割のときの専用ウィンドウの名前は `shells`（spawn-session は `cc-sessions`）。

Claude Code のセッションを開きたいときは spawn-session、ssh で接続したタブを開きたいときは spawn-ssh を使う。

## 前提

- **Claude のツールから開いたシェルは、Claude のセッション固有の環境変数（`CLAUDE_CODE_CHILD_SESSION=1`、親の `CLAUDE_CODE_SESSION_ID` など）を引き継ぐ。** そのシェルで `claude` を起動すると子セッション扱いになり、会話の記録が保存されない。同梱のスクリプトは、どの起動先でもこれらの変数を消してからシェルを渡す。
- **Windows Terminal の `wt` は、コマンドの中の `;` を自分の区切り記号として扱う。** そのため、フォルダのパスに `;` があるとスクリプトが止まる。

## 1. 開くものを決める

- **作業フォルダ:** 指定がなければ今の作業フォルダにする。
- **ウィンドウ名:** 指定がなければ付けない（tmux が自動で付ける）。付けるときは英数字・ハイフン・アンダースコアだけにする。psmux は名前に `.` があると `-t` で取り違えるため。
- **ペイン分割:** ユーザーが「並べて」「分割して」などと言ったときだけ分割する。指定がなければ聞かずに、新しいウィンドウにする。
- **画面の切り替え:** 既定では切り替える。ユーザーが「後ろで開いて」「画面はそのまま」などと言ったときだけ切り替えない。

## 2. 開く

OS に合わせてスクリプトを実行する。スクリプトはこの SKILL.md と同じフォルダの `scripts/` にある。

**Windows（ネイティブ）:** PowerShell ツールで実行する。

```powershell
pwsh -NoProfile -File "<このスキルのフォルダ>\scripts\launch-window.ps1" -Dir "<作業フォルダ>" [-Name <ウィンドウ名>] [-Split] [-Background]
```

**macOS / Linux / WSL:** Bash ツールで実行する。

```bash
sh "<このスキルのフォルダ>/scripts/launch-window.sh" -d "<作業フォルダ>" [-n <ウィンドウ名>] [-s] [-b]
```

- 起動先はスクリプトが環境変数で判断する（下の「ターミナルごとの対応」）。
- **tmux の中（`$TMUX` がある）では、ほかの判断より先に tmux を使う。**
  - 普段は新しいウィンドウ（`new-window -d -P`）で開き、出てきた `セッション名:ウィンドウ番号` に `select-window` で切り替える。
  - `-Split`（`-s`）のときは、名前が `shells` の専用ウィンドウに並べる。なければ作り、あれば分割して `select-layout tiled` で並べ直す。切り替えるときは新しいペインが選ばれた状態になる。
  - `-Background`（`-b`）を付けると、`-d` のまま作って切り替えない。
  - psmux では `-t` に `@ID` / `%ID` を使わない（別のセッションやウィンドウの同じ番号として扱われることがある）。スクリプトの外で tmux を操作するときも、`-t セッション名:ウィンドウ名` か `セッション名:ウィンドウ番号` で指定する。
- tmux の外（Windows Terminal など）では、新しいタブが前に出る。`-Background` / `-b` は効かない。
- 終了コード 2 は、自動でタブを開けなかったことを表す。そのときは、表示された手順をユーザーに伝えて、手で開いてもらう。

## 3. 確かめて報告する

- **tmux の中:** スクリプトの `switched:` の行（`-Background` のときは `launched:` の行とウィンドウ名）で、開いた場所が分かる。中身を確かめるときは `tmux capture-pane -p -t <セッション名:ウィンドウ番号>` を 1 回だけ使う。何度も確認を繰り返さない。
- **それ以外:** タブの中身は見えないので、`launched:` の行を根拠に「開いた」とだけ報告する。
- ユーザーには、開いたフォルダ・開き方（新しいタブ / ウィンドウ / 分割）・画面を切り替えたかどうかを短く報告する。

## ターミナルごとの対応

| 環境 | 起動方法 | 確認状況 |
|---|---|---|
| tmux の互換（psmux 3.4.0、Windows） | `$env:TMUX` があれば `tmux new-window -d -P -F '#{session_name}:#{window_index}'` → `select-window`。`-Split` のときは専用ウィンドウ `shells` を作成 / `split-window` → `select-layout tiled` | 2026/10/21 に確認（新しいウィンドウに切り替わること、フォルダに移ること、プロファイルが読み込まれること、`CLAUDECODE` と `CLAUDE_CODE_SESSION_ID` が消えていること、`-Background` で画面が変わらないこと、`-Split` を 2 回で `shells` に 2 ペインが並び、新しいペインが選ばれること） |
| Windows Terminal | `wt -w 0 new-tab --reloadEnvironment -d <フォルダ> pwsh -NoExit -File start-shell.ps1 -Dir <フォルダ>` | 未確認（spawn-session の同じ起動方法は確認済み） |
| Windows で Windows Terminal がない | `Start-Process pwsh`（新しいウィンドウ。タブではない） | 未確認 |
| tmux（WSL / Linux / macOS） | `tmux new-window -d -P ... "sh <起動用スクリプト>"` → `select-window`。`-s` のときは上と同じ | 未確認（`sh -n` で構文だけ確認） |
| WezTerm / kitty / iTerm2 / Ghostty / macOS のターミナル / GNOME Terminal / Konsole / WSL の中の Windows Terminal | spawn-session の `launch-session.sh` と同じ方法で、起動用スクリプトを `sh` で実行する | 未確認 |
| 上のどれでもない | 自動では開かない。手で開いて `cd` するよう表示する | — |

未確認の環境で初めて使って、うまく動かなかったときは、このスキルを直す。
