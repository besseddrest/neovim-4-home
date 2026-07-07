local M = {}

M.base_30 = {
  white = "#B8C8C0",
  darker_black = "#000810",
  black = "#001018",
  black2 = "#0A1820",
  one_bg = "#0C2028",
  one_bg2 = "#102028",
  one_bg3 = "#183838",
  grey = "#204040",
  grey_fg = "#285058",
  grey_fg2 = "#306068",
  light_grey = "#404868",
  red = "#581008",
  baby_pink = "#F06070",
  pink = "#F83048",
  line = "#102830",
  green = "#185050",
  vibrant_green = "#80C8B0",
  nord_blue = "#404868",
  blue = "#88A8C0",
  yellow = "#E09840",
  sun = "#E0B060",
  purple = "#585878",
  dark_purple = "#302030",
  teal = "#306868",
  orange = "#581008",
  cyan = "#68B8A0",
  statusline_bg = "#000810",
  lightbg = "#0A1820",
  pmenu_bg = "#302030",
  folder_bg = "#68A898",
}

M.base_16 = {
  base00 = "#001018",
  base01 = "#0A1820",
  base02 = "#102028",
  base03 = "#306868",
  base04 = "#404868",
  base05 = "#B8C8C0",
  base06 = "#C8D8D0",
  base07 = "#D8E8E0",
  base08 = "#581008",
  base09 = "#E09840",
  base0A = "#E0B060",
  base0B = "#80C8B0",
  base0C = "#68B8A0",
  base0D = "#88A8C0",
  base0E = "#F83048",
  base0F = "#585878",
}

M.type = "dark"

M = require("base46").override_theme(M, "smasher")

M.polish_hl = {
  defaults = {
      Visual = { bg = "#302030" },
      SnacksDashboardHeader = { fg = "#581008" },
      Cursor = { fg = "#001018", bg = "#F83048" },
    iCursor = { fg = "#001018", bg = "#F83048" },
    LineNr = { fg = "#306068" },
    MatchParen = { bg = "#402838" },
    IncSearch = { bg = "#581008", fg = "#B8C8C0" },
    Search = { bg = "#402838" },
    Subtle = { bg = "#0A1820" },
    NormalFloat = { bg = "#102028" },
    FloatBorder = { fg = "#88A8C0" },
    SnacksIndent1 = { bg = "#25166D" },
    SnacksIndent2 = { bg = "#301368" },
    SnacksIndent3 = { bg = "#3D1061" },
    SnacksIndent4 = { bg = "#4C0D5A" },
    SnacksIndent5 = { bg = "#5C0952" },
    SnacksIndent6 = { bg = "#6D0549" },
    SnacksIndent7 = { bg = "#800040" },
    SnacksIndent8 = { bg = "#961F43" },
  },
}

return M
