#!/usr/bin/env node
// session-initialize の台帳 (~/.claude/session-ledger/<メインのセッション ID>.jsonl) を使って、
// サブセッションの返答を session-main に届ける Hook (完了報告の案 A)。
//   stop:   サブセッション (環境変数 CC_LEDGER がある) の Stop で、そのターンの最後の返答を report として台帳に追記する。
//           モデルは呼ばず、止めもしない。
//   prompt: session-main (自分のセッション ID の台帳がある) の UserPromptSubmit で、まだ読んでいない報告と、
//           振り分け役であることを additionalContext で渡す。読んだ位置は <ID>.read に行数で残す。
import { appendFileSync, existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const DIR = join(homedir(), ".claude", "session-ledger");
const MAX_SUMMARY = 600; // 報告 1 件に残す文字数

const mode = process.argv[2];
let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }

// ~/.claude/sessions/<pid>.json から、セッション ID に当たる名前を探す (Claude Code の内部形式)
function sessionName(id) {
  const dir = join(homedir(), ".claude", "sessions");
  try {
    for (const f of readdirSync(dir).filter((f) => f.endsWith(".json"))) {
      try {
        const j = JSON.parse(readFileSync(join(dir, f), "utf8"));
        if (j.sessionId === id) return j.name || id;
      } catch { /* 書きかけのファイルは飛ばす */ }
    }
  } catch { /* フォルダがなければ ID を使う */ }
  return id;
}

if (mode === "stop") {
  const ledger = process.env.CC_LEDGER;
  if (!ledger || !existsSync(ledger)) process.exit(0);
  const msg = String(input.last_assistant_message || "").trim();
  if (!msg) process.exit(0);
  const summary = msg.length > MAX_SUMMARY ? msg.slice(0, MAX_SUMMARY - 1) + "…" : msg;
  const ev = { ts: new Date().toISOString(), id: process.env.CC_TASK_ID || null, event: "report", by: sessionName(input.session_id), session_id: input.session_id, summary };
  try { appendFileSync(ledger, JSON.stringify(ev) + "\n"); } catch { /* 書けなくても止めない */ }
  process.exit(0);
}

if (mode === "prompt") {
  const id = input.session_id;
  const ledger = id && join(DIR, `${id}.jsonl`);
  if (!ledger || !existsSync(ledger)) process.exit(0);
  const readPath = join(DIR, `${id}.read`);
  const lines = readFileSync(ledger, "utf8").split("\n").filter(Boolean);
  let done = 0;
  try { done = parseInt(readFileSync(readPath, "utf8"), 10) || 0; } catch { /* 初めて */ }
  // まだ読んでいない報告を、送り手ごとに最新の 1 件にまとめる (Stop が 1 ターンに何度か走ることがあるため)
  const latest = new Map();
  for (const l of lines.slice(done)) {
    try {
      const e = JSON.parse(l);
      if (e.event === "report") latest.set(e.by || e.session_id, e);
    } catch { /* 壊れた行は飛ばす */ }
  }
  try { writeFileSync(readPath, String(lines.length)); } catch { /* 次回また読むだけ */ }
  let ctx = "（Hook）このセッションは session-initialize の振り分け役。入力は作業ごとに分けて、サブセッションか名前なしのサブエージェントに頼み、台帳（session-initialize の ledger.mjs）に記録する。自分では作業しない。";
  if (latest.size) {
    ctx += "\nサブセッションからの未読の報告（台帳の状態を ledger.mjs state で更新し、ユーザーに要点を伝える）:";
    for (const e of latest.values()) ctx += `\n- [${e.id || "ID なし"}] ${e.by}（${e.ts}）: ${e.summary.replace(/\n+/g, " ")}`;
  }
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: ctx } }));
  process.exit(0);
}
