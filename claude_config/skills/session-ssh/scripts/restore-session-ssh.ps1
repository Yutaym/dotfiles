# session-ssh で開いた ssh のウィンドウを、接続の記録 (~/.claude/state/session-ssh/*.json) から開き直す (Windows ネイティブ用)
# MSI の再起動などで psmux のウィンドウごと消えたときに使う。記録は ssh-generate の start-ssh.ps1 が書き、
# ssh が終了コード 0 で終わったときに消す。
#
# 使い方:
#   pwsh -NoProfile -File restore-session-ssh.ps1 -List            # 記録と状態を一覧にする (何も開かない)
#   pwsh -NoProfile -File restore-session-ssh.ps1 -Name a,b        # 指定したものを開き直す
#   pwsh -NoProfile -File restore-session-ssh.ps1 -All             # 開き直せるものをすべて開き直す
#
# 状態:
#   open      このマシンに同じ名前のウィンドウがある (開き直さない)
#   alive     接続先に同じ名前の tmux セッションが残っている (開き直すと attach する)
#   gone      接続先に tmux セッションがない (Claude は終わっている。開き直さず、記録を消す)
#   unknown   接続先に ssh できなかった (スリープ中など。開き直さない)

param(
    [switch]$List,
    [switch]$All,
    [string[]]$Name = @()
)

$ErrorActionPreference = 'Stop'
# pwsh -File では -Name a,b が 1 つの文字列 "a,b" で届くので分ける
$Name = @($Name | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$StateDir = Join-Path $HOME '.claude/state/session-ssh'
$records = @(if (Test-Path $StateDir) { Get-ChildItem $StateDir -Filter *.json | ForEach-Object { Get-Content -Raw $_.FullName | ConvertFrom-Json } })
if (-not $records) { Write-Output '接続の記録はありません。'; exit 0 }
if (-not $List -and -not $All -and -not $Name) { $List = $true }

# このマシンの psmux / tmux にあるウィンドウの名前
$windows = @()
if ($env:TMUX -and (Get-Command tmux -ErrorAction SilentlyContinue)) {
    $windows = @(tmux list-windows -a -F '#{window_name}' 2>$null)
}

function Test-RemoteSession($r) {
    $cmd = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($r.RemoteCommandB64))
    # session-ssh の sh 系の接続先は exec "$SHELL" -lic ... で始まる。それ以外は PowerShell (psmux)
    if ($cmd.StartsWith('exec "$SHELL"')) {
        $probe = 'exec "$SHELL" -lic ''command tmux has-session -t "=' + $r.Name + '"'''
    }
    else {
        $probe = "tmux has-session -t $($r.Name); exit `$LASTEXITCODE"
    }
    & ssh -o BatchMode=yes -o ConnectTimeout=8 $r.Target $probe *> $null
    switch ($LASTEXITCODE) { 0 { 'alive' } 255 { 'unknown' } default { 'gone' } }
}

$rows = foreach ($r in $records) {
    $state = if ($windows -contains $r.Name) { 'open' } else { Test-RemoteSession $r }
    [pscustomobject]@{ Name = $r.Name; Target = $r.Target; State = $state; Saved = $r.Saved; Record = $r }
}

$rows | Format-Table Name, Target, State, Saved -AutoSize | Out-String -Width 200 | Write-Output
if ($List) { exit 0 }

$Launcher = Join-Path $PSScriptRoot '..\..\ssh-generate\scripts\launch-ssh.ps1'
$selected = if ($All) { $rows } else { $rows | Where-Object { $Name -contains $_.Name } }
foreach ($n in $Name) { if (-not ($rows.Name -contains $n)) { Write-Output "記録がありません: $n" } }
foreach ($row in $selected) {
    switch ($row.State) {
        'alive' {
            $cmd = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($row.Record.RemoteCommandB64))
            & $Launcher -RemoteCommand $cmd -Title $row.Name -Background $row.Target
            Write-Output "開き直しました: $($row.Name) ($($row.Target))"
        }
        'gone' {
            Remove-Item -ErrorAction SilentlyContinue (Join-Path $StateDir "$($row.Name).json")
            Write-Output "接続先にセッションがないので、記録を消しました: $($row.Name)"
        }
        'open' { Write-Output "すでにウィンドウがあります: $($row.Name)" }
        default { Write-Output "接続先に ssh できませんでした (開き直していません): $($row.Name) ($($row.Target))" }
    }
}
