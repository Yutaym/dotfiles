# 新しいタブの中で実行される。Claude のセッション固有の環境変数を消してから claude を起動する。
param(
    [Parameter(Mandatory)][string]$Dir,
    [string]$Name = '',
    # 新しく始めずに、この ID の会話を開く (claude --resume <ID>)
    [string]$Resume = '',
    # モデル (claude --model) と effort (claude --effort)。空なら Claude Code の既定
    [string]$Model = '',
    [string]$Effort = '',
    # git の worktree の名前 (claude --worktree)
    [string]$Worktree = '',
    # session-initialize の台帳のパス・作業の ID・親の受信口のアドレス (CC_LEDGER / CC_TASK_ID / CC_PARENT_ADDR にする)
    [string]$Ledger = '',
    [string]$TaskId = '',
    [string]$ParentAddr = ''
)

# 親セッションから引き継ぐと困る変数 (子セッション扱い・親のセッション ID や受信口の取り違えの原因になる)
$vars = @(
    'CLAUDECODE', 'CLAUDE_PID', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_ENTRYPOINT',
    'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_SESSION_ATTENDED',
    'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_CODE_BRIDGE_SESSION_ID'
)
foreach ($v in $vars) { Remove-Item "env:$v" -ErrorAction SilentlyContinue }
# 台帳の変数は、指定があるときだけ設定する (指定がなければ、呼び出し元から引き継いだものも消す)
foreach ($p in @(@('CC_LEDGER', $Ledger), @('CC_TASK_ID', $TaskId), @('CC_PARENT_ADDR', $ParentAddr))) {
    if ($p[1]) { Set-Item "env:$($p[0])" $p[1] } else { Remove-Item "env:$($p[0])" -ErrorAction SilentlyContinue }
}

Set-Location -LiteralPath $Dir
$claudeArgs = @()
if ($Name) { $claudeArgs += @('-n', $Name) }
if ($Resume) { $claudeArgs += @('--resume', $Resume) }
if ($Model) { $claudeArgs += @('--model', $Model) }
if ($Effort) { $claudeArgs += @('--effort', $Effort) }
if ($Worktree) { $claudeArgs += @('--worktree', $Worktree) }
claude @claudeArgs
