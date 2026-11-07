-- Lo especifico del arbol del kernel: estilo, checkpatch, get_maintainer y
-- compile_commands.json, sin salir del editor.
--
-- Los comandos se definen siempre, pero solo funcionan dentro de un arbol
-- del kernel; fuera avisan y no hacen nada.

local M = {}

local function aviso(mensaje)
  vim.notify(mensaje, vim.log.levels.WARN, { title = "kernel" })
end

-- Un arbol del kernel se reconoce por estos tres a la vez. Solo por el
-- Makefile no vale: cualquier proyecto en C tiene uno.
local MARCAS = { "Kbuild", "MAINTAINERS", "scripts/checkpatch.pl" }

function M.raiz(desde)
  desde = desde or vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  if desde == nil or desde == "" then
    desde = vim.uv.cwd()
  end

  local directorios = { desde }
  for padre in vim.fs.parents(desde) do
    directorios[#directorios + 1] = padre
  end

  for _, directorio in ipairs(directorios) do
    local completo = true
    for _, marca in ipairs(MARCAS) do
      if not vim.uv.fs_stat(directorio .. "/" .. marca) then
        completo = false
        break
      end
    end
    if completo then
      return directorio
    end
  end

  return nil
end

local function raiz_o_aviso()
  local raiz = M.raiz()
  if not raiz then
    aviso("no estas dentro de un arbol del kernel")
  end
  return raiz
end

-- ── checkpatch ───────────────────────────────────────────────────────────
-- Con --terse cada aviso cabe en una linea (fichero:linea: NIVEL:TIPO: texto),
-- que es justo lo que hace falta para llenar el quickfix. El formato de por
-- defecto ocupa tres lineas por aviso y no se puede parsear a ojo.

local NIVELES = { ERROR = "E", WARNING = "W", CHECK = "I" }

local function a_quickfix(salida, raiz)
  local entradas = {}

  for linea in vim.gsplit(salida, "\n", { trimempty = true }) do
    local fichero, numero, nivel, texto =
      linea:match("^(.-):(%d+):%s*([A-Z]+):%s*(.+)$")

    if fichero and NIVELES[nivel] then
      if not vim.startswith(fichero, "/") then
        fichero = raiz .. "/" .. fichero
      end
      entradas[#entradas + 1] = {
        filename = fichero,
        lnum = tonumber(numero),
        type = NIVELES[nivel],
        text = texto,
      }
    end
  end

  return entradas
end

function M.checkpatch(revision)
  local raiz = raiz_o_aviso()
  if not raiz then
    return
  end

  local orden = {
    raiz .. "/scripts/checkpatch.pl",
    "--terse", "--strict", "--show-types", "--no-summary",
  }
  local titulo

  if revision and revision ~= "" then
    vim.list_extend(orden, { "--git", revision })
    titulo = "checkpatch " .. revision
  else
    local fichero = vim.api.nvim_buf_get_name(0)
    if fichero == "" then
      return aviso("el buffer no tiene fichero; usa :Checkpatch HEAD")
    end
    vim.list_extend(orden, { "-f", fichero })
    titulo = "checkpatch " .. vim.fs.basename(fichero)
  end

  vim.notify("pasando checkpatch...", vim.log.levels.INFO, { title = "kernel" })

  -- checkpatch sale con 1 cuando encuentra algo: eso no es un fallo.
  vim.system(orden, { cwd = raiz, text = true }, vim.schedule_wrap(function(res)
    local salida = (res.stdout or "") .. (res.stderr or "")
    local entradas = a_quickfix(salida, raiz)

    if #entradas == 0 then
      vim.fn.setqflist({}, " ", { title = titulo, items = {} })
      return vim.notify("checkpatch limpio", vim.log.levels.INFO, { title = "kernel" })
    end

    vim.fn.setqflist({}, " ", { title = titulo, items = entradas })
    vim.cmd.copen()
    -- El foco vuelve al codigo: el quickfix se lee de reojo, y asi
    -- :Maintainers a continuacion sigue viendo el fichero, no la lista.
    vim.cmd.wincmd("p")
    vim.notify(("checkpatch: %d aviso(s)"):format(#entradas),
      vim.log.levels.WARN, { title = "kernel" })
  end))
end

-- ── get_maintainer ───────────────────────────────────────────────────────

local function flotante(lineas, titulo)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lineas)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local ancho = 0
  for _, linea in ipairs(lineas) do
    ancho = math.max(ancho, #linea)
  end
  ancho = math.min(math.max(ancho + 2, 40), vim.o.columns - 8)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = ancho,
    height = math.min(#lineas, vim.o.lines - 8),
    row = math.floor((vim.o.lines - #lineas) / 2) - 1,
    col = math.floor((vim.o.columns - ancho) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. titulo .. " ",
  })
  vim.wo[win].wrap = false

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
  return buf
end

function M.maintainers()
  local raiz = raiz_o_aviso()
  if not raiz then
    return
  end

  local fichero = vim.api.nvim_buf_get_name(0)
  if fichero == "" then
    return aviso("el buffer no tiene fichero")
  end

  -- --nogit evita que recorra el historial entero: sobre un arbol grande
  -- eso tarda decenas de segundos y aporta poco frente a MAINTAINERS.
  local orden = { raiz .. "/scripts/get_maintainer.pl", "--nogit", "--nogit-fallback" }
  if fichero:match("%.patch$") or fichero:match("%.diff$") then
    orden[#orden + 1] = fichero
  else
    vim.list_extend(orden, { "-f", fichero })
  end

  vim.system(orden, { cwd = raiz, text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      return aviso("get_maintainer.pl fallo: " .. (res.stderr or ""))
    end

    local lineas = vim.split(vim.trim(res.stdout or ""), "\n", { trimempty = true })
    if #lineas == 0 then
      return aviso("get_maintainer.pl no devolvio nada")
    end

    -- La lista limpia, sin los roles entre parentesis, lista para pegar en
    -- git send-email --to=... --cc=...
    local direcciones = {}
    for _, linea in ipairs(lineas) do
      direcciones[#direcciones + 1] = vim.trim(linea:gsub("%s*%b()%s*$", ""))
    end
    vim.fn.setreg("+", table.concat(direcciones, ", "))

    local contenido = vim.list_extend({}, lineas)
    contenido[#contenido + 1] = ""
    contenido[#contenido + 1] = "(la lista sin roles esta en el portapapeles; q para cerrar)"
    flotante(contenido, "get_maintainer: " .. vim.fs.basename(fichero))
  end))
end

-- ── compile_commands.json ────────────────────────────────────────────────
-- clangd no entiende el kernel sin esto: cada fichero se compila con un
-- juego distinto de -D y -I segun la configuracion, y sin la base de datos
-- clangd adivina mal y marca en rojo medio arbol.

function M.compile_commands()
  local raiz = raiz_o_aviso()
  if not raiz then
    return
  end

  local generador = raiz .. "/scripts/clang-tools/gen_compile_commands.py"
  if not vim.uv.fs_stat(generador) then
    return aviso("este arbol no trae scripts/clang-tools/gen_compile_commands.py")
  end

  vim.notify("generando compile_commands.json...", vim.log.levels.INFO,
    { title = "kernel" })

  vim.system({ "python3", generador }, { cwd = raiz, text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        local motivo = vim.trim((res.stderr or "") .. (res.stdout or ""))
        -- El fallo habitual no es el script: es que el arbol no esta
        -- construido y no hay ficheros .cmd de los que sacar las banderas.
        return aviso("fallo: " .. motivo .. "\ncompila el arbol antes (make -j$(nproc))")
      end

      vim.notify("compile_commands.json listo; reinicia clangd con :LspRestart",
        vim.log.levels.INFO, { title = "kernel" })
    end))
end

-- ── estilo ───────────────────────────────────────────────────────────────

local grupo = vim.api.nvim_create_augroup("aureola_kernel", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = grupo,
  pattern = { "c", "cpp" },
  callback = function()
    -- Documentation/process/coding-style.rst: tabs de 8, y esos cinoptions
    -- exactos vienen recomendados alli.
    vim.bo.expandtab = false
    vim.bo.tabstop = 8
    vim.bo.shiftwidth = 8
    vim.bo.softtabstop = 8
    vim.bo.cindent = true
    vim.bo.cinoptions = ":0,l1,t0,g0,(0"
    -- 80 es el limite de estilo; 100 el que hace fallar a checkpatch desde
    -- 5.7. Se marcan los dos.
    vim.opt_local.colorcolumn = { "81", "101" }
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = grupo,
  pattern = { "gitcommit", "gitsendemail" },
  callback = function()
    -- 72 columnas: el cuerpo del mensaje se lee en git log indentado 4.
    vim.bo.textwidth = 72
    vim.wo.spell = true
    vim.opt_local.colorcolumn = { "51", "73" }
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = grupo,
  pattern = { "diff" },
  callback = function()
    vim.wo.wrap = false
  end,
})

-- defconfig no lo detecta Neovim de serie, y son ficheros que se tocan a
-- diario al trastear con configuraciones.
vim.filetype.add({
  filename = { [".config"] = "kconfig" },
  pattern = {
    [".*/arch/.*/configs/.*_defconfig"] = "kconfig",
    [".*/arch/.*/configs/.*%.config"] = "kconfig",
  },
  extension = { dtso = "dts" },
})

-- ── comandos ─────────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("Checkpatch", function(opts)
  M.checkpatch(opts.args)
end, {
  nargs = "?",
  desc = "checkpatch.pl sobre el fichero actual, o sobre una revision git",
})

vim.api.nvim_create_user_command("Maintainers", function()
  M.maintainers()
end, { desc = "get_maintainer.pl del fichero actual" })

vim.api.nvim_create_user_command("CompileCommands", function()
  M.compile_commands()
end, { desc = "genera compile_commands.json para clangd" })

vim.api.nvim_create_user_command("KernelRoot", function()
  local raiz = M.raiz()
  if raiz then
    vim.notify(raiz, vim.log.levels.INFO, { title = "kernel" })
  else
    aviso("no estas dentro de un arbol del kernel")
  end
end, { desc = "muestra la raiz del arbol del kernel detectada" })

return M
