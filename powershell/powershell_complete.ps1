
# set-alias sudo Run-AsAdmin()

Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function DeleteChar
Set-PSReadLineKeyHandler -Key "Ctrl+w" -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key "Ctrl+u" -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+k" -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key "Ctrl+a" -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+e" -Function EndOfLine
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardChar
Set-PSReadLineKeyHandler -Key "Ctrl+b" -Function BackwardChar
Set-PSReadLineKeyHandler -Key "Alt+f" -Function NextWord
Set-PSReadLineKeyHandler -Key "Alt+b" -Function BackwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function PreviousHistory
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function NextHistory
Set-PSReadLineKeyHandler -Key Ctrl+g -ScriptBlock {
    $line = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().InputLine
    Invoke-CopilotSuggest $line
}

## input History Plugin
$psReadLineModule = Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

if ($psReadLineModule -and $psReadLineModule.Version -ge [version]'2.1.0') {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -Colors @{
        InLinePrediction = [ConsoleColor]::DarkGray
        ListPrediction   = [ConsoleColor]::Cyan
    }
}


Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command (gh completion -s powershell | Out-String)
}
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command (docker completion powershell | Out-String)
}
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command (kubectl completion powershell | Out-String)
}
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command (pnpm completion pwsh | Out-String)
}
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Invoke-Expression -Command (uv generate-shell-completion powershell | Out-String)
}

## git補完 (posh-git) 未インストールの環境では自動インストールしてからインポートする
## プロンプトは自前のprompt関数を使い続けるため、posh-git側のプロンプト統合(Add-PoshGitToProfile)は行わない
## https://github.com/dahlbyk/posh-git
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (-not (Get-Module posh-git -ListAvailable)) {
        Install-Module posh-git -Scope CurrentUser -Force
    }
    Import-Module posh-git
}

