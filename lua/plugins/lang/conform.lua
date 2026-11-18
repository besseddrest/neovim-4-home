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
			json = { "prettier" },
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
			return { lsp_format = "fallback" }
		end,
		formatters = {
			-- same prettier args as before (no print-width override)
			prettier = {
				prepend_args = { "--tab-width", tostring(vim.g.indent_width or 4), "--use-tabs", "false" },
			},
			-- PATH's qmlformat is Qt5 (shadowed by qt5-declarative); need Qt6
			qmlformat = {
				command = "/usr/lib/qt6/bin/qmlformat",
			},
		},
	},
}
