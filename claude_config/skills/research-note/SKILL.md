---
name: research-note
description: 調べもの・調査・比較の結果を、人が読むための Obsidian のノートにまとめ、vault の 00_Inbox に新しく作る（type: note、project: research）。図は必要なときだけ Mermaid で描き、数値はグラフ、挿絵は comfyui-klein で生成して 50_Resources に入れる。自動では動かず、頼まれたときだけ使う。「調べたことをノートにまとめて」「この調査をノートにして」「調べものを見やすくまとめて」「/research-note」などと言われたときに使う。
argument-hint: "[まとめる内容・タイトル（省略すると直前の調べもの）]"
---

# research-note

調べものの結果を、人が読むための Obsidian のノートにする。VAULT_DIR（既定 `~/vaults`）に作る。コスト（トークン・お金）を最小にするため、HTML は作らず、Obsidian がそのまま描ける Markdown と Mermaid だけで書く。

## 1. まとめる内容を決める

- 引数があればその内容を、なければこの会話の直前の調べものをまとめる。何をまとめるか分からなければ、ユーザーに聞く。
- このスキルのために新しく調べ直さない。足りない事実があれば、CLAUDE.md の「返答の正確性」に従い、確かめるか「嘘をついているかもしれない」と書く。

## 2. ファイル名と属性

- 保存先: `VAULT_DIR/00_Inbox/YYMMDD_タイトル.md`（例: `261110_Artifact の使い方.md`）。YYMMDD は今日の日付。
  - タイトルは内容が分かる短い日本語にする。ファイル名に使えない文字（`\ / : * ? " < > |`、`#` `^` `[` `]`）は使わない。
  - 同じ名前のファイルがあれば、上書きせず、末尾に `_2` などを付ける。
- frontmatter は `99_Template/Inbox_template.md` と同じ項目にし、project は `research` にする。

```yaml
---
type: note
created: YYYY-MM-DD
status: inbox
project: "research"
---
```

## 3. 本文の形

```markdown
# タイトル

## 要点
- 結論を 3〜5 行で。

## 詳細
（見出し・表・箇条書きで。比較は表にする）

## 図
（必要なときだけ。要らなければこの見出しごと書かない）

## 出典
- [ページの名前](URL) — 何を確かめたか
```

- 「嘘をついているかもしれない」部分は、本文にもそのまま書き、何が未確認かを残す。
- 内部の確認作業（実行したコマンドの手順など）は書かず、読む人に要ることだけを書く。

## 4. 図と画像（必要なときだけ。安い順に選ぶ）

図は、表や箇条書きでは分かりにくいとき（流れ・関係・構成・時間の順など）だけ作る。なくてよければ作らない。

1. **Mermaid**（第一の手段）: ```` ```mermaid ```` のコードブロックで書く。Obsidian がそのまま描く。ノードの文字は短くし、日本語や記号を含むラベルは `A["ラベル"]` のように `"` で囲む。
2. **数値のグラフ**: 数値を比べるときだけ、matplotlib で PNG を作る（`uv run --with matplotlib python <スクリプト>`。スクリプトはスクラッチパッドに置く）。日本語は Windows なら `Yu Gothic`、mac なら `Hiragino Sans` のフォントを指定する。
3. **生成した挿絵**: 雰囲気・イメージを伝える挿絵が読む助けになるときだけ、comfyui-klein MCP の `generate_image` で作る（1 つのノートで 1〜2 枚まで）。プロンプトは英語で書く。
   - 正確さが要る図（仕組み・数値・文字が入る図）には使わない。Mermaid かグラフにする。
   - プロンプトには基本「no text, no letters」を入れる。文字を入れるなら、大きく短い英語の見出しだけにする。日本語（特に漢字）と小さい文字は崩れる（2026/11/10 に試した）。
   - そのノートの画像をすべて生成し終えたら、ComfyUI のモデルを VRAM から解放する（ComfyUI は時間がたっても自分では解放せず、yutapc の VRAM を約 7.6GB 使ったままになるため）。次に生成するときは、自動で読み直す。
     ```bash
     ssh Home_Desktop_PC_1 'curl -s -X POST localhost:8188/free -H "Content-Type: application/json" -d "{\"unload_models\":true,\"free_memory\":true}"'
     ```
     解放に失敗しても、ノート作りは続ける（返答で一言伝える）。
   - `comfyui_status` で使えないと分かったら、生成は飛ばし、そのことを返答で伝える（ノートは画像なしで作る）。
4. **ほかのサイトの画像**: ダウンロードしない。リンク（`[説明](URL)`）と出典だけを書く。

### 画像の保存先（2 と 3 の画像）

`50_Resources` の決まり（Obsidian の Custom Attachment Location の設定と同じ）に合わせる。

- 保存先: `VAULT_DIR/50_Resources/YYYY/MM/`（今日の年・月。フォルダがなければ作る）
- ファイル名: `<ノートのファイル名（拡張子なし）>_<画像の内容>.png`（例: `261110_Artifact の使い方_構成図.png`）
- 生成した画像は、comfyui-klein が返した出力のパス（`\\yutapc\share\ComfyUI\output` の下）から、この場所へコピーする。
- ノートには `![[ファイル名.png]]` で貼り、下に出典か「comfyui-klein（FLUX.2 klein）で生成」と書く。
- 50_Resources の添付は git の管理外（Remotely Save で同期する。`50_Resources/README.md`）。コミットには入らないので、git の容量は増えない。

## 5. 保存と同期

- ノートを保存したら、CLAUDE.md の「VAULT_DIR / META_DIR の同期」に従い、`sync-vaults` スキルの git の手順で、コミットして push する（コミットメッセージは `Claude: yyyy/MM/dd HH:mm:ss ±HHMM`、帰属表示の行は付けない）。
- 90_Meta への保存は、これまでどおり CLAUDE.md の決まりで別に判断する（Claude 用の簡潔なメモ。このノートとは別に残す）。

## 6. 返答

- 作ったノートのパスと、図・画像を作ったか（作らなかった理由も一言）を短く書く。
- ノートの本文を返答に貼り直さない。
