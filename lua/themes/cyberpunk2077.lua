local M = {}

-- local C = {
-- #06070D,
-- #0B080F	(0,0,0)
-- #c5003c	(197,0,60)
-- #880425	(136,4,37)
-- #9a9f17	(154,159,23)
-- #f3e600	(243,230,0)
-- #39c4b6	(57,196,182)
-- #55ead4	(85,234,212)

-- title
-- #00060e	(0,6,14)
-- #9a9f17	(154,159,23)
-- #fee801	(254,232,1)
-- #54c1e6	(84,193,230)
-- #39c4b6	(57,196,182)
-- }

M.base_30 = {
	black = "#0B080F",
	darker_black = "#06070D",
	white = "#C3D6DC",
	black2 = "#111423",
	one_bg = "#150D14",
	one_bg2 = "#1D1520",
	one_bg3 = "#251D28",
	grey = "#2D2530",
	grey_fg = "#3D3540",
	grey_fg2 = "#4D4550",
	light_grey = "#5D5560",
	red = "#AF4A56",
	baby_pink = "#C56A76",
	pink = "#82252E",
	line = "#1A1220",
	green = "#60AEAD",
	vibrant_green = "#78D3CE",
	nord_blue = "#699495",
	blue = "#77FDF7",
	yellow = "#FEE801",
	sun = "#9DE0E0",
	purple = "#473743",
	dark_purple = "#372733",
	teal = "#305557",
	orange = "#762730",
	cyan = "#77FDF7",
	statusline_bg = "#06070D",
	lightbg = "#1D1520",
	pmenu_bg = "#82252E",
	folder_bg = "#699495",
}

M.base_16 = {
	base00 = "#0B080F",
	base01 = "#111423",
	base02 = "#1D1520",
	base03 = "#473743",
	base04 = "#596669",
	base05 = "#C3D6DC",
	base06 = "#DEE3E7",
	base07 = "#F5F5FA",
	base08 = "#AF4A56",
	base09 = "#762730",
	base0A = "#77FDF7",
	base0B = "#00BFA5",
	base0C = "#78D3CE",
	base0D = "#26C6DA",
	base0E = "#A52A3A",
	base0F = "#2D2530",
}

M = require("base46").override_theme(M, "cyberpunk2077")

M.type = "dark"

M.polish_hl = {
	defaults = {
		Visual = { bg = "#FEE801", fg = "#0B080F" },
		SnacksDashboardHeader = { fg = "#FEE801" },
    LineNr = { fg = "#5D5560" },
    NormalFloat = { bg = "#1D1520" },
    FloatBorder = { fg = "#77FDF7" },
    SnacksIndent1 = { fg = "#25166D" },
    SnacksIndent2 = { fg = "#301368" },
    SnacksIndent3 = { fg = "#3D1061" },
    SnacksIndent4 = { fg = "#4C0D5A" },
    SnacksIndent5 = { fg = "#5C0952" },
    SnacksIndent6 = { fg = "#6D0549" },
    SnacksIndent7 = { fg = "#800040" },
    SnacksIndent8 = { fg = "#961F43" },
	},
}

return M
