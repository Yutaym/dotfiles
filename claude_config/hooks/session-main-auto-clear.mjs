// session-main で話題が変わったら、自動で /clear して依頼を送り直す（2026/11/19 にユーザーが決めた）。
//   prompt（UserPromptSubmit）: session-main で、人が打った依頼のとき、会話が MIN_TOKENS（50k）以上なら、
//     「別の話題なら作業せずに [auto-clear] と書いて終える」と Claude に伝え、依頼の文を状態ファイルに残す。
//     話題が変わったかは、会話を知っている session-main の Claude 自身が判断する（2026/11/19 にユーザーが選んだ）。
//   stop（Stop）: 最後の返答に [auto-clear] があれば、裏で次を行う（tmux / psmux の中だけ）。
//     ペインが空くのを待つ → send-keys で /clear を打って送信 → 残した依頼の文を貼り付けて送信。
// - Hook には /clear を実行する機能がない（公式の hooks のページに無い）ので、send-keys でユーザーの入力として打ち込む。
// - 送信のキーは Alt+Enter（keybindings.json で enter は改行、alt/shift/ctrl+enter が送信）。2026/11/19 に psmux で動作を確認。
// - /clear のあとは session-main.mjs（SessionStart の source=clear）が決まりを読み込ませ直す。会話が短くなるので、
//   送り直した依頼で再び [auto-clear] にはならない。
import { readFileSync, writeFileSync, mkdirSync, unlinkSync, openSync, readSync, fstatSync, closeSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";

// これより短い会話では /clear しない（2026/11/19 にユーザーが決めた）。環境変数は試すとき用
const MIN_TOKENS = Number(process.env.AUTO_CLEAR_MIN_TOKENS ?? 50_000);
const MARK = "[auto-clear]";
const NOT_HUMAN_PREFIX = /^\s*(Another Claude session sent a message:|<cross-session-message|\[Cross-session|<task-notification>)/;

const mode = process.argv[2];
let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }
if (input.agent_id || !input.session_id || !input.transcript_path) process.exit(0);
const sid = input.session_id;

const isMain = (() => {
  if (input.session_title === "session-main") return true;
  try { readFileSync(join(homedir(), ".claude", "state", "session-main-rules", `${sid}.json`)); return true; } catch { return false; }
})();
if (!isMain) process.exit(0);

const stateDir = join(homedir(), ".claude", "state", "session-main-auto-clear");
const stateFile = join(stateDir, `${sid}.json`);

function tail(path, bytes = 4 * 1024 * 1024) {
  let fd;
  try {
    fd = openSync(path, "r");
    const size = fstatSync(fd).size;
    const len = Math.min(size, bytes);
    const buf = Buffer.alloc(len);
    readSync(fd, buf, 0, len, size - len);
    return buf.toString("utf8").split("\n");
  } catch { return []; } finally { if (fd !== undefined) try { closeSync(fd); } catch {} }
}

function lastContextTokens(lines) {
  for (let i = lines.length - 1; i >= 0; i--) {
    const l = lines[i];
    if (!l.includes('"type":"assistant"') || !l.includes('"usage"')) continue;
    try {
      const j = JSON.parse(l);
      if (j.type !== "assistant" || j.isSidechain) continue;
      const u = j.message && j.message.usage;
      if (u) return (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
    } catch {}
  }
  return 0;
}

if (mode === "prompt") {
  const prompt = input.prompt ?? "";
  const kind = input.origin?.kind;
  if ((kind && kind !== "human") || NOT_HUMAN_PREFIX.test(prompt) || prompt.trim().startsWith("/")) process.exit(0);
  const tokens = lastContextTokens(tail(input.transcript_path));
  if (tokens < MIN_TOKENS) { try { unlinkSync(stateFile); } catch {} process.exit(0); }
  try { mkdirSync(stateDir, { recursive: true }); writeFileSync(stateFile, JSON.stringify({ prompt, tokens, at: new Date().toISOString() })); } catch { process.exit(0); }
  const k = Math.round(tokens / 1000);
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: `（Hook: 自動の /clear）会話は約 ${k}k トークン。この依頼が、これまでの会話と別の話題（前の作業の続き・関係する作業ではないもの）なら、作業も調べものもせずに「話題が変わったので /clear して続けます。」とだけ書き、最後の行に ${MARK} とだけ書いて終える（Hook が /clear して、この依頼をそのまま送り直す）。同じ話題・関係する作業なら、この一文は無視していつもどおり進める。迷うときは同じ話題として扱う。`,
    },
  }));
  process.exit(0);
}

