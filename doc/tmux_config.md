# tmux 設定まとめ

`tmux_config/` の設定内容。Linux / macOS の tmux と、Windows の psmux（Windows ネイティブの tmux 互換ツール）で同じ設定ファイル `.tmux.conf` を使う。Prefix キーは `Ctrl-q`。

## ファイル構成

```text
tmux_config/
├── .tmux.conf         # 設定ファイル本体（tmux / psmux 共通）
├── install_tmux.sh    # インストーラー（Linux / macOS）
└── install_tmux.ps1   # インストーラー（Windows / psmux）
```

## インストール

```sh
bash ~/dotfiles/tmux_config/install_tmux.sh      # Linux / macOS
```

```powershell
pwsh ~/dotfiles/tmux_config/install_tmux.ps1     # Windows（psmux）
```

どちらも、済んでいる処理はスキップする。リンク先に既存のファイルがあれば、警告してスキップする（上書きしない）。

| 項目           | Linux / macOS（`install_tmux.sh`）                                  | Windows（`install_tmux.ps1`）                          |
| -------------- | ------------------------------------------------------------------- | ------------------------------------------------------ |
| 本体の確認     | tmux が無ければ警告だけ（apt / brew などで入れる）                  | psmux が無ければ `winget install --id marlocarlo.psmux -e` を案内 |
| リンク         | `~/.config/tmux/tmux.conf` → `tmux_config/.tmux.conf`               | `~/.psmux.conf` → `tmux_config/.tmux.conf`             |
| プラグイン     | tpm を `~/.config/tmux/.tmux/plugins/tpm` に clone（git が必要）    | ppm を `~/.psmux/plugins/ppm` に置く（git が必要）      |
| その他         | `~/.tmux.conf` があれば警告（こちらが優先して読まれるため）         | —                                                      |

