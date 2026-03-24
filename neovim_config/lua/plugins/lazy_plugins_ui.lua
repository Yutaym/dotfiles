return {
    {
      "lewis6991/gitsigns.nvim",
      cond = function() return vim.g.vscode == nil end,
      event = { "BufReadPre", "BufNewFile" },
      opts = {
        current_line_blame = true,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end
          map("n", "[c", gs.prev_hunk, "Prev Hunk")
          map("n", "]c", gs.next_hunk, "Next Hunk")
          map({ "n", "v" }, "<leader>hs", gs.stage_hunk, "Stage Hunk")
          map({ "n", "v" }, "<leader>hr", gs.reset_hunk, "Reset Hunk")
          map("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end, "Blame Line")
        end,
      },
    },
    {
      "nvim-neo-tree/neo-tree.nvim",
      cond = function() return vim.g.vscode == nil end,
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      cmd = "Neotree",
      keys = {
        { "<leader>ss", "<cmd>Neotree toggle<CR>", desc = "File Explorer" },
      },
      opts = {
        window = { position = "left", width = 30 },
        filesystem = {
          follow_current_file = { enabled = true },
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      },
      config = function(_, opts)
        require("neo-tree").setup(opts)

        local ok, common_commands = pcall(require, "neo-tree.sources.common.commands")
        if not ok then
          return
        end

        local function with_tree_guard(fn)
          return function(state, ...)
            if not (state and state.tree and type(state.tree.get_node) == "function") then
              vim.notify("Neo-tree の状態が未初期化です。もう一度開き直してください。", vim.log.levels.WARN)
              return
            end
            return fn(state, ...)
          end
        end

        for _, name in ipairs({
          "open",
          "open_split",
          "open_vsplit",
          "open_tabnew",
          "open_drop",
          "open_with_window_picker",
          "open_rightbelow_vs",
          "open_leftabove_vs",
          "open_leftbelow_vs",
          "open_rightabove_vs",
        }) do
          if type(common_commands[name]) == "function" then
            common_commands[name] = with_tree_guard(common_commands[name])
          end
        end
      end,
    },
    {
      "nvim-lualine/lualine.nvim",
      cond = function() return vim.g.vscode == nil end,
      dependencies = { "nvim-tree/nvim-web-devicons" },
      event = "VeryLazy",
      opts = {
        options = {
          theme = "auto",
          icons_enabled = true,
          globalstatus = true,
          section_separators = "",
          component_separators = "",
        },
      },
    },
    {
      "folke/which-key.nvim",
      cond = function() return vim.g.vscode == nil end,
      event = "VeryLazy",
      opts = {},
    },
    {
        'nvim-tree/nvim-web-devicons',
        cond = function() return vim.g.vscode == nil end,
        opts = {
            color_icons = true,
            default = true,
            strict = true, -- keep highlight groups consistent when overriding
            override_by_extension = {
                log = { icon = "", color = "#6d8086", name = "Log" },
                ts  = { icon = "", color = "#3178c6", name = "TypeScript" },
                vue = { icon = "﵂", color = "#41b883", name = "Vue" },
                astro = { icon = "", color = "#ff5d01", name = "Astro" },
                rs  = { icon = "", color = "#dea584", name = "Rust" },
            },
            override_by_filename = {
                ["docker-compose.yml"] = { icon = "", color = "#458ee6", name = "DockerCompose" },
                [".env"] = { icon = "", color = "#6d8086", name = "Env" },
                ["Makefile"] = { icon = "", color = "#e37933", name = "Makefile" },
            },
        }
    },
}
