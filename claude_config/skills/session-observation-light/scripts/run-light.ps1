# observe_light.py (session-observation-light) を動かす (Windows ネイティブ用。launch-light.ps1 が、分割したペインや新しいタブの中で実行する)
#
# 使い方:
#   pwsh -NoProfile -File run-observer.ps1 [-Interval 秒] [-RemoteInterval 秒] [-NoRemote]
#
# エラーで終わったときは、ペインやタブがすぐ閉じて原因が見えなくなるので、Enter を押すまで待つ

param(
    [double]$Interval = 10,
    [double]$RemoteInterval = 60,
    [switch]$NoRemote
)

$Observe = Join-Path $PSScriptRoot 'observe_light.py'
$ObserveArgs = @('--interval', $Interval, '--remote-interval', $RemoteInterval)
if ($NoRemote) { $ObserveArgs += '--no-remote' }
$env:PYTHONIOENCODING = 'utf-8'

& uv run --no-project --with rich python $Observe @ObserveArgs
if ($LASTEXITCODE) {
    Read-Host "observe_light.py がエラーで終了した (終了コード $LASTEXITCODE)。Enter で閉じる"
}
