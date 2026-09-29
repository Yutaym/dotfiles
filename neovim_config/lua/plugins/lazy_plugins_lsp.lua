return {
  {
    "williamboman/mason.nvim",
    cond = function() return vim.g.vscode == nil end,
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },

  -- mason でインストールするツールを自動で揃える
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cond = function() return vim.g.vscode == nil end,
    lazy = false,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "pyright",
        "ruff",
        "clangd",
        "lua-language-server",
        "tree-sitter-cli", -- nvim-treesitter (main) のパーサービルドに必要
      },
    },
  },

  -- nvim-lspconfig は削除して、Neovim のネイティブ LSP を使用
  {
    "hrsh7th/cmp-nvim-lsp",
    cond = function() return vim.g.vscode == nil end,
    lazy = false,
    config = function()
      -- LSP サーバーの設定
      local on_attach = function(client, bufnr)
        local bufmap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        bufmap("n", "<leader>r", vim.lsp.buf.rename, "Rename")
        bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        -- K / gr* は他のマッピングで使うため、LSP 操作は gx プレフィックスにまとめる
        bufmap("n", "gxh", vim.lsp.buf.hover, "Hover")
        bufmap("n", "gxd", vim.diagnostic.open_float, "Line Diagnostics")
        bufmap("n", "gxi", vim.lsp.buf.implementation, "Go to Implementation")
        bufmap("n", "gxr", vim.lsp.buf.references, "References")
        bufmap("n", "gxn", vim.lsp.buf.rename, "Rename")
        bufmap({"n", "x"}, "gxa", vim.lsp.buf.code_action, "Code Action")
      end

      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- ⭐ 新しい vim.lsp.config API を使用

      -- Pyright の設定
      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        filetypes = { "python" },
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
            },
          },
        },
        capabilities = capabilities,
        on_attach = on_attach,
      }

      -- Clangd の設定
      vim.lsp.config.clangd = {
        cmd = { "clangd" },
        root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", ".git" },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        capabilities = capabilities,
        on_attach = on_attach,
      }

      -- Ruff の設定（リント + フォーマット）
      -- augroup は一度だけ作り、バッファごとにはそのバッファの autocmd だけを消す
      local format_group = vim.api.nvim_create_augroup("RuffFormat", { clear = true })
      vim.lsp.config.ruff = {
        cmd = { "ruff", "server" },
        root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
        filetypes = { "python" },
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          -- hover は pyright に任せる
          client.server_capabilities.hoverProvider = false
          vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_group,
            buffer = bufnr,
            callback = function()
              -- 保存前に整形を終わらせるため同期で実行する
              vim.lsp.buf.format({ bufnr = bufnr, name = "ruff", async = false })
            end,
          })
        end,
      }

      -- Lua Language Server の設定（Neovim 設定の編集用）
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
        filetypes = { "lua" },
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim", "Snacks" } },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
        capabilities = capabilities,
        on_attach = on_attach,
      }

      -- ⭐ LSP サーバーを有効化
      vim.lsp.enable("pyright")
      vim.lsp.enable("clangd")
      vim.lsp.enable("ruff")
      vim.lsp.enable("lua_ls")

      -- フロートウィンドウ（hover / signature help / 診断）を丸角にする
      vim.o.winborder = "rounded"
      vim.opt.signcolumn = "yes"
    end,
  },
}
