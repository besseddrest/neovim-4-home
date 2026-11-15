return {
	"echasnovski/mini.files",
	version = false,
	lazy = true,
	keys = {
		{
			"<S-n>",
			function()
				require("mini.files").open()
			end,
			desc = "MiniFiles Toggle",
		},
	},
	config = function()
		require("mini.files").setup()
	end,
	dependencies = { "echasnovski/mini.icons" },
}
