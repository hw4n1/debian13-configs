-- Telescope. En un arbol de 90.000 ficheros el buscador no es un lujo: es
-- la unica forma de moverse sin saberte las rutas de memoria.

return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    lazy = true,
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        -- El matcher en C. Sin el, teclear en un arbol del tamano del kernel
        -- va a tirones porque el fuzzy en Lua no da abasto.
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix = "󰫢  ",
          selection_caret = "󰋑 ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_strategy = "flex",
          layout_config = {
            prompt_position = "top",
            horizontal = { preview_width = 0.55 },
            flex = { flip_columns = 160 },
          },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case", "--trim",
          },
          -- Artefactos de construccion del kernel: aparecen a miles y no se
          -- abren nunca.
          file_ignore_patterns = {
            "%.o$", "%.a$", "%.ko$", "%.mod$", "%.mod%.c$", "%.cmd$",
            "%.order$", "%.symvers$", "%.d$", "%.su$", "%.tmp$",
            "^%.git/", "/%.git/", "^build/", "%.pyc$",
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = {
            -- ripgrep lista ficheros mucho mas rapido que find y respeta el
            -- .gitignore del arbol, que ya excluye lo compilado. Si no esta
            -- instalado se deja el buscador por defecto de telescope: mas
            -- lento, pero funciona.
            find_command = vim.fn.executable("rg") == 1
              and { "rg", "--files", "--hidden", "--glob", "!**/.git/*" }
              or nil,
          },
          buffers = {
            sort_mru = true,
            mappings = { i = { ["<C-d>"] = actions.delete_buffer } },
          },
          live_grep = { additional_args = { "--hidden" } },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
    end,
  },
}
