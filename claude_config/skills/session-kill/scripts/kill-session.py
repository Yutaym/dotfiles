"""Claude Code のセッションを、名前を指定して終了する。開いていたウィンドウも閉じる。

~/.claude/sessions/<pid>.json からセッション名に合うプロセスを探し、
そのプロセスがまだ動いていて claude のプロセスであることを確かめてから終了する。

どこで動いているかを親プロセスから判断し、終了するものを変える。
- tmux: claude の親 (ペインのシェル) を tmux の #{pane_pid} で探し、そのシェルごと終了する。
        ペインの最初のプロセスが終わるとペインが閉じ、最後のペインならウィンドウも閉じる。
        psmux は -t の @ID / %ID を取り違えることがあるので、-t は使わずにプロセスで閉じる。
- ターミナル: claude の親がシェルで、その親がターミナル (Windows Terminal など) なら、シェルごと終了してタブを閉じる。
- それ以外 (VS Code など): claude だけを終了する。

使い方:
    uv run --no-project python kill-session.py <セッション名> [<セッション名> ...] [--dry-run] [--keep-window]

出力 (1 セッションにつき 1 行):
    killed: <名前> pid=<PID> where=<tmux|terminal|other> closed=<閉じたもの> cwd=<フォルダ>
    would kill: ...        (--dry-run のとき)
    not found: <名前>      (動いているプロセスが見つからない)
    skipped: <名前> ...    (claude のプロセスではない、など)
    failed: <名前> ...     (終了できなかった)
終了コード: すべて killed (または would kill) なら 0、それ以外があれば 1。
"""

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

SESSIONS_DIR = Path.home() / ".claude" / "sessions"
IS_WINDOWS = sys.platform == "win32"

SHELLS = {"pwsh", "powershell", "cmd", "bash", "zsh", "sh", "fish", "dash", "nu"}
TERMINALS = {
    "windowsterminal", "openconsole", "wezterm-gui", "wezterm", "kitty", "alacritty", "ghostty",
    "iterm2", "terminal", "gnome-terminal-server", "konsole", "xterm", "tilix", "foot",
}


def base(name):
    """プロセス名を小文字にし、パスと .exe を除く。"""
    name = (name or "").lower().replace("\\", "/").rsplit("/", 1)[-1]
    return name[:-4] if name.endswith(".exe") else name


def load_sessions():
    out = []
    for f in SESSIONS_DIR.glob("*.json"):
        try:
            j = json.loads(f.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        if isinstance(j, dict) and j.get("pid") and j.get("name"):
            out.append(j)
    return out


def proc_info(pid):
    """動いていれば (名前, 親の PID) を、なければ None を返す。"""
    try:
        if IS_WINDOWS:
            r = subprocess.run(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command",
                 f"$p = Get-CimInstance Win32_Process -Filter 'ProcessId={int(pid)}'; "
                 "if ($p) { \"$($p.Name)`t$($p.ParentProcessId)\" }"],
                capture_output=True, text=True, errors="replace",
            )
        else:
            # comm は macOS で 16 文字に切られる (/Users/yuta/.loc) ので、args の最初の語 (実行ファイルのパス) を使う
            r = subprocess.run(["ps", "-o", "ppid=,args=", "-p", str(pid)], capture_output=True, text=True)
            if r.stdout.strip():
                ppid, args = r.stdout.strip().split(None, 1)
                exe = args.split(None, 1)[0]
                # ネイティブ版の claude は ~/.local/share/claude/versions/<版> という名前で動く
                name = "claude" if "/claude/versions/" in exe else base(exe)
                return name, int(ppid)
            return None
        line = r.stdout.strip()
        if not line:
            return None
        name, ppid = line.split("\t")
        return base(name), int(ppid)
    except (OSError, ValueError):
        return None


def tmux_pane_of(pid):
    """#{pane_pid} が pid のペインを探して 'セッション:ウィンドウ番号 ウィンドウ名' を返す。"""
    if not shutil.which("tmux"):
        return None
    r = subprocess.run(
        ["tmux", "list-panes", "-a", "-F", "#{pane_pid}\t#{session_name}:#{window_index} #{window_name}"],
        capture_output=True, text=True, errors="replace",
    )
    for line in r.stdout.splitlines():
        ppid, _, where = line.partition("\t")
        if ppid.strip() == str(pid):
            return where
    return None


