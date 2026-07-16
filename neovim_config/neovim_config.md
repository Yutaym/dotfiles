# Neovim 設定まとめ

## 基本設定 (base.lua)

### エディタ表示
| 設定           | 値                         |
| -------------- | -------------------------- |
| 行番号         | 絶対 + 相対行番号          |
| カーソルライン | 有効（インサート中は無効） |
| スクロールオフ | 3行                        |
| 折り返し表示   | 有効                       |
| 特殊文字表示   | tab:»-, trail:-, eol:↲, 等 |
| conceallevel   | 0（隠さない）              |

### 検索
| 設定       | 値                               |
| ---------- | -------------------------------- |
| ignorecase | 有効                             |
| smartcase  | 有効                             |
| wrapscan   | 有効（最終行から先頭に折り返す） |
| incsearch  | 有効                             |
| hlsearch   | 有効                             |

### ファイル・バックアップ
| 設定                 | 値    |
| -------------------- | ----- |
| swapfile             | 無効  |
| backup / writebackup | 無効  |
| autoread             | 有効  |
| encoding             | UTF-8 |

### インデント
| 設定                               | 値               |
| ---------------------------------- | ---------------- |
| expandtab                          | 有効（スペース） |
| tabstop / shiftwidth / softtabstop | 4                |
| smartindent / autoindent           | 有効             |

### その他
- `foldmethod = marker`, `foldenable = false`（折り畳み手動）
- `updatetime = 300`
- `mouse = "a"`（全モードでマウス有効）
- `clipboard = unnamed`（WSL環境ではwl-clipboard利用）
- `lazyredraw = true`

---

## キーマッピング (mapping.lua)

**Leader = `<Space>`**

### モード移行
| キー    | 動作             | モード          |
| ------- | ---------------- | --------------- |
| `jj`    | ESC              | i               |
| `<C-j>` | ESC              | i, c            |
| `<C-[>` | ノーマルモードへ | t（ターミナル） |

### カーソル移動
| キー              | 動作                  | モード |
| ----------------- | --------------------- | ------ |
| `gl`              | 行末（`$`）           | n      |
| `gl`              | 行末1文字手前（`$h`） | x      |
| `gh`              | 行頭（`^`）           | n, x   |
| `H`               | 10文字左              | n, x   |
| `J`               | 10行下                | n, x   |
| `K`               | 10行上                | n, x   |
| `L`               | 10文字右              | n, x   |
| `<Down>` / `<Up>` | 折り返し行単位移動    | n, x   |

### テキスト操作
| キー      | 動作                                         | モード |
| --------- | -------------------------------------------- | ------ |
| `x` / `X` | ブラックホール削除（クリップボード汚染なし） | n      |
| `Y`       | 行末までヤンク（`y$`）                       | n      |
| `U`       | Redo（`<C-r>`）                              | n      |
| `gW`      | `gw`（テキスト整形）                         | n      |
| `<C-u>`   | アンドゥ（ESC→u→i）                          | i      |

### 検索・置換
| キー         | 動作                                  | モード |
| ------------ | ------------------------------------- | ------ |
| `ss`         | `/`（検索開始）                       | n      |
| `ss`         | 選択テキストで置換（`:%s/<選択>//g`） | x, v   |
| `sr`         | `:s/`（カーソル行置換）               | n      |
| `sa`         | `:%s/`（全体置換）                    | n      |
| `<ESC><ESC>` | ハイライト消去（`:nohlsearch`）       | n      |

### ウィンドウ操作（`s`プレフィックス）
| キー             | 動作（Neovim）              |
| ---------------- | --------------------------- |
| `sd`             | 水平分割                    |
| `sv`             | 垂直分割                    |
| `sw`             | 次ウィンドウへフォーカス    |
| `sh/sj/sk/sl`    | 左/下/上/右ウィンドウへ移動 |
| `so`             | 最大化                      |
| `s=/s>/s</s+/s-` | ウィンドウサイズ調整        |
| `sn` / `sp`      | 次/前タブ                   |
| `at`             | 新規タブ                    |
| `sbb`            | 新規バッファ                |
| `sbq/sbd`        | バッファを閉じる            |
| `sbp`            | 前のバッファへ              |

### インサートモード補助（Emacs風）
| キー              | 動作      |
| ----------------- | --------- |
| `<C-a>`           | Home      |
| `<C-e>`           | End       |
| `<C-b>`           | Left      |
| `<C-f>`           | Right     |
| `<C-d>`           | Delete    |
| `<C-n>` / `<C-p>` | Down / Up |

### テキストオブジェクト
| キー        | 動作           |
| ----------- | -------------- |
| `i<space>`  | `iw`（単語内） |
| `sa` / `ga` | 全選択（ggVG） |

### その他
| キー            | 動作                                        |
| --------------- | ------------------------------------------- |
| `;`             | `:`                                         |
| `q;`            | `q:`（コマンド履歴）                        |
| `gw`            | `<C-w>`（ウィンドウプレフィックス）         |
| `(` / `[` / `{` | 自動クローズ（insert、非VSCode）            |
| `s`             | `<Nop>`（カスタムプレフィックスとして確保） |

