# 新しいタブの中で実行される。Claude のセッション固有の環境変数を消してから claude を起動する。
param(
    [Parameter(Mandatory)][string]$Dir,
    [string]$Name = ''
)

# 親セッションから引き継ぐと困る変数 (子セッション扱い・親のセッション ID や受信口の取り違えの原因になる)
$vars = @(
    'CLAUDECODE', 'CLAUDE_PID', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_ENTRYPOINT',
    'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_SESSION_ATTENDED',
    'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_CODE_BRIDGE_SESSION_ID'
)
foreach ($v in $vars) { Remove-Item "env:$v" -ErrorAction SilentlyContinue }

Set-Location -LiteralPath $Dir
if ($Name) { claude -n $Name } else { claude }
