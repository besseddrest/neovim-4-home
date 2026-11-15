return {
  "folke/noice.nvim",
  event = "UIEnter",
  opts = {
    presets = { inc_rename = true, lsp_doc_border = true },
    notify = { enabled = false },
    lsp = {
      -- Native hover merges multi-client replies and drops empty ones (qmlls).
      hover = { enabled = false },
      signature = { enabled = false },
    },
    routes = {
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
            { find = "%d fewer lines" },
            { find = "%d more lines" },
          },
        },
        opts = { skip = true },
      },
      {
        view = "notify",
        filter = { event = "msg_showmode" },
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
}
