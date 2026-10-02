# この環境固有のパス設定

- META_DIR: `~/vaults/90_Meta`
- VAULT_DIR: `~/vaults`（git リポジトリ。remote: `origin`、ブランチ: `master`）

## Claude 設定ファイルの実体（シンボリックリンク）

`~/.claude` 下の次のファイルはシンボリックリンクで、直接は編集できない。編集するときは、場所を調べずに最初から実体のパスを使う。

- `~/.claude/CLAUDE.md` → `~/dotfiles/claude_config/CLAUDE.md`
- `~/.claude/settings.json` → `~/dotfiles/claude_config/settings.json`
- `~/.claude/keybindings.json` → `~/dotfiles/claude_config/keybindings.json`
