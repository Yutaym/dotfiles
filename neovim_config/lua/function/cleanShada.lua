-- ShaDa 書き込み時に残った一時ファイル (main.shada.tmp.a ～ .tmp.z) を削除する
-- 26 個すべて埋まると E138 で ShaDa が書けなくなるため
function cleanShada()
    local shada_dir = vim.fn.stdpath('state') .. '/shada'
    local tmp_files = vim.fn.glob(shada_dir .. '/*.shada.tmp.*', false, true)

    if #tmp_files == 0 then
        print("CleanShada: no tmp files")
        return
    end

    local removed = 0
    for _, file in ipairs(tmp_files) do
        if vim.fn.delete(file) == 0 then
            removed = removed + 1
        else
            vim.notify("CleanShada: failed to delete " .. file, vim.log.levels.WARN)
        end
    end
    print("CleanShada: removed " .. removed .. " tmp files")
end

vim.api.nvim_create_user_command( 'CleanShada', function() cleanShada() end, {} )
