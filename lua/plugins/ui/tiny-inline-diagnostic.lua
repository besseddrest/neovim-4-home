return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "VeryLazy",
	priority = 1000,
	config = function()
		-- Native VT can't wrap with hanging indent. This plugin can.
		-- Padding = win_width - colorcolumn so wrap ends at the 80-col ruler.
		local function colorcol_padding()
			local cc = tonumber(vim.o.colorcolumn) or 80
			local ww = vim.api.nvim_win_get_width(0)
			return math.max(0, ww - cc)
		end

		require("tiny-inline-diagnostic").setup({
			preset = "powerline",
			options = {
				show_all_diags_on_cursorline = true,
				softwrap = 30,
				multilines = {
					enabled = true,
					always_show = false,
				},
				overflow = {
					mode = "wrap",
					padding = colorcol_padding(),
				},
				virt_texts = {
					priority = 9999,
				},
			},
		})

		vim.diagnostic.config({ virtual_text = false })

		-- Keep wrap boundary glued to colorcolumn on resize / :set cc=
		local function refresh_padding()
			local ok, tid = pcall(require, "tiny-inline-diagnostic")
			if not ok or not tid.config then
				return
			end
			tid.config.options.overflow.padding = colorcol_padding()
		end
		local grp = vim.api.nvim_create_augroup("TinyInlineColorColWrap", { clear = true })
		vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
			group = grp,
			callback = refresh_padding,
		})
		vim.api.nvim_create_autocmd("OptionSet", {
			group = grp,
			pattern = "colorcolumn",
			callback = refresh_padding,
		})
	end,
}
