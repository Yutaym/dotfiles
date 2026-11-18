# スタートアップに AutoHotkey スクリプトのショートカットを作る（何度実行してもよい）
# 対象は $scripts の *.ahk。ショートカットの名前はスクリプト名と同じ。
$ahk = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
$scripts = 'esc-ime-off.ahk', 'runPowerToys.ahk'
$startup = [Environment]::GetFolderPath('Startup')
$shell = New-Object -ComObject WScript.Shell
foreach ($name in $scripts) {
    $script = Join-Path $PSScriptRoot $name
    $lnk = Join-Path $startup ([IO.Path]::GetFileNameWithoutExtension($name) + '.lnk')
    $s = $shell.CreateShortcut($lnk)
    $s.TargetPath = $ahk
    $s.Arguments = "`"$script`""
    $s.WorkingDirectory = $PSScriptRoot
    $s.Save()
    Write-Output "created: $lnk"
}
