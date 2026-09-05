-- blink.cmp: completado, firma de funciones y snippets en un solo plugin.
-- Se fija a la serie 1.x; la 2 esta en desarrollo y rompe la configuracion.

return {
  {
    "Saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      keymap = {
        preset = "default",
        ["<C-y>"] = { "select_and_accept" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          -- El buffer entero de un fichero del kernel son miles de simbolos;
          -- que no compitan con lo que dice clangd, que sabe de verdad.
          buffer = { score_offset = -3 },
        },
      },
      completion = {
        accept = { auto_brackets = { enabled = false } },
        documentation = { auto_show = true, auto_show_delay_ms = 250 },
        menu = { border = "rounded", draw = { treesitter = { "lsp" } } },
        ghost_text = { enabled = false },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      cmdline = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
}
