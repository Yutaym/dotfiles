// Claude Code の subagentStatusLine 用スクリプト。入力欄の下のエージェント一覧で、サブエージェントの行の中身を書き換える
//   説明 [種類] · トークン数 (+直近の増え) · ctx 使用率 · 経過時間
// stdin の JSON の tasks[] の 1 件ごとに {"id", "content"} を 1 行ずつ出す。出さなかった行は Claude Code の既定の表示になる
// 右端まで空白で寄せたりブロック文字を使ったりすると、表示できる幅が狭いときに後ろが切れて見えなくなったので、文字だけを左から詰めて並べる
let raw = '';
for await (const chunk of process.stdin) raw += chunk;
let d = {};
try {
  d = JSON.parse(raw);
} catch {}

const RED = 31, YELLOW = 33, GREEN = 32;
const paint = (code, s) => `\x1b[${code}m${s}\x1b[0m`;
const dim = (s) => paint(2, s);
// 説明の表示幅の上限。数字が先に切れないよう、説明のほうを短くする
const LABEL_MAX = 40;

const tokens = (n) => (n >= 1e6 ? `${(n / 1e6).toFixed(1)}M` : n >= 1e3 ? `${(n / 1e3).toFixed(1)}k` : String(n));
const elapsed = (ms) => {
  const s = Math.max(0, Math.floor(ms / 1000));
  return s >= 3600 ? `${Math.floor(s / 3600)}h${String(Math.floor((s % 3600) / 60)).padStart(2, '0')}m` : s >= 60 ? `${Math.floor(s / 60)}m${String(s % 60).padStart(2, '0')}s` : `${s}s`;
};
const width = (s) =>
  [...s.replace(/\x1b\[[0-9;]*m/g, '')].reduce(
    (w, c) => w + (/[ᄀ-ᅟ⺀-꓏가-힣豈-﫿︰-﹏＀-｠￠-￦]/.test(c) ? 2 : 1),
    0,
  );
// 表示幅が n を超えないように末尾を … で切る
const cut = (s, n) => {
  if (width(s) <= n) return s;
  let out = '', w = 0;
  for (const c of s) {
    const cw = width(c);
    if (w + cw > n - 1) return out + '…';
    out += c;
    w += cw;
  }
  return out;
};

const now = Date.now();
for (const t of d.tasks ?? []) {
  const running = t.status === 'running';
  const samples = t.tokenSamples ?? [];
  // 直近の refresh でのトークン数の増え。動いている間だけ出す
  const delta = samples.length >= 2 ? samples[samples.length - 1] - samples[samples.length - 2] : 0;
  const pct = t.contextWindowSize ? Math.round((t.tokenCount / t.contextWindowSize) * 100) : null;
  const pctColor = pct >= 80 ? RED : pct >= 50 ? YELLOW : GREEN;
  const type = t.agentType && t.agentType !== 'general-purpose' ? dim(` [${t.agentType}]`) : '';
  const parts = [
    cut(t.label || t.description || '', LABEL_MAX) + type,
    tokens(t.tokenCount ?? 0) + (running && delta > 0 ? paint(GREEN, ` (+${tokens(delta)})`) : ''),
    pct == null ? null : paint(pctColor, `ctx ${pct}%`),
    elapsed(now - (t.startTime ?? now)),
    t.status === 'failed' || t.status === 'killed' ? paint(RED, t.status) : null,
  ];
  const content = parts.filter(Boolean).join(dim(' · '));
  console.log(JSON.stringify({ id: t.id, content: running ? content : dim(content.replace(/\x1b\[[0-9;]*m/g, '')) }));
}
