if ( vim.g.vscode == false ) then
    return {
        {
            'nvim-lualine/lualine.nvim',
            version = "*",
        },
    }
else
    return {}
end
