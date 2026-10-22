"""ほかの Claude Code のセッションの状況を、一定の間隔で画面を描き直して表示し続ける。

使い方:
    uv run --no-project --with rich python observe.py [--interval 秒] [--remote-interval 秒] [--no-remote]
    uv run --no-project python observe.py --stop     # 動いている監視を止める (ほかのセッションからも使える)

- このマシンのセッションは --interval (既定 3 秒) ごと、ssh の接続先のセッションは --remote-interval
  (既定 60 秒) ごとに読み直す。ssh は重いので、別のスレッドで読み、表示は止めない。
- 材料は session-overview スキルの session-overview.py から取る (このマシンは import して直接呼び、
  ssh の接続先では session-overview.py --json を実行する)。表に入れる・入れないの決まりも session-overview に合わせる。
- 監視は同時に 1 つだけ動かす。起動すると ~/.claude/session-observation/observer.json に自分の印を書き、
  毎回の更新でその印が自分のものかを確かめる。新しい監視が起動して印が書き換わったとき、
  または --stop で印のファイルが消されたときに終了する (tmux のペインやタブも一緒に閉じる)。
"""

import argparse
import datetime
import glob
import importlib.util
import json
import os
import re
import subprocess
import sys
import threading
import time
import uuid

# session-overview のスクリプトを import するときに、そのフォルダに __pycache__ を作らない
sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
OVERVIEW_DIR = os.path.join(HERE, "..", "..", "session-overview", "scripts")
CONFIG_DIR = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
STATE_DIR = os.path.join(CONFIG_DIR, "session-observation")
LOCK = os.path.join(STATE_DIR, "observer.json")
REMOTE_SCRIPT = "~/.claude/skills/session-overview/scripts/session-overview.py"


def load_module(name, filename):
    spec = importlib.util.spec_from_file_location(name, os.path.join(OVERVIEW_DIR, filename))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# ---------- 同時に 1 つだけ動かすための印 ----------

