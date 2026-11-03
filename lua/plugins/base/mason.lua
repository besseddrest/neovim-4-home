return {
	"mason-org/mason.nvim",
	cmd = { "Mason", "MasonInstall", "MasonUpdate" },
	opts = {
		ui = {
			border = "rounded",
		},
		ensure_installed = {
			"lua_ls",
			"html",
			"cssls",
			"markdown_oxide",
			"somesass_ls",
			"eslint",
			"jsonls",
			"sqlls",
			"ts_ls",
			"bashls",
			"dartls",
		},
	},
}
