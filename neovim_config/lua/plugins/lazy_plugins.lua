local pluginlist = {}
table.insert(pluginlist, {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = true
    -- {'akinsho/toggleterm.nvim', version = "*", opts = {--[[ things you want to change go here]]}}
})
table.insert(pluginlist, {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
})
table.insert(pluginlist, {'numToStr/Comment.nvim' -- opts = {
-- add any options here
-- }
})
table.insert(pluginlist, {'vim-scripts/ReplaceWithRegister'})
table.insert(pluginlist, {'vim-scripts/camelcasemotion'})
table.insert(pluginlist, {'rhysd/clever-f.vim'})
table.insert(pluginlist, {'wellle/targets.vim'})
table.insert(pluginlist, {'monaqa/dial.nvim'})
table.insert(pluginlist, {'haya14busa/vim-edgemotion'})
table.insert(pluginlist, {'rapan931/lasterisk.nvim'})
table.insert(pluginlist, {'kevinhwang91/nvim-hlslens'})
-- table.insert(pluginlist,{
--     })
-- table.insert(pluginlist,{
--     })
if (vim.g.vscode == nil) then
    -- table.insert(pluginlist, {
    --     'nvim-lualine/lualine.nvim',
    --     version = "*"
    -- })
    -- table.insert(pluginlist, {
    --     'neoclide/coc.nvim',
    --     branch = 'master',
    --     build = 'npm ci'
    -- })
    table.insert(pluginlist, {'neovim/nvim-lspconfig'})
    table.insert(pluginlist, {'williamboman/mason.nvim'})
    table.insert(pluginlist, {'williamboman/mason-lspconfig.nvim'})
    table.insert(pluginlist, {'hrsh7th/nvim-cmp'})
    table.insert(pluginlist, {'hrsh7th/cmp-nvim-lsp'})
    table.insert(pluginlist, {'hrsh7th/cmp-buffer'})
    table.insert(pluginlist, {'hrsh7th/cmp-path'})
    table.insert(pluginlist, {'hrsh7th/cmp-cmdline'})
    table.insert(pluginlist, {'hrsh7th/cmp-vsnip'})
    table.insert(pluginlist, {'hrsh7th/vim-vsnip'})
    table.insert(pluginlist, {'onsails/lspkind.nvim'})
    table.insert(pluginlist, {'yuki-yano/fzf-preview.vim'})
    table.insert(pluginlist, {
        'voldikss/vim-translator',
        cmd = {"TranslateW", "TranslateW --target_lang=en"}
    })

end
return pluginlist
