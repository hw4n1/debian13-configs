-- LSP con la API nativa de Neovim 0.11+ (vim.lsp.config / vim.lsp.enable).
-- No hay nvim-lspconfig a proposito: para dos o tres servidores, el plugin
-- solo anade una capa que upstream ya declaro obsoleta.

local function capacidades()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    return blink.get_lsp_capabilities()
  end
  return nil
end

-- clangd sobre el kernel necesita mano dura:
--   --header-insertion=never   el kernel decide sus includes a mano; que
--                              clangd los anada solo mete ruido en el diff.
--   --clang-tidy=false         las comprobaciones genericas dan cientos de
--                              falsos positivos contra el estilo del kernel.
--   --query-driver             sin esto clangd no encuentra los includes
--                              internos de gcc y todo el arbol sale en rojo.
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy=false",
    "--header-insertion=never",
    "--completion-style=detailed",
    "--all-scopes-completion",
    "--pch-storage=memory",
    "--limit-results=200",
    "--query-driver=/usr/bin/*gcc*,/usr/bin/*clang*",
    "-j=" .. math.max(2, math.floor((vim.uv.available_parallelism() or 4) / 2)),
  },
  filetypes = { "c", "cpp" },
  -- compile_commands.json primero: es lo que hace que clangd entienda las
  -- banderas reales con las que se compilo cada fichero del kernel.
  root_markers = { "compile_commands.json", ".clangd", "Kbuild", ".git" },
  capabilities = capacidades(),
})

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".git" },
  capabilities = capacidades(),
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("bashls", {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  root_markers = { ".git" },
  capabilities = capacidades(),
})

-- El kernel genera rust-project.json con 'make rust-analyzer', que es lo que
-- rust-analyzer necesita para entender los drivers en Rust del arbol (ahi no
-- hay Cargo.toml que valga).
vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "rust-project.json", "Cargo.toml", ".git" },
  capabilities = capacidades(),
})

-- Solo se habilita lo que esta instalado: un servidor ausente deja un error
-- en el log cada vez que abres un fichero.
for servidor, binario in pairs({
  clangd = "clangd",
  lua_ls = "lua-language-server",
  bashls = "bash-language-server",
  rust_analyzer = "rust-analyzer",
}) do
  if vim.fn.executable(binario) == 1 then
    vim.lsp.enable(servidor)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("aureola_lsp", { clear = true }),
  callback = function(ev)
    local function map(tecla, accion, descripcion, modo)
      vim.keymap.set(modo or "n", tecla, accion,
        { buffer = ev.buf, desc = "LSP: " .. descripcion })
    end

    local telescope_ok, builtin = pcall(require, "telescope.builtin")

    map("gd", telescope_ok and builtin.lsp_definitions or vim.lsp.buf.definition,
      "ir a la definicion")
    map("gr", telescope_ok and builtin.lsp_references or vim.lsp.buf.references,
      "referencias")
    map("gi", telescope_ok and builtin.lsp_implementations or vim.lsp.buf.implementation,
      "implementaciones")
    map("gy", telescope_ok and builtin.lsp_type_definitions or vim.lsp.buf.type_definition,
      "definicion del tipo")
    map("gD", vim.lsp.buf.declaration, "declaracion")
    map("K", vim.lsp.buf.hover, "documentacion")
    map("<C-s>", vim.lsp.buf.signature_help, "firma de la funcion", "i")
    map("<leader>rn", vim.lsp.buf.rename, "renombrar")
    map("<leader>ca", vim.lsp.buf.code_action, "acciones de codigo")
    map("<leader>ss", telescope_ok and builtin.lsp_document_symbols or vim.lsp.buf.document_symbol,
      "simbolos del fichero")
    map("<leader>sS", telescope_ok and builtin.lsp_dynamic_workspace_symbols or vim.lsp.buf.workspace_symbol,
      "simbolos del proyecto")

    map("<leader>th", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
        { bufnr = ev.buf })
    end, "pistas en linea")

    -- Formateo a mano y nunca al guardar: reformatear un fichero del kernel
    -- entero convierte un parche de tres lineas en uno de trescientas.
    map("<leader>cf", function() vim.lsp.buf.format({ async = true }) end,
      "formatear (solo bajo peticion)")

    local cliente = vim.lsp.get_client_by_id(ev.data.client_id)
    if cliente and cliente:supports_method("textDocument/documentHighlight") then
      local grupo = vim.api.nvim_create_augroup("aureola_lsp_highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = grupo, buffer = ev.buf, callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = grupo, buffer = ev.buf, callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- Neovim no trae :LspRestart; lo daba nvim-lspconfig, que aqui no esta. Hace
-- falta despues de generar compile_commands.json: clangd lee la base de datos
-- al arrancar y no se entera de que ha aparecido.
vim.api.nvim_create_user_command("LspRestart", function()
  local buf = vim.api.nvim_get_current_buf()
  local nombres = {}

  for _, cliente in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    nombres[#nombres + 1] = cliente.name
  end

  if #nombres == 0 then
    return vim.notify("no hay ningun servidor enganchado a este buffer",
      vim.log.levels.WARN, { title = "lsp" })
  end

  for _, nombre in ipairs(nombres) do
    vim.lsp.enable(nombre, false)
  end

  -- Un respiro para que los procesos mueran antes de volver a levantarlos.
  vim.defer_fn(function()
    for _, nombre in ipairs(nombres) do
      vim.lsp.enable(nombre)
    end
    vim.notify("reiniciado: " .. table.concat(nombres, ", "),
      vim.log.levels.INFO, { title = "lsp" })
  end, 300)
end, { desc = "reinicia los servidores LSP de este buffer" })
