return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },

  -- nvim-lspconfig は削除して、Neovim のネイティブ LSP を使用
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = false,
    config = function()
      -- LSP サーバーの設定
      local on_attach = function(client, bufnr)
        local bufmap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        bufmap("n", "K", vim.lsp.buf.hover, "Hover")
        bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        bufmap("n", "gr", vim.lsp.buf.references, "References")
        bufmap("n", "<Space>r", vim.lsp.buf.rename, "Rename")
        bufmap("n", "<Space>a", vim.lsp.buf.code_action, "Code Action")
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

      -- Ruff の設定
      vim.lsp.config.ruff = {
        cmd = { "ruff", "server" },
        root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
        filetypes = { "python" },
        capabilities = capabilities,
        on_attach = on_attach,
      }

      -- ⭐ LSP サーバーを有効化
      vim.lsp.enable("pyright")
      vim.lsp.enable("clangd")
      vim.lsp.enable("ruff")
    end,
  },

  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup({
        ui = { border = "rounded" },
        lightbulb = {
          enable = true,
          enable_in_insert = false,
        },
      })

      local ok, lsp_signature = pcall(require, "lsp_signature")
      if ok then
        lsp_signature.setup({
          floating_window = false,
          hint_enable = false,
        })
      end

      vim.opt.signcolumn = "yes"

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover,
        { border = "rounded", max_width = 60, max_height = 20 }
      )
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help,
        { border = "rounded", max_width = 60, max_height = 10 }
      )

      local keymap = vim.keymap.set
      keymap("n", "gv", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Doc" })
      keymap("n", "gy", "<cmd>Lspsaga show_line_diagnostics<CR>", { desc = "Line Diagnostics" })
      keymap("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to Definition" })
      keymap("n", "gr", "<cmd>Lspsaga finder<CR>", { desc = "LSP Finder" })
      keymap("n", "<Space>r", "<cmd>Lspsaga rename<CR>", { desc = "Rename Symbol" })
      keymap("n", "<Space>a", "<cmd>Lspsaga code_action<CR>", { desc = "Code Action" })
    end,
  },
}