if (mode !== "stop" || input.stop_hook_active) process.exit(0);
const pane = process.env.TMUX_PANE;

// 最後の返答の文
let lastText = "";
for (const l of tail(input.transcript_path, 512 * 1024).reverse()) {
  if (!l.includes('"type":"assistant"')) continue;
  try {
    const j = JSON.parse(l);
    if (j.type !== "assistant" || j.isSidechain || !Array.isArray(j.message?.content)) continue;
    const t = j.message.content.filter((c) => c.type === "text").map((c) => c.text).join("\n");
    if (t) { lastText = t; break; }
  } catch {}
}
if (!lastText.includes(MARK)) process.exit(0);

let saved = null;
try { saved = JSON.parse(readFileSync(stateFile, "utf8")); } catch {}
try { unlinkSync(stateFile); } catch {}
if (!saved?.prompt || !process.env.TMUX || !pane) {
  console.log(JSON.stringify({ systemMessage: "（auto-clear）話題が変わりました。/clear してから、依頼をもう一度送ってください（tmux の外か、依頼の文が残っていないため自動ではできませんでした）。" }));
  process.exit(0);
}

// 依頼の文を一時ファイルに置き、裏の node に send-keys させる（Hook はすぐ終える）
const promptFile = join(tmpdir(), `auto-clear-${sid}.txt`);
try { writeFileSync(promptFile, saved.prompt); } catch { process.exit(0); }
const worker = `
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const [pane, file] = process.argv.slice(1);
const env = { ...process.env, MSYS_NO_PATHCONV: "1" };
const t = (...a) => execFileSync("tmux", a, { env, encoding: "utf8", windowsHide: true });
const sleep = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
// ペインが空くのを、続けて 2 回確かめるまで待つ（最大 60 秒）。作業中は入力欄の上に
// 「* Elucidating… (5m 21s · ↓ 20.7k tokens)」のような行が出る（終わると「✻ Churned for 1s · done」）。2026/11/19 に確認
const BUSY = /…\\s*\\((\\d+[hms]\\s*)+/;
let idle = 0;
for (let i = 0; i < 60 && idle < 2; i++) {
  sleep(1000);
  let s = "";
  try { s = t("capture-pane", "-p", "-t", pane); } catch { process.exit(0); }
  const bottom = s.split("\\n").filter((x) => x.trim()).slice(-10).join("\\n");
  idle = BUSY.test(bottom) ? 0 : idle + 1;
}
if (idle < 2) process.exit(0);
try {
  t("send-keys", "-t", pane, "-l", "/clear");
  sleep(800);
  t("send-keys", "-t", pane, "M-Enter");
  sleep(4000);
  t("load-buffer", "-b", "auto-clear", file);
  t("paste-buffer", "-p", "-d", "-b", "auto-clear", "-t", pane);
  sleep(1000);
  t("send-keys", "-t", pane, "M-Enter");
} catch {}
try { fs.unlinkSync(file); } catch {}
`;
try {
  const child = spawn(process.execPath, ["-e", worker, pane, promptFile], { detached: true, stdio: "ignore", windowsHide: true });
  child.unref();
} catch { process.exit(0); }
console.log(JSON.stringify({ systemMessage: "（auto-clear）話題が変わったので、/clear して依頼を送り直します。" }));
