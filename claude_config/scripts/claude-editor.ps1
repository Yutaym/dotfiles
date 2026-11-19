# Claude Code の Ctrl+G（外部エディタ）用のラッパー（Windows 用）。
# Claude Code が起動したエディタは、同じコンソールで Claude 本体が入力を読み続けるため、
# キーを受け取れない（ConPTY の多重化ソフト psmux の中で起きる。anthropics/claude-code #92757）。
# そこで、エディタを Claude とは別のコンソールで開き、閉じるまで待つ。
#   - psmux / tmux の中: 新しいウィンドウで開き、wait-for で終わりを待って、元のウィンドウに戻る。
#   - それ以外（素の Windows Terminal など）: 同じ画面でそのままエディタを開く。
# 実際に使うエディタは CLAUDE_EDITOR_REAL（既定は nvim）。
$ErrorActionPreference = 'Stop'
$editor = if ($env:CLAUDE_EDITOR_REAL) { $env:CLAUDE_EDITOR_REAL } else { 'nvim' }
function Quote-Ps([string]$s) { "'" + ($s -replace "'", "''") + "'" }
$cwd = (Get-Location).ProviderPath

if ($env:TMUX) {
    $ch = "claude-edit-$PID"
    $codeFile = Join-Path ([IO.Path]::GetTempPath()) "$ch.exitcode"
    Remove-Item -LiteralPath $codeFile -ErrorAction SilentlyContinue
    $wid = $null
    if ($env:TMUX_PANE) { $wid = (& tmux display-message -p -t $env:TMUX_PANE '#{window_id}' 2>$null) }
    $argStr = ($args | ForEach-Object { Quote-Ps $_ }) -join ' '
    # psmux の wait-for は合図を待たずに戻るため、エディタの終了時に書く終了コードのファイルを待つ。
    $inner = "`$c = 1; try { & $(Quote-Ps $editor) $argStr; `$c = `$LASTEXITCODE } finally { Set-Content -LiteralPath $(Quote-Ps $codeFile) `$c }"
    $nw = @('new-window', '-P', '-F', '#{window_id}', '-n', 'claude-edit', '-c', $cwd)
    if ($env:CLAUDE_EDITOR_DETACH) { $nw += '-d' }   # テスト用: 画面を切り替えない
    $newWid = (& tmux @nw $inner | Select-Object -First 1)
    $n = 0
    while (-not (Test-Path -LiteralPath $codeFile)) {
        Start-Sleep -Milliseconds 200
        # ウィンドウが消えたのにファイルがない（強制終了など）ときは抜ける
        if ((++$n % 10) -eq 0 -and $newWid) {
            $ids = & tmux list-windows -a -F '#{window_id}' 2>$null
            if ($ids -notcontains $newWid) { Start-Sleep -Milliseconds 300; break }
        }
    }
    if ($wid -and -not $env:CLAUDE_EDITOR_DETACH) { & tmux select-window -t $wid 2>$null }
    $code = 1
    if (Test-Path -LiteralPath $codeFile) { $code = [int](Get-Content -LiteralPath $codeFile -Raw).Trim(); Remove-Item -LiteralPath $codeFile }
    exit $code
}
else {
    # tmux・psmux の外: Claude と同じ画面でそのままエディタを開く（別ウィンドウに分けない）。
    # 外でも入力を横取りされて固まる場合は、CLAUDE_EDITOR_NEWWIN=1 で新しいコンソールのウィンドウに戻せる。
    if ($env:CLAUDE_EDITOR_NEWWIN) {
        $argStr = ($args | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }) -join ' '
        $p = Start-Process -FilePath $editor -ArgumentList $argStr -WorkingDirectory $cwd -Wait -PassThru
        exit $p.ExitCode
    }
    & $editor @args
    exit $LASTEXITCODE
}
