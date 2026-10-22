# ssh の接続先で、Remote Control つきの Claude Code を名前付きで起動する (Windows ネイティブ用)
#
# 使い方:
#   pwsh -NoProfile -File launch-session-ssh.ps1 -Target <接続先> -Name <セッション名> [-Dir <接続先のフォルダ>]
#        [-RemoteShell auto|posix|pwsh] [-NoTmux] [-Split] [-Background]
#
# タブ・ウィンドウの開き方は ssh-generate の launch-ssh.ps1 に任せる (起動先の判断・-Split・-Background も同じ)。
# 接続先に tmux (Windows では psmux) があれば、セッション名と同じ名前の tmux セッションの中で起動する。
# ssh が切れても claude が動き続け、同じ名前でもう一度実行すると、そのセッションにつなぎ直す (tmux new-session -A)。
#
# 接続先のシェル (-RemoteShell。auto のときは ssh で $PSVersionTable.PSEdition を出させて判断する):
#   posix: sh 系 (bash / zsh など)。ログインシェルを対話モードで起動してから claude を実行する
#          (macOS の zsh などで、claude が .zshrc の中でだけ使えるようになっていることがあるため)。
#   pwsh:  Windows の OpenSSH で、既定のシェルが PowerShell のもの。PowerShell のプロファイルを読んだ状態で実行する。

param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Name,
    [string]$Dir = '~',
    [ValidateSet('auto', 'posix', 'pwsh')][string]$RemoteShell = 'auto',
    [switch]$NoTmux,
    [switch]$Split,
    [switch]$Background
)

$ErrorActionPreference = 'Stop'

# 名前とフォルダは接続先のコマンドにそのまま埋め込むので、引用符や空白を含めない
if ($Name -notmatch '^[A-Za-z0-9_-]+$') {
    Write-Error "セッション名には英数字と _ - だけを使ってください: $Name"
}
if ($Dir -notmatch '^~?[A-Za-z0-9._/-]*$') {
    Write-Error "フォルダには英数字と . _ / - (先頭の ~) だけを使ってください: $Dir"
}

if ($RemoteShell -eq 'auto') {
    # PowerShell なら Core / Desktop と出る。sh 系では $PSVersionTable が空なので .PSEdition と出る。
    # パスワードを聞かれる接続先などで判断できないときは sh 系とみなす
    $probe = & ssh -o BatchMode=yes -o ConnectTimeout=8 $Target 'echo $PSVersionTable.PSEdition' 2>$null | Select-Object -Last 1
    $RemoteShell = if ("$probe".Trim() -in 'Core', 'Desktop') { 'pwsh' } else { 'posix' }
    Write-Output "remote shell: $RemoteShell"
}

$Claude = "claude --name $Name --remote-control"
if ($RemoteShell -eq 'pwsh') {
    if ($NoTmux) {
        $Remote = "Set-Location $Dir; $Claude"
    }
    else {
        $Remote = "Set-Location $Dir; if (Get-Command tmux -ErrorAction SilentlyContinue) { tmux new-session -A -s $Name '$Claude' } else { $Claude }"
    }
}
else {
    if ($NoTmux) {
        $Body = "cd $Dir || exit 1; $Claude"
    }
    else {
        # tmux が動かすコマンドは sh -c で実行されるので、もう一度ログインシェルを対話モードで起動してから claude を実行する
        $Body = "cd $Dir || exit 1; if command -v tmux >/dev/null 2>&1; then exec tmux new-session -A -s $Name " +
            '"$SHELL -lic \"' + $Claude + '\""' + "; else $Claude; fi"
    }
    $Remote = 'exec "$SHELL" -lic ''' + $Body + ''''
}

$Launcher = Join-Path $PSScriptRoot '..\..\ssh-generate\scripts\launch-ssh.ps1'
$opts = @{ RemoteCommand = $Remote; Title = $Name }
if ($Split) { $opts.Split = $true }
if ($Background) { $opts.Background = $true }
& $Launcher @opts $Target
exit $LASTEXITCODE
