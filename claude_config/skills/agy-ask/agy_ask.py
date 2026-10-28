#!/usr/bin/env python3
"""Antigravity CLI（agy）に作業を渡す。標準ライブラリだけで動く。

  agy_ask.py "質問"                      # 1 回だけ答えさせる（読み取り専用の plan モード）
  agy_ask.py -f a.py -f b.md "指示"      # ファイルの中身を指示に付ける
  cat log.txt | agy_ask.py "要約して"    # 標準入力は指示の後ろに付く
  agy_ask.py --models                    # 使えるモデルの一覧
  agy_ask.py --check                     # 使用リミット（5 時間・週）を見て、作業を外に回すか判定する
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

RATE_FILE = Path.home() / ".claude" / "cache" / "rate_limits.json"
# Windows のコマンドラインは約 32K 文字まで。指示とファイルの合計がこれを超える場合は断る
MAX_PROMPT_CHARS = 24000
STALE_SEC = 600


def find_agy():
    p = shutil.which("agy")
    if p:
        return p
    candidates = [Path.home() / ".local" / "bin" / "agy"]
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidates.insert(0, Path(local) / "agy" / "bin" / "agy.exe")
    for c in candidates:
        if c.exists():
            return str(c)
    sys.exit("agy が見つかりません。claude_config/install_agy.sh（Windows は install_agy.ps1）で導入してください")


def check(threshold):
    """~/.claude/cache/rate_limits.json（statusline.mjs が書く）を読み、threshold 以上なら offload=true にする"""
    out = {"threshold": threshold, "offload": False}
    try:
        d = json.loads(RATE_FILE.read_text(encoding="utf-8"))
    except Exception as e:
        out["reason"] = f"使用リミットのファイルを読めない（{type(e).__name__}）。判定できないので offload=false"
        print(json.dumps(out, ensure_ascii=False))
        return
    age = time.time() - d.get("updated_at", 0)
    out["age_sec"] = round(age)
    out["stale"] = age > STALE_SEC
    hit = []
    for key in ("five_hour", "seven_day"):
        w = d.get(key) or {}
        p = w.get("used_percentage")
        if p is None:
            continue
        # 枠がリセットされた後の古い値は無視する
        if w.get("resets_at") and w["resets_at"] < time.time():
            out[key] = "reset"
            continue
        out[key] = p
        if p >= threshold:
            hit.append(key)
    out["offload"] = bool(hit)
    out["reason"] = ("しきい値以上: " + ", ".join(hit)) if hit else "しきい値未満"
    if out["stale"]:
        out["reason"] += "（ファイルが古いので参考値）"
    print(json.dumps(out, ensure_ascii=False))


def main():
    ap = argparse.ArgumentParser(description="Antigravity CLI（agy）に作業を渡す")
    ap.add_argument("prompt", nargs="?", help="頼む内容")
    ap.add_argument("-f", "--file", action="append", default=[], help="指示に付けるファイル（複数可）")
    ap.add_argument("-m", "--model", help="モデル（--models で一覧）。省略時は agy の既定")
    ap.add_argument("--effort", choices=["low", "medium", "high", "xhigh", "max"], help="思考の深さ")
    ap.add_argument("--timeout", type=int, default=300, help="待つ秒数（既定 300）")
    ap.add_argument("--json", action="store_true", help="agy の JSON（応答・トークン数）をそのまま出す")
    ap.add_argument("--models", action="store_true", help="使えるモデルの一覧を出して終わる")
    ap.add_argument("--check", action="store_true", help="使用リミットを見て、外に回すか JSON で出して終わる")
    ap.add_argument("--threshold", type=float, default=80, help="--check のしきい値（%%、既定 80）")
    a = ap.parse_args()

    if a.check:
        check(a.threshold)
        return
    agy = find_agy()
    if a.models:
        sys.exit(subprocess.call([agy, "models"]))
    if not a.prompt:
        ap.error("prompt が必要です")

    prompt = a.prompt
    for f in a.file:
        p = Path(f)
        prompt += f"\n\n--- ファイル: {p.name} ---\n{p.read_text(encoding='utf-8', errors='replace')}"
    if not sys.stdin.isatty():
        data = sys.stdin.read()
        if data:
            prompt += f"\n\n--- 標準入力 ---\n{data}"
    if len(prompt) > MAX_PROMPT_CHARS:
        sys.exit(f"指示とファイルの合計が {len(prompt)} 文字で、上限 {MAX_PROMPT_CHARS} 文字を超えています。分けて渡してください")

    # -p は直後の引数を指示として取る（値のないオプションを後ろに置くと、それが指示と誤認される）ので、-p は最後に置く
    # plan モード（読み取り専用）で、空の一時フォルダの中で動かす。ツールの許可を求められる作業は黙って拒否される
    cmd = [agy, "--mode", "plan", "--output-format", "json"]
    if a.model:
        cmd += ["--model", a.model]
    if a.effort:
        cmd += ["--effort", a.effort]
    cmd += ["-p", prompt]
    with tempfile.TemporaryDirectory(prefix="agy-ask-") as cwd:
        try:
            r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8", timeout=a.timeout)
        except subprocess.TimeoutExpired:
            sys.exit(f"{a.timeout} 秒で終わりませんでした")
    out = r.stdout.strip()
    try:
        d = json.loads(out)
    except Exception:
        print(out)
        print(r.stderr.strip(), file=sys.stderr)
        sys.exit(r.returncode or 1)
    if a.json:
        print(json.dumps(d, ensure_ascii=False))
        return
    if d.get("status") != "SUCCESS":
        print(f"status={d.get('status')} {d.get('error', '')}".strip(), file=sys.stderr)
        sys.exit(1)
    print(d.get("response", "").rstrip())
    u = d.get("usage", {})
    print(f"[agy] {d.get('duration_seconds', 0):.1f}s tokens={u.get('total_tokens')}", file=sys.stderr)


if __name__ == "__main__":
    main()
