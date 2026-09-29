# Neovim 設定まとめ

`neovim_config/` の設定内容。素の Neovim と VSCode Neovim（`vim.g.vscode`）の両方で使う前提で、VSCode 上では UI 系・LSP 系プラグインを読み込まない。

## ファイル構成

```text
neovim_config/
├── init.lua                  # エントリーポイント
├── install_nvim.ps1          # インストーラー（Windows）
├── install_nvim.sh           # インストーラー（Linux）
├── .textlintrc.json
└── lua/
    ├── base.lua              # 基本オプション
    ├── mapping.lua           # キーマッピング
    ├── config/
    │   └── lazy.lua          # lazy.nvim のブートストラップ
    ├── function/
    │   ├── toggleMotion.lua  # :ToggleMotion
    │   └── cleanShada.lua    # :CleanShada
    └── plugins/              # lazy.nvim のプラグイン spec（ディレクトリごと import）
        ├── lazy_plugins.lua             # 編集系（共通）
        ├── lazy_plugins_denops.lua      # Denops 系
        ├── lazy_plugins_snacks.lua      # snacks.nvim
        ├── lazy_plugins_ui.lua          # gitsigns / neo-tree / lualine など
        ├── lazy_plugins_novscode.lua    # テーマ / translator など
        ├── lazy_plugins_lsp.lua         # LSP / mason / 保存時フォーマット
        ├── lazy_plugins_cmp.lua         # 補完
        ├── lazy_plugins_notes.lua       # Markdown / Git / zk
        ├── lazy_plugins_claudecode.lua  # Claude Code 連携
        └── lazy_toggle_term.lua         # toggleterm
```

## インストール

| OS      | コマンド                              |
| ------- | ------------------------------------- |
| Windows | `pwsh neovim_config/install_nvim.ps1` |
| Linux   | `bash neovim_config/install_nvim.sh`  |

どちらも以下を行う（済んでいる処理はスキップ）。

1. Neovim 本体を GitHub の最新リリースからインストール
   - Windows: `%LOCALAPPDATA%\Programs\Neovim`
   - Linux: `~/.local`（x86_64 用 tarball）
2. `bin` が PATH に無ければ追加
   - Windows: ユーザー環境変数 `Path`
   - Linux: `~/.zshrc` / `~/.bashrc` に `export PATH="$HOME/.local/bin:$PATH"` を追記
3. `init.lua` / `lua` / `.textlintrc.json` を設定ディレクトリへシンボリックリンク
   - Windows: `%XDG_CONFIG_HOME%\nvim`（未設定なら `%LOCALAPPDATA%\nvim`）
   - Linux: `${XDG_CONFIG_HOME:-~/.config}/nvim`
   - リンク先に既存ファイルがある場合は警告してスキップ

> Windows でシンボリックリンクを作るには「開発者モード」の有効化か管理者権限が必要。

外部依存: `git`（lazy.nvim の取得）、`deno`（Denops 系）、C コンパイラ（treesitter パーサーのビルド）、`lazygit`（任意）、`npm`（markdown-preview のビルド）、`zk`。

