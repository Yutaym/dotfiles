#!/usr/bin/env python3
"""
VSCode拡張機能のビューIDを一覧表示する (Linux/WSL用)

keybindings.jsonのwhen句で使えるコンテキストキーを出力する。
  activeViewlet   : サイドバーコンテナがアクティブな時の値
  activePanel     : パネルコンテナがアクティブな時の値
  focusedView     : 個別ビューにフォーカスがある時の値

WSL環境では ~/.vscode/extensions (Linux側) を参照する。
Windowsホスト側の拡張機能を見たい場合は --win オプションを使う。

Usage:
  vscode_view_ids.sh [vscode|cursor] [--win]
    vscode|cursor : 対象エディタ (省略時は vscode)
    --win         : WSLからWindowsホストの拡張機能ディレクトリを参照
"""

import json
import os
import sys
import subprocess
from pathlib import Path

CYAN    = "\033[96m"
YELLOW  = "\033[93m"
GRAY    = "\033[90m"
GREEN   = "\033[92m"
RESET   = "\033[0m"

LOCATION_KEY = {
    "activitybar":      "activeViewlet  ",
    "panel":            "activePanel    ",
    "secondarySidebar": "activeAuxiliary",
}

def get_windows_home():
    """WSL環境でWindowsホームディレクトリのパスを取得する"""
    try:
        result = subprocess.run(
            ["wslpath", "-u", os.environ.get("USERPROFILE", "")],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip())
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    # フォールバック: /mnt/c/Users/<username>
    win_user = os.environ.get("LOGNAME") or os.environ.get("USER", "")
    return Path(f"/mnt/c/Users/{win_user}")

def main():
    args = sys.argv[1:]
    use_win = "--win" in args
    args = [a for a in args if a != "--win"]

    editor = args[0] if args else "vscode"
    if editor not in ("vscode", "cursor"):
        print(f"Usage: {sys.argv[0]} [vscode|cursor] [--win]", file=sys.stderr)
        sys.exit(1)

    if use_win:
        base = get_windows_home()
        ext_dir = base / f"AppData/Roaming/Code/User/extensions" if editor == "vscode" \
                  else base / f".{editor}/extensions"
        # VSCodeのWindowsインストール時の拡張機能パス
        ext_dir = base / f".{editor}/extensions"
    else:
        ext_dir = Path.home() / f".{editor}" / "extensions"

    if not ext_dir.exists():
        print(f"拡張機能ディレクトリが見つかりません: {ext_dir}", file=sys.stderr)
        sys.exit(1)

    containers = []
    views = []

    for pkg_path in sorted(ext_dir.glob("*/package.json")):
        try:
            pkg = json.loads(pkg_path.read_text(encoding="utf-8", errors="ignore"))
        except (json.JSONDecodeError, OSError):
            continue

        ext_name = pkg.get("name", pkg_path.parent.name)
        contributes = pkg.get("contributes", {})

        for location, items in contributes.get("viewsContainers", {}).items():
            for item in (items if isinstance(items, list) else []):
                if item.get("id"):
                    containers.append({
                        "ext": ext_name,
                        "location": location,
                        "id": item["id"],
                        "title": item.get("title", ""),
                    })

        for container, items in contributes.get("views", {}).items():
            for item in (items if isinstance(items, list) else []):
                if item.get("id"):
                    views.append({
                        "ext": ext_name,
                        "container": container,
                        "id": item["id"],
                        "title": item.get("name", ""),
                    })

    # --- activeViewlet / activePanel 出力 ---
    print(f"\n{CYAN}=== activeViewlet / activePanel (コンテナID) ==={RESET}\n")
    for c in sorted(containers, key=lambda x: (x["ext"], x["location"], x["id"])):
        key = LOCATION_KEY.get(c["location"], c["location"].ljust(15))
        ctx = f"workbench.view.extension.{c['id']}"
        print(f"{YELLOW}[{c['ext']}] {c['title']}{RESET}")
        print(f"  {key} == '{ctx}'")

    # --- focusedView 出力 ---
    print(f"\n{CYAN}=== focusedView (個別ビューID) ==={RESET}\n")
    for v in sorted(views, key=lambda x: (x["ext"], x["container"], x["id"])):
        print(f"  focusedView == '{v['id']}'"
              f"{GRAY}   # [{v['ext']}] in:{v['container']}{RESET}")

    print(f"\n{GREEN}完了: {len(containers)} コンテナ, {len(views)} ビュー{RESET}")

if __name__ == "__main__":
    main()