## ssh/scp Host補完 (~/.ssh/config の Host エントリを候補にする)
## https://qiita.com/SAITO_Keita/items/3f9fa4cfb873d6795779
## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter
## オプション一覧は `ssh`/`scp` (OpenSSH) の usage 文字列に基づく
$sshOptionList = @(
    @{ Flag = "-4"; Desc = "IPv4のみ使用" }
    @{ Flag = "-6"; Desc = "IPv6のみ使用" }
    @{ Flag = "-A"; Desc = "認証エージェント転送を有効化" }
    @{ Flag = "-a"; Desc = "認証エージェント転送を無効化" }
    @{ Flag = "-B"; Desc = "bind_interface: 送信元インターフェースを指定" }
    @{ Flag = "-b"; Desc = "bind_address: 送信元アドレスを指定" }
    @{ Flag = "-C"; Desc = "圧縮を有効化" }
    @{ Flag = "-c"; Desc = "cipher_spec: 暗号方式を指定" }
    @{ Flag = "-D"; Desc = "[bind_address:]port: 動的ポートフォワード(SOCKS)" }
    @{ Flag = "-E"; Desc = "log_file: デバッグログの追記先ファイル" }
    @{ Flag = "-e"; Desc = "escape_char: エスケープ文字を指定" }
    @{ Flag = "-F"; Desc = "configfile: 設定ファイルを指定" }
    @{ Flag = "-f"; Desc = "接続確立後にバックグラウンドへ移行" }
    @{ Flag = "-G"; Desc = "設定を評価して表示するだけで接続しない" }
    @{ Flag = "-g"; Desc = "リモートホストからのローカルポート接続を許可" }
    @{ Flag = "-I"; Desc = "pkcs11: PKCS#11共有ライブラリを指定" }
    @{ Flag = "-i"; Desc = "identity_file: 秘密鍵ファイルを指定" }
    @{ Flag = "-J"; Desc = "[user@]host[:port]: ジャンプホスト(踏み台)を経由" }
    @{ Flag = "-K"; Desc = "GSSAPI資格情報の転送を有効化" }
    @{ Flag = "-k"; Desc = "GSSAPI資格情報の転送を無効化" }
    @{ Flag = "-L"; Desc = "address: ローカルポートフォワード" }
    @{ Flag = "-l"; Desc = "login_name: ログインユーザー名を指定" }
    @{ Flag = "-M"; Desc = "接続共有のマスターモード" }
    @{ Flag = "-m"; Desc = "mac_spec: MACアルゴリズムを指定" }
    @{ Flag = "-N"; Desc = "リモートコマンドを実行しない" }
    @{ Flag = "-n"; Desc = "標準入力を/dev/nullにリダイレクト" }
    @{ Flag = "-O"; Desc = "ctl_cmd: 接続共有の制御コマンド" }
    @{ Flag = "-o"; Desc = "option: ssh_config形式でオプション指定" }
    @{ Flag = "-p"; Desc = "port: 接続先ポート番号" }
    @{ Flag = "-Q"; Desc = "query_option: 対応アルゴリズム等を問い合わせ" }
    @{ Flag = "-q"; Desc = "警告・診断メッセージを抑制" }
    @{ Flag = "-R"; Desc = "address: リモートポートフォワード" }
    @{ Flag = "-S"; Desc = "ctl_path: 接続共有用ソケットのパス" }
    @{ Flag = "-s"; Desc = "サブシステムを要求" }
    @{ Flag = "-T"; Desc = "疑似端末の割り当てを無効化" }
    @{ Flag = "-t"; Desc = "疑似端末の割り当てを強制" }
    @{ Flag = "-V"; Desc = "バージョンを表示" }
    @{ Flag = "-v"; Desc = "デバッグ出力(verbose、重ねがけ可)" }
    @{ Flag = "-W"; Desc = "host:port: 標準入出力をホストポートへ転送" }
    @{ Flag = "-w"; Desc = "local_tun[:remote_tun]: tunデバイス転送" }
    @{ Flag = "-X"; Desc = "X11フォワードを有効化" }
    @{ Flag = "-x"; Desc = "X11フォワードを無効化" }
    @{ Flag = "-Y"; Desc = "信頼済みX11フォワードを有効化" }
    @{ Flag = "-y"; Desc = "syslog経由でログ送信" }
)
$scpOptionList = @(
    @{ Flag = "-3"; Desc = "2つのリモートホスト間をローカル経由で転送" }
    @{ Flag = "-4"; Desc = "IPv4のみ使用" }
    @{ Flag = "-6"; Desc = "IPv6のみ使用" }
    @{ Flag = "-A"; Desc = "認証エージェント転送を許可" }
    @{ Flag = "-B"; Desc = "バッチモード(パスワード入力なし)" }
    @{ Flag = "-C"; Desc = "圧縮を有効化" }
    @{ Flag = "-c"; Desc = "cipher: 暗号方式を指定" }
    @{ Flag = "-D"; Desc = "sftp_server_path: ローカルSFTPサーバーへ直接接続" }
    @{ Flag = "-F"; Desc = "ssh_config: 設定ファイルを指定" }
    @{ Flag = "-i"; Desc = "identity_file: 秘密鍵ファイルを指定" }
    @{ Flag = "-J"; Desc = "destination: ジャンプホスト(踏み台)を経由" }
    @{ Flag = "-l"; Desc = "limit: 帯域制限(Kbit/s)" }
    @{ Flag = "-O"; Desc = "レガシーSCPプロトコルを使用" }
    @{ Flag = "-o"; Desc = "ssh_option: ssh_config形式でオプション指定" }
    @{ Flag = "-P"; Desc = "port: 接続先ポート番号" }
    @{ Flag = "-p"; Desc = "更新時刻・パーミッションを保持" }
    @{ Flag = "-q"; Desc = "進捗表示と診断メッセージを無効化" }
    @{ Flag = "-R"; Desc = "リモートホスト間を直接転送" }
    @{ Flag = "-r"; Desc = "ディレクトリを再帰的にコピー" }
    @{ Flag = "-S"; Desc = "program: 暗号化転送に使うプログラム" }
    @{ Flag = "-s"; Desc = "SFTPプロトコルを強制使用" }
    @{ Flag = "-T"; Desc = "ファイル名チェックを無効化" }
    @{ Flag = "-v"; Desc = "詳細出力(verbose)" }
)

