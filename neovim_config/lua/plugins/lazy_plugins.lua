return {
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        config = true
      --{'akinsho/toggleterm.nvim', version = "*", opts = {--[[ things you want to change go here]]}}
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    },
    {
        'numToStr/Comment.nvim',
        --opts = {
            -- add any options here
        --}
    },
    {
        'vim-scripts/ReplaceWithRegister',
    },
    {
        'vim-scripts/camelcasemotion',
    },

}
