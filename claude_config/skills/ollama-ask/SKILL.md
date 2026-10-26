---
name: ollama-ask
description: 別の PC（既定は yutapc）の Ollama のローカル LLM に、要約・翻訳・分類・下書き・簡単なコードの確認などの軽い作業を任せる。同梱の ollama_ask.py でプロンプトとファイルを送り、答えを受け取る。「ollama に聞いて」「ローカル LLM に任せて」「qwen で〜して」「ollama のモデル一覧を出して」などと言われたときに使う。Claude Code 自体のモデルを Ollama に切り替える方法は、このスキルではなく下の「参考」を見る。
effort: low
argument-hint: "[モデル名] <頼む内容>"
---

# ollama-ask

別の PC の Ollama に作業を送り、答えを受け取る。送り先は環境変数 `CLAUDE_OLLAMA_URL`（無ければ `http://yutapc:11434`）。

## 1. 使うかどうか決める
- 向いている: 長い文章の要約・翻訳・分類・抽出、定型の下書き、外に出したくない文書の処理、Claude の使用量を節約したい大量の単純作業。
- 向いていない: 正確さが大事な判断、込み入ったコード、最新の知識が要るもの。ローカル LLM の答えは間違いがありうるので、結果は Claude が確かめてからユーザーに渡す。そのまま事実として返さない。

## 2. 実行する
スクリプトは標準ライブラリだけで動く。`python3`（Windows では `python`）で実行する。

```bash
S=~/.claude/skills/ollama-ask/ollama_ask.py
python3 $S --list                                   # モデルの一覧（読み込み中のものに印）
python3 $S "日本の首都を一語で"                     # 既定モデル qwen3.5:9b、思考オフ
python3 $S -m qwen2.5-coder:7b "バグを指摘して" -f main.py   # ファイルを付ける（-f は複数可）
cat log.txt | python3 $S "エラーの原因を3行で要約して"      # 標準入力は指示の後ろに付く
python3 $S --json "…を {\"a\":[]} の形の JSON だけで答えて"  # JSON で答えさせる
```

主なオプション: `-m` モデル、`-s` システムプロンプト、`-f` ファイル、`--think` 思考を有効にする（遅い）、`--num-ctx` context の長さ、`--keep-alive 30m` 読み込んだままにする時間、`--url` 送り先。
答えは標準出力、トークン数と時間は標準エラーに出る。

## 3. 注意
- 初回はモデルの読み込みに 30 秒ほどかかる。続けて使うなら `--keep-alive 30m` を付ける。
- モデルを切り替えると読み込み直しになる（GPU は RTX 3060 12GB で、1 つずつしか載らない）。同じ作業は同じモデルでまとめて送る。
- context は既定で 4096 トークン。長い入力は黙って切り詰められる。標準エラーに注意が出たら `--num-ctx 16384` などを付ける（目安: qwen3.5:9b は 32K で VRAM 10GB、qwen2.5-coder は上限 32K）。
- 日本語は qwen3.5 系がよい。コードは qwen2.5-coder 系。
- 接続できないときは yutapc の電源と Ollama を確かめる。相手の PC の設定（OLLAMA_HOST、ファイアウォールなど）を変えるときは、先にユーザーに確認する。

## 参考
調査とテストの記録、Claude Code 自体を Ollama で動かす方法（`qwen3.5:9b-32k` と環境変数）: `~/vaults/90_Meta/research/remote-ollama-from-claude-code.md`
