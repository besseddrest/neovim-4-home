-- This file needs to have same structure as nvconfig.luagitsign
-- https://github-.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.nvdash = {
  load_on_startup = false,
}

M.base46 = {
  theme = "rosepine",
  transparency = true,
  telescope = { style = "bordered" },
  -- base0F is #524f67 (same grey family as comments) — braces become unreadable in QML.
  -- base04 is rose-pine subtle (#908caa): visible punctuation without competing with text.
  hl_override = {
    -- one_bg2 reads clearly over a transparent terminal; black2 is too close to void.
    CursorLine = { bg = "one_bg2" },
    ["@punctuation.bracket"] = { fg = "base04" },
    ["@punctuation.delimiter"] = { fg = "base04" },
  },
}

M.colorify = {
  enabled = false,
}

M.cmp = {
  completion = {
    autocomplete = false,
  },
}

M.ui = {
    -- cmp = {
    --     lspkind_text = true,
    --     style = "default", -- default/flat_light/flat_dark/atom/atom_colored
    --     format_colors = {
    --         tailwind = false,
    --     },
    -- },
    -- statusline = {
    -- 	theme = "minimal",
    --  border = "rounded",
    -- 	separator_style = "arrow",
    -- },
    tabufline = {
        enabled = false,
    },
}

M.term = {
  winopts = { scl = "auto" },
  float = {
    width = 0.8,
    height = 0.5,
    row = 0.25,
    col = 0.1,
    border = "rounded",
    relative = "editor",
  },
  sizes = {
    vsp = 0.45,
    sp = 0.35,
  },
}

return M
