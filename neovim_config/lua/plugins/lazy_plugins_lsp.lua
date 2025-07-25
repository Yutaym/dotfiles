return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",

    {
      "nvimdev/lspsaga.nvim",
      event = "LspAttach",
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons"
      },
      config = function()
        require("lspsaga").setup({
          ui = { border = "rounded" },
          lightbulb = {
            enable = true,
            enable_in_insert = false
          }
        })

        require("lsp_signature").setup({
          floating_window = false,
          hint_enable = false
        })

        vim.opt.signcolumn = "yes"
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
          border = "rounded", max_width = 60, max_height = 20
        })
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
          border = "rounded", max_width = 60, max_height = 10
        })

        local keymap = vim.keymap.set
        keymap("n", "gv", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Doc" })
        keymap("n", "gy", "<cmd>Lspsaga show_line_diagnostics<CR>", { desc = "Line Diagnostics" })
        keymap("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to Definition" })
        keymap("n", "gr", "<cmd>Lspsaga finder<CR>", { desc = "LSP Finder" })
        keymap("n", "<Space>r", "<cmd>Lspsaga rename<CR>", { desc = "Rename Symbol" })
        keymap("n", "<Space>a", "<cmd>Lspsaga code_action<CR>", { desc = "Code Action" })
      end,
    },
  },
  config = function()
    require("mason").setup()

    require("mason-lspconfig").setup({
      ensure_installed = { "pyright", "clangd", "ruff" }, -- ✅ Mason ID
      automatic_installation = true,
    })

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

    local lspconfig = require("lspconfig")
    local mason_registry = require("mason-registry")

    -- ✅ ruff_lsp を使うには mason 側の "ruff" を確認
    if mason_registry.has_package("ruff") then
      lspconfig.ruff_lsp.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        init_options = {
          settings = {
            args = {},
          },
        },
      })
    end

    require("mason-lspconfig").setup_handlers({
      ["pyright"] = function()
        lspconfig.pyright.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
              },
            },
          },
        })
      end,
      function(server_name)
        if server_name ~= "ruff_lsp" and server_name ~= "pylsp" then
          lspconfig[server_name].setup({
            on_attach = on_attach,
            capabilities = capabilities,
          })
        end
      end,
    })
  end,
}
