# ssh の接続先で、Remote Control つきの Claude Code を名前付きで起動する (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-session-ssh.ps1 -Target <接続先> -Name <セッション名> [-Dir <接続先のフォルダ>]
#        [-RemoteShell auto|posix|pwsh] [-NoTmux] [-Split] [-Background] [-Model <モデル>] [-Effort <effort>]
#   -Model / -Effort: 接続先の claude --model / --effort に渡す (省略すると接続先の Claude Code の既定)
#
# タブ・ウィンドウの開き方は ssh-generate の launch-ssh.ps1 に任せる (起動先の判断・-Split・-Background も同じ)。
# フォルダの既定は ~/claudeWS (ホームは信頼の確認が保存されないため)。なければ作る (-Dir で指定したときも)。
# 接続先に tmux (Windows では psmux) があれば、セッション名と同じ名前の tmux セッションの中で起動する。
# ssh が切れても claude が動き続け、同じ名前でもう一度実行すると、そのセッションにつなぎ直す
# (PowerShell は tmux new-session -A、sh 系は has-session でなければ作ってから attach)。
#
# 接続先のシェル (-RemoteShell。auto のときは ssh で $PSVersionTable.PSEdition を出させて判断する):
#   posix: sh 系 (bash / zsh など)。ログインシェルを対話モードで起動してから claude を実行する
#          (macOS の zsh などで、claude が .zshrc の中でだけ使えるようになっていることがあるため)。
#   pwsh:  Windows の OpenSSH で、既定のシェルが PowerShell のもの。PowerShell のプロファイルを読んだ状態で実行する。

param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Name,
    [string]$Dir = '~/claudeWS',
    [ValidateSet('auto', 'posix', 'pwsh')][string]$RemoteShell = 'auto',
    [switch]$NoTmux,
    [switch]$Split,
    [switch]$Background,
    # モデル (claude --model)。fable / opus / sonnet / haiku の短い名前なら、いつも最新版になる
    [string]$Model = '',
    # effort (claude --effort)
    [ValidateSet('', 'low', 'medium', 'high', 'xhigh', 'max')][string]$Effort = ''
)

$ErrorActionPreference = 'Stop'

# 名前とフォルダは接続先のコマンドにそのまま埋め込むので、引用符や空白を含めない
if ($Name -notmatch '^[A-Za-z0-9_-]+$') {
    Write-Error "セッション名には英数字と _ - だけを使ってください: $Name"
}
if ($Dir -notmatch '^~?[A-Za-z0-9._/-]*$') {
    Write-Error "フォルダには英数字と . _ / - (先頭の ~) だけを使ってください: $Dir"
}
if ($Model -and $Model -notmatch '^[A-Za-z0-9._-]+$') {
    Write-Error "-Model には英数字と . _ - だけを使ってください (例: opus, claude-opus-5-5): $Model"
}

if ($RemoteShell -eq 'auto') {
    # PowerShell なら Core / Desktop と出る。sh 系では $PSVersionTable が空なので .PSEdition と出る。
    # パスワードを聞かれる接続先などで判断できないときは sh 系とみなす
    $probe = & ssh -o BatchMode=yes -o ConnectTimeout=8 $Target 'echo $PSVersionTable.PSEdition' 2>$null | Select-Object -Last 1
    $RemoteShell = if ("$probe".Trim() -in 'Core', 'Desktop') { 'pwsh' } else { 'posix' }
    Write-Output "remote shell: $RemoteShell"
}

$Claude = "claude --name $Name --remote-control"
if ($Model) { $Claude += " --model $Model" }
if ($Effort) { $Claude += " --effort $Effort" }
if ($RemoteShell -eq 'pwsh') {
    if ($NoTmux) {
        $Remote = "New-Item -ItemType Directory -Force $Dir | Out-Null; Set-Location $Dir; $Claude"
    }
    else {
        $Remote = "New-Item -ItemType Directory -Force $Dir | Out-Null; Set-Location $Dir; if (Get-Command tmux -ErrorAction SilentlyContinue) { tmux new-session -A -s $Name '$Claude' } else { $Claude }"
    }
}
else {
    if ($NoTmux) {
        $Body = "mkdir -p $Dir && cd $Dir || exit 1; $Claude"
    }
    else {
        # ペインは普通の対話シェルで起動し、claude はキー入力で打ち込む。
        # ペインのコマンドを "$SHELL -lic claude" にすると、Ctrl+Z で claude を suspend したときに
        # 戻る先のプロンプトがなくシェルが終わり、tmux のセッションと ssh まで閉じるため。
        # 後ろの exit で、claude が終わったらペインを閉じる (suspend すると zsh は行の残りを捨てるので、fg で戻したあとはシェルが残る)。
        # "=名前" は前方一致ではなく名前の完全一致 (zsh では = で始まる語がコマンドのパスに展開されるので引用符で囲む)。tmux はエイリアスのことがあるので command tmux で呼ぶ (exec の後ろは展開されない)
        $Body = "mkdir -p $Dir && cd $Dir || exit 1; if command -v tmux >/dev/null 2>&1; then " +
            "command tmux has-session -t `"=$Name`" 2>/dev/null || { command tmux new-session -d -s $Name && command tmux send-keys -t `"=${Name}:`" `"$Claude; exit`" Enter; }; " +
            "exec tmux attach -t `"=$Name`"; else $Claude; fi"
    }
    $Remote = 'exec "$SHELL" -lic ''' + $Body + ''''
}

$Launcher = Join-Path $PSScriptRoot '..\..\ssh-generate\scripts\launch-ssh.ps1'
$opts = @{ RemoteCommand = $Remote; Title = $Name }
if ($Split) { $opts.Split = $true }
if ($Background) { $opts.Background = $true }
& $Launcher @opts $Target
exit $LASTEXITCODE
