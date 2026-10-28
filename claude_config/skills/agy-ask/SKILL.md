---
name: agy-ask
description: Google の Antigravity CLI（agy）に、要約・翻訳・調べもの・下書き・コードの確認などの作業を任せる。Claude の使用リミット（5 時間・週）が 80% 以上のときに軽い作業を外に回す判定（--check）もできる。「agy に聞いて」「Gemini に任せて」「Antigravity に頼んで」「使用量が多いので他の AI に回して」「リミットを見て振り分けて」などと言われたときに使う。
effort: low
argument-hint: "[モデル名] <頼む内容>"
---

# agy-ask

Antigravity CLI（`agy`）に 1 回だけ作業を渡し、答えを受け取る。Google アカウントのログインで動く（API キーは使わない）。

## 1. 使うかどうか決める
- 向いている: 長い文章の要約・翻訳・分類・抽出、下書き、調べもの、コードの読み取りと指摘、Claude の使用量を節約したい軽い作業。
- 向いていない: 正確さが大事な判断、ファイルの編集や実行をさせる作業（この呼び出しは読み取り専用）、秘密情報を含む内容（Google に送られる）。結果は Claude が確かめてからユーザーに渡す。そのまま事実として返さない。
- 送り先の選び方: 外に出したくない文書は ollama-ask（手元の LLM）、そうでなく品質がほしいときは agy-ask。

## 2. 使用リミットを見て振り分ける
`--check` は `~/.claude/cache/rate_limits.json`（`statusline.mjs` が約 60 秒ごとに書く）を読み、5 時間枠か週枠のどちらかが 80% 以上なら `"offload": true` を返す。

```bash
S=~/.claude/skills/agy-ask/agy_ask.py
python $S --check                    # しきい値 80%
python $S --check --threshold 70     # しきい値を変える
```

- `offload: true` のとき、軽い作業（上の「向いている」もの）は、自分でやらずに agy-ask か ollama-ask に回す。重い作業や判断は、回さずに自分で行うか、ユーザーに状況を伝える。
- `offload: false` のときは、ふつうに自分で行う。
- ファイルが無い・古い（`stale`）ときは判定の参考にしかならない。Pro / Max 以外のアカウントや、最初の応答の前は、ファイルが無い。

## 3. 実行する
スクリプトは標準ライブラリだけで動く。`python3`（Windows では `python`）で実行する。

```bash
S=~/.claude/skills/agy-ask/agy_ask.py
python $S "日本の首都を一語で"
python $S -f main.py "バグを指摘して"                 # ファイルの中身を指示に付ける（-f は複数可）
cat log.txt | python $S "エラーの原因を3行で要約して"  # 標準入力は指示の後ろに付く
python $S --models                                    # 使えるモデルの一覧
python $S -m gemini-3.8-flash-low "…"                 # モデルを指定する
python $S --effort high "…"                           # 思考を深くする（遅い）
python $S --json "…"                                  # 応答・トークン数・秒数を JSON で出す
```

答えは標準出力、所要時間とトークン数は標準エラーに出る。

## 4. 注意
- 読み取り専用の plan モードで、空の一時フォルダの中で動かす。ファイルを作る・コマンドを実行するといったツールは、許可を求められて黙って拒否される（「no output produced」と出たら、その作業は向いていない）。
- 指示とファイルの合計は 24,000 文字まで（Windows のコマンドラインの上限のため）。超えるときは分けて渡す。
- 標準入力やファイルは、agy に直接渡すのではなく、指示の文章に埋め込んで渡している。
- 1 回の呼び出しに 6〜13 秒かかる。初回やモデルによっては、もっとかかる。
- Google AI Plus の利用上限は未確認。上限に達したら、エラーが返る。
- agy が無いときは `~/dotfiles/claude_config/install_agy.sh`（Windows は `install_agy.ps1`）で導入し、ログインは対話型の `agy` を 1 回起動して行う。
