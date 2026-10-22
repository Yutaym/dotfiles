"""ssh の接続先の ~/dotfiles を pull し、Claude の設定のリンクを張り直す。

使い方:
    uv run --no-project python sync-remotes.py [接続先 ...] [--no-install]

接続先を省略すると、DEFAULT_HOSTS を順に更新する。接続先ごとに次を行い、結果を 1 行で出す。
1. ssh で $PSVersionTable.PSEdition を出させて、接続先のシェルが PowerShell (Windows) か sh 系かを見分ける
   (session-ssh / session-overview の remote-overview.py と同じ見分け方)。
2. ~/dotfiles に未コミットの変更があれば、何もせずに dirty として止める (接続先の作業を壊さないため)。
3. git pull --ff-only。早送りできなければ (接続先にだけコミットがあるなど) failed として止める。
4. Claude の設定のリンクを張り直す (claude_config/install_claude.sh / .ps1。何度実行してもよい)。
   新しく作ったリンク ([link] の行) があれば、その名前を出す。

出力 (接続先ごとに 1 行):
    updated: <接続先> <前のコミット> -> <今のコミット> [linked: <名前>, ...]
    up-to-date: <接続先> <コミット> [linked: ...]
    dirty: <接続先> <未コミットのファイル>
    failed: <接続先> <理由>
終了コード: dirty / failed があれば 1、それ以外は 0。

ssh は BatchMode=yes で実行するので、パスワードを聞かれる接続先は failed になる。
接続先のシェルが PowerShell のときは、プロファイルの警告 (「ハンドルが無効です」など) が標準エラーに出るが、無視する。
"""

import argparse
import re
import subprocess
import sys

# 普段 dotfiles を同期する接続先 (~/.ssh/config の Host)。増えたらここに足す
DEFAULT_HOSTS = ["Home_Mac_1", "Home_Desktop_PC_1_win"]

MARK = "@@SYNC@@"


def ssh(host, command, timeout=180):
    try:
        r = subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", host, command],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, str(e)
    return r, None


def remote_shell(host):
    r, err = ssh(host, "echo $PSVersionTable.PSEdition", timeout=30)
    if r is None:
        return None, err
    last = (r.stdout.strip().splitlines() or [""])[-1].strip()
    if r.returncode != 0 and not last:
        reason = (r.stderr.strip().splitlines() or [f"終了コード {r.returncode}"])[-1]
        return None, reason
    return ("pwsh" if last in ("Core", "Desktop") else "posix"), None


def script_for(shell, install):
    """接続先で実行するコマンド。結果は MARK で始まる行で返す。"""
    if shell == "pwsh":
        lines = [
            "Set-Location ~/dotfiles",
            f"$d = git status --porcelain; if ($d) {{ '{MARK}dirty ' + (($d | ForEach-Object {{ $_.Trim() }}) -join ', '); exit 0 }}",
            f"$old = git rev-parse --short HEAD; git pull --ff-only -q 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) {{ '{MARK}failed git pull --ff-only'; exit 0 }}",
            "$new = git rev-parse --short HEAD",
        ]
        if install:
            lines.append(
                "$links = pwsh -NoProfile -File claude_config/install_claude.ps1 2>&1 | Where-Object { \"$_\" -like '[[]link]*' } | "
                "ForEach-Object { ($_ -split ' -> ')[0] -replace '^\\[link\\] ', '' | Split-Path -Leaf }"
            )
        else:
            lines.append("$links = @()")
        lines.append(f"'{MARK}ok ' + $old + ' ' + $new + ' ' + (@($links) -join ',')")
        return "; ".join(lines)
    install_cmd = (
        'links=$(sh claude_config/install_claude.sh 2>&1 | sed -n "s/^\\[link\\] \\([^ ]*\\) -> .*/\\1/p" | xargs -n1 basename 2>/dev/null | paste -sd, -)'
        if install else "links="
    )
    return (
        "cd ~/dotfiles || exit 1; "
        f'd=$(git status --porcelain); if [ -n "$d" ]; then echo "{MARK}dirty $(echo "$d" | sed "s/^ *//" | paste -sd, -)"; exit 0; fi; '
        f'old=$(git rev-parse --short HEAD); git pull --ff-only -q >/dev/null 2>&1 || {{ echo "{MARK}failed git pull --ff-only"; exit 0; }}; '
        "new=$(git rev-parse --short HEAD); "
        f"{install_cmd}; "
        f'echo "{MARK}ok $old $new $links"'
    )


def sync(host, install):
    shell, err = remote_shell(host)
    if shell is None:
        return "failed", f"failed: {host} 接続できない ({err})"
    r, err = ssh(host, script_for(shell, install))
    if r is None:
        return "failed", f"failed: {host} {err}"
    found = [l[len(MARK):] for l in r.stdout.splitlines() if l.startswith(MARK)]
    if not found:
        reason = re.sub(r"\x1b\[[0-9;]*m", "", (r.stderr.strip().splitlines() or [f"終了コード {r.returncode}"])[-1])
        return "failed", f"failed: {host} {reason}"
    kind, _, rest = found[-1].partition(" ")
    if kind == "dirty":
        return "dirty", f"dirty: {host} {rest}"
    if kind == "failed":
        return "failed", f"failed: {host} {rest}"
    parts = rest.split(" ", 2)
    old, new = parts[0], parts[1]
    links = parts[2].strip() if len(parts) > 2 else ""
    tail = f" linked: {links.replace(',', ', ')}" if links else ""
    if old == new:
        return "ok", f"up-to-date: {host} {new}{tail}"
    return "ok", f"updated: {host} {old} -> {new}{tail}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("hosts", nargs="*", help=f"接続先 (省略時は {', '.join(DEFAULT_HOSTS)})")
    ap.add_argument("--no-install", action="store_true", help="リンクの張り直しをしない")
    args = ap.parse_args()
    ok = True
    for host in args.hosts or DEFAULT_HOSTS:
        kind, line = sync(host, not args.no_install)
        print(line, flush=True)
        ok = ok and kind == "ok"
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    main()