---

## Plugin（共通）

### folke/lazy.nvim

遅延ローディング対応プラグインマネージャ。

### kylechui/nvim-surround

囲み文字の追加・変更・削除。HTML/XML(`t`)・LaTeX(`c`)の専用サラウンドあり。

### numToStr/Comment.nvim

コメントアウト。Treesitterで複合ファイルタイプ対応。

| キー  | 動作                   |
| ----- | ---------------------- |
| `gcc` | 行コメントトグル       |
| `gbc` | ブロックコメントトグル |
| `gc`  | コメントオペレータ     |

### vim-scripts/ReplaceWithRegister

| キー  | 動作                             |
| ----- | -------------------------------- |
| `gr`  | レジスタ内容で置換（オペレータ） |
| `grr` | 行をレジスタ内容で置換           |

### vim-scripts/camelcasemotion

CamelCase/snake_caseの単語移動。

| キー                        | 動作               |
| --------------------------- | ------------------ |
| `sw` / `se` / `sb`          | CamelCase単語移動  |
| `<C-w>` / `<C-e>` / `<C-b>` | 同上（別バインド） |

### rhysd/clever-f.vim

`f/F/t/T`を強化。`,`で前方リピート、`:`で後方リピート。

### wellle/targets.vim

追加テキストオブジェクト（`,`・`)`・`]`等の引数やペア）。

### monaqa/dial.nvim

インクリメント/デクリメントを拡張。

| キー                | 動作                        |
| ------------------- | --------------------------- |
| `<C-a>` / `<C-x>`   | インクリメント/デクリメント |
| `g<C-a>` / `g<C-x>` | 連番インクリメント          |

カスタム対象: `and/or`, `&&/||`, `yes/no`, `on/off`, `public/private/protected`, ログレベル(`DEBUG/INFO/WARN/ERROR`), 日付(`YYYY/MM/DD`)

### haya14busa/vim-edgemotion

| キー        | 動作                 |
| ----------- | -------------------- |
| `gj` / `gk` | ブロック端へジャンプ |

### kevinhwang91/nvim-hlslens

検索時にマッチ数をフローティング表示。`n/N/*/# `に統合済み。

### nacro90/numb.nvim

`:123`入力中にリアルタイムプレビュー。

### ysmb-wtsg/in-and-out.nvim

| キー     | 動作             |
| -------- | ---------------- |
| `<C-CR>` | 括弧の外へ抜ける |

### vim-denops/denops.vim

Deno製プラグインのランタイム基盤。

### lambdalisue/vim-kensaku

コマンドラインの`<CR>`をフックして日本語ローマ字入力でも検索可能にする。

### lambdalisue/vim-kensaku-search

vim-kensakuと連携してインクリメンタル検索にも対応。

### yuki-yano/fuzzy-motion.vim

| キー       | 動作         |
| ---------- | ------------ |
| `<Space>m` | ファジー移動 |

### kbwo/vim-shareedit

共同編集（`ShareEditStartServer` / `ShareEditConnect`コマンド）。

### folke/snacks.nvim

多機能プラグイン。以下の機能を有効化:

- `bigfile`: 大ファイル高速化
- `dashboard`: スタート画面
- `picker`: ファジーファインダー
- `words`: カーソル下単語ハイライト
- `zen`: 集中モード
- `lazygit`: lazygit統合

| キー                        | 動作                          |
| --------------------------- | ----------------------------- |
| `<leader><space>`           | スマートファイル検索          |
| `<leader>ff`                | ファイル検索                  |
| `<leader>fg`                | Grep検索                      |
| `<leader>fb`                | バッファ一覧                  |
| `<leader>fr`                | 最近のファイル                |
| `<leader>fh`                | ヘルプ検索                    |
| `<leader>gg`                | Lazygit                       |
| `<leader>gf`                | 現ファイルのGitログ           |
| `<leader>gl`                | Gitログ                       |
| `<leader>gb`                | Git Browse                    |
| `<leader>bd` / `<leader>bo` | バッファ削除 / 他バッファ削除 |
| `<leader>z` / `<leader>Z`   | Zenモード / ズーム            |
| `<leader>un` / `<leader>nh` | 通知消去 / 通知履歴           |

---

## Plugin（非VSCode）

### projekt0n/github-nvim-theme

カラースキーム（`github_dark_default`）。

### yuki-yano/fzf-preview.vim

FZFを使ったファイル・LSP情報のプレビュー付き検索。

| キー          | 動作                     |
| ------------- | ------------------------ |
| `<leader>pf`  | プロジェクトファイル検索 |
| `<leader>pb`  | バッファ一覧             |
| `<leader>pr`  | リソース一覧             |
| `<leader>ld`  | 診断情報                 |
| `<leader>lr`  | LSP参照                  |
| `<leader>ldf` | LSP定義                  |

