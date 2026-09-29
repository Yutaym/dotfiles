# dotfiles

Windows / Linux / macOS で使うエディタ・シェル・ツールの設定ファイル集。

## 構成

| ディレクトリ          | 内容                                          | インストーラー                                      | 配置方法         |
| --------------------- | --------------------------------------------- | --------------------------------------------------- | ---------------- |
| `neovim_config/`      | Neovim（lazy.nvim、VSCode Neovim 対応）       | `install_nvim.ps1` / `install_nvim.sh`              | シンボリックリンク |
| `vim_config/`         | Vim（`.vimrc`）                               | `install_vim.ps1` / `install_vim.sh`                | シンボリックリンク |
| `powershell_config/`  | PowerShell 7 のプロファイル                   | `install_powershell.ps1`                            | コピー           |
| `zsh_config/`         | zsh（oh-my-zsh は初回起動時に自動インストール） | `install_zsh.sh`                                    | コピー           |
| `claude_config/`      | Claude Code（`CLAUDE.md` / `settings.json` など） | `install_claude.ps1` / `install_claude.sh`          | シンボリックリンク |
| `winterminal_config/` | Windows Terminal の `settings.json`           | なし（手動でコピー）                                | —                |
| `tmux_config/`        | tmux（`.tmux.config`）                        | なし（手動で `~/.tmux.conf` に配置）                | —                |
| `python_config/`      | Miniconda のインストール・conda パッケージ導入 | `install_miniconda.sh` / `python_init.bat`          | —                |
| `scripts/`            | 補助スクリプト（zsh 用ツールのインストールなど） | —                                                   | —                |
| `doc/`                | 設定のドキュメント                            | —                                                   | —                |
| `tmp/`                | 使わなくなった旧設定の置き場                  | —                                                   | —                |

## セットアップ

`~/dotfiles`（Windows は `%USERPROFILE%\dotfiles`）に clone する。

```sh
git clone https://github.com/Yutaym/dotfiles.git ~/dotfiles
```

各インストーラーは何度実行しても問題ない（済んでいる処理はスキップする）。

### Windows（PowerShell）

```powershell
pwsh ~/dotfiles/powershell_config/install_powershell.ps1   # -SkipAutoInstall でツールの自動インストールを省略
pwsh ~/dotfiles/neovim_config/install_nvim.ps1
pwsh ~/dotfiles/vim_config/install_vim.ps1
pwsh ~/dotfiles/claude_config/install_claude.ps1
```

> シンボリックリンクを作るインストーラーは、「開発者モード」の有効化か管理者権限での実行が必要。

### Linux / macOS

```sh
bash ~/dotfiles/zsh_config/install_zsh.sh
bash ~/dotfiles/neovim_config/install_nvim.sh   # Neovim 本体のインストールは Linux x86_64 のみ
bash ~/dotfiles/vim_config/install_vim.sh
bash ~/dotfiles/claude_config/install_claude.sh
```

### インストーラーの動作

- **シンボリックリンク方式**（Neovim / Vim / Claude Code）: リポジトリのファイルを直接参照するので、リポジトリ側の変更がすぐ反映される。リンク先に既存ファイルがある場合は警告してスキップする
- **コピー方式**（PowerShell / zsh）: 既存ファイルと内容が異なる場合は `*.bak.<日時>` にバックアップしてから上書きする。リポジトリを `~/dotfiles` 以外に置いた場合は、読み込み先のパスを書き換えてコピーする
- **デフォルトシェル**: PowerShell / zsh のインストーラーは、デフォルトシェルが pwsh / zsh でなければ変更手順を表示する（変更自体は手動）
- **Claude Code**: `local-paths.md` は環境ごとに編集するため、リンクではなくコピーする（既存なら上書きしない）

## ドキュメント

- [Neovim 設定まとめ](doc/neovim_config.md) — オプション・キーマッピング・プラグインの一覧
