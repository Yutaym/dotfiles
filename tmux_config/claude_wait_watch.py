"""返事待ちの Claude Code のセッションがあるウィンドウを、tmux / psmux のユーザーオプションに書き続ける。

.tmux.conf の run-shell -b から起動し、tmux のサーバーが止まるまで動く。同時に 1 つだけ動く（ロックファイル）。

判定は session-overview スキルの judge_waiting をそのまま使う（session-overview の表・session-observation の監視画面と同じ）:
  - sessions/*.json の status が waiting / requires_action（ツールの許可などで止まっている）
  - idle で、24 時間以内の最後の返答の最後の行が「❓ 返事待ち: …」

書き出すオプション（値が変わったときだけ書く）:
  @claude_wait_ids   " 0:3 0:6 "   … 照らし合わせ用（window-status-format でタブを赤くする）
  @claude_wait       "❓ 3·6 "      … 表示用（status-right の先頭。0 件なら空）
メニュー（Prefix + ?）用に ~/.claude/state/claude-wait-menu.conf も書く（source-file で読む）。
"""
import importlib.util
import os
import subprocess
import sys
import time

INTERVAL = 5          # 調べる間隔（秒）
PROCS_TTL = 60        # プロセス一覧を取り直す間隔（秒）。Windows は 1 回 1 秒ほどかかるため
QUIT_AFTER = 3        # tmux のサーバーに続けてつながらなかったら終わる回数

HOME = os.path.expanduser("~")
SKILL = os.path.join(HOME, ".claude", "skills", "session-overview", "scripts", "session-overview.py")
STATE_DIR = os.path.join(HOME, ".claude", "state")
LOCK = os.path.join(STATE_DIR, "claude-wait-watch.lock")
MENU = os.path.join(STATE_DIR, "claude-wait-menu.conf")


def load_overview():
    spec = importlib.util.spec_from_file_location("session_overview", SKILL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def lock():
    """ロックを取る。ほかに動いていれば None。ファイルは開いたまま持ち続ける。"""
    os.makedirs(STATE_DIR, exist_ok=True)
    f = open(LOCK, "a+")
    try:
        if sys.platform == "win32":
            import msvcrt
            f.seek(0)
            msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl
            fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        f.close()
        return None
    return f


def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True, encoding="utf-8", errors="replace")


class Transcripts:
    """会話記録の最後の返答を、ファイルが変わったときだけ読み直す。"""

    def __init__(self, ov):
        self.ov, self.cache = ov, {}

    def get(self, sid):
        import glob
        paths = glob.glob(os.path.join(self.ov.CONFIG_DIR, "projects", "*", f"{sid}.jsonl"))
        if not paths:
            return None, None
        path = paths[0]
        try:
            st = os.stat(path)
        except OSError:
            return None, None
        key = (st.st_mtime_ns, st.st_size)
        hit = self.cache.get(path)
        if not hit or hit[0] != key:
            _, last_reply, _, last_time = self.ov.read_transcript(path)
            hit = (key, last_reply, last_time)
            self.cache[path] = hit
        return hit[1], hit[2]


def waiting_windows(ov, procs, panes, transcripts):
    """返事待ちのセッションがある tmux のウィンドウを [(セッション:番号, ウィンドウ名)] で返す（番号順）。"""
    found = {}
    for s in ov.load_sessions(set()):
        if not ov.is_alive(s, procs):
            continue
        pid = int(s.get("pid") or 0)
        me = procs.get(pid)
        if not me or me[1] not in panes:
            continue  # tmux の外のセッション
        where = panes[me[1]]  # "セッション:番号 ウィンドウ名"
        target, _, wname = where.partition(" ")
        item = {"status": s.get("status"), "statusUpdatedAt": s.get("statusUpdatedAt") or s.get("updatedAt"),
                "lastTime": None, "lastReply": None}
        if item["status"] == "idle":
            last_reply, last_time = transcripts.get(s.get("sessionId", ""))
            item["lastTime"] = last_time
            if last_reply:
                item["lastReply"] = {"time": last_reply[0], "text": last_reply[1],
                                     "tail": ov.tail_for_judging(last_reply[1])}
        if ov.judge_waiting(item):
            found[target] = wname
    def order(t):
        sess, _, idx = t.rpartition(":")
        return (sess, int(idx) if idx.isdigit() else 0)
    return [(t, found[t]) for t in sorted(found, key=order)]


def label(windows):
    if not windows:
        return ""
    sessions = {t.rpartition(":")[0] for t, _ in windows}
    names = [t.rpartition(":")[2] if len(sessions) == 1 else t for t, _ in windows]
    # 色と三角は .tmux.conf の @wait_seg で付ける（psmux は三角あり、tmux は四角）
    return "❓ " + "·".join(names)


def menu_conf(windows):
    if not windows:
        return "display-message '返事待ちのウィンドウはありません'\n"
    q = lambda s: "'" + s.replace("'", "") + "'"
    items = []
    for i, (t, wname) in enumerate(windows):
        key = str(i + 1) if i < 9 else ""
        items.append(f"{q(t + ' ' + wname)} {q(key)} {q('select-window -t ' + t)}")
    return "display-menu -T '❓ 返事待ち' " + " ".join(items) + "\n"


def main():
    held = lock()
    if not held:
        return  # ほかに動いている
    ov = load_overview()
    transcripts = Transcripts(ov)
    procs, procs_at = {}, 0.0
    last = (None, None)
    misses = 0
    while True:
        if tmux("display", "-p", "ok").returncode != 0:
            misses += 1
            if misses >= QUIT_AFTER:
                return
            time.sleep(INTERVAL)
            continue
        misses = 0
        try:
            panes = ov.tmux_panes()
            pids = [int(s.get("pid") or 0) for s in ov.load_sessions(set())]
            if time.time() - procs_at >= PROCS_TTL or any(p and p not in procs for p in pids):
                procs, procs_at = ov.process_table(), time.time()
            windows = waiting_windows(ov, procs, panes, transcripts)
            ids = " " + " ".join(t for t, _ in windows) + " " if windows else ""
            text = label(windows)
            if (ids, text) != last:
                tmux("set", "-g", "@claude_wait_ids", ids)
                tmux("set", "-g", "@claude_wait", text)
                last = (ids, text)
            conf = menu_conf(windows)
            try:
                with open(MENU, encoding="utf-8") as f:
                    same = f.read() == conf
            except OSError:
                same = False
            if not same:
                with open(MENU, "w", encoding="utf-8", newline="\n") as f:
                    f.write(conf)
        except Exception as e:  # 1 回の失敗で止まらない
            print(f"claude_wait_watch: {e}", file=sys.stderr)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
