// SessionStart の Hook: 起動したモデルが settings.json の modelSettings になければ、
// { "effortLevel": "medium" } で書き足す（2026/11/11 にユーザーが決めた）。
// - 一番上の effortLevel は Opus 5.5 以降に効かないため、effort はモデルごとに modelSettings に置いている。
//   新しいモデルが出たときに、手で足さなくても medium で始まるようにする。
// - 入力の model（例: claude-opus-5-5[1m]、claude-sonnet-5-5-20261001）から [1m] と日付を外し、
//   claude-<名前>-<数字>(-<数字>) の形になったときだけ書く。それ以外の形・model が無いときは何もしない。
// - すでにあるモデルの値（/effort で保存したものなど）は変えない。
// - 書き足したセッションには効かないことがある（設定は起動時に読まれるため）。次のセッションから効く。
import { readFileSync, writeFileSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const LEVEL = "medium";

let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }

let id = typeof input.model === "string" ? input.model.trim() : "";
id = id.replace(/\[[^\]]*\]$/, "").replace(/-\d{8}$/, "");
if (!/^claude-[a-z]+-\d+(-\d+)?$/.test(id)) process.exit(0);

let path;
try { path = realpathSync(join(homedir(), ".claude", "settings.json")); } catch { process.exit(0); }

let text, json;
try { text = readFileSync(path, "utf8"); json = JSON.parse(text); } catch { process.exit(0); }

if (json.modelSettings && Object.prototype.hasOwnProperty.call(json.modelSettings, id)) process.exit(0);

// 差分を小さくするため、"modelSettings": { の直後に 1 行差し込む。できなければ全体を書き直す。
let next = null;
const m = text.match(/^([ \t]*)"modelSettings"\s*:\s*\{[ \t]*\r?\n([ \t]*)/m);
if (m) {
  const eol = text.includes("\r\n") ? "\r\n" : "\n";
  const line = `${m[2]}${JSON.stringify(id)}: { "effortLevel": ${JSON.stringify(LEVEL)} },${eol}`;
  const at = m.index + m[0].length - m[2].length;
  next = text.slice(0, at) + line + text.slice(at);
  try { JSON.parse(next); } catch { next = null; }
}
if (next === null) {
  json.modelSettings = { ...(json.modelSettings || {}), [id]: { effortLevel: LEVEL } };
  next = JSON.stringify(json, null, 2) + "\n";
}

try { writeFileSync(path, next); } catch { process.exit(0); }

const msg = `${id} を modelSettings に追加しました（effortLevel: ${LEVEL}。次のセッションから効きます）。`;
console.log(JSON.stringify({ systemMessage: msg }));
