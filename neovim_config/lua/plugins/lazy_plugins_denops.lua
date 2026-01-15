return {
  {
    "vim-denops/denops.vim",
    -- event = "VeryLazy",
    lazy = false,
    init = function()
      -- vim.g["denops#server#deno_args"] = {"--no-lock"}
      vim.g['denops#deno_options'] = {
        '--allow-net',
        '--allow-read',
        '--allow-write',
        '--allow-run',
        '--no-lock',
      }
    end,
  },
  {
    "lambdalisue/vim-kensaku",
    dependencies = { "vim-denops/denops.vim" },
    lazy = false,
    config = function()
      -- この部分を削除または以下に変更
      vim.keymap.set("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "lambdalisue/vim-kensaku-search",
    dependencies = { "lambdalisue/vim-kensaku" },
    event = "VeryLazy",
  },
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = { "vim-denops/denops.vim" },
    event = "VeryLazy",
    init = function()
      vim.keymap.set("n", "<Space>m", "<Plug>(fuzzy-motion)", { noremap = false })
    end,
  },
  {
    "kbwo/vim-shareedit",
    dependencies = {"vim-denops/denops.vim" -- 🔑 Denops の依存
    },
    cmd = {"ShareEditStartServer", "ShareEditConnect"},
    event = {"BufReadPre", "BufNewFile"}
  },
  {
    "lambdalisue/gin.vim",
    dependencies = { "vim-denops/denops.vim" },
    cmd = { "Gin", "GinBuffer", "GinBranch", "GinStatus" },
  }
}
