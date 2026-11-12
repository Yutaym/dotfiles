---
name: research-html
description: 調べもの・調査・比較の結果を、図や表で読みやすい 1 枚の HTML ノートにまとめ、vault の 50_Resources/html_notes/ に保存し、00_Inbox に要点とリンクだけの索引ノート（type: note、group: html_index）を作る。頼まれたときだけ Artifact として公開し（スマホの Claude アプリでも見られる）、前に作った HTML ノートの追記・更新もする。既定の Markdown のノートは research-note を使い、このスキルは HTML を頼まれたときだけ使う。「HTML でまとめて」「調べたことを HTML のノートにして」「HTML レポートにして」「前の HTML ノートを更新して」「Artifact にして」「/research-html」などと言われたときに使う。
argument-hint: "[まとめる内容・タイトル（省略すると直前の調べもの）]"
---

# research-html

調べものの結果を、図や表で読みやすい 1 枚の HTML にする。Markdown では文章が長くなって読みにくいときに使う。既定は research-note（Markdown）で、このスキルは HTML を頼まれたときだけ使う（2026/11/12 にユーザーが決めた）。

## 1. research-note と同じ決まり

`~/.claude/skills/research-note/SKILL.md` の次の部分を読んで、そのとおりにする（決まりを 1 か所にまとめるため、ここには書き写さない）。

- 「1. まとめる内容を決める」（調べ直さない。裏付けのない部分には「嘘をついているかもしれない」と書く）
- 「2. ファイル名と属性」の名前の付け方（`YYMMDD_タイトル`、使えない文字、vault 全体で同じ名前がないかの確かめ方）。`.md` と `.html` の両方の名前で確かめる。
- 「3. 本文の形」の中身の順番（要点 → 詳細 → 残っている作業 → 図 → 出典）と、書かないこと（内部の確認作業）

## 2. 置き場所

- HTML: `VAULT_DIR/50_Resources/html_notes/YYMMDD_タイトル/YYMMDD_タイトル.html`
  - 画像は同じフォルダに置き、HTML からは相対パス（`./画像.png`）で参照する。
  - 50_Resources は git の管理外（Remotely Save で同期する。`50_Resources/README.md`）。
- 索引ノート: `VAULT_DIR/00_Inbox/YYMMDD_タイトル.md`
  - frontmatter は `99_Template/Inbox_template.md` と同じ項目にし、group は `html_index` にする（振り分けで `20_Notes/html_index` に移る。research-note のノートの `group: research` とは分ける）。

```yaml
---
type: note
created: YYYY-MM-DD
status: inbox
group: "html_index"
---
```

```markdown
# タイトル

## 要点
- 結論を 3〜5 行で。

## HTML ノート
- ファイル: [[YYMMDD_タイトル.html]]
- Artifact: （公開したら URL。公開していなければ「未公開」）
- 最終更新: YYYY-MM-DD
```

- HTML へのリンクは `[[名前.html]]` の形にする。振り分けでノートが移っても切れないように、相対パスは使わない。

## 3. HTML の書き方

あとで Artifact にするときにそのまま公開できるように、初めから Artifact の決まりに合わせて書く。

- CSS をインラインで入れた 1 つのファイルにする。`<title>` は 2〜4 語の名前にする。`<meta charset="utf-8">` と viewport の meta を入れる。
- 色は `:root` のトークンにし、ダークモードを `@media (prefers-color-scheme: dark)`（`:root:not([data-theme="light"])`）と `:root[data-theme="dark"]` の両方で定義する。`body` には背景色をはっきり付ける。
- スマホの幅で読めるようにする（左右の余白 16px、ページ全体に横スクロールを出さない）。横に長い表は、その表だけを横スクロールにする。
- 外部のスクリプトは、どうしても要るとき（Mermaid など）だけ、cdnjs.cloudflare.com か cdn.jsdelivr.net/npm/ から、版を固定して読む（例: `https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js`）。
- 図: 流れ・関係は Mermaid かインラインの SVG で描く。数値の比較はインラインの SVG か CSS の棒グラフにする（matplotlib の PNG は使わない）。図は、表や箇条書きでは分かりにくいときだけ作る。
- 挿絵: research-note の「4. 図と画像」の 3（comfyui-klein）と同じ条件・手順（VRAM の解放も含む）で作り、HTML と同じフォルダにコピーする。下に「comfyui-klein（FLUX.2 klein）で生成」と書く。
- ほかのサイトの画像はダウンロードせず、リンクと出典だけを書く。
- 出典はリンクにする。「嘘をついているかもしれない」の部分は、目立つ囲みにして、何が未確認かを書く。

## 4. Artifact への公開（頼まれたときだけ）

- 「Artifact にして」「スマホで見たい」などと頼まれたときだけ公開する。既定では公開しない（公開の料金・上限が確かめられていないため。2026/11/12）。
- 公開するときは、Artifact ツールの決まり（artifact-design スキルを先に読む、など）に従う。画像があれば `files` で一緒に送る。
- 公開した URL は、索引ノートの「Artifact:」に書く。

## 5. 更新

- 「前の〜の HTML ノートを更新して」と言われたら、索引ノート（00_Inbox か `20_Notes/html_index`。振り分けで移っていることがあるので vault 全体を名前で探す）を見つけ、そこから HTML をたどる。
- HTML を直し、索引ノートの要点と「最終更新」を直す。
- Artifact に公開済みなら、同じ URL に上書きで公開し直す（`url` を渡す。URL は変わらない）。新しい Artifact は作らない。

## 6. 保存と同期・返答

- 索引ノートは git の管理下なので、research-note の「5. 保存と同期」と同じく、sync-vaults の手順でコミットして push する。HTML と画像は git に入らない（Remotely Save で同期される）。
- 返答: HTML と索引ノートのパス、Artifact に公開したならその URL、図・画像を作ったかを短く書く。本文は貼り直さない。