### voldikss/vim-translator

テキスト翻訳（`TranslateW`コマンド）。

### lewis6991/gitsigns.nvim

Gitの差分をgutterに表示。行のblame表示あり。

| キー         | 動作             |
| ------------ | ---------------- |
| `[c` / `]c`  | 前/次のhunkへ    |
| `<leader>hs` | hunkをステージ   |
| `<leader>hr` | hunkをリセット   |
| `<leader>hp` | hunkをプレビュー |
| `<leader>hb` | 行のblame表示    |

### nvim-neo-tree/neo-tree.nvim

ファイルエクスプローラー。dotfileや.gitignoreファイルも表示。

| キー         | 動作                             |
| ------------ | -------------------------------- |
| `<leader>ss` | ファイルエクスプローラーをトグル |

### nvim-lualine/lualine.nvim

ステータスバー（autoテーマ、globalstatus）。

### folke/which-key.nvim

キー入力後にサジェストポップアップを表示。

### nvim-tree/nvim-web-devicons

ファイルアイコン。拡張子・ファイル名ごとにカスタムアイコンあり。

### lambdalisue/gin.vim

Denops製Git操作（`Gin`, `GinStatus`, `GinBranch`等のコマンド）。

### williamboman/mason.nvim

LSPサーバーインストーラー。

### hrsh7th/nvim-cmp

補完エンジン。ソース: `nvim_lsp`, `luasnip`, `buffer`, `path`。

| キー                | 動作                          |
| ------------------- | ----------------------------- |
| `<C-n>` / `<C-p>`   | 次/前の候補                   |
| `<Tab>` / `<S-Tab>` | 候補選択 / スニペットジャンプ |
| `<CR>`              | 確定                          |
| `<C-Space>`         | 補完トリガー                  |
| `<C-d>` / `<C-f>`   | ドキュメントスクロール        |

コマンドライン(`:`)とインクリメンタル検索(`/`,`?`)にも補完あり。

### LSPサーバー（cmp-nvim-lsp経由）

| サーバー | 言語                 |
| -------- | -------------------- |
| pyright  | Python（型チェック） |
| ruff     | Python（リント）     |
| clangd   | C/C++                |

| キー       | 動作             |
| ---------- | ---------------- |
| `K`        | ホバー情報       |
| `gd`       | 定義へ移動       |
| `gr`       | 参照一覧         |
| `<Space>r` | シンボルリネーム |
| `<Space>a` | コードアクション |

### nvimdev/lspsaga.nvim

LSP UIの強化（丸角ボーダー、lightbulb等）。

| キー | 動作               |
| ---- | ------------------ |
| `gv` | ホバードキュメント |
| `gy` | 行の診断情報       |
| `gd` | 定義へ移動         |
| `gr` | LSPファインダー    |

### nvimtools/none-ls.nvim

- **Black**（Python）: 保存時に自動フォーマット

### MeanderingProgrammer/render-markdown.nvim

Markdownをノーマルモードでリッチレンダリング。

### iamcco/markdown-preview.nvim

| キー         | 動作                       |
| ------------ | -------------------------- |
| `<leader>mp` | ブラウザプレビューをトグル |

### tpope/vim-fugitive

| キー         | 動作           |
| ------------ | -------------- |
| `<leader>gs` | Git Status     |
| `<leader>gd` | Git Diff Split |
| `<leader>gb` | Git Blame      |
| `<leader>gl` | Git Log        |

### zk-org/zk-nvim

Zettelkastenノート管理。

| キー         | 動作                   |
| ------------ | ---------------------- |
| `<leader>zn` | 新規ノート作成         |
| `<leader>zo` | ノート一覧（更新日順） |
| `<leader>zt` | タグ一覧               |
| `<leader>zf` | ノート検索             |

### coder/claudecode.nvim

| キー         | 動作                              |
| ------------ | --------------------------------- |
| `<leader>ac` | Claude Codeをトグル               |
| `<leader>af` | Claude Codeにフォーカス           |
| `<leader>ar` | セッションを再開                  |
| `<leader>aC` | 会話を継続                        |
| `<leader>am` | モデル選択                        |
| `<leader>ab` | 現在のファイルをClaude Codeに追加 |
| `<leader>as` | 選択範囲を送信（visual）          |
| `<leader>aa` | 変更を承認                        |
| `<leader>ad` | 変更を拒否                        |

---

## カスタム関数・コマンド

### :ToggleMotion

`w/e/b`を通常の単語移動とCamelCase移動でトグルするコマンド。
ファイル: `lua/function/toggleMotion.lua`

---

## 無効化されているもの

- **Telescope** — 完全にコメントアウト（Snacksのpickerを使用）
- **rapan931/lasterisk.nvim** — ロードはされるがマッピングはすべてコメントアウト
- **config/lspconfig, config/cmpconfig** — init.luaでコメントアウト（lazy_plugins_lsp/cmpで代替）
