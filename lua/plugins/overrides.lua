-- NvChad / default plugins we don't want
return {
	{ "nvim-tree/nvim-tree.lua", enabled = false },
	{ "nvzone/minty", enabled = false }, -- Huefy / Shades
	{ "lukas-reineke/indent-blankline.nvim", enabled = false },

	-- blink is the completion engine; drop nvim-cmp stack
	{ "hrsh7th/nvim-cmp", enabled = false },
	{ "hrsh7th/cmp-nvim-lsp", enabled = false },
	{ "hrsh7th/cmp-nvim-lua", enabled = false },
	{ "hrsh7th/cmp-buffer", enabled = false },
	{ "saadparwaiz1/cmp_luasnip", enabled = false },
	{ "windwp/nvim-autopairs", enabled = false },
}
