"""同じマシンの Claude Code のセッションを一覧にし、要約の材料を会話記録から抜き出す。

使い方:
    uv run --no-project python session-overview.py [セッション名 ...] [--prompts N] [--chars N]

セッション名を指定しなければ、~/.claude/sessions/*.json にあるセッションをすべて出す。
各セッションについて、状態・フォルダ・場所 (tmux / terminal / other)・起動時刻・最後に動いた時刻・自動で付いたタイトル・
依頼 (ユーザーが入力したもの / 別のセッションから届いたもの) の最初と最後の N 件・最後の返答を表示する。
要約そのものは、この出力を読んだ Claude が書く。

注意: sessions/*.json と会話の記録の形式は Claude Code の内部形式で、公式には
「バージョンによって変わる」とされている。項目が取れなくなったら、このスクリプトを直す。
"""

import argparse
import datetime
import glob
import json
import os
import re
import shutil
import subprocess
import sys

CONFIG_DIR = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
SELF_ID = os.environ.get("CLAUDE_CODE_SESSION_ID", "")


def local_time(value):
    """ミリ秒のエポック時刻か ISO 形式の文字列を、ローカル時刻の文字列にする。"""
    if not value:
        return "-"
    if isinstance(value, (int, float)):
        dt = datetime.datetime.fromtimestamp(value / 1000, tz=datetime.timezone.utc)
    else:
        dt = datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    return dt.astimezone().strftime("%m/%d %H:%M")


def shorten(text, limit):
    text = " ".join(text.split())
    return text if len(text) <= limit else text[:limit] + " …"


PEER_RE = re.compile(r'<cross-session-message[^>]*from-name="([^"]*)"[^>]*>(.*?)</cross-session-message>', re.S)
COMMAND_NAME_RE = re.compile(r"<command-name>(.*?)</command-name>", re.S)
COMMAND_ARGS_RE = re.compile(r"<command-args>(.*?)</command-args>", re.S)


def user_text(content):
    """依頼の本文を取り出す。VS Code などではテキストのリストで記録され、
    開いているファイルの情報 (<ide_opened_file> など) も混ざるので、< で始まるものは除く。"""
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    texts = [c.get("text", "") for c in content if c.get("type") == "text"]
    return "\n".join(t for t in texts if not t.lstrip().startswith("<")).strip()


def prompt(entry):
    """依頼なら (human / peer, 読みやすくした本文) を返す。ツールの結果や自動で付く文は None。"""
    content = entry.get("message", {}).get("content")
    origin = (entry.get("origin") or {}).get("kind")
    if origin == "peer":
        m = PEER_RE.search(content if isinstance(content, str) else "")
        return ("peer", f"{m.group(1)} から: {m.group(2).strip()}") if m else ("peer", user_text(content))
    if entry.get("isMeta"):
        return None
    # 古い形式の記録には origin がない。そのときもユーザーの入力として扱う
    if origin != "human" and "origin" in entry:
        return None
    raw = content if isinstance(content, str) else ""
    name = COMMAND_NAME_RE.search(raw)
    if name and raw.lstrip().startswith("<command-"):
        args = COMMAND_ARGS_RE.search(raw)
        return ("human", f"{name.group(1).strip()} {args.group(1).strip() if args else ''}".strip())
    text = user_text(content)
    # <local-command-caveat> などの自動で付く文や、テキストのない入力は除く
    if not text or text.lstrip().startswith("<local-command") or (isinstance(content, str) and text.lstrip().startswith("<")
                                                                 and not text.lstrip().startswith("<pasted_content")):
        return None
    return ("human", text)


def load_sessions(names):
    sessions = []
    for path in glob.glob(os.path.join(CONFIG_DIR, "sessions", "*.json")):
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError):
            continue
        if names and data.get("name") not in names:
            continue
        sessions.append(data)
    return sorted(sessions, key=lambda s: s.get("startedAt", 0))


def read_transcript(path):
    """依頼・最後の返答・タイトル・最後の時刻を取り出す。"""
    prompts, last_reply, title, last_time = [], None, None, None
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            kind = entry.get("type")
            if kind == "ai-title":
                title = entry.get("aiTitle") or title
            elif kind == "custom-title":
                title = entry.get("customTitle") or title
            if kind not in ("user", "assistant"):
                continue
            last_time = entry.get("timestamp") or last_time
            content = entry.get("message", {}).get("content")
            if kind == "user":
                p = prompt(entry)
                if p:
                    prompts.append((entry.get("timestamp"),) + p)
            elif isinstance(content, list):
                text = "\n".join(c.get("text", "") for c in content if c.get("type") == "text").strip()
                if text:
                    last_reply = (entry.get("timestamp"), text)
    return prompts, last_reply, title, last_time


