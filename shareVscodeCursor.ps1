# 1. 念のため、既存の Cursor 設定をバックアップ
# Copy-Item "$env:APPDATA\Cursor\User" "$env:APPDATA\Cursor\User_backup" -Recurse -Force

# 2. Cursor の設定フォルダを削除（リンク作成のため）
Remove-Item "$env:APPDATA\Cursor\User\settings.json" -Recurse -Force
Remove-Item "$env:APPDATA\Cursor\User\keybindings.json" -Recurse -Force
Remove-Item "$env:APPDATA\Cursor\User\snippets" -Recurse -Force

# 3. VSCode の設定フォルダをターゲットにシンボリックリンクを作成
cmd /c mklink "%APPDATA%\Cursor\User\settings.json" "%APPDATA%\Code\User\settings.json"
cmd /c mklink "%APPDATA%\Cursor\User\keybindings.json" "%APPDATA%\Code\User\keybindings.json"
cmd /c mklink /D "%APPDATA%\Cursor\User\snippets" "%APPDATA%\Code\User\snippets"
