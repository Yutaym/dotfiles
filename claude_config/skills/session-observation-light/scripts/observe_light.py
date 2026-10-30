"""session-observation のコンパクト版。No・状態・場所 (tmux の「セッション:ウィンドウ」) の 3 列だけを表示し続ける。

使い方:
    uv run --no-project --with rich python observe_light.py [--interval 秒] [--remote-interval 秒] [--no-remote]
    uv run --no-project python observe_light.py --stop     # 動いている監視を止める (session-observation のものも止まる)

- 材料の読み取り・状態の判定・並び・ssh の接続先の読み込み・キー操作は、session-observation の observe.py を
  import してそのまま使う。違うのは表の列と見出しだけ。
- 監視の印 (~/.claude/session-observation/observer.json) は session-observation と共用する。
  light と session-observation は合わせて 1 つだけ動き、新しく開いたほうに置き換わる (2026/10/30 にユーザーが決めた)。
"""

import argparse
import datetime
import importlib.util
import os
import sys
import time

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
OBSERVE = os.path.join(HERE, "..", "..", "session-observation", "scripts", "observe.py")


def load_observe():
    spec = importlib.util.spec_from_file_location("observe", OBSERVE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ob = load_observe()


def place(item, host=None, windows=None):
    """tmux の「セッション:ウィンドウ」だけを返す。分からないときは -。
    ssh の接続先のセッションは、その ssh を開いているこのマシンのウィンドウを返す。"""
    if host:
        named = [w for w in windows or [] if w.split(" ", 1)[-1] == item.get("name")]
        wins = [w.split(" ", 1)[0] for w in (named or windows or [])]
        return ",".join(wins) or "-"
    m = ob.PLACE_RE.match(item.get("location") or "")
    return m.group(1) if m else "-"


def render(console, view, local, remote_result, remote_updated, args, overview, wait_log):
    """画面全体を作る。observe.py の render と同じ流れで、列を No・状態・場所に絞る。"""
    from io import StringIO

    from rich.console import Console, Group
    from rich.table import Table
    from rich.text import Text

    table = Table(box=None, pad_edge=False, header_style="bold cyan")
    table.add_column("No", justify="right")
    table.add_column("状態", no_wrap=True)
    table.add_column("場所", no_wrap=True, overflow="ellipsis")

    rows = []
    notes = []
    for item in local:
        rows.append((ob.row(item), item, None, place(item)))
    for host, r in sorted(remote_result.items()):
        if r["sessions"] is None:
            notes.append(f"{host}: 読めない")
            continue
        # ssh の接続先は、Remote Control につながっているものだけを出す (session-observation と同じ)
        if r["sessions"] and not any("remoteControl" in item for item in r["sessions"]):
            notes.append(f"{host}: 接続先が古い")
            continue
        shown_items = [item for item in r["sessions"] if item.get("alive") and item.get("remoteControl")]
        keys = [f"{host}|{item.get('sessionId')}" for item in shown_items]
        numbers = overview.session_numbers(keys, scope=f"{host}|")
        for item, key in zip(shown_items, keys):
            item = dict(item, number=numbers.get(key))
            rows.append((ob.row(item, host, r["windows"]), item, host, place(item, host, r["windows"])))
    rows.sort(key=lambda r: r[0][0])
    for (_, waiting, no, _name, state, *_rest, style), item, host, where in rows:
        if waiting:
            wait_log.write(item, host, *waiting)
        # observe.py の状態の欄は、返事待ちを waiting など、返事待ち? を idle と出すので、light では書き分ける
        # (どちらかは observe.py の row が付けた色で見分ける)
        if str(state.style) == "bold red":
            state = Text("返事待ち", style="bold red")
        elif str(state.style) == "red":
            state = Text("返事待ち?", style="red")
        table.add_row(no, state, where, style=style)

    width, height = console.size
    buf = StringIO()
    Console(file=buf, width=width, force_terminal=True, color_system=console.color_system or "standard",
            legacy_windows=False).print(table)
    lines = buf.getvalue().rstrip("\n").split("\n")
    body = max(3, height - 1 - len(notes))
    view["page"] = body
    view["offset"] = max(0, min(view["offset"], len(lines) - body))
    shown = lines[view["offset"]:view["offset"] + body]
    position = f" {view['offset'] + 1}-{view['offset'] + len(shown)}/{len(lines)}" if len(lines) > body else ""

    header = Text.assemble((datetime.datetime.now().strftime("%H:%M:%S"), "bold"), (position, "bold magenta"),
                           no_wrap=True, overflow="ellipsis")
    parts = [header, Text.from_ansi("\n".join(shown))]
    parts += [Text(n, style="red", no_wrap=True, overflow="ellipsis") for n in notes]
    return Group(*parts)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--interval", type=float, default=10, help="このマシンのセッションを読み直す間隔 (秒)")
    parser.add_argument("--remote-interval", type=float, default=60, help="ssh の接続先を読み直す間隔 (秒)")
    parser.add_argument("--no-remote", action="store_true", help="ssh の接続先を読まない")
    parser.add_argument("--stop", action="store_true", help="動いている監視を止める")
    args = parser.parse_args()

    if args.stop:
        ob.stop()
        return

    from rich.console import Console
    from rich.live import Live

    overview = ob.load_module("session_overview", "session-overview.py")
    local = ob.Local(overview)
    remote = None
    if not args.no_remote:
        remote = ob.Remote(ob.load_module("remote_overview", "remote-overview.py"), args.remote_interval)
        remote.start()

    token = ob.take_lock()
    console = Console()
    keys = ob.Keys()
    keys.start()
    view = {"offset": 0}
    wait_log = ob.WaitLog()
    try:
        with Live(console=console, screen=True, auto_refresh=False) as live:
            data, next_collect = [], 0.0
            while ob.still_owner(token):
                if time.time() >= next_collect:
                    data = local.collect()
                    next_collect = time.time() + args.interval
                result, updated = remote.snapshot() if remote else ({}, None)
                live.update(render(console, view, data, result, updated, args, overview, wait_log), refresh=True)
                keys.event.wait(max(0.05, min(0.5, next_collect - time.time())))
                keys.event.clear()
                while keys.queue:
                    key = keys.queue.pop(0)
                    if key == "quit":
                        raise KeyboardInterrupt
                    ob.scroll(view, key)
    except KeyboardInterrupt:
        pass
    finally:
        if keys.restore:
            keys.restore()
        if ob.still_owner(token):
            try:
                os.remove(ob.LOCK)
            except OSError:
                pass


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    main()
