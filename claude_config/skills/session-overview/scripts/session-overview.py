"""同じマシンの Claude Code のセッションを一覧にし、要約の材料を会話記録から抜き出す。

使い方:
    uv run --no-project python session-overview.py [セッション名 ...] [--prompts N] [--chars N] [--json]

セッション名を指定しなければ、~/.claude/sessions/*.json にあるセッションをすべて出す。
各セッションについて、状態・フォルダ・場所 (tmux / terminal / other)・起動時刻・最後に動いた時刻・自動で付いたタイトル・
依頼 (ユーザーが入力したもの / 別のセッションから届いたもの) の最初と最後の N 件・最後の返答を表示する。
要約そのものは、この出力を読んだ Claude が書く。
--json を付けると、同じ材料を JSON で出す (session-observation スキルが、ssh の接続先でも読むのに使う)。
JSON には、プロセスが生きているかどうか (alive) も入る。

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
import time

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
    """プロセス名を小文字にし、パスと .exe と、ログインシェルの先頭の - (例: -zsh) を除く。"""
    name = (name or "").lower().replace("\\", "/").rsplit("/", 1)[-1].lstrip("-")
    return name[:-4] if name.endswith(".exe") else name


def process_table():
    """{PID: (名前, 親の PID, 開始時刻)} を 1 回のコマンドで取る。取れなければ空。
    開始時刻はエポック秒 (取れなければ None)。Windows は CreationDate、macOS / Linux は ps の lstart を UTC で読む。"""
    env = None
    try:
        if sys.platform == "win32":
            cmd = ["powershell", "-NoProfile", "-NonInteractive", "-Command",
                   "Get-CimInstance Win32_Process | ForEach-Object { \"$($_.ProcessId)`t$($_.ParentProcessId)`t$($_.Name)`t$(if ($_.CreationDate) { $_.CreationDate.ToFileTimeUtc() })\" }"]
        else:
            # lstart は「Thu Oct 15 01:53:08 2026」の 5 語。sessions/*.json の procStart (macOS) と同じく UTC・英語で出させる
            cmd = ["ps", "-A", "-o", "pid=,ppid=,lstart=,comm="]
            env = dict(os.environ, TZ="UTC", LC_ALL="C")
        out = subprocess.run(cmd, capture_output=True, text=True, errors="replace", env=env).stdout
    except OSError:
        return {}
    table = {}
    for line in out.splitlines():
        if "	" in line:
            parts = line.split("	")
            if len(parts) < 3:
                continue
            pid, ppid, name = parts[0].strip(), parts[1].strip(), parts[2].strip()
            start = parse_start(parts[3].strip() if len(parts) > 3 else "")
        else:
            parts = line.split(None, 7)
            if len(parts) < 8:
                continue
            pid, ppid, name = parts[0], parts[1], parts[7].strip()
            start = parse_start(" ".join(parts[2:7]))
        if pid.isdigit() and ppid.isdigit():
            table[int(pid)] = (base(name), int(ppid), start)
    return table


FILETIME_EPOCH = 11644473600  # 1601/01/01 から 1970/01/01 までの秒数


def parse_start(value):
    """プロセスの開始時刻をエポック秒にする。Windows の FILETIME (100 ナノ秒単位の整数) と、
    macOS の procStart・ps の lstart の形式 (UTC の「Thu Oct 15 01:53:08 2026」) を読む。読めなければ None。"""
    value = " ".join(str(value or "").split())
    if value.isdigit() and len(value) >= 17:
        return int(value) / 10_000_000 - FILETIME_EPOCH
    try:
        dt = datetime.datetime.strptime(value, "%a %b %d %H:%M:%S %Y")
    except ValueError:
        return None
    return dt.replace(tzinfo=datetime.timezone.utc).timestamp()


def linux_ticks(pid):
    """Linux の /proc/<pid>/stat の starttime (起動からのクロック数)。読めなければ None。"""
    try:
        with open(f"/proc/{pid}/stat", encoding="utf-8") as f:
            return int(f.read().rsplit(")", 1)[1].split()[19])
    except (OSError, ValueError, IndexError):
        return None


VERSION_RE = re.compile(r"^\d+\.\d+\.\d+")


def is_alive(s, procs):
    """sessions/*.json のセッションのプロセスが今も動いているか。sessions/ には終了したセッションのファイルも残る。
    PID の使い回しで取り違えないように、プロセスの開始時刻が procStart と 2 秒以内で一致するかを見る
    (Windows は FILETIME、macOS は UTC の ctime 形式。2026/10/22 に確かめた)。
    procStart の形式が分からないときは、プロセス名が claude らしいか (claude / node / バージョン番号の名前) で判断する。"""
    pid = int(s.get("pid") or 0)
    me = procs.get(pid)
    if not me:
        return False
    proc_start = str(s.get("procStart") or "").strip()
    expected = parse_start(proc_start)
    if expected is not None and me[2] is not None:
        return abs(me[2] - expected) <= 2
    # Linux で procStart が /proc/<pid>/stat の starttime の形式なら、それと比べる (形式は未確認)
    if proc_start.isdigit():
        ticks = linux_ticks(pid)
        if ticks is not None:
            return ticks == int(proc_start)
    name = me[0]
    return "claude" in name or name == "node" or bool(VERSION_RE.match(name))


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


NUMBERS = os.path.join(CONFIG_DIR, "session-numbers.json")
NUMBER_TTL = 7 * 86400  # この期間見かけなかった番号は捨てる (ssh の接続先を開かなくなったときなど)


def session_numbers(keys, scope=None):
    """セッションの番号 (No) を {鍵: 番号} で返す。session-overview・session-kill・session-observation で同じ番号を使う。

    番号は ~/.claude/session-numbers.json に記録し、セッションが終わるまで変えない。新しいセッションには、
    空いている一番小さい番号を振る。鍵は、このマシンのセッションは sessionId、ssh の接続先は「接続先|sessionId」。
    scope に "" (このマシン) か "接続先|" を渡すと、keys がその範囲で生きているセッションのすべてだとみなし、
    範囲の中で keys にない番号を捨てる。一部の名前だけを調べたときは scope を渡さない。"""
    try:
        with open(NUMBERS, encoding="utf-8") as f:
            entries = json.load(f)
    except (OSError, ValueError):
        entries = {}
    before = json.dumps(entries, sort_keys=True)
    now = int(datetime.datetime.now().timestamp())
    for key in list(entries):
        local = "|" not in key
        in_scope = scope is not None and (local if scope == "" else key.startswith(scope))
        if (in_scope and key not in keys) or now - entries[key].get("seen", 0) > NUMBER_TTL:
            del entries[key]
    used = {e["no"] for e in entries.values()}
    for key in keys:
        if key not in entries:
            no = 1
            while no in used:
                no += 1
            used.add(no)
            entries[key] = {"no": no, "seen": now}
        elif now - entries[key].get("seen", 0) > 3600:
            entries[key]["seen"] = now
    if json.dumps(entries, sort_keys=True) != before:
        # ほかのスクリプトと同時に書いても壊れないように、別のファイルに書いてから置き換える
        tmp = f"{NUMBERS}.{os.getpid()}.tmp"
        try:
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(entries, f)
            os.replace(tmp, NUMBERS)
        except OSError:
            pass
    return {key: entries[key]["no"] for key in keys}


def local_numbers(procs):
    """このマシンの生きているセッションすべてに番号を振り、{sessionId: 番号} を返す。"""
    alive = [s for s in load_sessions(set()) if is_alive(s, procs) and s.get("sessionId")]
    return session_numbers([s["sessionId"] for s in alive], scope="")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="*", help="出すセッションの名前 (ListAgents の名前)。省略時はすべて")
    parser.add_argument("--prompts", type=int, default=2, help="最初と最後から出す依頼の件数")
    parser.add_argument("--chars", type=int, default=300, help="依頼・返答を切り詰める文字数")
    parser.add_argument("--json", action="store_true", help="材料を JSON で出す")
    parser.add_argument("--no-number", action="store_true",
                        help="番号を振らない (ssh の接続先で動かすとき。番号は ssh を開いた側のマシンで振る)")
    args = parser.parse_args()

    sessions = load_sessions(set(args.names))
    procs, panes = process_table(), tmux_panes()
    numbers = {} if args.no_number else local_numbers(procs)
    if args.json:
        print_json(sessions, procs, panes, args.prompts, args.chars, numbers)
        return
    found = {s.get("name") for s in sessions}
    for name in args.names:
        if name not in found:
            print(f"## {name}\n(このマシンの {CONFIG_DIR}/sessions に見つからない。クラウドや別のマシンのセッションか、終了している)\n")

    for s in sessions:
        sid = s.get("sessionId", "")
        me = " (このセッション)" if sid and sid == SELF_ID else ""
        print(f"## {s.get('name')}{me}")
        print(f"番号: {numbers.get(sid, '-')} / ID: {sid}")
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
        item = {"status": s.get("status"), "lastTime": last_time, "statusUpdatedAt": s.get("statusUpdatedAt") or s.get("updatedAt"),
                "lastReply": {"time": last_reply[0], "text": last_reply[1]} if last_reply else None}
        w = judge_waiting(item)
        print(f"判定: {wait_label(item)}" + (f"（{w[1]}）" if w else "") + " ← 表の「最後の動き」の返事待ちは、この判定に従う")
        print()


def to_epoch(value):
    """ミリ秒のエポック時刻か ISO 形式の文字列を、秒のエポック時刻にする。"""
    if not value:
        return None
    if isinstance(value, (int, float)):
        return value / 1000
    try:
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


# 返事待ちかどうかの判定は、session-overview (この出力の「判定:」行) と session-observation の監視画面 (observe.py) の
# 両方がこの関数を使う。基準を変えるときはここだけを直す。
# 返答の終わり方から「返事待ち?」と推定する言葉。「ください」は、ユーザーの返事を求めるもの (教えて・選んで など) だけにする。
# 「確認してください」「実行してください」などの作業のお願いは、返事が要らないので含めない (2026/10/22 にユーザーが決めた)
QUESTION_RE = re.compile(
    r"(？|\?|ますか|ですか|でしょうか"
    r"|(?:教えて|選んで|決めて|知らせて|お知らせ|返信して|回答して|指示して|返事を|回答を|指示を|ご指示|ご返信|ご回答)"
    r"(?:ください|下さい))"
    r"[。．.!！]?[)）」』]?\s*$"
)
# 「崩れていたら教えてください」のような、条件付きの依頼は返事待ちにしない (2026/10/26 にユーザーが決めた。案 A)。
# 条件の言葉 (たら・れば・なら・場合は・ときは) と「教えて・知らせて」の依頼が同じ文にあるものを除く。
# 元に戻すときは、judge_waiting の COND_RE を使っている条件を消す (~/vaults/90_Meta の session-observation メモも参照)
COND_RE = re.compile(r"(?:たら|れば|なら|場合は|ときは)[^。．.!！？?]*$")
WAITING = {"waiting", "requires_action"}


def judge_waiting(item):
    """返事待ちかどうかを (種類, 判断の材料) で返す。返事待ちでなければ None。
    種類は "状態" (sessions/*.json の status が waiting / requires_action。確か) か
    "推定" (idle で、24 時間以内の最後の返答が QUESTION_RE で終わる)。
    item は status・lastTime・statusUpdatedAt・lastReply ({time, text, tail}) を持つ辞書 (--json の 1 要素と同じ形)。"""
    status = item.get("status")
    if status in WAITING:
        return "状態", f"status={status}"
    reply = item.get("lastReply")
    last = item.get("lastTime") or item.get("statusUpdatedAt")
    if status != "idle" or not reply or time.time() - (to_epoch(last) or 0) >= 86400:
        return None
    # ssh の接続先の返答は切り詰めてあるので、切り詰めていない最後の部分 (tail) で判断する
    tail = reply.get("tail") or tail_for_judging(reply.get("text") or "")
    # 最後の数行のどれかが質問で終わっていれば返事待ち (質問のあとに「次の手順」などの行が続く返答がある)
    for line in reversed(tail.splitlines()):
        m = QUESTION_RE.search(line)
        if m and not (m.group(1).startswith(("教えて", "知らせて", "お知らせ")) and COND_RE.search(line[:m.end()].rstrip("。．.!！)）」』 "))):
            return "推定", f"「{m.group(1)}」で終わる"
    return None


def wait_label(item):
    """judge_waiting の結果を「返事待ち」「返事待ち?」「なし」にする。"""
    w = judge_waiting(item)
    return "なし" if not w else "返事待ち" if w[0] == "状態" else "返事待ち?"


def tail_for_judging(text, n=3):
    """返事待ちの判断に使う、返答の最後の n 行 (改行は残す)。末尾の「※ 〜」で始まる補足の行は、質問ではないので除く
    (2026/10/26 に、質問のあとに補足が付いた返答が「完了」と出た)。"""
    lines = text.rstrip().splitlines()
    while lines and (not lines[-1].strip() or lines[-1].lstrip().startswith("※")):
        lines.pop()
    return "\n".join(" ".join(ln.split())[-100:] for ln in lines[-n:] if ln.strip())


def print_json(sessions, procs, panes, n, chars, numbers):
    """セッションごとの材料を JSON の配列で出す。時刻はミリ秒のエポック時刻か ISO 形式のまま。
    lastReply.tail は、返答の最後の 3 行 (※ の補足行を除く。1 行 100 文字まで)。返事待ちかどうかを、返答の終わり方で判断するのに使う。"""
    out = []
    for s in sessions:
        sid = s.get("sessionId", "")
        item = {
            "name": s.get("name"), "sessionId": sid, "number": numbers.get(sid), "self": bool(sid and sid == SELF_ID),
            "status": s.get("status"), "kind": s.get("kind"), "cwd": s.get("cwd"),
            "alive": is_alive(s, procs), "location": location(int(s.get("pid") or 0), procs, panes),
            # Remote Control につながっているセッションには bridgeSessionId がある (2026/10/22 に、ListAgents の
            # Remote Control の行と数が合うことを確かめた。ListAgents の名前は自動で付いた別の名前のことがある)
            "remoteControl": bool(s.get("bridgeSessionId")),
            "startedAt": s.get("startedAt"), "statusUpdatedAt": s.get("statusUpdatedAt") or s.get("updatedAt"),
            "transcript": False, "title": None, "lastTime": None, "promptCount": 0, "prompts": [], "lastReply": None,
        }
        transcripts = glob.glob(os.path.join(CONFIG_DIR, "projects", "*", f"{sid}.jsonl"))
        if transcripts:
            prompts, last_reply, title, last_time = read_transcript(transcripts[0])
            picked = prompts if len(prompts) <= n * 2 else prompts[:n] + prompts[-n:]
            item.update({
                "transcript": True, "title": title, "lastTime": last_time, "promptCount": len(prompts),
                "prompts": [{"time": ts, "origin": o, "text": shorten(t, chars)} for ts, o, t in picked],
                "lastReply": {"time": last_reply[0], "text": shorten(last_reply[1], chars * 2),
                              "tail": tail_for_judging(last_reply[1])} if last_reply else None,
            })
        item["wait"] = wait_label(item)
        out.append(item)
    print(json.dumps(out, ensure_ascii=False))


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    main()
