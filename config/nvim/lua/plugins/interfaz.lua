-- La barra de estado, con los colores de aureola y un indicador propio:
-- si estas dentro de un arbol del kernel, lo dice y con que version.

local p = {
  mantle  = "#12121c",
  base    = "#171622",
  surface1 = "#302f43",
  overlay = "#565575",
  subtext = "#9fb0cf",
  text    = "#dee5f3",
  halo    = "#b9d4f0",
  rose    = "#f2a8c0",
  blush   = "#ef8fa8",
  lavanda = "#c4b6f2",
  menta   = "#9fe0cf",
  oro     = "#f0dcae",
}

local tema = {
  normal = {
    a = { fg = p.base, bg = p.rose, gui = "bold" },
    b = { fg = p.text, bg = p.surface1 },
    c = { fg = p.subtext, bg = p.mantle },
  },
  insert   = { a = { fg = p.base, bg = p.menta, gui = "bold" } },
  visual   = { a = { fg = p.base, bg = p.lavanda, gui = "bold" } },
  replace  = { a = { fg = p.base, bg = p.blush, gui = "bold" } },
  command  = { a = { fg = p.base, bg = p.oro, gui = "bold" } },
  terminal = { a = { fg = p.base, bg = p.halo, gui = "bold" } },
  inactive = {
    a = { fg = p.overlay, bg = p.mantle },
    b = { fg = p.overlay, bg = p.mantle },
    c = { fg = p.overlay, bg = p.mantle },
  },
}

-- La barra se redibuja constantemente y detectar la raiz implica varios
-- stat() por directorio padre: se cachea por directorio.
local cache = {}

local function version_kernel()
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  if dir == nil or dir == "" then
    return ""
  end

  if cache[dir] ~= nil then
    return cache[dir]
  end

  local raiz = require("kernel").raiz(dir)
  if not raiz then
    cache[dir] = ""
    return ""
  end

  local campos = {}
  local makefile = io.open(raiz .. "/Makefile", "r")
  if makefile then
    for _ = 1, 10 do
      local linea = makefile:read("l")
      if not linea then
        break
      end
      local clave, valor = linea:match("^(%u+)%s*=%s*(%S*)")
      if clave then
        campos[clave] = valor
      end
    end
    makefile:close()
  end

  local etiqueta = "󰌽 linux"
  if campos.VERSION and campos.PATCHLEVEL then
    etiqueta = ("󰌽 %s.%s%s"):format(campos.VERSION, campos.PATCHLEVEL,
      campos.EXTRAVERSION or "")
  end

  cache[dir] = etiqueta
  return etiqueta
end

return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = tema,
        globalstatus = true,
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { { "mode", fmt = string.lower } },
        lualine_b = { "branch", { "diff", symbols = { added = "+", modified = "~", removed = "-" } } },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " 󰏫", readonly = " 󰌾" } },
          { "diagnostics", symbols = { error = "󰅖 ", warn = "󰀦 ", info = "󰋼 ", hint = "󰌵 " } },
        },
        lualine_x = {
          { version_kernel, color = { fg = p.oro } },
          {
            function()
              local clientes = vim.lsp.get_clients({ bufnr = 0 })
              if #clientes == 0 then
                return ""
              end
              return "󰒋 " .. clientes[1].name
            end,
            color = { fg = p.menta },
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "quickfix", "lazy", "man" },
    },
  },
}
