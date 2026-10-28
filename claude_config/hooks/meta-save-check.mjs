#!/usr/bin/env node
// 90_Meta（META_DIR）への保存を Claude に判断させる Hook。
//   prompt: UserPromptSubmit で、保存の判断を思い出させる一行を渡す。
//   stop:   Stop で、調べもの（WebFetch / WebSearch / サブエージェント）をしたか、
//           ユーザーのメッセージに覚えておく情報がありそうなのに 90_Meta に何も書いていなければ、1 回だけ止めて判断させる。
import { readFileSync } from "node:fs";

const KEYWORDS = ["覚え", "記録", "メモ", "今後", "いつも", "毎回", "決めた", "決定", "環境", "パス", "設定", "好み"];
const LONG_PROMPT = 200; // これより長いメッセージは、情報を含むとみなす
const RESEARCH_TOOLS = new Set(["WebFetch", "WebSearch", "Agent", "Task"]);
const WRITE_TOOLS = new Set(["Write", "Edit", "MultiEdit", "Bash", "PowerShell", "NotebookEdit"]);

const mode = process.argv[2];
let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }

if (mode === "prompt") {
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "（Hook）このメッセージに今後も覚えておくべき情報（環境・好み・手順・決定事項など）があれば、返答の中で META_DIR（90_Meta）に保存する。",
    },
  }));
  process.exit(0);
}

if (mode !== "stop" || input.stop_hook_active || !input.transcript_path) process.exit(0);

let entries;
try {
  entries = readFileSync(input.transcript_path, "utf8").trim().split("\n")
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
} catch { process.exit(0); }

// 最後のユーザーのメッセージ（tool_result ではないもの）から後を、このターンとして見る
let start = -1;
for (let i = entries.length - 1; i >= 0; i--) {
  const e = entries[i];
  if (e.type === "user" && !e.isSidechain && typeof e.message?.content === "string") { start = i; break; }
}
if (start < 0) process.exit(0);

const prompt = entries[start].message.content;
let researched = false;
let wroteMeta = false;
for (const e of entries.slice(start + 1)) {
  if (e.type !== "assistant" || e.isSidechain || !Array.isArray(e.message?.content)) continue;
  for (const c of e.message.content) {
    if (c.type !== "tool_use") continue;
    if (RESEARCH_TOOLS.has(c.name)) researched = true;
    if (WRITE_TOOLS.has(c.name) && JSON.stringify(c.input ?? {}).includes("90_Meta")) wroteMeta = true;
  }
}

const informative = prompt.length > LONG_PROMPT || KEYWORDS.some((k) => prompt.includes(k));
if (wroteMeta || !(researched || informative)) process.exit(0);

const why = researched ? "このターンで調べもの（WebFetch / WebSearch / サブエージェント）をした" : "ユーザーのメッセージに覚えておく情報がありそう";
console.log(JSON.stringify({
  decision: "block",
  reason: `（Hook）${why}のに、90_Meta に何も書いていない。CLAUDE.md のナレッジベースの決まりに従い、保存するか判断する。残す価値があれば保存し、保存しないなら理由を返答に一言書いて終える。`,
}));
