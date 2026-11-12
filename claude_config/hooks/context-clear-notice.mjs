// Stop の Hook: 会話が長くなったら「作業が変わるなら /clear を」と画面に一言出す（2026/11/11 にユーザーが決めた）。
// - 長いセッションは、返事のたび・ほかのセッションから報告が届くたびに会話全体を送り直すので、使用量が増える。
// - 基準: ふつうのセッションは 200k トークン、session-main は 100k（報告を何度も受けるため低め）。
//   基準を超えたら 1 回出し、そのあとは 100k 増えるごとにもう一度出す。基準より短くなったら（/clear 後など）数え直す。
// - 長さは transcript_path の最後の assistant 行の usage（input + cache_read + cache_creation）。会話記録は少し遅れて
//   書かれるので目安。読めないとき・待っている作業（background_tasks / session_crons）があるときは何も出さない。
// - セッション名は ~/.claude/sessions/<pid>.json（sessionId・name）で調べる。
// - /clear を実行できるのはユーザーだけなので、知らせるだけにする。
import { readFileSync, writeFileSync, mkdirSync, readdirSync, openSync, readSync, fstatSync, closeSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const THRESHOLD = { "session-main": 100_000 };
const DEFAULT_THRESHOLD = 200_000;
const STEP = 100_000;

let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }
if (input.agent_id || input.stop_hook_active) process.exit(0);
if ((input.background_tasks || []).length || (input.session_crons || []).length) process.exit(0);
const sid = input.session_id;
if (!sid || !input.transcript_path) process.exit(0);

function lastContextTokens(path) {
  let fd;
  try {
    fd = openSync(path, "r");
    const size = fstatSync(fd).size;
    const len = Math.min(size, 4 * 1024 * 1024);
    const buf = Buffer.alloc(len);
    readSync(fd, buf, 0, len, size - len);
    const lines = buf.toString("utf8").split("\n");
    for (let i = lines.length - 1; i >= 0; i--) {
      const l = lines[i];
      if (!l.includes('"type":"assistant"') || !l.includes('"usage"')) continue;
      try {
        const j = JSON.parse(l);
        if (j.type !== "assistant" || j.isSidechain) continue;
        const u = j.message && j.message.usage;
        if (!u) continue;
        return (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
      } catch { /* 途中で切れた行 */ }
    }
  } catch { /* 読めない */ } finally { if (fd !== undefined) try { closeSync(fd); } catch {} }
  return 0;
}

function sessionName(id) {
  const dir = join(homedir(), ".claude", "sessions");
  const tryFile = (f) => { try { const j = JSON.parse(readFileSync(join(dir, f), "utf8")); return j.sessionId === id ? (j.name || "") : null; } catch { return null; } };
  const byPid = tryFile(`${process.ppid}.json`);
  if (byPid !== null) return byPid;
  try {
    for (const f of readdirSync(dir)) if (f.endsWith(".json")) { const n = tryFile(f); if (n !== null) return n; }
  } catch {}
  return "";
}

const tokens = lastContextTokens(input.transcript_path);
if (!tokens) process.exit(0);

const name = sessionName(sid);
const threshold = THRESHOLD[name] ?? DEFAULT_THRESHOLD;

const stateDir = join(homedir(), ".claude", "state", "context-clear-notice");
const stateFile = join(stateDir, `${sid}.json`);
let last = 0;
try { last = JSON.parse(readFileSync(stateFile, "utf8")).step || 0; } catch {}

const step = tokens < threshold ? 0 : Math.floor((tokens - threshold) / STEP) + 1;
if (step !== last && (step === 0 || step > last)) {
  try { mkdirSync(stateDir, { recursive: true }); writeFileSync(stateFile, JSON.stringify({ step, tokens, name, at: new Date().toISOString() })); } catch {}
}
if (step === 0 || step <= last) process.exit(0);

const k = Math.round(tokens / 1000);
const msg = name === "session-main"
  ? `session-main の会話が ${k}k トークンになりました。報告を受けるたびにこの長さ分を使います。区切りなら /clear を（頼んだ作業の状況は session-overview で確かめられます）。`
  : `会話が ${k}k トークンになりました。別の作業に移るなら /clear を（/clear は使用量を使いません）。`;
console.log(JSON.stringify({ systemMessage: msg }));
