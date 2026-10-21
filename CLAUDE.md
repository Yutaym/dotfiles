# dotfiles リポジトリのルール

## シェルスクリプトの実行権限

- シェルスクリプト（`*.sh`）は、すべて実行権限付き（git のモード `100755`）で記録する。
- Windows の git は `core.fileMode=false` なので、`chmod +x` は記録されず、新しく追加した `.sh` は `100644` になる。`.sh` を追加したら、コミットの前に `git update-index --chmod=+x <ファイル>` で付ける。
  - `git add` の後に実行する（インデックスにないファイルには付けられない）。
  - 確認: `git diff --cached --summary` に `mode change 100644 => 100755`（新規なら `create mode 100755`）と出る。
  - 漏れの確認と一括で付ける方法: `git ls-files -s -- '*.sh' | awk '$1=="100644"{print $4}' | xargs -r git update-index --chmod=+x`

## 必須アプリのインストーラー

- 環境構築や設定の実行に必要なアプリ（ランタイム・パッケージマネージャーなど、どの環境でも入れるもの）のインストールは、`scripts/install_essentials.sh`（Linux / macOS）と `scripts/install_essentials.ps1`（Windows）にまとめて書く。各設定のインストーラーや別のスクリプトに散らさない。
  - 今入れているもの: git（Linux / macOS は確認だけ）、nvm（Windows は nvm-windows）と Node.js の LTS、npm のグローバルパッケージ（`scripts/npm_global_packages.txt`。nvm の node に入れる）、uv、GitHub Copilot CLI（Windows は winget、Linux / macOS は npm）。
  - 新しく足すときは、`.sh` と `.ps1` の両方に書く（片方の OS でしか使わないものは、その OS のほうだけでよい）。入っていればスキップする形にして、何度実行してもよいようにする。
  - 足したら、`README.md` の構成とセットアップの説明、この一覧も更新する。
