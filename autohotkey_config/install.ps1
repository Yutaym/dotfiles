# スタートアップに esc-ime-off.ahk のショートカットを作る（何度実行してもよい）
$ahk = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
$script = Join-Path $PSScriptRoot 'esc-ime-off.ahk'
$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'esc-ime-off.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $ahk
$s.Arguments = "`"$script`""
$s.WorkingDirectory = $PSScriptRoot
$s.Save()
Write-Output "created: $lnk"