LSP サーバーと `tree-sitter` CLI は、初回起動時に mason-tool-installer が自動でインストールする（[LSP](#lspneovim-ネイティブ-vimlspconfig) 参照）。

---

## init.lua

読み込み順: `base` → `mapping` → `config.lazy` → `function.toggleMotion` → `function.cleanShada`

- 起動時間を計測し、起動直後に `⚡ Neovim 起動時間: xx ms` を通知
- Neovim 0.11+ のデフォルト LSP キーマップ `gri` / `grr` / `grn` / `gra` を削除（ReplaceWithRegister の `gr` と競合するため）。代替は LSP の `gx*` マッピング
- デフォルトの `gx`（カーソル下の URL・パスを開く、n / x）を `gxx` に移動（LSP の `gx*` と前方一致して待たされるのを防ぐため）

---

## 基本設定 (base.lua)

### エディタ表示
| 設定           | 値                                                 |
| -------------- | -------------------------------------------------- |
| 行番号         | 絶対 + 相対行番号                                  |
| カーソルライン | 有効（インサート中は無効）                         |
| スクロールオフ | 3行                                                |
| 折り返し表示   | 有効                                               |
| 特殊文字表示   | `tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%` |
| conceallevel   | 0（隠さない）                                      |
| showmatch      | 有効（`matchtime = 1`）                            |
| title          | 有効                                               |
| laststatus     | 2                                                  |
| display        | `lastline`                                         |

### 検索
| 設定       | 値                               |
| ---------- | -------------------------------- |
| ignorecase | 有効                             |
| smartcase  | 有効                             |
| wrapscan   | 有効（最終行から先頭に折り返す） |
| incsearch  | 有効                             |
| hlsearch   | 有効                             |

### ファイル・バックアップ
| 設定                 | 値                                   |
| -------------------- | ------------------------------------ |
| swapfile             | 無効                                 |
| backup / writebackup | 無効                                 |
| autoread             | 有効                                 |
| hidden               | 有効（未保存でもバッファ切り替え可） |
| fileencoding         | UTF-8                                |

### インデント
| 設定                               | 値               |
| ---------------------------------- | ---------------- |
| expandtab                          | 有効（スペース） |
| tabstop / shiftwidth / softtabstop | 4                |
| smartindent / autoindent           | 有効             |

### その他
- `foldmethod = marker`, `foldenable = false`
- `updatetime = 300`
- `mouse = "a"`（全モードでマウス有効）
- `virtualedit = onemore`（行末の1文字先までカーソル移動可）
- `whichwrap` に `b,s,h,l,<,>,[,],~` を追加（行をまたいで左右移動）
- `wildmenu` 有効、`wildmode = list:longest,full`
- `lazyredraw = true`, `visualbell = true`
- Ruby / Perl プロバイダを無効化
- `shellslash = true`（Windows のみのオプションなので `pcall` で囲んで設定）

### クリップボード
- WSL: `wl-copy` / `wl-paste` を使うクリップボードプロバイダを設定（`wl-clipboard` が無ければメッセージを表示）
- それ以外: `clipboard` に `unnamed` を追加

---

## キーマッピング (mapping.lua)

**Leader = `<Space>`**

### モード移行
| キー    | 動作                      | モード        |
| ------- | ------------------------- | ------------- |
| `jj`    | ESC                       | i             |
| `<C-j>` | ESC                       | i             |
| `<C-c>` | ESC（InsertLeave も発火） | i, x          |
| `<C-[>` | ノーマルモードへ          | t（非VSCode） |

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
| `<Down>` / `<Up>` | 表示行単位で移動      | n, x   |

### テキスト操作
| キー      | 動作                                     | モード |
| --------- | ---------------------------------------- | ------ |
| `x` / `X` | ブラックホール削除（レジスタを汚さない） | n      |
| `Y`       | 行末までヤンク（`y$`）                   | n      |
| `U`       | Redo（`<C-r>`）                          | n      |
| `gW`      | `gw`（テキスト整形）                     | n      |
| `<C-u>`   | アンドゥ（ESC→u→i）                      | i      |

### 検索・置換
| キー         | 動作                                  | モード |
| ------------ | ------------------------------------- | ------ |
| `ss`         | `/`（検索開始）                       | n      |
| `ss`         | 選択テキストで置換（`:%s/<選択>//g`） | x, v   |
| `sr`         | `:s/`（カーソル行置換）               | n      |
| `sa`         | `:%s/`（全体置換）                    | n      |
| `<ESC><ESC>` | ハイライト消去（`:nohlsearch`）       | n      |

### ウィンドウ・タブ・バッファ操作（`s` プレフィックス）

`s` 単体は `<Nop>`（n, v）にしてプレフィックスとして使う。VSCode では対応する VSCode コマンドを呼ぶ。

| キー                             | 動作（Neovim）              | 動作（VSCode）               |
| -------------------------------- | --------------------------- | ---------------------------- |
| `sd`                             | 水平分割                    | エディタを上に分割           |
| `sv`                             | 垂直分割                    | エディタを右に分割           |
| `sw`                             | 次ウィンドウへ              | 次のエディタグループへ       |
| `sh` / `sj` / `sk` / `sl`        | 左/下/上/右ウィンドウへ移動 | 左/下/上/右へ移動            |
| `so`                             | ウィンドウ最大化            | エディタグループ最大化トグル |
| `sn` / `sp`                      | 次/前タブ                   | 次/前のエディタ              |
| `sq`                             | —                           | エディタを閉じる             |
| `st`                             | —                           | 新規ファイル                 |
| `s=` / `s>` / `s<` / `s+` / `s-` | ウィンドウサイズ調整        | —                            |
| `at`                             | 新規タブ                    | —                            |
| `sbb`                            | 新規バッファ                | —                            |
| `sbq` / `sbd`                    | バッファを閉じる            | —                            |
| `sbp`                            | 前のバッファへ              | —                            |
| `cd`                             | —                           | シンボルのリネーム           |

### インサート / コマンドラインモード補助（Emacs風）
| キー              | 動作      | モード |
| ----------------- | --------- | ------ |
| `<C-a>`           | Home      | i, c   |
| `<C-e>`           | End       | i, c   |
| `<C-b>`           | Left      | i, c   |
| `<C-f>`           | Right     | i, c   |
| `<C-d>`           | Delete    | i, c   |
| `<C-n>` / `<C-p>` | Down / Up | i, c   |

### テキストオブジェクト・選択
| キー       | 動作           | モード |
| ---------- | -------------- | ------ |
| `i<space>` | `iw`（単語内） | o, x   |
| `sa`       | 全選択（ggVG） | v      |
| `ga`       | 全選択（ggVG） | v, x   |

### その他
| キー            | 動作                              |
| --------------- | --------------------------------- |
| `;`             | `:`（n, x）                       |
| `q;`            | `q:`（コマンド履歴）              |
| `(` / `[` / `{` | 閉じ括弧を自動挿入（i、非VSCode） |

---

## Plugin（共通：VSCode でも読み込む）

### folke/lazy.nvim

プラグインマネージャ。`lua/plugins/` をまとめて import。luarocks 連携（`rocks`）は無効。

### kylechui/nvim-surround

囲み文字の追加・変更・削除。filetype 別の追加サラウンド:

| キー | 対象 filetype                      | 内容                                |
| ---- | ---------------------------------- | ----------------------------------- |
| `t`  | html, xml, markdown, tex, plaintex | `<tag>...</tag>`（タグ名を入力）    |
| `c`  | 同上                               | `\command{...}`（コマンド名を入力） |

### vim-scripts/ReplaceWithRegister

| キー  | 動作                             | モード |
| ----- | -------------------------------- | ------ |
| `gr`  | レジスタ内容で置換（オペレータ） | n      |
| `grr` | 行をレジスタ内容で置換           | n      |
| `gr`  | 選択範囲をレジスタ内容で置換     | v, x   |

### vim-scripts/camelcasemotion

CamelCase / snake_case 単位の単語移動。キー入力で遅延読み込み。

| キー                  | 動作                                 | モード |
| --------------------- | ------------------------------------ | ------ |
| `gw` / `ge` / `gb`    | CamelCase 単語移動（w / e / b）      | n, v   |
| `igw` / `ige` / `igb` | CamelCase 単語のテキストオブジェクト | o, v   |

組み込みの `gw`（テキスト整形）は `gW` で、組み込みの `ge` は使えない。

### rhysd/clever-f.vim

`f/F/t/T` を強化（同じキーで次のマッチへ）。`,` で前方リピート、`:` で後方リピート。

### wellle/targets.vim

追加テキストオブジェクト（引数、各種括弧・区切り文字など）。

### monaqa/dial.nvim

インクリメント/デクリメントを拡張。

| キー                | 動作                        | モード |
| ------------------- | --------------------------- | ------ |
| `<C-a>` / `<C-x>`   | インクリメント/デクリメント | n, v   |
| `g<C-a>` / `g<C-x>` | 連番インクリメント          | n, v   |

対象: 10進数、`and/or`, `&&/||`, `yes/no`, `on/off`, `public/private/protected`, `DEBUG/INFO/WARN/ERROR`, `debug/info/warn/error`, 日付（`YYYY/MM/DD`）

### haya14busa/vim-edgemotion

| キー        | 動作                    | モード |
| ----------- | ----------------------- | ------ |
| `gj` / `gk` | 下/上のブロック端へ移動 | n, v   |

### kevinhwang91/nvim-hlslens

検索時にマッチ位置・件数を仮想テキストで表示（`calm_down`, `nearest_only`）。`n` / `N` / `*` / `#` / `g*` / `g#` に統合済み。

### rapan931/lasterisk.nvim

読み込みのみ。マッピングはすべてコメントアウトされている。

### nacro90/numb.nvim

`:123` 入力中に該当行をリアルタイムプレビュー。

### ysmb-wtsg/in-and-out.nvim

| キー     | 動作                     | モード |
| -------- | ------------------------ | ------ |
| `<C-CR>` | 括弧・引用符の外へ抜ける | i      |

### vim-denops/denops.vim

Deno 製プラグインのランタイム。起動時に読み込み、Deno に `--allow-net/read/write/run` と `--no-lock` を渡す。

### lambdalisue/vim-kensaku / vim-kensaku-search

ローマ字で日本語を検索できる（Migemo 相当）。コマンドラインの `<CR>` をフックして `/` 検索に適用。

### yuki-yano/fuzzy-motion.vim

| キー       | 動作         |
| ---------- | ------------ |
| `<leader>m` | ファジー移動 |

### kbwo/vim-shareedit

VSCode などとの編集同期（`:ShareEditStartServer` / `:ShareEditConnect`）。

---

## Plugin（非VSCode のみ）

### projekt0n/github-nvim-theme

カラースキーム `github_dark_default`。コメント・関数はイタリック、キーワード・変数は太字。コンパイル済みテーマファイルが消えていたら（Temp 削除対策）再コンパイルする。

### folke/snacks.nvim

多機能プラグイン。有効な機能:

- `bigfile`: 大きなファイルを高速に開く
- `bufdelete`: レイアウトを崩さずにバッファ削除
- `dashboard`: スタート画面（header / keys / startup）
- `git` / `gitbrowse`: Git 統合・ブラウザで開く
- `lazygit`: lazygit 統合（`lazygit` が PATH にある場合のみ）
- `image`: 画像プレビュー（Windows 以外）
- `input`: 入力ダイアログ
- `picker`: ファジーファインダー
- `quickfile`: ファイルを素早く表示
- `words`: カーソル下の単語をハイライト
- `zen`: 集中モード

`notifier` と `statuscolumn` は無効。デバッグ用に `dd(...)`（inspect）、`bt()`（backtrace）をグローバル定義し、`vim.print` を `dd` に置き換える。

| キー                        | 動作                          |
| --------------------------- | ----------------------------- |
| `<leader>fa`                | スマートファイル検索          |
| `<leader>ff`                | ファイル検索                  |
| `<leader>fg`                | Grep 検索                     |
| `<leader>fb`                | バッファ一覧                  |
| `<leader>fr`                | 最近のファイル                |
| `<leader>fh`                | ヘルプ検索                    |
| `<leader>gg`                | Lazygit                       |
| `<leader>gf`                | 現ファイルの履歴（Lazygit）   |
| `<leader>gl`                | Git ログ（Lazygit）           |
| `<leader>gb`                | Git Browse（n, v）            |
| `<leader>bd` / `<leader>bo` | バッファ削除 / 他バッファ削除 |
| `<leader>zz` / `<leader>Z`  | Zen モード / ズーム           |

### numToStr/Comment.nvim

コメントアウト。nvim-ts-context-commentstring で Vue / TSX など複合ファイルタイプに対応。

| キー  | 動作                       |
| ----- | -------------------------- |
| `gcc` | 行コメントトグル           |
| `gBc` | ブロックコメントトグル     |
| `gc`  | 行コメントオペレータ       |
| `gB`  | ブロックコメントオペレータ |

`gb` は camelcasemotion で使うため、ブロックコメントはデフォルトの `gb` から `gB` に変更している。

### nvim-treesitter/nvim-treesitter

`main` ブランチ版（遅延読み込み非対応のため起動時に読み込む）。起動時に下記のパーサーをインストールし（インストール済みはスキップ）、パーサーがあるファイルタイプでハイライト（`vim.treesitter.start`）とインデント（`indentexpr`）を有効にする。

インストール対象: javascript, typescript, tsx, html, css, vue, lua, python, bash, json, markdown, markdown_inline

パーサーのビルドには `tree-sitter` CLI（mason で自動インストール）と C コンパイラが必要。

### voldikss/vim-translator

テキスト翻訳（`:TranslateW`）。

### jghauser/mkdir.nvim

保存時に存在しない親ディレクトリを自動作成。

### lewis6991/gitsigns.nvim

Git の差分をサインカラムに表示。カーソル行の blame を常時表示。

| キー         | 動作              | モード |
| ------------ | ----------------- | ------ |
| `[c` / `]c`  | 前/次の hunk へ   | n      |
| `<leader>hs` | hunk をステージ   | n, v   |
| `<leader>hr` | hunk をリセット   | n, v   |
| `<leader>hp` | hunk をプレビュー | n      |
| `<leader>hb` | 行の blame 表示   | n      |

### nvim-neo-tree/neo-tree.nvim

ファイルエクスプローラー（左側、幅 30）。dotfile・gitignore 対象も表示し、現在のファイルに追従する。ツリー未初期化時の open 系コマンドのエラーをガードしている。

| キー         | 動作                             |
| ------------ | -------------------------------- |
| `<leader>ss` | ファイルエクスプローラーをトグル |

### nvim-lualine/lualine.nvim

ステータスライン（テーマ auto、globalstatus、セパレータなし）。

### folke/which-key.nvim

キー入力途中で候補をポップアップ表示。

### nvim-tree/nvim-web-devicons

ファイルアイコン。拡張子（log, ts, vue, astro, rs）とファイル名（docker-compose.yml, .env, Makefile）のアイコンを上書き。

### lambdalisue/gin.vim

Denops 製 Git 操作（`:Gin`, `:GinBuffer`, `:GinBranch`, `:GinStatus`）。

### tpope/vim-fugitive

snacks.nvim の `<leader>g*` と分けるため、大文字 `<leader>G*` をプレフィックスにしている。

| キー         | 動作           |
| ------------ | -------------- |
| `<leader>Gs` | Git Status     |
| `<leader>Gd` | Git Diff Split |
| `<leader>Gb` | Git Blame      |
| `<leader>Gl` | Git Log        |

### LSP（Neovim ネイティブ `vim.lsp.config`）

nvim-lspconfig は使わず、`lazy_plugins_lsp.lua` 内で `vim.lsp.config` / `vim.lsp.enable` を直接呼ぶ。

| サーバー | 言語                                     |
| -------- | ---------------------------------------- |
| pyright  | Python（型チェック `basic`、hover）      |
| ruff     | Python（リント・フォーマット）           |
| clangd   | C / C++ / Objective-C / CUDA             |
| lua_ls   | Lua（`vim` / `Snacks` をグローバルとして認識） |

- **保存時フォーマット**: Python は ruff だけで同期フォーマットする（保存前に整形が終わる）。augroup `RuffFormat` は一度だけ作り、バッファごとにそのバッファの autocmd だけを入れ替える
- ruff の hover は無効化（pyright と重複するため）
- フロートウィンドウは `winborder = rounded` で丸角、`signcolumn = yes`

LSP アタッチ時のバッファローカルキー（`K` / `gr` は他の用途に使うため、LSP 操作は `gx*` にまとめている）:

| キー       | 動作                     |
| ---------- | ------------------------ |
| `gd`       | 定義へ移動               |
| `<leader>r` | シンボルリネーム         |
| `<leader>ca` | コードアクション         |
| `gxh`      | ホバー情報               |
| `gxd`      | 行の診断情報             |
| `gxi`      | 実装へ移動               |
| `gxr`      | 参照一覧                 |
| `gxn`      | リネーム                 |
| `gxa`      | コードアクション（n, x） |

### williamboman/mason.nvim / mason-tool-installer.nvim

起動時に以下のツールが無ければ自動インストールする（`:Mason` で状態確認）。

- `pyright`, `ruff`, `clangd`, `lua-language-server`
- `tree-sitter-cli`（nvim-treesitter のパーサービルド用）

### hrsh7th/nvim-cmp

補完エンジン（`InsertEnter` で読み込み）。ソース: `nvim_lsp`, `luasnip`, `buffer`, `path`。lspkind でアイコン + 種別を表示し、lsp_signature で引数ヒントを表示。

| キー                | 動作                          |
| ------------------- | ----------------------------- |
| `<C-n>` / `<C-p>`   | 次/前の候補                   |
| `<Tab>` / `<S-Tab>` | 候補選択 / スニペットジャンプ |
| `<CR>`              | 確定                          |
| `<C-Space>`         | 補完トリガー                  |
| `<C-d>` / `<C-f>`   | ドキュメントスクロール        |

コマンドライン `:`（path, cmdline）と検索 `/` `?`（buffer）にも補完あり。

### MeanderingProgrammer/render-markdown.nvim

Markdown をノーマル / コマンドモードでリッチ表示。

### iamcco/markdown-preview.nvim

ブラウザでプレビュー（ダークテーマ、バッファを離れると自動で閉じる）。

| キー         | 動作                       |
| ------------ | -------------------------- |
| `<leader>Mp` | ブラウザプレビューをトグル |

### zk-org/zk-nvim

Zettelkasten ノート管理（zk LSP を markdown に自動アタッチ）。一覧・検索には snacks の picker（`snacks_picker`）を使う。

| キー         | 動作                   |
| ------------ | ---------------------- |
| `<leader>zn` | 新規ノート作成         |
| `<leader>zo` | ノート一覧（更新日順） |
| `<leader>zt` | タグ一覧               |
| `<leader>zf` | ノート検索             |

### akinsho/toggleterm.nvim

ターミナル（水平分割、高さ 20）。`<leader>t` か `:ToggleTerm` で読み込む。ターミナルモードのキーは toggleterm のターミナルだけに設定する（claudecode.nvim など他のターミナルには影響しない）。

| キー        | 動作               | モード |
| ----------- | ------------------ | ------ |
| `<leader>t` | ターミナルをトグル | n      |
| `jj`        | ノーマルモードへ   | t      |
| `<Esc>`     | ノーマルモードへ   | t      |

### coder/claudecode.nvim

Claude Code 連携（snacks のターミナルで右側 40% に表示、選択範囲を追跡）。

| キー         | 動作                     |
| ------------ | ------------------------ |
| `<leader>ac` | Claude Code をトグル     |
| `<leader>af` | Claude Code にフォーカス |
| `<leader>ar` | セッションを再開         |
| `<leader>aC` | 会話を継続               |
| `<leader>am` | モデル選択               |
| `<leader>ab` | 現在のファイルを追加     |
| `<leader>as` | 選択範囲を送信（v）      |
| `<leader>aa` | 変更を承認               |
| `<leader>ad` | 変更を拒否               |

---

## カスタムコマンド

| コマンド        | 内容                                                                                              | ファイル                        |
| --------------- | ------------------------------------------------------------------------------------------------- | ------------------------------- |
| `:ToggleMotion` | `w` / `e` / `b` / `iw` / `ie` / `ib` を通常の単語移動と CamelCase 移動で切り替える                | `lua/function/toggleMotion.lua` |
| `:CleanShada`   | ShaDa の一時ファイル（`*.shada.tmp.*`）を削除する。26 個溜まると E138 で ShaDa が書けなくなるため | `lua/function/cleanShada.lua`   |

---

## 無効化されているもの

- **yuki-yano/fzf-preview.vim** — `enabled = false`（`main` ブランチはビルドが必要で動かないため。snacks の picker で代替）。キーは `<leader>pf` / `pb` / `pr` / `ldd`（診断）/ `lr` / `ldf`
- **rapan931/lasterisk.nvim** — 読み込みのみでマッピングは全てコメントアウト
- **snacks の notifier / statuscolumn** — 無効（notifier 用の `<leader>un` / `<leader>nh` もコメントアウト）
