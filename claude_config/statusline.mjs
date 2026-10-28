// Claude Code の statusLine 用スクリプト。stdin の JSON から次を 1 行にまとめて右揃えで出す
//   使用リミット（5 時間・週）と、このペースで上限に届く時刻 / コンテキスト使用率 / キャッシュの残り時間 / effort などの状態 / モデル
// rate_limits は Pro / Max のみ、セッションの最初の応答の後から入る。各項目は欠けることがあるので、あるものだけ出す
import { spawnSync } from 'node:child_process';
import { mkdirSync, renameSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

let raw = '';
for await (const chunk of process.stdin) raw += chunk;
let d = {};
try {
  d = JSON.parse(raw);
} catch {}

const now = Date.now() / 1000;
const RED = 31, YELLOW = 33, GREEN = 32;
const paint = (code, s) => `\x1b[${code}m${s}\x1b[0m`;
const dim = (s) => paint(2, s);
const color = (p) => (p >= 80 ? RED : p >= 50 ? YELLOW : GREEN);
const pct = (label, p) => paint(color(p), `${label} ${Math.round(p)}%`);
const pad = (n) => String(n).padStart(2, '0');
const clock = (epoch, withDate) => {
  const t = new Date(epoch * 1000);
  const hm = `${pad(t.getHours())}:${pad(t.getMinutes())}`;
  return withDate ? `${t.getMonth() + 1}/${t.getDate()} ${hm}` : hm;
};

// 使用リミットの 1 枠。今のペース（使用率 ÷ 経過時間）のままだとリセット前に 100% に届くなら、その時刻を ⚠ で出す
// 枠の始めはペースがぶれるので、経過が枠の 10% 未満のうちは予測しない
const rateLimit = (label, w, windowSec, withDate) => {
  const used = w.used_percentage;
  let s = `${pct(label, used)} ${dim('~' + clock(w.resets_at, withDate))}`;
  const elapsed = windowSec - (w.resets_at - now);
  if (used > 0 && used < 100 && elapsed >= windowSec * 0.1) {
    const reach = now + ((100 - used) * elapsed) / used;
    // ⚠ は端末によって全角幅で描かれ、後ろの数字に重なるので、空白を 2 つ空ける
    if (reach < w.resets_at) s += ' ' + paint(RED, `⚠  ${clock(reach, withDate)}`);
  }
  return s;
};

// プロンプトキャッシュの残り時間。切れると次の応答でコンテキスト全体を読み直す（遅く、使用量も増える）
const cache = (c) => {
  if (!c?.caching_observed) return null;
  const left = c.warm && c.expires_at ? c.expires_at - now : 0;
  if (left <= 0) return dim('cache cold');
  const min = Math.ceil(left / 60);
  return paint(min <= 5 ? YELLOW : GREEN, `cache ${min}m`);
};

// effort などの状態。思考がオン（既定）のときは出さず、オフのときだけ出す
const EFFORT = { low: 'low', medium: 'med', high: 'high', xhigh: 'xhigh', max: 'max' };
const badges = () => {
  const b = [];
  if (d.effort?.level) b.push(EFFORT[d.effort.level] ?? d.effort.level);
  if (d.thinking && !d.thinking.enabled) b.push('no-think');
  if (d.fast_mode) b.push(paint(YELLOW, 'fast'));
  return b.length ? b.join(' ') : null;
};

const parts = [];
const rl = d.rate_limits ?? {};

// 使用リミットを ~/.claude/cache/rate_limits.json に書き出す（スキルなどが、使用率を見て作業の振り分けを決めるため）
// 同じアカウントの値なので、どのセッションが書いても同じ。読み手が途中まで書かれたファイルを読まないよう、一時ファイルに書いてから置き換える
const saveRateLimits = () => {
  if (rl.five_hour?.used_percentage == null && rl.seven_day?.used_percentage == null) return;
  const dir = join(homedir(), '.claude', 'cache');
  const file = join(dir, 'rate_limits.json');
  const tmp = `${file}.${process.pid}.tmp`;
  mkdirSync(dir, { recursive: true });
  writeFileSync(tmp, JSON.stringify({ updated_at: now, ...rl }));
  renameSync(tmp, file);
};
try {
  saveRateLimits();
} catch {}
if (rl.five_hour?.used_percentage != null) parts.push(rateLimit('5h', rl.five_hour, 5 * 3600, false));
if (rl.seven_day?.used_percentage != null) parts.push(rateLimit('週', rl.seven_day, 7 * 86400, true));
if (d.context_window?.used_percentage != null) parts.push(pct('ctx', d.context_window.used_percentage));
parts.push(cache(d.prompt_cache), badges(), d.model?.display_name);

// 右揃えにする。画面の幅は Claude Code が COLUMNS に入れて渡す（tput cols では取れない）
// 表示幅は ANSI の色指定を除き、全角文字を 2 として数える。RIGHT_MARGIN は Claude Code 側の余白のぶんの調整
// Claude Code は行頭の空白を詰めるので、先頭に色のリセット（\x1b[0m）を置いて空白を残す
const RIGHT_MARGIN = 4;
const line = parts.filter(Boolean).join(' │ ');
const width = (s) =>
  [...s.replace(/\x1b\[[0-9;]*m/g, '')].reduce(
    (w, c) => w + (/[ᄀ-ᅟ⺀-꓏가-힣豈-﫿︰-﹏＀-｠￠-￦]/.test(c) ? 2 : 1),
    0,
  );
const cols = Number(process.env.COLUMNS) || 0;
console.log('\x1b[0m' + ' '.repeat(Math.max(0, cols - RIGHT_MARGIN - width(line))) + line);

// tmux（psmux）の中なら、ウィンドウ名をセッション名（--name や /rename で付けた名前）にそろえる
// 自動で付いたタイトル（日本語や空白を含む）は使わないよう、英数字と - _ だけの名前のときに限る
// 同じウィンドウで Claude（psmux では node、tmux では claude か node）が 2 つ以上動いていれば変えない
// psmux は -t %ID を取り違えることがあるので、list-panes で「セッション名:ウィンドウ番号」に直して指定する
const syncTmuxWindowName = () => {
  const name = d.session_name;
  const pane = process.env.TMUX_PANE;
  if (!process.env.TMUX || !pane || !name || !/^[A-Za-z0-9_-]+$/.test(name)) return;
  const r = spawnSync('tmux', ['list-panes', '-a', '-F', '#{pane_id}\t#{session_name}:#{window_index}\t#{window_name}\t#{pane_current_command}'], {
    encoding: 'utf8',
    timeout: 2000,
  });
  if (r.status !== 0 || !r.stdout) return;
  const rows = r.stdout.trim().split(/\r?\n/).map((l) => l.split('\t'));
  const me = rows.find((x) => x[0] === pane);
  if (!me || me[2] === name) return;
  const claudes = rows.filter((x) => x[1] === me[1] && /^(claude|node)(\.exe)?$/.test(x[3] ?? ''));
  if (claudes.length > 1) return;
  spawnSync('tmux', ['rename-window', '-t', me[1], name], { timeout: 2000 });
};
try {
  syncTmuxWindowName();
} catch {}
