#!/usr/bin/env node
// session-initialize の台帳を読み書きする。
//
// 台帳: ~/.claude/session-ledger/<メインのセッション ID>.jsonl (1 行 1 件の出来事を追記していく JSON Lines)
//   環境変数 CC_LEDGER があればそれ (サブセッションの中)、なければ CLAUDE_CODE_SESSION_ID から決める (メインの中)。
//
// 使い方:
//   ledger.mjs init                                  台帳を作り、パスを表示する (メインで実行)
//   ledger.mjs path                                  台帳のパスを表示する
//   ledger.mjs whoami                                このセッションの名前・ID・受信口のアドレスを表示する
//   ledger.mjs add <kind> <target> <task> [--cwd <dir>] [--worktree <name>]
//                                                    頼んだことを記録し、作業の ID (t001 など) を表示する。kind は session / subagent
//   ledger.mjs state <id> <state> [summary]          状態を記録する。state は running / waiting / done / failed / killed
//   ledger.mjs list [--all]                          作業ごとの今の状態を表で表示する (--all がなければ killed は出さない)
//   ledger.mjs open-sessions                         閉じていないサブセッションの名前を 1 行ずつ表示する (まとめて閉じるとき用)
//
// 出来事 (event): dispatch (頼んだ) / report (サブセッションの Stop Hook が書く) / state (状態が変わった)
import { appendFileSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { homedir, hostname } from "node:os";
import { join } from "node:path";

const DIR = join(homedir(), ".claude", "session-ledger");
const STATES = new Set(["running", "waiting", "done", "failed", "killed"]);

function die(msg) { console.error(msg); process.exit(1); }

function ledgerPath() {
  if (process.env.CC_LEDGER) return process.env.CC_LEDGER;
  const id = process.env.CLAUDE_CODE_SESSION_ID;
  if (!id) die("CC_LEDGER も CLAUDE_CODE_SESSION_ID もありません (Claude Code のセッションの中で実行してください)");
  return join(DIR, `${id}.jsonl`);
}

// ~/.claude/sessions/<pid>.json から、このセッションの名前と受信口を探す (Claude Code の内部形式)
function self() {
  const id = process.env.CLAUDE_CODE_SESSION_ID;
  const dir = join(homedir(), ".claude", "sessions");
  let info = {};
  try {
    for (const f of readdirSync(dir).filter((f) => f.endsWith(".json"))) {
      try {
        const j = JSON.parse(readFileSync(join(dir, f), "utf8"));
        if (j.sessionId === id) { info = j; break; }
      } catch { /* 書きかけのファイルは飛ばす */ }
    }
  } catch { /* フォルダがなければ空のまま */ }
  const sock = process.env.CLAUDE_CODE_MESSAGING_SOCKET || info.messagingSocketPath || "";
  return { name: info.name || "", sessionId: id || "", addr: sock ? `uds:${sock}` : "", host: hostname() };
}

function read(path) {
  if (!existsSync(path)) return [];
  return readFileSync(path, "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
}

function append(path, ev) {
  mkdirSync(DIR, { recursive: true });
  appendFileSync(path, JSON.stringify({ ts: new Date().toISOString(), ...ev }) + "\n");
}

// 作業 (id) ごとに、頼んだ内容と最後の状態・報告をまとめる
function tasks(events) {
  const m = new Map();
  for (const e of events) {
    if (!e.id) continue;
    if (e.event === "dispatch") m.set(e.id, { ...e, state: "running", last: "" });
    const t = m.get(e.id);
    if (!t || e.event === "dispatch") continue;
    if (e.state) t.state = e.state;
    if (e.summary) t.last = e.summary;
    t.updated = e.ts;
  }
  return [...m.values()];
}

function opt(args, name) {
  const i = args.indexOf(name);
  if (i < 0) return undefined;
  const v = args[i + 1];
  args.splice(i, 2);
  return v;
}

const [cmd, ...args] = process.argv.slice(2);
const path = cmd === "whoami" ? "" : ledgerPath();

switch (cmd) {
  case "init": {
    mkdirSync(DIR, { recursive: true });
    if (!existsSync(path)) writeFileSync(path, "");
    console.log(path);
    break;
  }
  case "path":
    console.log(path);
    break;
  case "whoami": {
    const s = self();
    console.log(`name=${s.name}\nsession_id=${s.sessionId}\naddr=${s.addr}\nhost=${s.host}`);
    break;
  }
  case "add": {
    const cwd = opt(args, "--cwd");
    const worktree = opt(args, "--worktree");
    const [kind, target, ...task] = args;
    if (!["session", "subagent"].includes(kind) || !target || !task.length) {
      die("usage: ledger.mjs add <session|subagent> <target> <task> [--cwd <dir>] [--worktree <name>]");
    }
    const n = read(path).filter((e) => e.event === "dispatch").length + 1;
    const id = `t${String(n).padStart(3, "0")}`;
    append(path, { id, event: "dispatch", by: self().name, kind, target, host: hostname(), cwd: cwd || null, worktree: worktree || null, task: task.join(" ") });
    console.log(id);
    break;
  }
  case "state": {
    const [id, state, ...summary] = args;
    if (!id || !STATES.has(state)) die("usage: ledger.mjs state <id> <running|waiting|done|failed|killed> [summary]");
    if (!tasks(read(path)).some((t) => t.id === id)) die(`台帳に ${id} がありません`);
    append(path, { id, event: "state", by: self().name, state, ...(summary.length ? { summary: summary.join(" ") } : {}) });
    break;
  }
  case "list": {
    const all = args.includes("--all");
    const rows = tasks(read(path)).filter((t) => all || t.state !== "killed");
    if (!rows.length) { console.log("(台帳に作業はありません)"); break; }
    const cut = (s, n) => (s && s.length > n ? s.slice(0, n - 1) + "…" : s || "");
    console.log("| ID | 種類 | 宛先 | 状態 | 頼んだこと | 最後の報告 |\n|---|---|---|---|---|---|");
    for (const t of rows) {
      console.log(`| ${t.id} | ${t.kind} | ${cut(t.target, 30)} | ${t.state} | ${cut(t.task, 40)} | ${cut(t.last, 60).replace(/\n/g, " ")} |`);
    }
    break;
  }
  case "open-sessions": {
    for (const t of tasks(read(path))) {
      if (t.kind === "session" && t.state !== "killed") console.log(t.target);
    }
    break;
  }
  default:
    die("usage: ledger.mjs init | path | whoami | add | state | list | open-sessions");
}
