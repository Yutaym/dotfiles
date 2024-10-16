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
    table.insert(pluginlist, {
        'nvim-lualine/lualine.nvim',
        version = "*"
    })
    table.insert(pluginlist, {
        'neoclide/coc.nvim',
        branch = 'master',
        build = 'npm ci'
    })
    table.insert(pluginlist, {'yuki-yano/fzf-preview.vim'})
end
return pluginlist
