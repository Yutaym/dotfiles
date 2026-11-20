# tmux（$TMUX があるときの決まり）

- `$TMUX` があるとき（tmux の中で動いているとき）は、作業に応じて自分からペイン分割・新しいウィンドウを使う。
  - 開発サーバー・ログ監視・長時間かかるビルドなど、終わらない／長いコマンドは `command tmux split-window -d -h -c <作業フォルダ> '<コマンド>'` で別ペインに出す。
  - 別のテーマの作業や調査は `command tmux new-window -d -n <名前> -c <作業フォルダ>` で別ウィンドウに出す。
  - `-d` を付けて、ユーザーが見ている画面を切り替えない。
  - 出力を確かめるときは `command tmux capture-pane -p -t <ペイン>` を使う。
- 必ず `command tmux` で呼ぶ（Bash ツールの zsh では `tmux` が oh-my-zsh のエイリアスになっていてエラーになるため）。素の `tmux` は Hook（`hooks/pretool-guard.mjs`）が止める。
