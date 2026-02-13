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
    event = "CmdlineEnter",
    config = function()
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
    keys = {
      {"<Space>m", "<Plug>(fuzzy-motion)", mode = "n", desc = "Fuzzy Motion"},
    },
  },
  {
    "kbwo/vim-shareedit",
    dependencies = { "vim-denops/denops.vim" },
    cmd = {"ShareEditStartServer", "ShareEditConnect"},
  },
  {
    "lambdalisue/gin.vim",
    cond = function() return vim.g.vscode == nil end,
    dependencies = { "vim-denops/denops.vim" },
    cmd = { "Gin", "GinBuffer", "GinBranch", "GinStatus" },
  }
}
