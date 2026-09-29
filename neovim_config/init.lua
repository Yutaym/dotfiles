-- 起動時間計測開始
local start_time = vim.uv.hrtime()

require("base")
require("mapping")
require("config.lazy")

-- Neovim 0.11+ のデフォルト gr* LSP キーマップを削除し、ReplaceWithRegister との競合を解消
for _, key in ipairs({ "gri", "grr", "grn", "gra" }) do
  pcall(vim.keymap.del, "n", key)
end
pcall(vim.keymap.del, "x", "gra")

-- デフォルトの gx（カーソル下の URL を開く）を gxx に移し、LSP の gx* と前方一致して待たされるのを防ぐ
for _, mode in ipairs({ "n", "x" }) do
  local gx = vim.fn.maparg("gx", mode, false, true)
  if gx.callback then
    vim.keymap.set(mode, "gxx", gx.callback, { desc = gx.desc })
    vim.keymap.del(mode, "gx")
  end
end

require("function.toggleMotion")
require("function.cleanShada")

-- 起動時間計測終了と表示
vim.defer_fn(function()
    local end_time = vim.uv.hrtime()
    local elapsed = (end_time - start_time) / 1000000  -- ミリ秒に変換
    local message = string.format("⚡ Neovim 起動時間: %.2f ms", elapsed)
    vim.notify(message, vim.log.levels.INFO)
end, 0)
