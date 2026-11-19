#!/usr/bin/env python3
"""90_Wiki（WIKI_DIR）と vault のノートをまとめて探し、候補を点数順に短く返す（wiki-search スキルの道具）。

探すもの（--scope all のとき）:
  - 90_Wiki の各ファイル: ファイル名・frontmatter（type・tags）・最初の見出し・フォルダの INDEX.md の説明・本文
  - private/: 候補には出すが、本文の抜き出しは出さない（中身は必要なときにファイルを開く）
  - vault-notes/（vault のノートの目次、自動生成）: 1 行 1 ノートの行
  - vault の 90_Wiki 以外のノート: ファイル名・本文
外すもの: .git/ .obsidian/ .trash/ .sync-*（同期の管理ファイル）

使い方:
  uv run --no-project python wiki_search.py <語> [<語> ...] [--type T] [--folder F] [--scope wiki|vault|all] [--limit N] [--any]
  語はすべて含むもの（AND）を探す。--any で、どれかを含むもの（OR）。大文字小文字は区別しない。
  WIKI_DIR / VAULT_DIR の環境変数があればそれを使う（既定 ~/vaults/90_Wiki、~/vaults）。
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

SKIP_DIRS = {".git", ".obsidian", ".trash", "node_modules"}
W = {"name": 6, "tags": 5, "title": 4, "index": 3, "type": 2, "body": 1}
BODY_CAP = 5  # 本文の一致は 1 語あたりこの回数まで数える


def expand(p: str) -> Path:
    return Path(os.path.expanduser(p)).resolve()


def read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def frontmatter(text: str) -> tuple[dict, str]:
    """(frontmatter の辞書, 本文) を返す。tags は文字列のリスト。"""
    fm: dict = {}
    m = re.match(r"\A---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    if not m:
        return fm, text
    body = text[m.end():]
    key = None
    for line in m.group(1).splitlines():
        kv = re.match(r"^([A-Za-z_]+):\s*(.*)$", line)
        if kv:
            key, val = kv.group(1), kv.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                fm[key] = [v.strip().strip("'\"") for v in val[1:-1].split(",") if v.strip()]
            elif val:
                fm[key] = val.strip("'\"")
            else:
                fm[key] = []
        elif key and re.match(r"^\s*-\s+", line) and isinstance(fm.get(key), list):
            fm[key].append(re.sub(r"^\s*-\s+", "", line).strip())
    return fm, body


def title_of(body: str) -> str:
    m = re.search(r"^#\s+(.+)$", body, re.M)
    return m.group(1).strip() if m else ""


def index_descs(folder: Path) -> dict[str, str]:
    """フォルダの INDEX.md から {ファイル名: 説明} を作る。"""
    out: dict[str, str] = {}
    for line in read(folder / "INDEX.md").splitlines():
        m = re.match(r"^\s*-\s+(?:`([^`]+\.md)`|\[([^\]]+\.md)\]\([^)]*\))\s*[—-]+\s*(.*)$", line)
        if m:
            out[Path(m.group(1) or m.group(2)).name] = m.group(3).strip()
    return out


def walk_md(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".sync-")]
        for f in filenames:
            if f.endswith(".md") and not f.startswith(".sync-"):
                yield Path(dirpath) / f


def count(hay: str, term: str) -> int:
    return hay.count(term) if term else 0


def score_fields(terms, fields: dict[str, str], any_mode: bool) -> tuple[int, int]:
    """(点数, 一致した語の数) を返す。"""
    total, hit = 0, 0
    for t in terms:
        s = 0
        for k, v in fields.items():
            c = count(v, t)
            if c:
                s += W[k] * (min(c, BODY_CAP) if k == "body" else 1)
        if s:
            hit += 1
            total += s
    if not any_mode and hit < len(terms):
        return 0, hit
    return total, hit


def snippet(body: str, terms) -> str:
    for line in body.splitlines():
        low = line.lower()
        if any(t in low for t in terms) and not line.startswith("#"):
            s = re.sub(r"\s+", " ", line).strip(" -*")
            return s[:110] + ("…" if len(s) > 110 else "")
    return ""


def main() -> int:
    ap = argparse.ArgumentParser(description="90_Wiki と vault のノートを探す")
    ap.add_argument("terms", nargs="+")
    ap.add_argument("--type", help="research / troubleshooting / setup / rule / record")
    ap.add_argument("--folder", help="90_Wiki のフォルダ名（例: claude-code）")
    ap.add_argument("--scope", choices=["wiki", "vault", "all"], default="all")
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--any", action="store_true", help="どれかの語を含めば候補にする（既定はすべて含む）")
    a = ap.parse_args()

    wiki = expand(os.environ.get("WIKI_DIR", "~/vaults/90_Wiki"))
    vault = expand(os.environ.get("VAULT_DIR", "~/vaults"))
    if not wiki.is_dir():
        print(f"WIKI_DIR がありません: {wiki}", file=sys.stderr)
        return 2
    terms = [t.lower() for t in a.terms]
    results = []  # (点数, 種類, 表示パス, 補足, 抜き出し)

    if a.scope in ("wiki", "all"):
        descs_cache: dict[Path, dict[str, str]] = {}
        for p in walk_md(wiki):
            rel = p.relative_to(wiki).as_posix()
            top = rel.split("/", 1)[0]
            if p.name == "INDEX.md" or top == "vault-notes":
                continue
            if a.folder and top != a.folder:
                continue
            text = read(p)
            fm, body = frontmatter(text)
            ftype = fm.get("type", "") if isinstance(fm.get("type"), str) else ""
            if a.type and ftype != a.type:
                continue
            descs = descs_cache.setdefault(p.parent, index_descs(p.parent))
            is_private = top == "private"
            fields = {
                "name": p.stem.lower(),
                "tags": " ".join(fm.get("tags", []) if isinstance(fm.get("tags"), list) else []).lower(),
                "title": title_of(body).lower(),
                "index": descs.get(p.name, "").lower(),
                "type": ftype.lower(),
                "body": body.lower(),
            }
            sc, _ = score_fields(terms, fields, a.any)
            if not sc:
                continue
            info = " ".join(x for x in [f"[{ftype}]" if ftype else "", fm.get("updated", "") if isinstance(fm.get("updated"), str) else ""] if x)
            desc = descs.get(p.name) or title_of(body)
            snip = "" if is_private else snippet(body, terms)
            results.append((sc, "wiki" + ("(private)" if is_private else ""), f"90_Wiki/{rel}", f"{info} {desc}".strip(), snip))

        # vault-notes（vault のノートの目次）の行
        vn = wiki / "vault-notes"
        if vn.is_dir() and not a.folder and not a.type:
            for p in walk_md(vn):
                if p.name == "INDEX.md":
                    continue
                for line in read(p).splitlines():
                    m = re.match(r"^\s*-\s+\[\[([^\]]+)\]\]\s*(.*)$", line)
                    if not m:
                        continue
                    low = line.lower()
                    hits = sum(1 for t in terms if t in low)
                    if (a.any and hits) or (not a.any and hits == len(terms)):
                        results.append((3 * hits, "vault-notes", f"[[{m.group(1)}]]", m.group(2).strip(" —-")[:110], f"目次: 90_Wiki/{p.relative_to(wiki).as_posix()}"))

    if a.scope in ("vault", "all") and not a.folder and not a.type:
        for p in walk_md(vault):
            try:
                p.relative_to(wiki)
                continue  # 90_Wiki は上で探した
            except ValueError:
                pass
            text = read(p)
            fm, body = frontmatter(text)
            fields = {
                "name": p.stem.lower(),
                "tags": " ".join(fm.get("tags", []) if isinstance(fm.get("tags"), list) else []).lower(),
                "title": title_of(body).lower(),
                "body": body.lower(),
            }
            sc, _ = score_fields(terms, fields, a.any)
            if sc:
                rel = p.relative_to(vault).as_posix()
                results.append((sc, "vault", rel, title_of(body)[:80], snippet(body, terms)))

    results.sort(key=lambda r: (-r[0], r[2]))
    # vault-notes と vault 本体で同じノートが二重に出たら、vault 本体のほうだけ残す
    seen_vault = {Path(r[2]).stem for r in results if r[1] == "vault"}
    results = [r for r in results if not (r[1] == "vault-notes" and r[2][2:-2] in seen_vault)]

    if not results:
        print("見つかりませんでした。語を減らす・言い換える・--any を付ける・--scope を広げる、を試す。")
        return 1
    shown = results[: a.limit]
    print(f"{len(results)} 件中 {len(shown)} 件（点数順。語: {' '.join(a.terms)}）")
    for sc, kind, path, info, snip in shown:
        print(f"- {sc:>3} {kind:<13} {path}  {info}")
        if snip:
            print(f"        {snip}")
    if len(results) > len(shown):
        print(f"（残り {len(results) - len(shown)} 件。--limit で増やすか、--type / --folder / --scope で絞る）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