def kill_tree(pid):
    if IS_WINDOWS:
        # /F: claude はコンソールのプロセスで、/F なしの終了要求には応じないことがある
        # /T: 子プロセス (claude、MCP サーバーなど) も一緒に終わらせる (親には広がらない)
        r = subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], capture_output=True, text=True, errors="replace")
        return r.returncode == 0, (r.stdout + r.stderr).strip()
    try:
        os.kill(pid, signal.SIGTERM)
        return True, ""
    except OSError as e:
        return False, str(e)


def end_with_code0(pid):
    """Windows で、プロセスを終了コード 0 で終わらせる。

    Windows Terminal の closeOnExit の既定 ("automatic" → 直接起動したタブは "graceful") は、
    正常終了 (終了コード 0) のときだけタブを閉じる。taskkill /F は終了コード 1 になり、
    タブが「プロセスが終了しました」と表示して残るため、TerminateProcess で 0 を渡す。
    """
    import ctypes
    k32 = ctypes.WinDLL("kernel32", use_last_error=True)
    k32.OpenProcess.restype = ctypes.c_void_p
    h = k32.OpenProcess(0x0001, False, int(pid))  # PROCESS_TERMINATE
    if not h:
        return False, f"OpenProcess に失敗 (error {ctypes.get_last_error()})"
    try:
        if not k32.TerminateProcess(ctypes.c_void_p(h), 0):
            return False, f"TerminateProcess に失敗 (error {ctypes.get_last_error()})"
        return True, ""
    finally:
        k32.CloseHandle(ctypes.c_void_p(h))


def plan(pid, keep_window):
    """終了するプロセスと、その場所 (tmux / terminal / other) と、閉じるものの説明を返す。"""
    me = proc_info(pid)
    parent = proc_info(me[1]) if me else None
    if keep_window or not parent or parent[0] not in SHELLS:
        return pid, "other", "-"
    shell_pid = me[1]
    pane = tmux_pane_of(shell_pid) if os.environ.get("TMUX") else None
    if pane:
        return shell_pid, "tmux", f"tmux {pane}"
    grand = proc_info(parent[1])
    if grand and grand[0] in TERMINALS:
        return shell_pid, "terminal", f"{grand[0]} のタブ ({parent[0]})"
    return pid, "other", "-"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="+")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--keep-window", action="store_true", help="claude だけを終了し、ウィンドウやタブは残す")
    args = ap.parse_args()

    sessions = load_sessions()
    ok = True
    for name in args.names:
        # 同じ名前の記録が複数あれば、動いているものだけを、更新の新しい順に見る
        cands = sorted((s for s in sessions if s["name"] == name), key=lambda s: s.get("updatedAt", 0), reverse=True)
        target = None
        for s in cands:
            info = proc_info(int(s["pid"]))
            if info:
                target = (s, info[0])
                break
        if not target:
            print(f"not found: {name}")
            ok = False
            continue
        s, pname = target
        pid = int(s["pid"])
        desc = f"pid={pid} cwd={s.get('cwd', '')}"
        if "claude" not in pname and "node" not in pname:
            # PID が別のプロセスに使い回されている
            print(f"skipped: {name} {desc} (process={pname} は claude ではない)")
            ok = False
            continue
        if s.get("sessionId") == os.environ.get("CLAUDE_CODE_SESSION_ID"):
            print(f"skipped: {name} {desc} (このスクリプトを実行しているセッション自身)")
            ok = False
            continue
        kill_pid, where, closes = plan(pid, args.keep_window)
        desc = f"pid={pid} where={where} closed={closes} cwd={s.get('cwd', '')}"
        if args.dry_run:
            print(f"would kill: {name} {desc}")
            continue
        if where == "terminal" and IS_WINDOWS:
            # 先に claude (と子プロセス) を終わらせ、残ったシェルを終了コード 0 で終わらせてタブを閉じる
            done, msg = kill_tree(pid)
            if done:
                done, msg = end_with_code0(kill_pid)
        else:
            done, msg = kill_tree(kill_pid)
        if done and where == "tmux":
            time.sleep(1)
            if tmux_pane_of(kill_pid):
                desc += " (ペインが残っている)"
        if done:
            print(f"killed: {name} {desc}")
        else:
            print(f"failed: {name} {desc} ({msg})")
            ok = False
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
