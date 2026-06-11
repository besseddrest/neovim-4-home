return {
	"stevearc/conform.nvim",
	event = "BufWritePre", -- uncomment for format on save
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				css = { "prettier" },
				html = { "prettier" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				json = { "jsonlint" },
				lua = { "stylua" },
				mysql = { "sqlfluff" },
				scss = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
			},
			format_on_save = function(bufnr)
				if vim.bo[bufnr].filetype == "markdown" then
					return nil
				end
				return { lsp_fallback = true }
			end,
			formatters = {
				prettier = {
					prepend_args = { "--tab-width", "2", "--use-tabs", "false" },
				},
			},
		})
	end,
}
