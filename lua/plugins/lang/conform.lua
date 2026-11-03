-- Single conform spec (overrides NvChad's minimal default via lazy merge)
return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	opts = {
		formatters_by_ft = {
			css = { "prettier" },
			html = { "prettier" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			json = { "jsonlint" },
			lua = { "stylua" },
			mysql = { "sqlfluff" },
			qml = { "qmlformat" },
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
			-- same prettier args as before (no print-width override)
			prettier = {
				prepend_args = { "--tab-width", "4", "--use-tabs", "false" },
			},
			qmlformat = {
				command = "qmlformat",
			},
		},
	},
}
