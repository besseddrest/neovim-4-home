-- mason.nvim itself has no `ensure_installed` setting -- passing one is silently
-- ignored, which is why the servers below were never actually installed. The
-- list lives on mason-tool-installer instead, and uses mason package names
-- (`lua-language-server`), not lspconfig names (`lua_ls`).
--
-- Not available from mason, installed with their SDKs instead:
--   dartls, qmlls, qml-language-server
return {
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		opts = {
			ui = {
				border = "rounded",
			},
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- Must not be lazy loaded: the install check is wired to VimEnter from
		-- the plugin's own plugin/ file, so anything later than startup (VeryLazy,
		-- User FilePost) registers that autocmd after VimEnter has already fired
		-- and nothing is ever installed. debounce_hours keeps the usual startup
		-- cost to one timestamp read -- check_install returns before it touches
		-- the mason registry.
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			debounce_hours = 24,
			ensure_installed = {
				-- servers, see lua/configs/lspconfig.lua
				"astro-language-server",
				"bash-language-server",
				"css-lsp",
				"eslint-lsp",
				"html-lsp",
				"json-lsp",
				"lua-language-server",
				"markdown-oxide",
				"some-sass-language-server",
				"sqlls",
				"typescript-language-server",

				-- formatters, see lua/plugins/lang/conform.lua
				"prettier",
				"sqlfluff",
				"stylua",
			},
		},
	},
}
