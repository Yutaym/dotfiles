#!/usr/bin/env node
// 90_Meta（META_DIR）への保存を Claude に判断させる Hook。
//   prompt: UserPromptSubmit で、人のメッセージのときだけ、保存の判断を思い出させる短い一行を渡す。
//   stop:   Stop で、調べもの（WebFetch / WebSearch / サブエージェント）をしたか、
//           人のメッセージに覚えておく情報がはっきりあるのに 90_Meta に何も書いていなければ、1 回だけ止めて判断させる。
// 人のメッセージかどうか: 会話記録では origin.kind が "human" のものだけ。自動のメッセージ（idle notice など）は
// isMeta: true で origin が付かないので、origin が無いものは人のメッセージとみなさない（2026/11/12 に確認）。
import { readFileSync } from "node:fs";

// 「覚えておいて」とはっきり言っているときだけに絞る（「設定」「環境」など普通の作業で出る言葉は入れない）
const KEYWORDS = ["覚えて", "覚えといて", "記録して", "メモして", "メモしておいて", "今後は", "これからは", "次からは", "決めた", "決定", "好み", "いつも", "毎回"];
const RESEARCH_TOOLS = new Set(["WebFetch", "WebSearch", "Agent", "Task"]);
const WRITE_TOOLS = new Set(["Write", "Edit", "MultiEdit", "Bash", "PowerShell", "NotebookEdit"]);
// UserPromptSubmit の入力に送り手が入っていないときに、文の頭で見分ける
const NOT_HUMAN_PREFIX = /^\s*(Another Claude session sent a message:|<cross-session-message|\[Cross-session|<task-notification>)/;

const mode = process.argv[2];
let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }

if (mode === "prompt") {
  const kind = input.origin?.kind;
  if ((kind && kind !== "human") || NOT_HUMAN_PREFIX.test(input.prompt ?? "")) process.exit(0);
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "（Hook）覚えておく情報があれば 90_Meta に保存する。",
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

// 最後に届いたメッセージ（tool_result ではないもの）から後を、このターンとして見る
let start = -1;
for (let i = entries.length - 1; i >= 0; i--) {
  const e = entries[i];
  if (e.type === "user" && !e.isSidechain && typeof e.message?.content === "string") { start = i; break; }
}
if (start < 0) process.exit(0);

const prompt = entries[start].message.content;
const fromHuman = entries[start].origin?.kind === "human" && !entries[start].isMeta;
let researched = false;
let wroteMeta = false;
let lastText = "";
for (const e of entries.slice(start + 1)) {
  if (e.type !== "assistant" || e.isSidechain || !Array.isArray(e.message?.content)) continue;
  for (const c of e.message.content) {
    if (c.type === "text") lastText = c.text;
    if (c.type !== "tool_use") continue;
    if (RESEARCH_TOOLS.has(c.name)) researched = true;
    if (WRITE_TOOLS.has(c.name) && JSON.stringify(c.input ?? {}).includes("90_Meta")) wroteMeta = true;
  }
}

// 最後の返答で、もう保存するかを判断していれば止めない
const judged = /保存(しない|しません|しなかった|なし|済み|しました)|90_Meta\s*(に|へ|には|:)/.test(lastText);
const informative = fromHuman && KEYWORDS.some((k) => prompt.includes(k));
if (wroteMeta || judged || !(researched || informative)) process.exit(0);

const why = researched ? "このターンで調べもの（WebFetch / WebSearch / サブエージェント）をした" : "ユーザーのメッセージに覚えておく情報がありそうな";
console.log(JSON.stringify({
  decision: "block",
  reason: `（Hook）${why}のに、90_Meta に何も書いていない。CLAUDE.md のナレッジベースの決まりに従い、保存するか判断する。残す価値があれば保存してどこに保存したかを書き、保存しないなら「（90_Meta: 保存なし）」とだけ書いて終える。`,
}));
