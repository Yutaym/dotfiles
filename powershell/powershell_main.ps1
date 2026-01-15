if (-not $env:path.Split(';').Contains('.')) {
    $env:path += ";."
}

$condaPath = Join-Path $env:USERPROFILE "miniconda3\Scripts\conda.exe"
#!! Contents within this block are managed by 'conda init' !!
If (Test-Path $condaPath) {
    (& $condaPath "shell.powershell" "hook") | Out-String | ? { $_ } | Invoke-Expression
}
