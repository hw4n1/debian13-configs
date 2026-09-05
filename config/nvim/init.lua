-- Neovim para trabajar en el kernel de Linux y en paquetes de Debian.
--
-- El directorio entero esta enlazado desde el repo (~/setup/config/nvim),
-- asi que lazy-lock.json cae dentro del repo y las versiones de los plugins
-- quedan versionadas con el resto de la maquina. Editar aqui edita la fuente.
--
-- Requiere Neovim >= 0.11 por vim.lsp.config/vim.lsp.enable. El binario lo
-- instala modules/editor.sh desde upstream: el de Debian trixie es 0.10.4.

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("opciones")

pcall(vim.cmd.colorscheme, "aureola")

-- lazy.nvim se instala solo la primera vez que arranca nvim.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local salida = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "no pude clonar lazy.nvim:\n", "ErrorMsg" },
      { salida, "WarningMsg" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "aureola" } },
  ui = { border = "rounded" },
  change_detection = { notify = false },
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "zipPlugin", "tohtml", "tutor" },
    },
  },
})

require("sintaxis")
require("lsp")
require("kernel")
require("atajos")
