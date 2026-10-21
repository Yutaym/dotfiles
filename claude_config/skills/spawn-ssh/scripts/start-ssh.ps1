# 新しいタブの中で実行される。ssh で接続し、失敗したときはタブを閉じずにエラーを読めるようにする。
param(
    [Parameter(Mandatory)][string]$Target
)

$Host.UI.RawUI.WindowTitle = $Target
ssh $Target
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ssh が終了しました (終了コード $LASTEXITCODE)。Enter で閉じます。"
    [void][Console]::ReadLine()
}
