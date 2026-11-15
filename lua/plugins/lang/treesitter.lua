-- nvim-treesitter (main): parsers + qmljs filetype mapping.
-- NvChad's TSInstallAll reads opts.ensure_installed; we also install on load
-- so parsers exist without a manual :TSInstallAll.
return {
	"nvim-treesitter/nvim-treesitter",
	opts = function(_, opts)
		opts = opts or {}
		local extra = {
			"bash",
			"css",
			"html",
			"javascript",
			"json",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"printf",
			"qmljs",
			"regex",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
		}
		local have = {}
		for _, lang in ipairs(opts.ensure_installed or {}) do
			have[lang] = true
		end
		opts.ensure_installed = opts.ensure_installed or {}
		for _, lang in ipairs(extra) do
			if not have[lang] then
				table.insert(opts.ensure_installed, lang)
			end
		end
		return opts
	end,
	config = function(_, opts)
		-- Neovim filetype is "qml"; parser/queries ship as "qmljs"
		vim.treesitter.language.register("qmljs", "qml")

		local list = opts and opts.ensure_installed
		if list and #list > 0 then
			require("nvim-treesitter").install(list)
		end
	end,
}
