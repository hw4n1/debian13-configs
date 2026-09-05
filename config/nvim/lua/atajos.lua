-- Atajos. Los de LSP viven en lua/lsp.lua porque solo tienen sentido con un
-- servidor enganchado al buffer.
--
-- Convenio de prefijos:
--   <leader>f  buscar (find)      <leader>k  kernel
--   <leader>g  git                <leader>x  listas (quickfix, diagnosticos)

local function map(modo, tecla, accion, descripcion)
  vim.keymap.set(modo, tecla, accion, { silent = true, desc = descripcion })
end

-- Basicos
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "quitar el resaltado de busqueda")
map("n", "<leader>w", "<cmd>write<cr>", "guardar")
map("n", "<leader>W", "<cmd>wall<cr>", "guardar todo")

-- Moverse entre ventanas sin el <C-w> de por medio
map("n", "<C-h>", "<C-w>h", "ventana de la izquierda")
map("n", "<C-j>", "<C-w>j", "ventana de abajo")
map("n", "<C-k>", "<C-w>k", "ventana de arriba")
map("n", "<C-l>", "<C-w>l", "ventana de la derecha")

-- Buffers
map("n", "]b", "<cmd>bnext<cr>", "buffer siguiente")
map("n", "[b", "<cmd>bprevious<cr>", "buffer anterior")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "cerrar el buffer")

-- El cursor centrado al saltar: en ficheros de miles de lineas se agradece
map("n", "<C-d>", "<C-d>zz", "media pagina abajo")
map("n", "<C-u>", "<C-u>zz", "media pagina arriba")
map("n", "n", "nzzzv", "siguiente coincidencia")
map("n", "N", "Nzzzv", "coincidencia anterior")

-- Mover bloques enteros en visual, util al reordenar casos de un switch
map("v", "J", ":m '>+1<cr>gv=gv", "bajar la seleccion")
map("v", "K", ":m '<-2<cr>gv=gv", "subir la seleccion")
map("v", "<", "<gv", "menos sangrado, sin perder la seleccion")
map("v", ">", ">gv", "mas sangrado, sin perder la seleccion")

-- Pegar encima de una seleccion sin perder lo que habia en el registro
map("x", "p", '"_dP', "pegar sin machacar el registro")

-- Quickfix: donde caen checkpatch, :grep y :make
map("n", "]q", "<cmd>cnext<cr>zz", "siguiente entrada del quickfix")
map("n", "[q", "<cmd>cprevious<cr>zz", "entrada anterior del quickfix")
map("n", "<leader>xq", function()
  local abierta = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      abierta = true
    end
  end
  vim.cmd(abierta and "cclose" or "copen")
end, "abrir/cerrar el quickfix")

-- Diagnosticos
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "siguiente diagnostico")
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "diagnostico anterior")
map("n", "<leader>e", vim.diagnostic.open_float, "ver el diagnostico")
map("n", "<leader>xd", vim.diagnostic.setqflist, "diagnosticos al quickfix")

-- Busqueda (telescope se carga solo la primera vez que se usa)
local function buscador(nombre, opciones)
  return function()
    require("telescope.builtin")[nombre](opciones or {})
  end
end

map("n", "<leader>ff", buscador("find_files"), "buscar ficheros")
map("n", "<leader>fg", buscador("live_grep"), "buscar texto en el arbol")
map("n", "<leader>fw", buscador("grep_string"), "buscar la palabra bajo el cursor")
map("n", "<leader>fb", buscador("buffers"), "buffers abiertos")
map("n", "<leader>fr", buscador("oldfiles"), "ficheros recientes")
map("n", "<leader>fh", buscador("help_tags"), "ayuda de neovim")
map("n", "<leader>fk", buscador("keymaps"), "atajos definidos")
map("n", "<leader>fq", buscador("quickfix"), "historial del quickfix")
map("n", "<leader>f/", buscador("current_buffer_fuzzy_find"), "buscar en este fichero")
map("n", "<leader>gc", buscador("git_commits"), "commits")
map("n", "<leader>gs", buscador("git_status"), "estado de git")

-- Kernel
map("n", "<leader>kc", "<cmd>Checkpatch<cr>", "checkpatch del fichero")
map("n", "<leader>kg", "<cmd>Checkpatch HEAD<cr>", "checkpatch del ultimo commit")
map("n", "<leader>km", "<cmd>Maintainers<cr>", "a quien mandarle el parche")
map("n", "<leader>kj", "<cmd>CompileCommands<cr>", "generar compile_commands.json")
map("n", "<leader>kr", "<cmd>KernelRoot<cr>", "raiz del arbol detectada")

-- Terminal: salir al modo normal sin pelearse
map("t", "<Esc><Esc>", "<C-\\><C-n>", "modo normal en la terminal")
