# 新しいタブの中で、pwsh -NoExit -File で実行される。Claude のセッション固有の環境変数を消して、作業フォルダに移る。
# -NoExit なので、このスクリプトが終わったあとも、そのまま対話のシェルとして残る (プロファイルも読み込まれる)。
param(
    [Parameter(Mandatory)][string]$Dir
)

# 引き継ぐと、このシェルで起動した claude が子セッション扱いになり、会話の記録が保存されない
$vars = @(
    'CLAUDECODE', 'CLAUDE_PID', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_ENTRYPOINT',
    'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_SESSION_ATTENDED',
    'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_CODE_BRIDGE_SESSION_ID'
)
foreach ($v in $vars) { Remove-Item "env:$v" -ErrorAction SilentlyContinue }

Set-Location -LiteralPath $Dir
