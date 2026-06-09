return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#131313',
				base01 = '#131313',
				base02 = '#a59e97',
				base03 = '#a59e97',
				base04 = '#fff6ed',
				base05 = '#fffbf7',
				base06 = '#fffbf7',
				base07 = '#fffbf7',
				base08 = '#ff9892',
				base09 = '#ff9892',
				base0A = '#ffc283',
				base0B = '#aaff99',
				base0C = '#ffdfbd',
				base0D = '#ffc283',
				base0E = '#ffcd99',
				base0F = '#ffcd99',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#a59e97',
				fg = '#fffbf7',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#ffc283',
				fg = '#131313',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#a59e97' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ffdfbd', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ffcd99',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#ffc283',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#ffc283',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#ffdfbd',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#aaff99',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#fff6ed' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#fff6ed' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#a59e97',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
