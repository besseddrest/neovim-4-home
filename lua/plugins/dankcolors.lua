return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#17130f',
				base01 = '#17130f',
				base02 = '#9f9993',
				base03 = '#9f9993',
				base04 = '#fff7ef',
				base05 = '#fffbf8',
				base06 = '#fffbf8',
				base07 = '#fffbf8',
				base08 = '#ffa59f',
				base09 = '#ffa59f',
				base0A = '#ffcb97',
				base0B = '#b4ffa5',
				base0C = '#ffe3c7',
				base0D = '#ffcb97',
				base0E = '#ffd4a9',
				base0F = '#ffd4a9',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#9f9993',
				fg = '#fffbf8',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#ffcb97',
				fg = '#17130f',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#9f9993' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ffe3c7', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ffd4a9',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#ffcb97',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#ffcb97',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#ffe3c7',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#b4ffa5',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#fff7ef' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#fff7ef' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#9f9993',
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
