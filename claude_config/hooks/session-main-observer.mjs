// session-main になったときに、session-observation の監視画面を自動で開く（2026/11/20 にユーザーが決めた）。
// session-main.mjs（SessionStart）と session-main-prompt.mjs（UserPromptSubmit）から呼ぶ。Hook として単独では動かさない。
// - tmux / psmux の中（環境変数 TMUX がある）ときだけ開く。それ以外では何もしない。
// - 開くのは session-main になったときだけ: tmux で最初に起動して自動で名前が付いたとき・--name session-main で起動したとき
//   （SessionStart の source が startup）、起動したあとに /rename session-main したとき（UserPromptSubmit）。
//   再開（--resume）・/clear・compact では開かない。
// - 監視画面がもう動いていれば（~/.claude/session-observation/observer.json の pid が生きていれば）開かない。
// - 開くのは session-observation の launch-observer.ps1 / .sh。呼び出し元（このセッション）のウィンドウを左右に分割する。
//   .ps1 は親プロセスをたどって呼び出し元のペインを探すので、終わるまで待つ（裏に回すと親がいなくなって探せない）。
import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

function observerRunning() {
  try {
    const j = JSON.parse(readFileSync(join(homedir(), ".claude", "session-observation", "observer.json"), "utf8"));
    const pid = Number(j.pid);
    if (!Number.isInteger(pid) || pid <= 0) return false;
    try { process.kill(pid, 0); return true; } catch (e) { return e.code === "EPERM"; }
  } catch { return false; }
}

// 開いたら説明の文を、開かなかったら "" を返す
export function openObserver() {
  if (!process.env.TMUX) return "";
  if (observerRunning()) return "";
  const dir = join(dirname(fileURLToPath(import.meta.url)), "..", "skills", "session-observation", "scripts");
  const r = process.platform === "win32"
    ? spawnSync("pwsh", ["-NoProfile", "-File", join(dir, "launch-observer.ps1")], { encoding: "utf8", timeout: 9000, windowsHide: true })
    : spawnSync("sh", [join(dir, "launch-observer.sh")], { encoding: "utf8", timeout: 9000 });
  if (r.status !== 0) return "";
  const m = /launched:\s*(.+)/.exec(r.stdout || "");
  return `session-observation の監視画面を開きました${m ? `（${m[1].trim()}）` : ""}。`;
}

