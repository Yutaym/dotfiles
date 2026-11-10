// SessionStart の Hook: 「Claude」カレンダーの自動実行（Home_Mac_1 の vault-jobs calendar-run）で、
// 新しく終わったもの（未確認＝タイトルが 🆕 の予定）があるかだけを見て、あれば件数を表示する（2026/11/10 にユーザーが決めた）。
// - Home_Mac_1 では手元のファイルを、ほかのマシンでは ssh で Home_Mac_1 のファイルを読む。
// - Mac に届かない・ファイルがない・0 件のときは、何も出さずに終わる（セッションの開始を遅らせすぎないよう 3 秒で打ち切る）。
// - 詳しく見るときは calendar-results スキルを使う。
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const REL = ".local/state/vault-jobs/calendar-unread.txt";
const local = join(homedir(), REL);

function readText() {
  // Home_Mac_1 自身（calendar-run が書いたファイルがある）
  if (existsSync(local)) {
    try { return readFileSync(local, "utf8"); } catch { return ""; }
  }
  const r = spawnSync("ssh", ["-o", "BatchMode=yes", "-o", "ConnectTimeout=2", "Home_Mac_1", `cat ~/${REL} 2>/dev/null`],
    { encoding: "utf8", timeout: 3000, windowsHide: true });
  return r.status === 0 ? r.stdout : "";
}

const n = parseInt((readText().split(/\r?\n/)[0] || "").trim(), 10);
if (Number.isFinite(n) && n > 0) {
  const msg = `Claude カレンダーの自動実行で、まだ確認していない結果が ${n} 件あります（詳しくは /calendar-results）。`;
  console.log(JSON.stringify({
    systemMessage: msg,
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: `（Hook）${msg}ユーザーに頼まれたら calendar-results スキルで見せる。` },
  }));
}
process.exit(0);