SHELLS = {"pwsh", "powershell", "cmd", "bash", "zsh", "sh", "fish", "dash", "nu"}
TERMINALS = {
    "windowsterminal", "openconsole", "wezterm-gui", "wezterm", "kitty", "alacritty", "ghostty",
    "iterm2", "terminal", "gnome-terminal-server", "konsole", "xterm", "tilix", "foot",
}


def base(name):
    """プロセス名を小文字にし、パスと .exe を除く。"""
    name = (name or "").lower().replace("\\", "/").rsplit("/", 1)[-1]
    return name[:-4] if name.endswith(".exe") else name


def process_table():
    """{PID: (名前, 親の PID)} を 1 回のコマンドで取る。取れなければ空。"""
    try:
        if sys.platform == "win32":
            cmd = ["powershell", "-NoProfile", "-NonInteractive", "-Command",
                   "Get-CimInstance Win32_Process | ForEach-Object { \"$($_.ProcessId)`t$($_.ParentProcessId)`t$($_.Name)\" }"]
        else:
            cmd = ["ps", "-A", "-o", "pid=,ppid=,comm="]
        out = subprocess.run(cmd, capture_output=True, text=True, errors="replace").stdout
    except OSError:
        return {}
    table = {}
    for line in out.splitlines():
        parts = line.split("	") if "	" in line else line.split(None, 2)
        if len(parts) == 3 and parts[0].strip().isdigit() and parts[1].strip().isdigit():
            table[int(parts[0])] = (base(parts[2].strip()), int(parts[1]))
    return table


def tmux_panes():
    """{ペインの最初のプロセスの PID: 'セッション:ウィンドウ番号 ウィンドウ名'}。"""
    if not shutil.which("tmux"):
        return {}
    r = subprocess.run(["tmux", "list-panes", "-a", "-F", "#{pane_pid}	#{session_name}:#{window_index} #{window_name}"],
                       capture_output=True, text=True, errors="replace")
    panes = {}
    for line in r.stdout.splitlines():
        pid, _, where = line.partition("	")
        if pid.strip().isdigit():
            panes[int(pid)] = where
    return panes


def location(pid, procs, panes):
    """claude の親プロセスから、どこで動いているか (tmux / terminal / other) を返す。"""
    me = procs.get(pid)
    if not me:
        return "不明 (プロセスが見つからない)"
    parent = procs.get(me[1])
    if parent and parent[0] in SHELLS:
        if me[1] in panes:
            return f"tmux ({panes[me[1]]})"
        grand = procs.get(parent[1])
        if grand and grand[0] in TERMINALS:
            return f"terminal ({grand[0]})"
    host = parent[0] if parent else "?"
    return f"other ({host})"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="*", help="出すセッションの名前 (ListAgents の名前)。省略時はすべて")
    parser.add_argument("--prompts", type=int, default=2, help="最初と最後から出す依頼の件数")
    parser.add_argument("--chars", type=int, default=300, help="依頼・返答を切り詰める文字数")
    args = parser.parse_args()

    sessions = load_sessions(set(args.names))
    procs, panes = process_table(), tmux_panes()
    found = {s.get("name") for s in sessions}
    for name in args.names:
        if name not in found:
            print(f"## {name}\n(このマシンの {CONFIG_DIR}/sessions に見つからない。クラウドや別のマシンのセッションか、終了している)\n")

    for s in sessions:
        sid = s.get("sessionId", "")
        me = " (このセッション)" if sid and sid == SELF_ID else ""
        print(f"## {s.get('name')}{me}")
        print(f"状態: {s.get('status')} / 種類: {s.get('kind')} / フォルダ: {s.get('cwd')}")
        print(f"場所: {location(int(s.get('pid') or 0), procs, panes)}")
        print(f"起動: {local_time(s.get('startedAt'))} / 状態の更新: {local_time(s.get('statusUpdatedAt') or s.get('updatedAt'))}")

        transcripts = glob.glob(os.path.join(CONFIG_DIR, "projects", "*", f"{sid}.jsonl"))
        if not transcripts:
            print("会話記録: なし (起動直後、または記録の保存がオフの子セッション)\n")
            continue
        prompts, last_reply, title, last_time = read_transcript(transcripts[0])
        print(f"タイトル: {title or '-'} / 最後の会話: {local_time(last_time)} / 依頼の数: {len(prompts)}")

        n = args.prompts
        picked = prompts if len(prompts) <= n * 2 else prompts[:n] + [None] + prompts[-n:]
        for p in picked:
            if p is None:
                print(f"  … (間の {len(prompts) - n * 2} 件は省略)")
                continue
            ts, origin, text = p
            who = "ユーザー" if origin == "human" else "別セッション"
            print(f"  [{local_time(ts)} {who}] {shorten(text, args.chars)}")
        if last_reply:
            print(f"  最後の返答 [{local_time(last_reply[0])}] {shorten(last_reply[1], args.chars * 2)}")
        print()


if __name__ == "__main__":
    main()
