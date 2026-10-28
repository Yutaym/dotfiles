#!/usr/bin/env node
// PreToolUse の Hook。グローバル CLAUDE.md の決まりを守らせる。
//   Bash:  素の tmux（`command tmux` ではないもの）と、uv を使わない Python の環境づくりを止める。
//   Agent: effort がなければ medium を足し、model がなければ止める。
import { readFileSync } from "node:fs";

let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { process.exit(0); }
const tool = input.tool_name;
const args = input.tool_input ?? {};

const out = (o) => { console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "PreToolUse", ...o } })); process.exit(0); };
const deny = (reason) => out({ permissionDecision: "deny", permissionDecisionReason: `（Hook）${reason}` });

// コマンドの先頭の位置（行頭・; & | ( ` $( の後）にあるかを見る
const AT_CMD = String.raw`(?:^|[;&|(\x60\n]|\$\()\s*(?:sudo\s+|env\s+(?:\S+=\S*\s+)*)?`;

if (tool === "Bash") {
  // heredoc の本文（ファイルに書く文章など）は、コマンドではないので外して調べる
  const cmd = String(args.command ?? "").replace(/<<-?\s*(['"]?)(\w+)\1[^\n]*\n[\s\S]*?\n\s*\2\s*(?=\n|$)/g, "");
  if (new RegExp(AT_CMD + String.raw`tmux(?=\s|$)`, "m").test(cmd)) {
    deny("tmux は必ず `command tmux` で呼ぶ（zsh では tmux が oh-my-zsh のエイリアスになっていて失敗するため）。`command tmux ...` に直して実行し直す。");
  }
  const py = new RegExp(AT_CMD + String.raw`(?:pip3?\s+install|python[0-9.]*\s+-m\s+(?:venv|pip\s+install)|py\s+-m\s+(?:venv|pip\s+install)|conda\s+create)\b`, "m");
  if (py.test(cmd)) {
    deny("Python の仮想環境・パッケージは uv で扱う（`uv venv`、`uv pip install`、`uv sync`、`uv run` など）。素の pip・`python -m venv`・conda は使わない。");
  }
}

if (tool === "Agent") {
  if (!args.model && args.subagent_type !== "fork") {
    deny("サブエージェントには model を必ず渡す（既定は sonnet。検索だけなら haiku。CLAUDE.md の「モデルと effort の使い分け」を参照）。model を付けて起動し直す。");
  }
  if (!args.effort) {
    out({ permissionDecision: "allow", updatedInput: { ...args, effort: "medium" } });
  }
}
