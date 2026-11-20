#!/usr/bin/env node
// 90_Wiki（WIKI_DIR）への保存を Claude に判断させる Hook。
//   prompt: UserPromptSubmit で、人のメッセージのときだけ、保存の判断を思い出させる短い一行を渡す。
//   stop:   Stop で、次のどちらかに当たれば、1 回だけ止めて直させる（両方なら 1 回にまとめる）。
//           - 調べもの（WebFetch / WebSearch / サブエージェント）をしたか、人のメッセージに覚えておく情報がはっきりあるのに、
//             90_Wiki に何も書いていない
//           - 返答の最後の行が「✅ 完了:」「❓ 返事待ち:」「⏳ 待機:」のどれでもない（CLAUDE.md の「作業の終わり方」。
//             session-overview / session-observation はこの行だけで状態を判定する。2026/11/20 にユーザーが決めた）
//           claude -p などの自動実行（entrypoint が sdk-*）は、最後の行の確かめを省く（2026/11/20 にユーザーが決めた）。
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
      additionalContext: "（Hook）覚えておく情報があれば 90_Wiki に保存する。",
    },
  }));
  process.exit(0);
}

if (mode !== "stop" || input.stop_hook_active) process.exit(0);

// 最後の行の印（太字などの飾りも許す）と、末尾に足させる「（90_Wiki: 保存なし）」のような行
const END_LINE_RE = /^[*_\s]*(✅\s*完了|❓\s*返事待ち|⏳\s*待機)[:：]/;
const WIKI_MARK_RE = /^[(（]90_Wiki[:：].*[)）]$/;

let entries = [];
try {
  entries = readFileSync(input.transcript_path, "utf8").trim().split("\n")
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
} catch { /* 会話記録が読めなくても、最後の行の確かめはする */ }

// 最後に届いたメッセージ（tool_result ではないもの）から後を、このターンとして見る
let start = -1;
for (let i = entries.length - 1; i >= 0; i--) {
  const e = entries[i];
  if (e.type === "user" && !e.isSidechain && typeof e.message?.content === "string") { start = i; break; }
}

const prompt = start >= 0 ? entries[start].message.content : "";
const fromHuman = start >= 0 && entries[start].origin?.kind === "human" && !entries[start].isMeta;
let researched = false;
let wroteWiki = false;
let lastText = "";
for (const e of start >= 0 ? entries.slice(start + 1) : []) {
  if (e.type !== "assistant" || e.isSidechain || !Array.isArray(e.message?.content)) continue;
  for (const c of e.message.content) {
    if (c.type === "text") lastText = c.text;
    if (c.type !== "tool_use") continue;
    if (RESEARCH_TOOLS.has(c.name)) researched = true;
    if (WRITE_TOOLS.has(c.name) && JSON.stringify(c.input ?? {}).includes("90_Wiki")) wroteWiki = true;
  }
}
// 会話記録は遅れて書かれることがあるので、最後の返答は Stop の入力の last_assistant_message を先に使う
if (typeof input.last_assistant_message === "string" && input.last_assistant_message.trim()) lastText = input.last_assistant_message;

// session-main-auto-clear が /clear するターン（返答に [auto-clear]）は止めない（止めると /clear の打ち込みが作業中に重なる）
if (lastText.includes("[auto-clear]")) process.exit(0);

// 1. 90_Wiki の保存の判断。最後の返答で、もう保存するかを判断していれば止めない
const judged = /保存(しない|しません|しなかった|なし|済み|しました)|90_Wiki\s*(に|へ|には|:)/.test(lastText);
const informative = fromHuman && KEYWORDS.some((k) => prompt.includes(k));
const needWiki = start >= 0 && !wroteWiki && !judged && (researched || informative);

// 2. 最後の行。自動実行（claude -p・SDK）は省く
const entrypoint = process.env.CLAUDE_CODE_ENTRYPOINT || entries.findLast?.((e) => e.entrypoint)?.entrypoint || "";
const lines = lastText.split("\n").map((l) => l.trim()).filter(Boolean);
while (lines.length && WIKI_MARK_RE.test(lines[lines.length - 1])) lines.pop();
const needEnd = !entrypoint.startsWith("sdk") && lastText.trim() !== "" && !(lines.length && END_LINE_RE.test(lines[lines.length - 1]));

if (!needWiki && !needEnd) process.exit(0);

const asks = [];
if (needWiki) {
  const why = researched ? "このターンで調べもの（WebFetch / WebSearch / サブエージェント）をした" : "ユーザーのメッセージに覚えておく情報がありそうな";
  asks.push(`${why}のに、90_Wiki に何も書いていない。CLAUDE.md のナレッジベースの決まりに従い、保存するか判断する。残す価値があれば wiki-save スキルの手順で保存してどこに保存したかを書き、保存しないなら「（90_Wiki: 保存なし）」と書く。`);
}
if (needEnd) {
  asks.push("返答の最後の行に「✅ 完了: …」「❓ 返事待ち: …」「⏳ 待機: …」のどれも書いていない。CLAUDE.md の「作業の終わり方」に従い、今の状態に合う行を書く（前の返答は書き直さない）。");
}
// 書き直した短い返答が新しい「最後の返答」になり、もう止めない（stop_hook_active）ので、どちらで止めても最後の行を書かせる
if (!needEnd) asks.push("そのあと、前の返答の最後の行と同じ状態の行（✅ 完了 / ❓ 返事待ち / ⏳ 待機）をもう一度書く。");
console.log(JSON.stringify({
  decision: "block",
  reason: `（Hook）${asks.join(" ")} 返答は、必ずその状態の行で終える。`,
}));
