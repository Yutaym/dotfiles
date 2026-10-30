"""Claude Code のセッションを、名前を指定して終了する。開いていたウィンドウも閉じる。

~/.claude/sessions/<pid>.json からセッション名に合うプロセスを探し、
そのプロセスがまだ動いていて claude のプロセスであることを確かめてから終了する。

どこで動いているかを親プロセスから判断し、終了するものを変える。
- tmux: claude の親 (ペインのシェル) を tmux の #{pane_pid} で探し、そのシェルごと終了する。
        ペインの最初のプロセスが終わるとペインが閉じ、最後のペインならウィンドウも閉じる。
        psmux は -t の @ID / %ID を取り違えることがあるので、-t は使わずにプロセスで閉じる。
- ターミナル: claude の親がシェルで、その親がターミナル (Windows Terminal など) なら、シェルごと終了してタブを閉じる。
- それ以外 (VS Code など): claude だけを終了する。
        ただし、親が tmux のペインのシェルなら ($TMUX がない ssh 越し。session-ssh の接続先)、そのシェルも終了する。

このスクリプトを実行しているセッション自身は、tmux の中のときだけ、ほかのセッションを終了したあとに最後に終了する。
先に同じ tmux のセッションの一番小さい番号のウィンドウ (自分のウィンドウが閉じて番号が詰まったあとの 1 番) に
切り替えてから終了する。何もしないで閉じると、直前に見ていたウィンドウに移るため。
終了したあとは何も出力できないので、自分の行は終了する前に出す。

使い方:
    uv run --no-project python kill-session.py <セッション名> [<セッション名> ...] [--dry-run] [--keep-window]

出力 (1 セッションにつき 1 行):
    killed: <名前> pid=<PID> where=<tmux|terminal|other> closed=<閉じたもの> cwd=<フォルダ>
    killing self: <名前> ... switch=<移る先のウィンドウ>  (自分自身。終了する直前に出す)
    would kill: ...        (--dry-run のとき。自分自身なら switch= も付く)
    not found: <名前>      (動いているプロセスが見つからない)
    skipped: <名前> ...    (claude のプロセスではない、tmux の外で自分自身、など)
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


def switch_target(pane):
    """自分のウィンドウを閉じたあとに見せるウィンドウ ('セッション:番号') を返す。切り替えが要らなければ None。

    pane は tmux_pane_of の戻り値 ('セッション:ウィンドウ番号 ウィンドウ名')。
    自分のウィンドウ以外で一番小さい番号のウィンドウを選ぶ。自分が 1 番なら 2 番を選び、
    閉じたあとに番号が詰まって 1 番になる。ペインがほかにもあって自分のウィンドウが残るなら、
    自分のウィンドウも候補に入れる。-t は psmux で確実な「セッション名:番号」で指定する。
    """
    me = pane.split(" ", 1)[0]
    session = me.rsplit(":", 1)[0]
    r = subprocess.run(
        ["tmux", "list-windows", "-t", session, "-F", "#{window_index}\t#{window_panes}"],
        capture_output=True, text=True, errors="replace",
    )
    idx = []
    for line in r.stdout.splitlines():
        i, _, panes = line.partition("\t")
        target = f"{session}:{i.strip()}"
        if target != me or panes.strip() not in ("", "1"):
            idx.append(int(i))
    if not idx:
        return None  # 最後のウィンドウ (tmux のセッションごと閉じる)
    target = f"{session}:{min(idx)}"
    return None if target == me else target


def kill_tree(pid):
    if IS_WINDOWS:
        # /F: claude はコンソールのプロセスで、/F なしの終了要求には応じないことがある
        # /T: 子プロセス (claude、MCP サーバーなど) も一緒に終わらせる (親には広がらない)
        r = subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], capture_output=True, text=True, errors="replace")
        return r.returncode == 0, (r.stdout + r.stderr).strip()
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return True, ""  # もう終わっている
    except OSError as e:
        return False, str(e)
    # Ctrl+Z で suspend されたプロセスは、再開するまで SIGTERM で終わらないので、続けて再開させる。
    # 端末がまだあると、再開しても裏のジョブとして端末に触れたところで (SIGTTOU で) また止まるので、
    # しばらく待っても止まったままなら強制終了する
    try:
        os.kill(pid, signal.SIGCONT)
        for _ in range(10):
            time.sleep(0.3)
            if not is_stopped(pid):
                return True, ""
        os.kill(pid, signal.SIGKILL)
    except OSError:
        pass
    return True, ""


def is_stopped(pid):
    """Ctrl+Z などで止まっていれば True (動いていない・Windows では False)。"""
    if IS_WINDOWS:
        return False
    r = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)], capture_output=True, text=True)
    return r.stdout.strip().startswith("T")


def pane_shell(pid):
    """claude の親が tmux のペインのシェルなら、そのシェルの PID を返す ($TMUX がない ssh 越しでも見つける)。

    session-ssh は、ペインの対話シェルに "claude ...; exit" を打ち込んで起動する。Ctrl+Z で suspend すると
    zsh は行の残り (exit) を捨てるので、fg で戻したあとも含め、claude が終わってもシェルとペインが残る。
    """
    if IS_WINDOWS:
        return None
    me = proc_info(pid)
    parent = proc_info(me[1]) if me else None
    # ログインシェルは "-zsh" のように - が付く
    if not parent or parent[0].lstrip("-") not in SHELLS:
        return None
    grand = proc_info(parent[1])
    # tmux のサーバーは、Linux では "tmux: server" と出ることがある
    return me[1] if grand and grand[0].startswith("tmux") else None


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
    me = None
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
            # 自分を先に終わらせると、残りのセッションを終了できないので、最後に回す
            me = (name, s, pid)
            continue
        kill_pid, where, closes = plan(pid, args.keep_window)
        shell = pane_shell(pid) if where == "other" and not args.keep_window else None
        if shell:
            closes = "tmux のペイン (ペインのシェルも終了)"
        desc = f"pid={pid} where={where} closed={closes} cwd={s.get('cwd', '')}"
        if args.dry_run:
            print(f"would kill: {name} {desc}")
            continue
        if where == "terminal" and IS_WINDOWS:
            # 先に claude (と子プロセス) を終わらせ、残ったシェルを終了コード 0 で終わらせてタブを閉じる
            done, msg = kill_tree(pid)
            if done:
                done, msg = end_with_code0(kill_pid)
        elif shell:
            # ペインのシェルは、端末が閉じたときと同じ SIGHUP で終わらせる (対話シェルは SIGTERM を無視する)。
            # suspend されているときはシェルを先に終わらせる。シェルは止まっているジョブ (claude) にも SIGHUP を送り、
            # ペインが閉じて端末がなくなるので、claude は再開してもまた止まることがない。
            # 動いているときは、claude を先に終わらせてきちんと閉じさせる
            stopped = is_stopped(pid)
            if not stopped:
                done, msg = kill_tree(kill_pid)
                time.sleep(1)
            try:
                os.kill(shell, signal.SIGHUP)
            except ProcessLookupError:
                pass  # "; exit" でもう終わっている
            except OSError as e:
                desc += f" (シェルを終了できなかった: {e})"
            if stopped:
                time.sleep(1)
                done, msg = kill_tree(kill_pid)
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
    if me:
        ok = kill_self(*me, args) and ok
    sys.exit(0 if ok else 1)


def kill_self(name, s, pid, args):
    """このスクリプトを実行しているセッション自身を終了する。tmux の中のときだけ。

    先に 1 番のウィンドウ (switch_target) に切り替えてから、ペインのシェルごと終了する。
    終了したあとは出力できないので、結果の行は終了する前に出す。
    """
    kill_pid, where, closes = plan(pid, args.keep_window)
    if where != "tmux":
        print(f"skipped: {name} pid={pid} cwd={s.get('cwd', '')} (このスクリプトを実行しているセッション自身。tmux の外では終了しない)")
        return False
    target = switch_target(closes.removeprefix("tmux "))
    desc = f"pid={pid} where={where} closed={closes} switch={target or '-'} cwd={s.get('cwd', '')}"
    if args.dry_run:
        print(f"would kill: {name} {desc}")
        return True
    print(f"killing self: {name} {desc}", flush=True)
    if target:
        subprocess.run(["tmux", "select-window", "-t", target], capture_output=True)
    done, msg = kill_tree(kill_pid)
    # 終了できても、Windows ではこのプロセスが taskkill から外れて最後まで動くことがある (出力は誰にも届かない)
    if not done:
        print(f"failed: {name} {desc} ({msg})")
    return done


if __name__ == "__main__":
    main()
