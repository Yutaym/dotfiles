-- 起動時間計測開始
local start_time = vim.loop.hrtime()

require('base')
require('mapping')
require("config.lazy")

-- require("config.toggleterm")
require("config.comment")
require("config.plugins")

-- if (vim.g.vscode == nil) then
--     require("config.lspconfig")
--     require("config.cmpconfig")
-- end

require("function.toggleMotion")

-- require('Comment').setup()

-- 起動時間計測終了と表示
vim.defer_fn(function()
    local end_time = vim.loop.hrtime()
    local elapsed = (end_time - start_time) / 1000000  -- ミリ秒に変換
    local message = string.format("⚡ Neovim 起動時間: %.2f ms", elapsed)
    vim.notify(message, vim.log.levels.INFO)
end, 0)
