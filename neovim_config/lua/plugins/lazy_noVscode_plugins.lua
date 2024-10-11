if ( vim.g.vscode == false ) then
    return {
    {
            'nvim-lualine/lualine.nvim',
            version = "*",
        },
        {
            'neoclide/coc.nvim',
        },
        {
            'yuki-yano/fzf-preview.vim',
        },
    }
else
    return {}
end
