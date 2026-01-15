if not vim.g.neovide then
  return {
    {
      "lewis6991/gitsigns.nvim",
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
          map({ "n", "v" }, "<Space>hs", gs.stage_hunk, "Stage Hunk")
          map({ "n", "v" }, "<Space>hr", gs.reset_hunk, "Reset Hunk")
          map("n", "<Space>hp", gs.preview_hunk, "Preview Hunk")
          map("n", "<Space>hb", function()
            gs.blame_line({ full = true })
          end, "Blame Line")
        end,
      },
    },
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      cmd = "Neotree",
      keys = {
        { "<Space>e", "<cmd>Neotree toggle<CR>", desc = "File Explorer" },
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
    },
    {
      "nvim-lualine/lualine.nvim",
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
      event = "VeryLazy",
      opts = {},
    },
    {
        'nvim-tree/nvim-web-devicons',
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
else
  return {}
end
