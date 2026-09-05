-- Resaltado.
--
-- Aqui no hay nvim-treesitter y es a proposito. Su rama main exige el CLI
-- tree-sitter 0.26.1 o superior para compilar parsers, y Debian trixie
-- congela tree-sitter-cli en 0.22.6: el plugin se instala, falla al compilar
-- cada parser y no resalta nada. Instalar algo que no puede funcionar es
-- justo lo que este repo evita.
--
-- Lo que queda cubre el caso de uso real:
--   * Neovim 0.12 trae de serie los parsers de c, lua, vim, vimdoc, markdown
--     y query. C es el 95% del kernel, asi que el arbol se lee con
--     treesitter de verdad, sin plugins.
--   * kconfig, dts, diff, gitcommit, make, bash, python y rust caen en la
--     sintaxis clasica del runtime, que para leer parches va sobrada.
--
-- Si algun dia entra un tree-sitter-cli reciente (backports, cargo install),
-- anadir nvim-treesitter es una espec de diez lineas en lua/plugins/.

local INCLUIDOS = {
  c = true,
  lua = true,
  markdown = true,
  query = true,
  vim = true,
  vimdoc = true,
}

-- Un fichero de varios MB (los hay en el kernel: tablas generadas, firmware
-- en hex) tarda mas en parsearse que en abrirse.
local LIMITE_BYTES = 2 * 1024 * 1024

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("aureola_sintaxis", { clear = true }),
  callback = function(ev)
    if not INCLUIDOS[ev.match] then
      return
    end

    local lineas = vim.api.nvim_buf_line_count(ev.buf)
    if vim.api.nvim_buf_get_offset(ev.buf, lineas) > LIMITE_BYTES then
      return
    end

    pcall(vim.treesitter.start, ev.buf)
  end,
})
