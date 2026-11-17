// SessionStart の Hook: 「Claude」カレンダーの自動実行（Home_Mac_1 の vault-jobs calendar-run）の状況を、件数だけ表示する（2026/11/10 にユーザーが決めた）。
// - 新しく終わったもの（未確認＝タイトルが 🆕 の予定）があれば、その件数。
// - 実行する PC に ssh でつながらず待機中（タイトルが 🔁 の予定）のものがあれば、待機中であることと、その PC の起動をうながす文（2026/11/17 に追加）。
// - Home_Mac_1 では手元のファイルを、ほかのマシンでは ssh で Home_Mac_1 のファイルを読む。
// - Mac に届かない・ファイルがない・0 件のときは、何も出さずに終わる（セッションの開始を遅らせすぎないよう 3 秒で打ち切る）。
// - 詳しく見るときは calendar-results スキルを使う。
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const DIR = ".local/state/vault-jobs";
const UNREAD = `${DIR}/calendar-unread.txt`;
const WAITING = `${DIR}/calendar-waiting.txt`;
const SEP = "\n=====\n";

function readTexts() {
  // Home_Mac_1 自身（calendar-run が書いたファイルがある）
  const u = join(homedir(), UNREAD);
  if (existsSync(u)) {
    const read = (rel) => { try { return readFileSync(join(homedir(), rel), "utf8"); } catch { return ""; } };
    return [read(UNREAD), read(WAITING)];
  }
  const r = spawnSync("ssh", ["-o", "BatchMode=yes", "-o", "ConnectTimeout=2", "Home_Mac_1",
    `cat ~/${UNREAD} 2>/dev/null; printf '${SEP.replace(/\n/g, "\n")}'; cat ~/${WAITING} 2>/dev/null`],
    { encoding: "utf8", timeout: 3000, windowsHide: true });
  if (r.status !== 0) return ["", ""];
  const [a = "", b = ""] = r.stdout.split(SEP);
  return [a, b];
}

const [unreadText, waitingText] = readTexts();
const count = (t) => { const n = parseInt((t.split(/\r?\n/)[0] || "").trim(), 10); return Number.isFinite(n) ? n : 0; };
const parts = [];

const n = count(unreadText);
if (n > 0) parts.push(`Claude カレンダーの自動実行で、まだ確認していない結果が ${n} 件あります（詳しくは /calendar-results）。`);

const w = count(waitingText);
if (w > 0) {
  const items = waitingText.split(/\r?\n/).slice(1).filter((l) => l.trim()).map((l) => l.split("\t"));
  const pcs = [...new Set(items.map((x) => x[1]).filter(Boolean))];
  const list = items.slice(0, 3).map((x) => `${x[0]} ${x[2]}（${x[1]}）`).join("、");
  parts.push(`Claude カレンダーの自動実行で、${w} 件が待機中です: ${list}${items.length > 3 ? " ほか" : ""}。` +
    `実行する PC（${pcs.join("、")}）に ssh でつながらないため、1 時間おきに再試行しています。` +
    `PC を起動してください（予定の開始から 24 時間つながらないと、エラーにして記録します）。`);
}

if (parts.length) {
  const msg = parts.join("\n");
  console.log(JSON.stringify({
    systemMessage: msg,
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: `（Hook）${msg}ユーザーに頼まれたら calendar-results スキルで見せる。` },
  }));
}
process.exit(0);
