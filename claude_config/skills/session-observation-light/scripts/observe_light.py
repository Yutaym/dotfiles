"""session-observation のコンパクト版。No・状態・場所 (tmux の「セッション:ウィンドウ」) の 3 列だけを表示し続ける。

使い方:
    uv run --no-project --with rich python observe_light.py [--interval 秒] [--remote-interval 秒] [--no-remote]
    uv run --no-project python observe_light.py --stop     # 動いている監視を止める (session-observation のものも止まる)

- 材料の読み取り・状態の判定・並び・ssh の接続先の読み込み・キー操作は、session-observation の observe.py を
  import してそのまま使う。違うのは表の列と見出しだけ (render)。
- 見出しの左端の [通常版] をクリックすると、同じペインのまま session-observation の表示に切り替わる (逆も同じ)。
- 監視の印 (~/.claude/session-observation/observer.json) は session-observation と共用する。
  light と session-observation は合わせて 1 つだけ動き、新しく開いたほうに置き換わる (2026/10/30 にユーザーが決めた)。
"""

import datetime
import importlib.util
import os
import sys

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
OBSERVE = os.path.join(HERE, "..", "..", "session-observation", "scripts", "observe.py")


def load_observe():
    spec = importlib.util.spec_from_file_location("observe", OBSERVE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ob = load_observe()


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
        rows.append((ob.row(item), item, None, ob.target(item)))
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
            rows.append((ob.row(item, host, r["windows"]), item, host, ob.target(item, host, r["windows"])))
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
        table.add_row(no, state, where or "-", style=style)

    width, height = console.size
    buf = StringIO()
    Console(file=buf, width=width, force_terminal=True, color_system=console.color_system or "standard",
            legacy_windows=False).print(table)
    lines = buf.getvalue().rstrip("\n").split("\n")
    body = max(3, height - 1 - len(notes))
    view["page"] = body
    view["offset"] = max(0, min(view["offset"], len(lines) - body))
    view["targets"] = ob.line_targets(lines, [r[3] for r in rows], boxed=False)
    view["numbers"] = {r[0][2]: r[3] for r in rows}
    shown = lines[view["offset"]:view["offset"] + body]
    position = f" {view['offset'] + 1}-{view['offset'] + len(shown)}/{len(lines)}" if len(lines) > body else ""

    header = Text.assemble((ob.SWITCH_TEXT["light"], "bold reverse"), " ",
                           (datetime.datetime.now().strftime("%H:%M:%S"), "bold"), (position, "bold magenta"),
                           (ob.typed_info(view), "bold reverse"),
                           no_wrap=True, overflow="ellipsis")
    parts = [header, Text.from_ansi("\n".join(shown))]
    parts += [Text(n, style="red", no_wrap=True, overflow="ellipsis") for n in notes]
    return Group(*parts)


def main():
    # 読み込み・描き直し・キー操作・表示の切り替えは observe.py の main が行う。light の表で始める
    ob.main(mode="light", light_render=render)


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    main()