$completerSshHost = {
    param($wordToComplete, $commandAst, $cursorPosition)

    # オプション補完 ("-"から始まる場合はHostではなくオプション一覧を候補にする)
    if ($wordToComplete -like "-*") {
        $commandName = $commandAst.CommandElements[0].Extent.Text
        $optionList = if ($commandName -eq "scp") { $scpOptionList } else { $sshOptionList }
        $optionList | Where-Object { $_.Flag -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_.Flag, $_.Flag, 'ParameterName', $_.Desc)
        }
        return
    }

    $sshConfigPath = "$HOME\.ssh\config"
    if (-not (Test-Path $sshConfigPath)) {
        return
    }

    # ~/.ssh/config取得(trimして空行と連続スペースは調整)
    $sshConfig = (Get-Content $sshConfigPath).Trim() -replace "\s+", " " | Where-Object { $_ -ne "" }
    # Hostのグルーピング
    $sshConfigHostGroup = $sshConfig | Select-String -Pattern "^Host\s" -Context 0, $sshConfig.count | Select-Object Line, @{name = 'DisplayPostContext'; Expression = { $_.Context.DisplayPostContext } }

    # 入力補完 格納配列
    $autoCompleteList = New-Object System.Collections.ArrayList

    # toolTip用にHost項目に紐づくHostnameとUserを取得して配列作成
    foreach ($sshConfigHost in $sshConfigHostGroup) {
        # User取得（Hostの位置以降から直近のuser項目取得）
        $user = $sshConfigHost.DisplayPostContext | Select-String -Pattern "^User\s" | Select-Object -First 1 | ForEach-Object { $_ -split "\s" | Select-Object -Skip 1 -First 1 }
        # Hostname取得（Hostの位置以降から直近のHostname項目取得）
        $hostname = $sshConfigHost.DisplayPostContext | Select-String -Pattern "^Hostname\s" | Select-Object -First 1 | ForEach-Object { $_ -split "\s" | Select-Object -Skip 1 -First 1 }
        # Host単位で入力補完生成
        # Host hostA hostB
        $sshConfigHost.line -split "\s+" | Select-Object -Skip 1 | ForEach-Object {
            $autoCompleteList += [pscustomobject]@{Host = $_; toolTips = "$user@$hostname" }
        }
    }

    # [System.Management.Automation.CompletionResult]を生成して返す
    $autoCompleteList | Where-Object { $_.host -like "$wordToComplete*" } | ForEach-Object {
        $resultType = [System.Management.Automation.CompletionResultType]::ParameterValue
        [System.Management.Automation.CompletionResult]::new($_.host, $_.host, $resultType, $_.toolTips)
    }
}

Register-ArgumentCompleter -CommandName ssh, scp -Native -ScriptBlock $completerSshHost

## npm補完 (Windowsではnpm completionが未対応のため自前で最小限を用意)
## npm run/run-script の第2引数はカレントディレクトリのpackage.jsonのscriptsキーを候補にする
## それ以外は主要なサブコマンド一覧を候補にする
## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter
$completerNpm = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $tokens = $commandAst.CommandElements | ForEach-Object { $_.Extent.Text }

    if ($tokens.Count -ge 2 -and $tokens[1] -in @("run", "run-script") -and (Test-Path ".\package.json")) {
        $scripts = (Get-Content ".\package.json" -Raw | ConvertFrom-Json).scripts
        if ($scripts) {
            $scripts.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "npm script: $_")
            }
        }
        return
    }

    $npmSubCommands = @(
        "install", "ci", "run", "run-script", "test", "start", "stop", "restart",
        "publish", "outdated", "update", "uninstall", "init", "link", "list", "ls",
        "audit", "cache", "config", "dedupe", "exec", "fund", "login", "logout",
        "pack", "ping", "prune", "rebuild", "root", "search", "version", "view", "whoami"
    )
    $npmSubCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -CommandName npm -Native -ScriptBlock $completerNpm
}

## nvm(nvm-windows)補完 (公式のシェル補完スクリプトが無いため自前で最小限を用意)
## nvm use/uninstall の第2引数は `nvm list` で取得したインストール済みバージョンを候補にする
## nvm install の第2引数は latest/lts エイリアスを候補にする
## それ以外は主要なサブコマンド一覧を候補にする
## https://github.com/coreybutler/nvm-windows
$completerNvm = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $tokens = $commandAst.CommandElements | ForEach-Object { $_.Extent.Text }

    if ($tokens.Count -ge 2 -and $tokens[1] -in @("use", "uninstall")) {
        nvm list 2>$null | Select-String -Pattern "\d+\.\d+\.\d+" | ForEach-Object { $_.Matches[0].Value } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
        return
    }

    if ($tokens.Count -ge 2 -and $tokens[1] -eq "install") {
        @("latest", "lts") | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
        return
    }

    if ($tokens.Count -ge 2 -and $tokens[1] -in @("list", "ls")) {
        @("available") | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
        return
    }

    $nvmSubCommands = @(
        "arch", "current", "debug", "install", "list", "ls", "on", "off",
        "proxy", "node_mirror", "npm_mirror", "root", "uninstall", "use", "version"
    )
    $nvmSubCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

if (Get-Command nvm -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -CommandName nvm -Native -ScriptBlock $completerNvm
}
