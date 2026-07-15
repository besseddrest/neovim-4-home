return {
	{
		"nvim-tree/nvim-tree.lua",
		enabled = false,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		enabled = false,
		event = "UIEnter",
		main = "ibl",
		opts = function(_, opts)
			-- Other blankline configuration here
			return require("indent-rainbowline").make_opts(opts, {
				-- How transparent should the rainbow colors be. 1 is completely opaque, 0 is invisible. 0.07 by default
				color_transparency = 0.4,
				-- The 24-bit colors to mix with the background. Specified in hex.
				-- { 0xffff40, 0x79ff79, 0xff79ff, 0x4fecec, } by default
				colors = { 0x006580, 0x003888, 0x303088, 0x482C88, 0x602888 },
			})
		end,
		dependencies = {
			"TheGLander/indent-rainbowline.nvim",
		},
	},
	{
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
		config = function(_, opts)
			require("gitsigns").setup(opts)
		end,
	},
	{ import = "plugins.lang.conform" },
	{ import = "plugins.base.mason" },
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("configs.lspconfig")
		end,
	},
	{ import = "nvchad.blink.lazyspec" },
	{
		"NvChad/nvim-colorizer.lua",
		event = "User FilePost",
		opts = { user_default_options = { names = false } },
		config = function(_, opts)
			require("colorizer").setup(opts)

			-- execute colorizer as soon as possible
			vim.defer_fn(function()
				require("colorizer").attach_to_buffer(0)
			end, 0)
		end,
	},
}
