// UserPromptSubmit の Hook: 起動したあとに /rename で「session-main」になったセッションに、
// session-main の決まり（hooks/session-main-rules.md）を 1 回だけ読み込ませる（2026/11/11 にユーザーが決めた）。
// - 起動・再開・/clear・compact のときは session-main.mjs（SessionStart）が読み込ませ、
//   ~/.claude/state/session-main-rules/<session_id>.json に印を残す。印があれば、ここでは何もしない。
// - 入力の session_title（--name・/rename などで付けた名前）が session-main のときだけ動く。
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }
if (input.agent_id || input.session_title !== "session-main" || !input.session_id) process.exit(0);

const st = join(homedir(), ".claude", "state", "session-main-rules");
const mark = join(st, `${input.session_id}.json`);
if (existsSync(mark)) process.exit(0);

let rules = "";
try { rules = readFileSync(join(dirname(fileURLToPath(import.meta.url)), "session-main-rules.md"), "utf8").trim(); } catch { process.exit(0); }
if (!rules) process.exit(0);

try { mkdirSync(st, { recursive: true }); writeFileSync(mark, JSON.stringify({ at: new Date().toISOString(), source: "prompt" })); } catch {}
console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "UserPromptSubmit", additionalContext: `（Hook）${rules}` } }));