def read_lock():
    try:
        with open(LOCK, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def take_lock():
    os.makedirs(STATE_DIR, exist_ok=True)
    token = uuid.uuid4().hex
    with open(LOCK, "w", encoding="utf-8") as f:
        json.dump({"token": token, "pid": os.getpid(), "startedAt": int(time.time() * 1000)}, f)
    return token


def still_owner(token):
    lock = read_lock()
    return bool(lock) and lock.get("token") == token


def stop():
    lock = read_lock()
    try:
        os.remove(LOCK)
    except OSError:
        pass
    if lock:
        print(f"停止を指示した (pid {lock.get('pid')})。次の更新のときに終了する。")
    else:
        print("動いている監視はない。")


# ---------- 材料を集める ----------

class Local:
    """このマシンのセッションを読む。会話記録は、更新時刻と大きさが変わったときだけ読み直す。"""

    def __init__(self, overview):
        self.ov = overview
        self.cache = {}

    def transcript(self, sid):
        paths = glob.glob(os.path.join(self.ov.CONFIG_DIR, "projects", "*", f"{sid}.jsonl"))
        if not paths:
            return None
        try:
            st = os.stat(paths[0])
        except OSError:
            return None
        key = (st.st_mtime, st.st_size)
        hit = self.cache.get(paths[0])
        if not hit or hit[0] != key:
            hit = (key, self.ov.read_transcript(paths[0]))
            self.cache[paths[0]] = hit
        return hit[1]

    def collect(self):
        sessions = self.ov.load_sessions(set())
        procs, panes = self.ov.process_table(), self.ov.tmux_panes()
        out = []
        for s in sessions:
            if not self.ov.is_alive(s, procs):
                continue
            item = {
                "name": s.get("name"), "status": s.get("status"), "cwd": s.get("cwd"),
                "location": self.ov.location(int(s.get("pid") or 0), procs, panes),
                "startedAt": s.get("startedAt"), "statusUpdatedAt": s.get("statusUpdatedAt") or s.get("updatedAt"),
                "transcript": False, "title": None, "lastTime": None, "prompts": [], "lastReply": None,
            }
            t = self.transcript(s.get("sessionId", ""))
            if t:
                prompts, last_reply, title, last_time = t
                item.update({
                    "transcript": True, "title": title, "lastTime": last_time,
                    "prompts": [{"time": ts, "origin": o, "text": text} for ts, o, text in prompts[-3:]],
                    "lastReply": {"time": last_reply[0], "text": last_reply[1]} if last_reply else None,
                })
            out.append(item)
        return out


class Remote(threading.Thread):
    """ssh で開いたウィンドウの接続先で session-overview.py --json を動かし、結果を持っておく。"""

    def __init__(self, remote_overview, interval):
        super().__init__(daemon=True)
        self.ro = remote_overview
        self.interval = interval
        self.shells = {}
        self.lock = threading.Lock()
        self.result = {}  # 接続先: {"windows": [...], "sessions": [...] または None, "error": str}
        self.updated = None
        self.wake = threading.Event()

    def fetch(self, host):
        if host not in self.shells:
            self.shells[host] = self.ro.remote_shell(host)
        args = "--json --prompts 1 --chars 200"
        if self.shells[host] == "pwsh":
            remote = f"$env:PYTHONIOENCODING = 'utf-8'; uv run --no-project python $HOME/{REMOTE_SCRIPT[2:]} {args}"
        else:
            remote = 'exec "$SHELL" -lic "uv run --no-project python ' + f'{REMOTE_SCRIPT} {args}"'
        try:
            res = subprocess.run(
                ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=8", host, remote],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60,
            )
        except (OSError, subprocess.SubprocessError) as e:
            return None, str(e)
        # ログインシェルが余計な行を出すことがあるので、最後の [ で始まる行を JSON として読む
        for line in reversed(res.stdout.splitlines()):
            if line.startswith("["):
                try:
                    return json.loads(line), None
                except ValueError:
                    break
        reason = (res.stderr.strip().splitlines() or [f"終了コード {res.returncode}"])[-1]
        return None, re.sub(r"\x1b\[[0-9;]*m", "", reason)[:80]

    def run(self):
        while True:
            hosts = self.ro.ssh_hosts()
            result = {}
            for host, windows in hosts.items():
                sessions, err = self.fetch(host)
                result[host] = {"windows": windows, "sessions": sessions, "error": err}
            with self.lock:
                self.result = result
                self.updated = time.time()
            self.wake.wait(self.interval)
            self.wake.clear()

    def snapshot(self):
        with self.lock:
            return dict(self.result), self.updated


# ---------- 表を作る ----------

def to_epoch(value):
    if not value:
        return None
    if isinstance(value, (int, float)):
        return value / 1000
    try:
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def hm(value):
    t = to_epoch(value)
    return datetime.datetime.fromtimestamp(t).strftime("%H:%M") if t else "-"


def ago(value):
    t = to_epoch(value)
    if not t:
        return ""
    sec = max(0, int(time.time() - t))
    if sec < 60:
        return f"{sec}秒前"
    if sec < 3600:
        return f"{sec // 60}分前"
    if sec < 86400:
        return f"{sec // 3600}時間前"
    return f"{sec // 86400}日前"


def one_line(text, limit):
    text = " ".join((text or "").split())
    return text if len(text) <= limit else text[:limit] + "…"


CONTINUED = "This session is being continued"
QUESTION_RE = re.compile(r"(？|\?|ますか。?|でしょうか。?|ください。?|教えて.{0,10})\s*$")
PLACE_RE = re.compile(r"^tmux \((\S+)")


def place(item, host=None, windows=None):
    folder = re.split(r"[\\/]", (item.get("cwd") or "").rstrip("\\/"))[-1] or "-"
    if host:
        named = [w for w in windows or [] if w.split(" ", 1)[-1] == item.get("name")]
        wins = ", ".join(w.split(" ", 1)[0] for w in (named or windows or []))
        return f"{host}:{folder} / ssh {wins}"
    loc = item.get("location") or "不明"
    m = PLACE_RE.match(loc)
    if m:
        return f"{folder} / tmux {m.group(1)}"
    if loc.startswith("terminal"):
        return f"{folder} / terminal"
    if loc.startswith("other (code)"):
        return f"{folder} / その他（VS Code）"
    if loc.startswith("other ("):
        return f"{folder} / その他（{loc[7:].rstrip(')')}）"
    return f"{folder} / 不明"


def row(item, host=None, windows=None):
    """(セッション, 状態, 場所, 何をしているか, 最後の動き, 色) を返す。"""
    from rich.text import Text

    status = item.get("status") or "?"
    in_tmux = host is None and (item.get("location") or "").startswith("tmux")
    name = Text(item.get("name") or "-", style="bold" if in_tmux else "")

    # 会話を圧縮したあとの「This session is being continued ...」は依頼ではないので除く
    prompts = [p for p in item.get("prompts") or [] if not (p.get("text") or "").startswith(CONTINUED)]
    last_prompt = prompts[-1] if prompts else None
    # タイトルがセッション名と同じ (名前を付けて起動したもの) ときは、中身が分からないので最後の依頼を出す
    title = item.get("title") if item.get("title") != item.get("name") else None
    peer = last_prompt and last_prompt.get("origin") == "peer"
    sender, _, body = (last_prompt or {}).get("text", "").partition(" から:") if peer else ("", "", "")
    doing = Text(one_line(title or body or (last_prompt or {}).get("text") or "-", 30))
    if peer:
        doing.append(f"\n{sender} から依頼", style="cyan")
    elif last_prompt and title:
        doing.append("\n← " + one_line(last_prompt.get("text"), 26), style="dim")

    reply = item.get("lastReply")
    last = item.get("lastTime") or item.get("statusUpdatedAt")
    if status == "busy":
        state, style = "busy", "bold yellow"
        move = Text(f"作業中（{ago(item.get('statusUpdatedAt'))}から）", style="yellow")
    elif status != "idle":
        state, style = status, "bold magenta"
        move = Text(f"{status}（{ago(item.get('statusUpdatedAt'))}から）", style="magenta")
    elif not item.get("transcript"):
        state, style = "idle", "green"
        move = Text("記録なし", style="dim")
    elif reply and QUESTION_RE.search(reply.get("text") or ""):
        state, style = "idle", "green"
        move = Text(f"返事待ち {hm(last)}（{ago(last)}）", style="bold red")
    else:
        state, style = "idle", "green"
        move = Text(f"完了 {hm(last)}（{ago(last)}）", style="green")
    if reply:
        move.append("\n" + one_line(reply.get("text"), 28), style="dim")

    # 1 時間以上動きのない idle のセッションは、全体を薄くする
    t = to_epoch(last)
    stale = status == "idle" and t and time.time() - t > 3600
    return name, Text(state, style=style), place(item, host, windows), doing, move, "dim" if stale else ""


def render(local, remote_result, remote_updated, args):
    from rich.console import Group
    from rich.table import Table
    from rich.text import Text

    table = Table(expand=True, show_lines=True, header_style="bold cyan")
    for col, kw in [("No", {"justify": "right", "width": 3}), ("セッション", {"ratio": 2, "min_width": 20}), ("状態", {"width": 6}),
                    ("場所", {"ratio": 3}), ("何をしているか", {"ratio": 4}), ("最後の動き", {"ratio": 4})]:
        table.add_column(col, overflow="fold", **kw)

    no = 0
    counts = {}
    notes = []
    for item in local:
        no += 1
        *cells, style = row(item)
        counts[item.get("status")] = counts.get(item.get("status"), 0) + 1
        table.add_row(str(no), *cells, style=style)
    for host, r in sorted(remote_result.items()):
        if r["sessions"] is None:
            notes.append(f"{host}: 読めなかった（{r['error']}）。表には入れていない")
            continue
        for item in r["sessions"]:
            if not item.get("alive"):
                continue
            no += 1
            *cells, style = row(item, host, r["windows"])
            counts[item.get("status")] = counts.get(item.get("status"), 0) + 1
            table.add_row(str(no), *cells, style=style)

    now = datetime.datetime.now().strftime("%H:%M:%S")
    summary = "  ".join(f"{k} {v}" for k, v in sorted(counts.items(), key=lambda kv: str(kv[0])))
    if args.no_remote:
        remote_info = "ssh: 読まない"
    elif remote_updated:
        remote_info = f"ssh: {args.remote_interval:g}秒ごと（最終 {datetime.datetime.fromtimestamp(remote_updated):%H:%M:%S}）"
    else:
        remote_info = "ssh: 読み込み中…"
    header = Text.assemble(
        ("session-observation", "bold"), f"  更新 {now}  このマシン: {args.interval:g}秒ごと  {remote_info}  ",
        (summary, "cyan"),
    )
    footer = Text("止める: Ctrl+C、またはほかのセッションから observe.py --stop", style="dim")
    parts = [header, table]
    parts += [Text("・" + n, style="red") for n in notes]
    parts.append(footer)
    return Group(*parts)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--interval", type=float, default=3, help="このマシンのセッションを読み直す間隔 (秒)")
    parser.add_argument("--remote-interval", type=float, default=60, help="ssh の接続先を読み直す間隔 (秒)")
    parser.add_argument("--no-remote", action="store_true", help="ssh の接続先を読まない")
    parser.add_argument("--stop", action="store_true", help="動いている監視を止める")
    args = parser.parse_args()

    if args.stop:
        stop()
        return

    from rich.console import Console
    from rich.live import Live

    overview = load_module("session_overview", "session-overview.py")
    local = Local(overview)
    remote = None
    if not args.no_remote:
        remote = Remote(load_module("remote_overview", "remote-overview.py"), args.remote_interval)
        remote.start()

    token = take_lock()
    console = Console()
    try:
        with Live(console=console, screen=True, auto_refresh=False) as live:
            while still_owner(token):
                result, updated = remote.snapshot() if remote else ({}, None)
                live.update(render(local.collect(), result, updated, args), refresh=True)
                # 止める指示にすぐ気づけるように、間隔を細かく分けて待つ
                end = time.time() + args.interval
                while time.time() < end and still_owner(token):
                    time.sleep(0.5)
    except KeyboardInterrupt:
        pass
    finally:
        if still_owner(token):
            try:
                os.remove(LOCK)
            except OSError:
                pass


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    main()
