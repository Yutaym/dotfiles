# dotfiles リポジトリのルール

## シェルスクリプトの実行権限

- シェルスクリプト（`*.sh`）は、すべて実行権限付き（git のモード `100755`）で記録する。
- Windows の git は `core.fileMode=false` なので、`chmod +x` は記録されず、新しく追加した `.sh` は `100644` になる。`.sh` を追加したら、コミットの前に `git update-index --chmod=+x <ファイル>` で付ける。
  - `git add` の後に実行する（インデックスにないファイルには付けられない）。
  - 確認: `git diff --cached --summary` に `mode change 100644 => 100755`（新規なら `create mode 100755`）と出る。
  - 漏れの確認と一括で付ける方法: `git ls-files -s -- '*.sh' | awk '$1=="100644"{print $4}' | xargs -r git update-index --chmod=+x`
