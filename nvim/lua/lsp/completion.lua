return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    "rafamadriz/friendly-snippets"
  },
  event = "VeryLazy",
  opts = {
    completion = {
      documentation = {
        auto_show = true
      }
    },
    keymap = {
      preset = "super-tab"
    },
    sources = {
      default = { "path", "snippets", "buffer", "lsp" }
    }
  }
}
