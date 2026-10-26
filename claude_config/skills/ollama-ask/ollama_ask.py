#!/usr/bin/env python3
"""別の PC の Ollama にプロンプトを送り、答えを標準出力に出す（標準ライブラリだけで動く）。"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

DEFAULT_URL = os.environ.get("CLAUDE_OLLAMA_URL", "http://yutapc:11434")
DEFAULT_MODEL = "qwen3.5:9b"


def request(url, path, body=None, timeout=60):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url.rstrip("/") + path, data=data,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def main():
    # Windows の既定のコードページでも日本語が化けないようにする
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    sys.stdin.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("prompt", nargs="?", help="プロンプト（標準入力があれば後ろに付ける）")
    p.add_argument("-m", "--model", default=DEFAULT_MODEL)
    p.add_argument("-s", "--system", help="システムプロンプト")
    p.add_argument("-f", "--file", action="append", default=[], help="プロンプトの後ろに付けるファイル（複数可）")
    p.add_argument("--think", action="store_true", help="思考を有効にする（遅くなる）")
    p.add_argument("--json", action="store_true", help="JSON で答えさせる（format=json）")
    p.add_argument("--num-ctx", type=int, help="context の長さ（既定はモデルの設定。多くは 4096）")
    p.add_argument("--keep-alive", help="答えたあとモデルを読み込んだままにする時間（例: 30m。既定は Ollama の 5 分）")
    p.add_argument("--timeout", type=int, default=300)
    p.add_argument("--url", default=DEFAULT_URL)
    p.add_argument("--list", action="store_true", help="モデルの一覧と読み込み中のモデルを出す")
    a = p.parse_args()

    try:
        if a.list:
            loaded = {m["name"]: m for m in request(a.url, "/api/ps")["models"]}
            for m in request(a.url, "/api/tags")["models"]:
                d = m["details"]
                mark = " (読み込み中)" if m["name"] in loaded else ""
                print(f'{m["name"]}\t{d.get("parameter_size")}\t{m["size"]/1e9:.1f}GB{mark}')
            return

        # 引数と標準入力の両方があれば、引数（指示）の後ろに標準入力（材料）を付ける
        piped = sys.stdin.read() if not sys.stdin.isatty() else ""
        prompt = "\n\n".join(x for x in (a.prompt, piped) if x)
        for path in a.file:
            with open(path, encoding="utf-8", errors="replace") as fh:
                prompt += f"\n\n--- {os.path.basename(path)} ---\n{fh.read()}"
        messages = ([{"role": "system", "content": a.system}] if a.system else []) + \
                   [{"role": "user", "content": prompt}]
        body = {"model": a.model, "messages": messages, "stream": False, "think": a.think}
        if a.keep_alive:
            body["keep_alive"] = a.keep_alive
        if a.json:
            body["format"] = "json"
        if a.num_ctx:
            body["options"] = {"num_ctx": a.num_ctx}
        res = request(a.url, "/api/chat", body, timeout=a.timeout)
    except urllib.error.HTTPError as e:
        sys.exit(f"ollama-ask: HTTP {e.code}: {e.read().decode(errors='replace')}")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        sys.exit(f"ollama-ask: {a.url} に接続できない: {e}")

    print(res["message"]["content"])
    n_in, n_out = res.get("prompt_eval_count", 0), res.get("eval_count", 0)
    print(f"[{a.model} 入力 {n_in} / 出力 {n_out} トークン, {res.get('total_duration', 0)/1e9:.1f} 秒"
          f"（うち読み込み {res.get('load_duration', 0)/1e9:.1f} 秒）]",
          file=sys.stderr)
    if a.num_ctx is None and n_in >= 4000:
        print("[注意: 入力が 4096 トークン近い。切り詰められている可能性があるので --num-ctx を付ける]", file=sys.stderr)


if __name__ == "__main__":
    main()
