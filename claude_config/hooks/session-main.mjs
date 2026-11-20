// SessionStart の Hook: session-main（作業を振り分けるセッション）まわりをまとめて行う（2026/11/11 にユーザーが決めた）。
// 1. 名前を付ける: tmux の中で最初に起動したセッションに「session-main」と付ける。
//    条件: source が "startup"、環境変数 TMUX がある、まだ名前がない（session_title がない）、
//    今動いている session-main がこの OS のユーザーにいない。名前は sessionTitle で付ける。
//    ただし sessionTitle はタイトル（tmux のウィンドウ名）だけで、ほかのセッションが送るときの名前（sessions/*.json の name）は
//    自動の名前（yutay-34 など）のまま（2026/11/20 に確認）。そのため、裏で画面が空くのを待って、send-keys で
//    「/rename session-main」を打って送る（/rename なら name も変わる。2026/11/20 にユーザーが決めた。送信は Alt+Enter）。
// 2. 決まりを読み込ませる: session-main なら（名前を付けたとき・--name / /rename 済みで起動・再開・/clear・compact のあと）、
//    hooks/session-main-rules.md を additionalContext に入れる。/clear のあとは、前に頼んだ作業を覚えていないことも伝える。
//    起動したあとに /rename で session-main になった場合は session-main-prompt.mjs（UserPromptSubmit）が読み込ませる。
// 3. 2 つ以上あると知らせる: 生きている session-main が自分を含めて 2 つ以上なら systemMessage で知らせる（起動時だけ）。
// - session-main がいるかは ~/.claude/sessions/<pid>.json の name で見る。終わったセッションのファイルが残ることがあるので、
//   pid が生きていて、そのプロセスが claude であるか（Windows は tasklist、ほかは ps）も確かめる。確かめられないときは生きているとみなす。
// - 数えるのはこの OS のユーザーのセッションだけ（~/.claude はユーザーごと）。SendMessage は名前で宛先を探すので 1 つにする。
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from "node:fs";
import { spawn, spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const NAME = "session-main";
const HOOK_DIR = dirname(fileURLToPath(import.meta.url));

let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }
if (input.agent_id) process.exit(0);
const sid = input.session_id || "";

function isClaudeAlive(pid) {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); } catch (e) { if (e.code !== "EPERM") return false; }
  const r = process.platform === "win32"
    ? spawnSync("tasklist", ["/FI", `PID eq ${pid}`, "/FO", "CSV", "/NH"], { encoding: "utf8", timeout: 3000, windowsHide: true })
    : spawnSync("ps", ["-p", String(pid), "-o", "comm="], { encoding: "utf8", timeout: 3000 });
  if (r.status !== 0 || !r.stdout) return true;
  return /claude/i.test(r.stdout);
}

const dir = join(homedir(), ".claude", "sessions");
const others = [];
let ownName = "";
try {
  for (const f of readdirSync(dir)) {
    if (!f.endsWith(".json")) continue;
    let j;
    try { j = JSON.parse(readFileSync(join(dir, f), "utf8")); } catch { continue; }
    if (j.sessionId === sid) { ownName = j.name || ""; continue; }
    if (j.name === NAME && isClaudeAlive(j.pid)) others.push(j);
  }
} catch { /* 一覧が読めない */ }

const out = {};
const hso = { hookEventName: "SessionStart" };
let isMain = input.session_title === NAME || (!input.session_title && ownName === NAME);

if (input.source === "startup" && process.env.TMUX && !input.session_title && !isMain && others.length === 0) {
  hso.sessionTitle = NAME;
  isMain = true;
  out.systemMessage = `tmux で最初のセッションなので「${NAME}」と名前を付けました（/rename で変えられます）。`;
  renameLater(process.env.TMUX_PANE);
}

// 起動の画面が落ち着いてから「/rename session-main」を打って送る（Hook はすぐ終える）
function renameLater(pane) {
  if (!pane) return;
  const worker = `
const { execFileSync } = require("node:child_process");
const pane = process.argv[1];
const env = { ...process.env, MSYS_NO_PATHCONV: "1" };
const t = (...a) => execFileSync("tmux", a, { env, encoding: "utf8", windowsHide: true });
const sleep = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
const BUSY = /…\\s*\\((\\d+[hms]\\s*)+/;
let idle = 0;
for (let i = 0; i < 60 && idle < 3; i++) {
  sleep(1000);
  let s = "";
  try { s = t("capture-pane", "-p", "-t", pane); } catch { process.exit(0); }
  const bottom = s.split("\\n").filter((x) => x.trim()).slice(-10).join("\\n");
  // 入力欄が見えていて（❯）、作業中の行がない
  idle = /❯/.test(bottom) && !BUSY.test(bottom) ? idle + 1 : 0;
}
if (idle < 3) process.exit(0);
try {
  t("send-keys", "-t", pane, "-l", "/rename ${NAME}");
  sleep(800);
  t("send-keys", "-t", pane, "M-Enter");
} catch {}
`;
  try {
    spawn(process.execPath, ["-e", worker, pane], { detached: true, stdio: "ignore", windowsHide: true }).unref();
  } catch {}
}

if (isMain) {
  let rules = "";
  try { rules = readFileSync(join(HOOK_DIR, "session-main-rules.md"), "utf8").trim(); } catch {}
  let ctx = rules ? `（Hook）${rules}` : "";
  if (input.source === "clear") {
    ctx += "\n\n（Hook）このセッションは /clear したばかりで、前に別のセッションへ頼んだ作業の内容を覚えていない。"
      + "ほかのセッションからの報告が届いたとき、またはユーザーに頼んだ作業の状況を聞かれたときは、まず session-overview スキルで各セッションの状況を確かめてから答える。";
  }
  if (ctx) {
    hso.additionalContext = ctx;
    try {
      const st = join(homedir(), ".claude", "state", "session-main-rules");
      mkdirSync(st, { recursive: true });
      writeFileSync(join(st, `${sid}.json`), JSON.stringify({ at: new Date().toISOString(), source: input.source }));
    } catch {}
  }
  if (others.length >= 1) {
    const where = others.map((m) => `pid ${m.pid}${m.tmux ? `（tmux ${m.tmux}）` : ""}`).join("、");
    out.systemMessage = `「${NAME}」が ${others.length + 1} つあります（このセッションと、${where}）。ほかのセッションからの報告が名前だけでは届かなくなるので、1 つにしてください（片方を /rename するか session-kill で止める）。`;
  }
} else if (others.length >= 2) {
  const where = others.map((m) => `pid ${m.pid}${m.tmux ? `（tmux ${m.tmux}）` : ""}`).join("、");
  out.systemMessage = `「${NAME}」が ${others.length} つあります（${where}）。ほかのセッションからの報告が名前だけでは届かなくなるので、1 つにしてください（片方を /rename するか session-kill で止める）。`;
}

if (hso.sessionTitle || hso.additionalContext) out.hookSpecificOutput = hso;
if (Object.keys(out).length) console.log(JSON.stringify(out));
