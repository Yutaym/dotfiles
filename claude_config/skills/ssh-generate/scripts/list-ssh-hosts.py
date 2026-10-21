"""~/.ssh/config から、ssh の接続先に使える Host の別名を一覧にする。

使い方:
    uv run --no-project python list-ssh-hosts.py [--config <パス>] [--names]

- Include も読む (相対パスは ~/.ssh からの相対、ワイルドカード可)。
- `*` `?` `!` を含むパターン (Host * など) は、接続先として選べないので除く。
- HostName / User / Port は、その Host ブロックの中に書かれた値だけを表示する
  (Host * などほかのブロックから当たる値は反映しない)。
- Host の行のすぐ次の行に `# not suggest` と書かれた Host は出さない。
- --names を付けると、別名だけを 1 行に 1 つ出す。
"""

import argparse
import glob
import os
import shlex
import sys

MAX_DEPTH = 16


def split_line(line):
    """ "Keyword value..." / "Keyword=value" を (keyword 小文字, [値...]) に分ける"""
    line = line.strip()
    if not line or line.startswith("#"):
        return None, []
    # Keyword=value の形にも対応する
    parts = line.split(None, 1)
    if "=" in parts[0]:
        key, _, rest = line.partition("=")
    else:
        key, rest = parts[0], parts[1] if len(parts) > 1 else ""
    try:
        values = shlex.split(rest, comments=True)
    except ValueError:
        values = rest.split()
    return key.strip().lower(), values


def is_not_suggest(line):
    line = line.strip()
    return line.startswith("#") and line.lstrip("#").strip().lower() == "not suggest"


def expand_include(pattern, ssh_dir):
    pattern = os.path.expanduser(pattern)
    if not os.path.isabs(pattern):
        pattern = os.path.join(ssh_dir, pattern)
    return sorted(glob.glob(pattern))


def parse(path, ssh_dir, hosts, seen, depth=0):
    if depth > MAX_DEPTH:
        return
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return
    current = []  # 今の Host ブロックの別名 (Match ブロックの中では空)
    prev_host = []  # 直前の行が Host の行なら、その別名
    for raw in lines:
        # Host の行のすぐ次の行の "# not suggest" は、その Host を一覧から隠す印
        if prev_host and is_not_suggest(raw):
            for name in prev_host:
                seen[name]["hidden"] = True
        prev_host = []
        key, values = split_line(raw)
        if key is None:
            continue
        if key == "host":
            current = []
            for name in values:
                if any(c in name for c in "*?!"):
                    continue
                if name not in seen:
                    seen[name] = {"host": name, "hostname": "", "user": "", "port": "", "file": path}
                    hosts.append(seen[name])
                current.append(name)
            prev_host = current
        elif key == "match":
            current = []
        elif key == "include":
            for pattern in values:
                for inc in expand_include(pattern, ssh_dir):
                    parse(inc, ssh_dir, hosts, seen, depth + 1)
        elif key in ("hostname", "user", "port") and values:
            for name in current:
                # ssh と同じく、最初に書かれた値を使う
                if not seen[name][key]:
                    seen[name][key] = values[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default=os.path.join(os.path.expanduser("~"), ".ssh", "config"))
    ap.add_argument("--names", action="store_true", help="別名だけを出す")
    args = ap.parse_args()

    if not os.path.isfile(args.config):
        print(f"ssh の設定ファイルがありません: {args.config}", file=sys.stderr)
        return 1

    hosts, seen = [], {}
    parse(args.config, os.path.dirname(os.path.abspath(args.config)), hosts, seen)
    hosts = [h for h in hosts if not h.get("hidden")]

    if args.names:
        for h in hosts:
            print(h["host"])
        return 0

    if not hosts:
        print("接続先に使える Host がありません")
        return 0
    rows = [("No", "Host", "HostName", "User", "Port")]
    for i, h in enumerate(hosts, 1):
        rows.append((str(i), h["host"], h["hostname"] or "-", h["user"] or "-", h["port"] or "-"))
    widths = [max(len(r[c]) for r in rows) for c in range(len(rows[0]))]
    for r in rows:
        print("  ".join(v.ljust(w) for v, w in zip(r, widths)).rstrip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
