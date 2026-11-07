-- aureola -- la paleta del escritorio, en Neovim.
-- Fuente de verdad de los hex: config/theme/aureola.conf. Si cambia alli,
-- cambia aqui: ni kitty ni polybar ni nvim saben importar variables.
--
-- Reparto de acentos pensado para leer C del kernel:
--   lavanda   flujo (if, return, static, goto)
--   blush     preprocesador (#define, #ifdef), que en el kernel es medio fichero
--   halo      funciones
--   ice       tipos (u32, struct foo)
--   oro       constantes y macros (NULL, EINVAL, BIT())
--   menta     cadenas
--   rose      numeros

local p = {
  crypt    = "#0e0e15",
  mantle   = "#12121c",
  base     = "#171622",
  surface0 = "#232232",
  surface1 = "#302f43",
  overlay  = "#565575",
  subtext  = "#9fb0cf",
  text     = "#dee5f3",
  white    = "#ffffff",
  halo     = "#b9d4f0",
  ice      = "#8fbce6",
  azur     = "#5d93c9",
  rose     = "#f2a8c0",
  blush    = "#ef8fa8",
  lavanda  = "#c4b6f2",
  menta    = "#9fe0cf",
  oro      = "#f0dcae",
}

vim.cmd.highlight("clear")
vim.o.background = "dark"
vim.g.colors_name = "aureola"

-- Fondos tenidos para diff y diagnosticos: el color puro de fondo tapa el texto.
local tinte = {
  add    = "#1b2d2a",
  del    = "#33202a",
  cambio = "#232a3a",
  texto  = "#31405c",
  error  = "#2c1a22",
  aviso  = "#2b2620",
}

local hl = vim.api.nvim_set_hl

local grupos = {
  -- Base
  Normal       = { fg = p.text, bg = p.base },
  NormalNC     = { fg = p.text, bg = p.base },
  NormalFloat  = { fg = p.text, bg = p.mantle },
  FloatBorder  = { fg = p.overlay, bg = p.mantle },
  FloatTitle   = { fg = p.rose, bg = p.mantle, bold = true },
  Cursor       = { fg = p.base, bg = p.rose },
  CursorLine   = { bg = p.surface0 },
  CursorLineNr = { fg = p.rose, bold = true },
  LineNr       = { fg = p.overlay },
  SignColumn   = { bg = p.base },
  ColorColumn  = { bg = p.surface0 },
  Visual       = { bg = p.surface1 },
  VisualNOS    = { bg = p.surface1 },
  Search       = { fg = p.base, bg = p.halo },
  IncSearch    = { fg = p.base, bg = p.rose },
  CurSearch    = { fg = p.base, bg = p.rose },
  MatchParen   = { fg = p.rose, bold = true },
  Folded       = { fg = p.overlay, bg = p.surface0 },
  FoldColumn   = { fg = p.overlay, bg = p.base },
  Conceal      = { fg = p.overlay },
  NonText      = { fg = p.surface1 },
  Whitespace   = { fg = p.surface1 },
  SpecialKey   = { fg = p.surface1 },
  EndOfBuffer  = { fg = p.base },
  Directory    = { fg = p.halo },
  Title        = { fg = p.rose, bold = true },
  WinSeparator = { fg = p.surface1 },
  ErrorMsg     = { fg = p.blush, bold = true },
  WarningMsg   = { fg = p.oro },
  MoreMsg      = { fg = p.menta },
  ModeMsg      = { fg = p.lavanda, bold = true },
  Question     = { fg = p.menta },
  QuickFixLine = { bg = p.surface1, bold = true },

  -- Menus y barras
  Pmenu        = { fg = p.subtext, bg = p.surface0 },
  PmenuSel     = { fg = p.text, bg = p.surface1, bold = true },
  PmenuSbar    = { bg = p.surface0 },
  PmenuThumb   = { bg = p.overlay },
  PmenuMatch   = { fg = p.rose, bold = true },
  StatusLine   = { fg = p.subtext, bg = p.mantle },
  StatusLineNC = { fg = p.overlay, bg = p.mantle },
  TabLine      = { fg = p.overlay, bg = p.mantle },
  TabLineSel   = { fg = p.rose, bg = p.base, bold = true },
  TabLineFill  = { bg = p.crypt },
  WildMenu     = { fg = p.base, bg = p.rose },

  -- Sintaxis clasica
  Comment      = { fg = p.overlay, italic = true },
  Constant     = { fg = p.oro },
  String        = { fg = p.menta },
  Character    = { fg = p.menta },
  Number       = { fg = p.rose },
  Boolean      = { fg = p.rose },
  Float        = { fg = p.rose },
  Identifier   = { fg = p.text },
  Function     = { fg = p.halo },
  Statement    = { fg = p.lavanda },
  Conditional  = { fg = p.lavanda },
  Repeat       = { fg = p.lavanda },
  Label        = { fg = p.lavanda },
  Operator     = { fg = p.subtext },
  Keyword      = { fg = p.lavanda },
  Exception    = { fg = p.lavanda },
  PreProc      = { fg = p.blush },
  Include      = { fg = p.blush },
  Define       = { fg = p.blush },
  Macro        = { fg = p.blush },
  PreCondit    = { fg = p.blush },
  Type         = { fg = p.ice },
  StorageClass = { fg = p.lavanda },
  Structure    = { fg = p.ice },
  Typedef      = { fg = p.ice },
  Special      = { fg = p.rose },
  Delimiter    = { fg = p.overlay },
  Todo         = { fg = p.base, bg = p.oro, bold = true },
  Error        = { fg = p.blush, bold = true },
  Underlined   = { fg = p.azur, underline = true },

  -- Treesitter
  ["@comment"]              = { link = "Comment" },
  ["@comment.todo"]         = { link = "Todo" },
  ["@comment.warning"]      = { fg = p.oro, bold = true },
  ["@comment.error"]        = { fg = p.blush, bold = true },
  ["@keyword"]              = { fg = p.lavanda },
  ["@keyword.directive"]    = { fg = p.blush },
  ["@keyword.import"]       = { fg = p.blush },
  ["@keyword.return"]       = { fg = p.lavanda, italic = true },
  ["@function"]             = { fg = p.halo },
  ["@function.call"]        = { fg = p.halo },
  ["@function.macro"]       = { fg = p.oro },
  ["@function.builtin"]     = { fg = p.halo, italic = true },
  ["@type"]                 = { fg = p.ice },
  ["@type.builtin"]         = { fg = p.ice, italic = true },
  ["@type.qualifier"]       = { fg = p.lavanda },
  ["@constant"]             = { fg = p.oro },
  ["@constant.builtin"]     = { fg = p.oro, italic = true },
  ["@constant.macro"]       = { fg = p.oro },
  ["@variable"]             = { fg = p.text },
  ["@variable.member"]      = { fg = p.subtext },
  ["@variable.parameter"]   = { fg = p.subtext, italic = true },
  ["@variable.builtin"]     = { fg = p.rose, italic = true },
  ["@property"]             = { fg = p.subtext },
  ["@string"]               = { fg = p.menta },
  ["@string.escape"]        = { fg = p.rose },
  ["@string.special.path"]  = { fg = p.azur, underline = true },
  ["@number"]               = { fg = p.rose },
  ["@operator"]             = { fg = p.subtext },
  ["@punctuation.bracket"]  = { fg = p.overlay },
  ["@punctuation.delimiter"] = { fg = p.overlay },
  ["@punctuation.special"]  = { fg = p.rose },
  ["@label"]                = { fg = p.lavanda },
  ["@module"]               = { fg = p.ice },
  ["@tag"]                  = { fg = p.lavanda },
  ["@markup.heading"]       = { fg = p.rose, bold = true },
  ["@markup.raw"]           = { fg = p.menta },
  ["@markup.link"]          = { fg = p.azur, underline = true },
  ["@markup.list"]          = { fg = p.lavanda },
  ["@markup.strong"]        = { bold = true },
  ["@markup.italic"]        = { italic = true },

  -- Diff y parches: media vida del kernel se pasa leyendo esto
  DiffAdd            = { bg = tinte.add },
  DiffDelete         = { fg = p.blush, bg = tinte.del },
  DiffChange         = { bg = tinte.cambio },
  DiffText           = { bg = tinte.texto, bold = true },
  Added              = { fg = p.menta },
  Removed            = { fg = p.blush },
  Changed            = { fg = p.oro },
  ["@diff.plus"]     = { fg = p.menta },
  ["@diff.minus"]    = { fg = p.blush },
  ["@diff.delta"]    = { fg = p.oro },
  diffAdded          = { fg = p.menta },
  diffRemoved        = { fg = p.blush },
  diffChanged        = { fg = p.oro },
  diffFile           = { fg = p.halo, bold = true },
  diffLine           = { fg = p.lavanda },
  diffIndexLine      = { fg = p.overlay },
  diffSubname        = { fg = p.subtext },

  -- LSP y diagnosticos
  DiagnosticError            = { fg = p.blush },
  DiagnosticWarn             = { fg = p.oro },
  DiagnosticInfo             = { fg = p.halo },
  DiagnosticHint             = { fg = p.menta },
  DiagnosticOk               = { fg = p.menta },
  DiagnosticUnderlineError   = { sp = p.blush, undercurl = true },
  DiagnosticUnderlineWarn    = { sp = p.oro, undercurl = true },
  DiagnosticUnderlineInfo    = { sp = p.halo, undercurl = true },
  DiagnosticUnderlineHint    = { sp = p.menta, undercurl = true },
  DiagnosticVirtualTextError = { fg = p.blush, bg = tinte.error },
  DiagnosticVirtualTextWarn  = { fg = p.oro, bg = tinte.aviso },
  DiagnosticVirtualTextInfo  = { fg = p.halo, bg = p.surface0 },
  DiagnosticVirtualTextHint  = { fg = p.menta, bg = p.surface0 },
  LspReferenceText           = { bg = p.surface1 },
  LspReferenceRead           = { bg = p.surface1 },
  LspReferenceWrite          = { bg = p.surface1, underline = true },
  LspSignatureActiveParameter = { fg = p.rose, bold = true },
  LspInlayHint               = { fg = p.overlay, bg = p.surface0, italic = true },
  -- El codigo bajo #ifdef que clangd descarta: apagado, no invisible
  LspInactiveRegion          = { fg = p.overlay },

  -- Telescope
  TelescopeNormal        = { fg = p.text, bg = p.mantle },
  TelescopeBorder        = { fg = p.overlay, bg = p.mantle },
  TelescopePromptNormal  = { fg = p.text, bg = p.surface0 },
  TelescopePromptBorder  = { fg = p.surface0, bg = p.surface0 },
  TelescopePromptTitle   = { fg = p.base, bg = p.rose, bold = true },
  TelescopePromptPrefix  = { fg = p.rose },
  TelescopeResultsTitle  = { fg = p.mantle, bg = p.mantle },
  TelescopePreviewTitle  = { fg = p.base, bg = p.menta, bold = true },
  TelescopeSelection     = { bg = p.surface1, bold = true },
  TelescopeSelectionCaret = { fg = p.rose, bg = p.surface1 },
  TelescopeMatching      = { fg = p.rose, bold = true },
  TelescopeMultiSelection = { fg = p.lavanda },

  -- Gitsigns
  GitSignsAdd       = { fg = p.menta },
  GitSignsChange    = { fg = p.oro },
  GitSignsDelete    = { fg = p.blush },
  GitSignsAddInline = { bg = tinte.add },
  GitSignsDeleteInline = { bg = tinte.del },
  GitSignsCurrentLineBlame = { fg = p.overlay, italic = true },

  -- blink.cmp
  BlinkCmpMenu           = { fg = p.subtext, bg = p.mantle },
  BlinkCmpMenuBorder     = { fg = p.overlay, bg = p.mantle },
  BlinkCmpMenuSelection  = { bg = p.surface1, bold = true },
  BlinkCmpLabelMatch     = { fg = p.rose, bold = true },
  BlinkCmpLabelDeprecated = { fg = p.overlay, strikethrough = true },
  BlinkCmpKind           = { fg = p.lavanda },
  BlinkCmpDoc            = { fg = p.text, bg = p.mantle },
  BlinkCmpDocBorder      = { fg = p.overlay, bg = p.mantle },
  BlinkCmpSignatureHelp  = { fg = p.text, bg = p.mantle },

  -- Ficheros propios del arbol del kernel
  kconfigKeyword    = { fg = p.lavanda },
  kconfigType       = { fg = p.ice },
  makeCommands      = { fg = p.text },
  makeTarget        = { fg = p.halo },
  gitcommitSummary  = { fg = p.text, bold = true },
  gitcommitOverflow = { fg = p.blush },
  gitcommitComment  = { fg = p.overlay, italic = true },
}

for grupo, opciones in pairs(grupos) do
  hl(0, grupo, opciones)
end

-- Colores del :terminal, para que un `make` dentro de nvim se lea igual
-- que en kitty.
local terminal = {
  p.surface1, p.blush, p.menta, p.oro, p.azur, p.lavanda, p.halo, p.subtext,
  p.overlay,  p.rose,  p.menta, p.oro, p.ice,  p.lavanda, p.halo, p.text,
}
for i, color in ipairs(terminal) do
  vim.g["terminal_color_" .. (i - 1)] = color
end

return p
