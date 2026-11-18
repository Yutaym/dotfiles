return {
  {
    "vim-denops/denops.vim",
    -- event = "VeryLazy",
    lazy = false,
    init = function()
      -- Windows: Git Bash 等で SHELL が設定されていると exepath('deno') が拡張子なしの
      -- シェル用 shim を返し、jobstart が -1 で失敗する。deno.cmd を明示する。
      if vim.fn.has('win32') == 1 then
        local deno_cmd = vim.fn.exepath('deno.cmd')
        if deno_cmd ~= '' then
          vim.g['denops#deno'] = deno_cmd
        end
      end
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
      {"<leader>m", "<Plug>(fuzzy-motion)", mode = "n", desc = "Fuzzy Motion"},
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
