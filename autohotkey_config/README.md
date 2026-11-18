# Esc で IME をオフにする（Windows 専用）

Windows Terminal で `Esc` を押したときに IME をオフにする AutoHotkey v2 のスクリプト。
Claude Code の vim モードで、NORMAL に戻ったとき日本語入力のままになり、`h` `j` `k` `l` などが打てない問題の対処。
`Esc` 自体はそのまま渡すので、NORMAL に戻る動作は変わらない。Mac には不要（対象外）。

## 動作
- 対象: Windows Terminal（`WindowsTerminal.exe`）がアクティブなときの `Esc` だけ。
- IME をオフにする方式: `ImmGetDefaultIMEWnd` の IME 制御用ウィンドウへ `WM_IME_CONTROL`（`IMC_SETOPENSTATUS` = オフ）を送る。
- INSERT に戻ったときに IME を自動でオンにはしない（モードを知る手段がない）。日本語を打つときは手動でオンにする。

## 導入手順（PowerShell）
1. AutoHotkey v2 を入れる（入っていれば省略）。
   ```powershell
   winget install AutoHotkey.AutoHotkey
   ```
   `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe` ができることを確かめる。
2. dotfiles を取得する（取得済みなら `git -C ~/dotfiles pull`）。
3. スタートアップに登録して、今すぐ起動する。
   ```powershell
   pwsh -NoProfile -File $HOME\dotfiles\autohotkey_config\install.ps1
   Start-Process (Join-Path ([Environment]::GetFolderPath('Startup')) 'esc-ime-off.lnk')
   Start-Process (Join-Path ([Environment]::GetFolderPath('Startup')) 'runPowerToys.lnk')   # 使うときだけ
   ```
   - `install.ps1` は `esc-ime-off.lnk` と `runPowerToys.lnk` をスタートアップに作る。何度実行してもよい。
   - AutoHotkey の場所が違うときは、`install.ps1` の `$ahk` を直す。

## 確認
1. Windows Terminal で、日本語入力をオンにする。
2. `Esc` を押して、日本語入力がオフ（半角英数）になれば成功。

## うまくいかないとき
- 「Target window not found」のダイアログが出る: スクリプトの `DetectHiddenWindows true` が抜けている（IME 制御用ウィンドウは非表示のため必須）。
- 何も起きない: タスクトレイに AutoHotkey のアイコン（緑の H）があるか確認する。なければ起動し直す。
- 日本語入力の変換中に `Esc` を押したときの文字の扱い、psmux の中での動作は、未確認。

## 止める・外す
- 一時的に止める: タスクトレイの AutoHotkey のアイコン → Exit。
- 自動起動をやめる: スタートアップの `esc-ime-off.lnk`（`runPowerToys.lnk`）を削除する。
  ```powershell
  Remove-Item (Join-Path ([Environment]::GetFolderPath('Startup')) 'esc-ime-off.lnk')
  ```

## そのほかのスクリプト
- `runPowerToys.ahk`: `Ctrl+Space` で PowerToys Run を起動する。元は `OneDrive\ドキュメント\AutoHotkey\` にあったもの。`install.ps1` でスタートアップに登録される（`esc-ime-off.ahk` と同じ）。
- `Ctrl+Space` を IME のオン・オフに割り当てている環境では、競合に注意する。
