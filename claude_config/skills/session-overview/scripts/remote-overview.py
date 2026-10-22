"""ssh で開いたウィンドウの接続先で session-overview.py を動かし、別のマシンのセッションの要約の材料を集める。

使い方:
    uv run --no-project python remote-overview.py <セッション名> [<セッション名> ...] [--prompts N] [--chars N]

このマシンの tmux (psmux) のペインのうち、ペインのオプション @ssh_host が付いているもの
(ssh-generate / session-ssh スキルで開いたもの) から接続先を集め、接続先ごとに
ssh <接続先> 'exec "$SHELL" -lic "uv run ... session-overview.py <名前> ..."' を実行する。
接続先のマシンにも session-overview スキル (~/.claude/skills/session-overview) と uv が必要。
接続先で見つかったセッションだけを、どの接続先・どのウィンドウ (ssh を開いているこのマシンのウィンドウ) かを付けて出す。
見つからなかった名前は、最後にまとめて出す。

接続先のシェルは、sh 系 (bash / zsh など) と、既定のシェルが PowerShell の Windows (OpenSSH) に対応する。
どちらかは、接続先ごとに ssh で $PSVersionTable.PSEdition を出させて判断する。
"""

import argparse
import importlib.util
import os
import re
import shutil
import subprocess
import sys

SCRIPT = "~/.claude/skills/session-overview/scripts/session-overview.py"
NOT_FOUND = "に見つからない"
ID_RE = re.compile(r"(?m)^番号: \S+ / ID: (\S+)$")


def load_overview():
    """同じフォルダの session-overview.py を読み込む (番号の表 session_numbers を使うため)。"""
    sys.dont_write_bytecode = True
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "session-overview.py")
    spec = importlib.util.spec_from_file_location("session_overview", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def ssh_hosts():
    """@ssh_host が付いたペインから {接続先: [このマシンのウィンドウ, ...]} を作る。"""
    if not shutil.which("tmux"):
        return {}
    try:
        out = subprocess.run(
            ["tmux", "list-panes", "-a", "-F", "#{session_name}:#{window_index} #{window_name}\t#{@ssh_host}"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=10,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return {}
    hosts = {}
    for line in out.splitlines():
        window, _, host = line.partition("\t")
        host = host.strip()
        if host:
            hosts.setdefault(host, [])
            if window not in hosts[host]:
                hosts[host].append(window)
    return hosts


def remote_shell(host):
    """接続先の既定のシェルが PowerShell なら "pwsh"、それ以外は "posix" を返す。

    PowerShell なら $PSVersionTable.PSEdition が Core / Desktop と出る。sh 系では空なので .PSEdition と出る
    (session-ssh スキルの launch-session-ssh.ps1 と同じ判断)。
    """
    try:
        out = subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8", host, "echo $PSVersionTable.PSEdition"],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return "posix"
    last = (out.strip().splitlines() or [""])[-1].strip()
    return "pwsh" if last in ("Core", "Desktop") else "posix"


def run_remote(host, names, prompts, chars, no_number=True):
    """接続先で session-overview.py を動かして、出力をセッションごとの塊に分ける。失敗したら (None, 理由)。
    接続先の session-overview.py が古くて --no-number を知らないときは、付けずに実行し直す。"""
    quoted = " ".join("'" + n + "'" for n in names)
    args = f"{quoted} --prompts {prompts} --chars {chars}" + (" --no-number" if no_number else "")
    if remote_shell(host) == "pwsh":
        # PowerShell は ~ をネイティブのコマンドの引数で展開しないことがあるので $HOME を使う。
        # 出力は UTF-8 にそろえる (このスクリプトは UTF-8 として読む)
        remote = ("$env:PYTHONIOENCODING = 'utf-8'; uv run --no-project python "
                  f"$HOME/{SCRIPT[2:]} {args}")
    else:
        remote = 'exec "$SHELL" -lic "uv run --no-project python ' + f'{SCRIPT} {args}"'
    try:
        res = subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8", host, remote],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, str(e)
    blocks = [b for b in re.split(r"(?m)^(?=## )", res.stdout) if b.startswith("## ")]
    if not blocks and no_number and "--no-number" in res.stderr:
        return run_remote(host, names, prompts, chars, no_number=False)
    if not blocks:
        reason = (res.stderr.strip().splitlines() or [f"終了コード {res.returncode}"])[-1]
        reason = re.sub(r"\x1b\[[0-9;]*m", "", reason)
        # Windows の接続先は、エラーが別の文字コードで返って化けるので、理由を言い換える
        if "�" in reason:
            reason = f"終了コード {res.returncode}。接続先のシェルが sh 系でない (Windows など) かもしれない"
        return None, reason
    return blocks, None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="+", help="調べるセッションの名前 (ListAgents で Remote Control と出るもの)")
    parser.add_argument("--prompts", type=int, default=2)
    parser.add_argument("--chars", type=int, default=300)
    args = parser.parse_args()

    # 名前は接続先のコマンドに ' で囲んで埋め込むので、引用符と $ ` \ を含む名前は使わない
    names = [n for n in args.names if not re.search(r"['\"$`\\]", n)]
    skipped = [n for n in args.names if n not in names]

    overview = load_overview()
    hosts = ssh_hosts()
    if not hosts:
        print("ssh で開いたウィンドウ (@ssh_host の付いたペイン) が見つからない。")
        return
    found = set()
    for host, windows in hosts.items():
        blocks, err = run_remote(host, names, args.prompts, args.chars)
        if blocks is None:
            print(f"# {host} (このマシンのウィンドウ {', '.join(windows)}): 読めなかった ({err})\n")
            continue
        for b in blocks:
            name = b.splitlines()[0][3:].split(" (")[0].strip()
            if NOT_FOUND in b or name in found:
                continue
            found.add(name)
            # 番号はこのマシンの番号の表で振る (鍵は「接続先|sessionId」)。接続先の session-overview.py が古いと ID がない
            m = ID_RE.search(b)
            if m:
                no = overview.session_numbers([f"{host}|{m.group(1)}"])[f"{host}|{m.group(1)}"]
                b = ID_RE.sub(f"番号: {no} / ID: {m.group(1)}", b, count=1)
            print(f"# 接続先: {host} (ssh を開いているこのマシンのウィンドウ: {', '.join(windows)})")
            print(b.rstrip() + "\n")
    rest = [n for n in names if n not in found] + skipped
    if rest:
        print("どの接続先でも見つからなかった: " + ", ".join(rest))


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    main()
