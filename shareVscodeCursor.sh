#!/bin/bash

# 1. 念のため、既存の Cursor 設定をバックアップ
cp -r ~/.config/Cursor/User ~/.config/Cursor/User_backup
# 2. Cursor の設定ファイルを削除（リンク作成のため）
rm -f ~/.config/Cursor/User/settings.json
rm -f ~/.config/Cursor/User/keybindings.json
rm -rf ~/.config/Cursor/User/snippets

# 3. VSCode の設定ファイルへのシンボリックリンクを作成
ln -s ~/.config/Code/User/settings.json ~/.config/Cursor/User/settings.json
ln -s ~/.config/Code/User/keybindings.json ~/.config/Cursor/User/keybindings.json
ln -s ~/.config/Code/User/snippets ~/.config/Cursor/User/snippets
