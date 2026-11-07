-- gitsigns: ver que has tocado sin salir del fichero. Al preparar un parche
-- el margen izquierdo es media revision hecha.

return {
  {
    "lewis6991/gitsigns.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "▁" },
        topdelete    = { text = "▔" },
        changedelete = { text = "▎" },
        untracked    = { text = "┆" },
      },
      current_line_blame = false,
      current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },
      preview_config = { border = "rounded" },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(tecla, accion, descripcion)
          vim.keymap.set("n", tecla, accion,
            { buffer = buf, desc = "git: " .. descripcion })
        end

        map("]h", function() gs.nav_hunk("next") end, "siguiente cambio")
        map("[h", function() gs.nav_hunk("prev") end, "cambio anterior")
        map("<leader>gp", gs.preview_hunk, "ver el cambio")
        map("<leader>gb", gs.blame_line, "quien escribio esta linea")
        map("<leader>gB", gs.toggle_current_line_blame, "blame en linea")
        map("<leader>gr", gs.reset_hunk, "descartar el cambio")
        map("<leader>gd", gs.diffthis, "diff contra el indice")
      end,
    },
  },
}
