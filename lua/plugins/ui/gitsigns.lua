-- Single gitsigns spec (merges with NvChad; keeps FilePost lazy load)
return {
	"lewis6991/gitsigns.nvim",
	event = "User FilePost",
	opts = function()
		local chad = require("nvchad.configs.gitsigns")
		chad.current_line_blame = true
		chad.current_line_blame_opts = {
			delay = 500,
		}
		return chad
	end,
}
