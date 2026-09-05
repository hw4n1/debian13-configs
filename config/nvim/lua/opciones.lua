-- Opciones generales. Lo especifico de C y del arbol del kernel esta en
-- lua/kernel.lua; aqui solo lo que vale para cualquier fichero.

local o = vim.opt

-- Numeros y senales
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 6
o.sidescrolloff = 8

-- Sangrado por defecto. El kernel manda tabs de 8 y eso lo fija kernel.lua;
-- ademas Neovim lee .editorconfig de serie, y el arbol del kernel trae uno.
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.smartindent = true

-- Busqueda
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true
o.inccommand = "split"

-- grep con ripgrep: :grep patron -- salta al quickfix sin salir del editor.
-- En un arbol de 90.000 ficheros la diferencia con el grep de siempre no es
-- sutil.
if vim.fn.executable("rg") == 1 then
  o.grepprg = "rg --vimgrep --smart-case"
  o.grepformat = "%f:%l:%c:%m"
end

-- Ficheros
o.undofile = true
o.swapfile = false
o.backup = false
o.writebackup = false
o.autoread = true

-- Interfaz
o.termguicolors = true
o.splitright = true
o.splitbelow = true
o.showmode = false
o.laststatus = 3
o.pumheight = 12
o.winborder = "rounded"
o.updatetime = 250
o.timeoutlen = 400
o.mouse = "a"
o.confirm = true
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- El portapapeles del sistema, para mover parches entre nvim y el navegador
o.clipboard = "unnamedplus"

-- Artefactos de construccion que no interesa completar ni buscar jamas
o.wildignore:append({
  "*.o", "*.a", "*.ko", "*.mod", "*.mod.c", "*.cmd", "*.order", "*.symvers",
  "*.d", "*.su", "*.so", "*.pyc", "*/.git/*", "*/build/*",
})
o.wildmode = "longest:full,full"

-- Diagnosticos: el kernel genera avisos a paladas, mejor legibles
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "󰫢" },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅖 ",
      [vim.diagnostic.severity.WARN]  = "󰀦 ",
      [vim.diagnostic.severity.INFO]  = "󰋼 ",
      [vim.diagnostic.severity.HINT]  = "󰌵 ",
    },
  },
})

-- Marcar el texto que se acaba de copiar, para ver que se pillo
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("aureola_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Volver a la ultima posicion conocida del fichero
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("aureola_ultima_linea", { clear = true }),
  callback = function(ev)
    local marca = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local total = vim.api.nvim_buf_line_count(ev.buf)
    if marca[1] > 0 and marca[1] <= total then
      pcall(vim.api.nvim_win_set_cursor, 0, marca)
    end
  end,
})
