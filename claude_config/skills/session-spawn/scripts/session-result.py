"""同じマシンで動いている Claude Code のセッションの状態と、最後の返答を表示する。

使い方:
    uv run --no-project python session-result.py <セッション名> [--count N]

セッション名 (ListAgents に出る名前) から ~/.claude/sessions/<pid>.json を探してセッション ID を調べ、
~/.claude/projects/*/<セッションID>.jsonl (会話の記録) から、テキストを含む最後の返答を N 件表示する。

注意: sessions/*.json と会話の記録の形式は Claude Code の内部形式で、公式には
「バージョンによって変わる」とされている。読めなくなったら、相手のセッションに
SendMessage で結果を送り返してもらう方法に切り替える。
"""

import argparse
import glob
import json
import os
import sys

CONFIG_DIR = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")


def find_session(name):
    best = None
    for path in glob.glob(os.path.join(CONFIG_DIR, "sessions", "*.json")):
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError):
            continue
        if data.get("name") != name:
            continue
        if best is None or data.get("updatedAt", 0) > best.get("updatedAt", 0):
            best = data
    return best


def last_replies(transcript, count):
    replies = []
    with open(transcript, encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("type") != "assistant":
                continue
            content = entry.get("message", {}).get("content", [])
            if not isinstance(content, list):
                continue
            text = "\n".join(c.get("text", "") for c in content if c.get("type") == "text").strip()
            if text:
                replies.append((entry.get("timestamp", ""), text))
    return replies[-count:]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name")
    parser.add_argument("--count", type=int, default=1)
    args = parser.parse_args()

    session = find_session(args.name)
    if session is None:
        sys.exit(f"セッション {args.name} が {CONFIG_DIR}/sessions に見つかりません (終了したか、名前が違う)")

    sid = session.get("sessionId")
    print(f"name={args.name} status={session.get('status')} cwd={session.get('cwd')} sessionId={sid}")

    transcripts = glob.glob(os.path.join(CONFIG_DIR, "projects", "*", f"{sid}.jsonl"))
    if not transcripts:
        sys.exit("会話の記録が見つかりません (記録の保存がオフの子セッションの可能性がある)")
    print(f"transcript={transcripts[0]}")

    for timestamp, text in last_replies(transcripts[0], args.count):
        print(f"\n----- {timestamp} -----\n{text}")


if __name__ == "__main__":
    main()