- Linux で `~/.config/tmux/tmux.conf` に置くのは、設定の中のリロード（`Prefix + r`）と tpm の読み込みがこのパスを前提にしているため
- psmux は `~/.psmux.conf` → `~/.psmuxrc` → `~/.tmux.conf` → `~/.config/psmux/psmux.conf` の順に探し、最初に見つけた 1 つだけ読む（[psmux docs/configuration.md](https://github.com/marlocarlo/psmux/blob/master/docs/configuration.md)）
- Windows でシンボリックリンクを作るには、管理者権限での実行が必要（開発者モードで作ったリンクは読めないことがある。README を参照）

---

## 簡単な操作方法

以下の `Prefix` は `Ctrl-q`。「`Prefix` → `c`」は、`Ctrl-q` を押して離してから `c` を押す。

### セッション（ターミナルから実行）

| コマンド                      | 動作                                       |
| ----------------------------- | ------------------------------------------ |
| `tmux`                        | 新しいセッションを開始                     |
| `tmux new -s <名前>`          | 名前を付けてセッションを開始               |
| `tmux ls`                     | セッションの一覧                           |
| `tmux a` / `tmux a -t <名前>` | 直近の / 指定したセッションに戻る（attach） |
| `tmux kill-session -t <名前>` | セッションを終了                           |

Windows では `tmux` の代わりに `psmux` でもよい（psmux は `tmux` という名前でも入る）。

### よく使うキー

| キー                         | 動作                                             | 備考         |
| ---------------------------- | ------------------------------------------------ | ------------ |
| `Prefix` → `d`               | セッションから抜ける（detach。中の処理は続く）   | 既定         |
| `Prefix` → `c`               | 新しいウィンドウ                                 | 既定         |
| `Prefix` → `,`               | ウィンドウの名前を変更                           | 既定         |
| `Prefix` → `Ctrl-h` / `Ctrl-l` | 前 / 次のウィンドウ（続けて押せる）            | この設定     |
| `Prefix` → `n` / `p`         | 次 / 前のウィンドウ                              | 既定         |
| `Prefix` → `1`〜`9`          | 番号のウィンドウへ（番号は 1 から）              | 既定         |
| `Prefix` → `w` / `s`         | ウィンドウ / セッションを一覧から選ぶ            | 既定         |
| `Prefix` → `\|`              | 左右に分割（今いるディレクトリで開く）           | この設定     |
| `Prefix` → `-`               | 上下に分割（今いるディレクトリで開く）           | この設定     |
| `Prefix` → `h` / `j` / `k` / `l` | 左 / 下 / 上 / 右のペインへ（続けて押せる）  | この設定     |
| `Alt` + `←` `↓` `↑` `→`      | 矢印の方向のペインへ（Prefix 不要）              | この設定     |
| `Ctrl-o`                     | 次のペインへ順番に移動（Prefix 不要）            | この設定     |
| `Prefix` → `H` / `J` / `K` / `L` | ペインの大きさを変える（続けて押せる）       | この設定     |
| `Prefix` → `z`               | ペインを最大化 / 元に戻す                        | 既定         |
| `Prefix` → `x` / `&`         | ペイン / ウィンドウを閉じる（確認あり）          | 既定         |
| `Prefix` → `[`               | コピーモード（スクロール・コピー）               | 既定         |
| `Prefix` → `]`               | コピーした内容を貼り付け                         | 既定         |
| `Prefix` → `r`               | 設定ファイルを再読み込み                         | この設定     |
| `Prefix` → `:`               | コマンドを入力                                   | 既定         |
| `Prefix` → `?`               | キーバインドの一覧                               | 既定         |

マウスも使える（ペインのクリックで選択、境界のドラッグで大きさの変更、ホイールでスクロール）。

### コピーモード（vi 風）

1. `Prefix` → `[` でコピーモードに入る（マウスのホイールでも入る）
2. `h` `j` `k` `l` などで移動し、`v` で選択を始める（`Ctrl-v` で矩形選択に切り替え）
3. `y` でコピーする（コピーモードは抜けない。`q` で抜ける）
4. `Prefix` → `]` で貼り付ける

`/` `?` で検索、`n` `N` で次 / 前の候補へ移動できる。

### プラグイン

| キー                    | 動作                                       |
| ----------------------- | ------------------------------------------ |
| `Prefix` → `I`          | プラグインのインストール（初回に必要）     |
| `Prefix` → `U`          | プラグインの更新                           |
| `Prefix` → `Alt-u`（tmux）/ `M`（psmux） | リストに無いプラグインの削除 |
| `Prefix` → `Ctrl-s`     | セッションの保存（resurrect）              |
| `Prefix` → `Ctrl-r`     | 保存したセッションの復元（resurrect）      |

---

## 基本設定

| 設定                                           | 内容                                                     |
| ---------------------------------------------- | -------------------------------------------------------- |
| `default-terminal 'screen-256color'`           | 256 色を使う                                             |
| `terminal-overrides 'xterm:colors=256'`        | xterm を 256 色として扱う                                |
| `prefix C-q` / `unbind C-b` / `bind C-q send-prefix` | Prefix を `Ctrl-b` から `Ctrl-q` に変更（2 回押すとアプリに `Ctrl-q` を送る） |
| `base-index 1` / `pane-base-index 1`           | ウィンドウ・ペインの番号を 1 から始める                  |
| `renumber-windows on`                          | ウィンドウを閉じたら番号を詰める                         |
| `escape-time 0`                                | Esc キーの待ち時間をなくす（vim で Esc がもたつかない）  |
| `mouse on`                                     | マウス操作を有効にする                                   |
| `mode-keys vi`                                 | コピーモードを vi 風にする                               |
| `extended-keys on` / `terminal-features 'xterm*:extkeys'` | 拡張キー（Shift+Enter などの区別）を有効にする |
| `terminal-features 'xterm*:RGB'` | 24 ビットカラーを使う（ステータスバーの `#RRGGBB` の色をそのまま出す） |

## キーバインド

| キー                         | コマンド                                          |
| ---------------------------- | ------------------------------------------------- |
| `Prefix` → `h` `j` `k` `l`   | `select-pane -L/-D/-U/-R`（`-r` で連続入力可）    |
| `Prefix` → `H` `J` `K` `L`   | `resize-pane`（左右は 5、上下は 1 ずつ。`-r`）    |
| `Prefix` → `Ctrl-h` / `Ctrl-l` | `select-window -t :-` / `:+`（`-r`）            |
| `Prefix` → `\|` / `-`        | `split-window -h` / `-v`（`-c '#{pane_current_path}'`） |
| `Prefix` → `r`               | `source-file ~/.config/tmux/tmux.conf` して「Reloard was successful.」と表示 |
| `Ctrl-o`（Prefix 不要）      | `select-pane -t :.+`                              |
| `Alt` + 矢印（Prefix 不要）  | `select-pane -L/-R/-U/-D`                         |
| `Ctrl-Enter`（Prefix 不要）  | `send-keys -H 1b 5b 31 33 3b 35 75`（CSI u の `ESC[13;5u` を送る） |
| コピーモードの `v` / `Ctrl-v` / `y` | `begin-selection` / `rectangle-toggle` / `copy-selection` |

- `Prefix` → `l` は既定では「直前のウィンドウへ」だが、この設定でペイン移動に上書きしている
- `Ctrl-o` は Prefix なしで tmux が受け取るので、シェルや vim の `Ctrl-o` は使えなくなる
- `Ctrl-Enter` の設定は psmux 用。psmux 3.4.0 は Windows で Ctrl+Enter を LF に変えて渡すため（psmux Issue #409）、CSI u のシーケンスをそのまま送る

## 見た目

### ステータスバー

- 上に表示する（`status-position top`）。1 秒ごとに更新する（`status-interval 1`。psmux は 15 秒）
- 配色は VS Code の One Dark Pro を元にしている（`#RRGGBB` で指定）。バーは文字 `#9da5b4`、背景 `#21252b`。ウィンドウ一覧は左寄せで、区切りの隙間なし
- 2 段にしている（`status 2`）
  - 1 段目: 左に「セッション名:現在のウィンドウ番号」（`status-left`。Prefix やコピーモードに関係なく常に `#4d78cc` の帯。10 文字を超えると切る）、続けてウィンドウ一覧。`status-right` は空。psmux は既定の 1 段目だとウィンドウ番号を帯の外に出すので、`status-format[0]` を自分で書いている（クリックで移れるように `#[range=...]` で囲む）
  - 2 段目（`status-format[1]`）: 左に Prefix を押している間の `Wait`、コピーモード中の `Copy`。右詰めで `📁 claudeWS | ⚡🔋: 59 % | 10/21 12:58 Wed`（今のフォルダ名 | バッテリー残量 | `%m/%d %H:%M %a`。ssh 中は `📁 フォルダ名` の代わりに `🌐 接続先`。接続先はシェルの `ssh` 関数と spawn-ssh がペインのオプション `@ssh_host` に入れる。充電中・AC につながっているときは ⚡ を付け、バッテリーが無ければ `🔋: AC`）。どちらもプラグインを使わずに書いている（下の「プラグインを使わずに書いているもの」）
  - 2 段目の左右の中身はユーザーオプション `@status2-left` / `@status2-right` に置き、`#{T:@status2-left}#[align=right]#{T:@status2-right}` で展開する。`status-format` は strftime を通らないので、`T:` で時刻も展開させる
- ウィンドウ: 非アクティブは `#3e4452`（文字 `#dcdcdc`）、アクティブは `#61afef`（文字 `#21252b`）の背景で番号と名前（`#I:#W`）を表示。区切りに Powerline の記号を使う（Nerd Font などの対応フォントが必要）
  - ウィンドウ名は 1 段目に収まるように「(画面の幅 - 17) / ウィンドウ数 - 7」文字で切り、`…` を付ける。フック（`client-resized` / `after-new-window` / `window-unlinked`）で `set -gF @wname` し、`#{=/11/…:window_name}` のような書式を作って `#{T:@wname}` で展開する（psmux は `#{=/#{...}/…:...}` のように長さに `#{}` を書けないため）

### ペイン

| 対象                       | 色                                       |
| -------------------------- | ---------------------------------------- |
| アクティブなペイン         | 文字 `white`、背景 `colour236`           |
| 非アクティブなペイン       | 文字 `white`、背景 `colour240`（少し明るくして区別する） |
| ペインの境界線             | 文字 `colour111`、背景 `colour236`       |
| メッセージ                 | 文字 `colour68`、背景 `brightwhite`、反転 |

## プラグイン

tmux は tpm、psmux は ppm（tpm の PowerShell 版）で管理する。設定ファイルの `%if "#{m:*psmux*,#{socket_path}}"` で切り替える（psmux のソケットは `~/.psmux/<名前>`、tmux は `/tmp/tmux-<UID>/<名前>`）。入れるプラグインは、tmux と psmux で同じもの（resurrect と continuum）にそろえている。

### tmux（tpm）

設定ファイルの最後で `~/.config/tmux/.tmux/plugins/tpm/tpm` を読み込む。

| プラグイン                                                                     | 内容                                                       |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| [tpm](https://github.com/tmux-plugins/tpm)                                     | プラグインマネージャー                                     |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)               | セッションの保存（`Prefix` → `Ctrl-s`）と復元（`Prefix` → `Ctrl-r`） |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)               | 15 分ごとにセッションを自動保存（起動時の自動復元は `@continuum-restore 'on'` が無いのでしない）。ほかに tmux のサーバーが動いているときは自動保存を始めない |

コメントアウトしているもの: tmux-online-status、tmux-sidebar。tmux 用の `@plugin` の行は `set -g` ではなく `set-option -g` と書く（ppm は設定ファイルの `set -g @plugin '...'` の行を文字列で探すので、`%else` の中にあっても tmux 用のプラグインまでインストールしてしまうため）。

### psmux（ppm）

プラグインは `~/.psmux/plugins/` に入る。psmux は `@plugin` の行で各プラグインの `plugin.conf` を読み込み、設定ファイルの最後で `~/.psmux/plugins/ppm/ppm.ps1` を実行する。プラグインは [psmux/psmux-plugins](https://github.com/psmux/psmux-plugins) にある。

| プラグイン          | 内容                                                                     |
| ------------------- | ------------------------------------------------------------------------ |
| ppm                 | プラグインマネージャー                                                   |
| psmux-resurrect     | セッションの保存（`Prefix` → `Ctrl-s`）と復元（`Prefix` → `Ctrl-r`）。保存先は `~/.psmux/resurrect` |
| psmux-continuum     | 15 分ごとにセッションを自動保存（tmux 側と同じく自動復元はしない）       |

- ppm のキー（`Prefix` → `I` / `U` / `M`）は設定ファイルで直接割り当てている。psmux は ppm 自身の `plugin.conf` を自動では読まず、`run` で ppm.ps1 を実行しても設定の再読み込みではキーが登録されなかったため
- `status-interval` は 15 秒にしている。`#()` を実行するたびに pwsh を起動するため
- psmux-continuum の `client-attached` フックは、ppm の読み込みの後で `run-shell -b` 付きに上書きしている。psmux 3.4.0 は attach 時のフックに `-b` を付けずに実行するので、そのままだと起動時にステータスバーに `running: pwsh ... auto_save.ps1` が一瞬出るため

### プラグインを使わずに書いているもの

Prefix の表示とバッテリー残量は、tmux・psmux とも、プラグイン（tmux-prefix-highlight / tmux-battery、psmux-prefix-highlight / psmux-battery）を使わずに `@status2-left` / `@status2-right` に直接書いている。

| 表示           | 書き方（tmux / psmux 共通）                                                                 | 使わないプラグイン |
| -------------- | ------------------------------------------------------------------------------------------- | ------------------ |
| Prefix・コピーモード | `#{?client_prefix,... Wait ,}` と `#{?pane_in_mode,... Copy ,}`                         | psmux-prefix-highlight は `status-right` を丸ごと上書きするので使わない（今は 2 段目に出すのでどのみち使えない）。tmux もそろえる |
| バッテリー残量 | `#()` で取得する。取り方は下の表                                                            | psmux-battery は試したときに値が「…」のまま変わらなかったので使わない（原因は未確認）。tmux もそろえる |

| 環境           | バッテリー残量の取り方                                                                      |
| -------------- | ------------------------------------------------------------------------------------------- |
| psmux          | `pwsh -EncodedCommand` で `Win32_Battery` の `EstimatedChargeRemaining` を読む（`#()` は `cmd /C` で実行され、括弧や `%` をそのまま書けないため、PowerShell のコマンドを Base64 にして渡す） |
| tmux（macOS）  | `pmset -g batt` の `NN%`                                                                    |
| tmux（Linux / WSL） | `/sys/class/power_supply/BAT*/capacity`                                                |

- tmux の `@status2-right` は `#{T:...}` で strftime を通るので、`#()` の中の `%` は `%%` と書く。`#()` は対になっていない `)` で終わるので、`case` の `)` は使えない（`$( )` は使える）

---

## 注意点


- **Windows（psmux）で効かないもの**
  - `Prefix` → `r` のリロード: `~/.config/tmux/tmux.conf` が無いので失敗する。`Prefix` → `:` で `source-file ~/.psmux.conf` を実行する

  - `extended-keys` / `terminal-features`: psmux は対応していない（読み込むと起動時に「unknown option」の警告が一瞬出る）。`%if` で tmux のときだけ読み込む
- **改行コード**: `.tmux.conf` は LF にする。CRLF だと Linux の tmux で `%if` などが効かなくなる（WSL の tmux 3.2a で確認）
- **ステータスバーの色**: psmux は `status-fg` / `status-bg` に対応していないので、`status-style` で指定している
