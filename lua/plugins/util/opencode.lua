return {
	"sudo-tee/opencode.nvim",
	-- Set vim.g.disable_opencode in lua/local.lua (gitignored) to skip on a machine.
	enabled = not vim.g.disable_opencode,
	-- No keys/cmd/ft triggers otherwise → lazy never loads it, so setup
	-- (and default <leader>o maps) never run.
	event = "VeryLazy",
	dependencies = {
		{ "folke/snacks.nvim", optional = true },
		-- Quiet Blink in the opencode prompt: menu only on @/#/~ triggers.
		{
			"saghen/blink.cmp",
			optional = true,
			opts = function(_, opts)
				opts.completion = opts.completion or {}
				opts.completion.menu = opts.completion.menu or {}
				opts.completion.ghost_text = opts.completion.ghost_text or {}

				local inherited_auto_show = opts.completion.menu.auto_show
				local inherited_ghost_text_enabled = opts.completion.ghost_text.enabled

				opts.completion.menu.auto_show = function(ctx, items)
					if vim.bo[ctx.bufnr].filetype == "opencode" then
						return ctx.trigger.kind == "trigger_character"
					end
					if type(inherited_auto_show) == "function" then
						return inherited_auto_show(ctx, items)
					end
					return inherited_auto_show ~= false
				end

				opts.completion.ghost_text.enabled = function()
					local ghost_text_enabled = type(inherited_ghost_text_enabled) == "function"
							and inherited_ghost_text_enabled()
						or inherited_ghost_text_enabled == true
					if vim.bo.filetype == "opencode" then
						return ghost_text_enabled and require("blink.cmp").is_menu_visible()
					end
					return ghost_text_enabled
				end

				return opts
			end,
		},
		{
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				anti_conceal = { enabled = false },
				file_types = { "markdown", "opencode_output" },
			},
			ft = { "markdown", "opencode_output" },
		},
	},
	opts = {
		preferred_picker = "snacks",
		default_mode = "build",
		keymap_prefix = "<leader>o",
		-- Agent edits on disk should reload without a manual checktime.
		-- (also set once on setup below via config)
		keymap = {
			editor = {
				-- Keep <leader>od for diagnostic float (mappings.lua).
				["<leader>od"] = false,
				["<leader>oD"] = { "diff_open", desc = "Open opencode diff" },
				-- Alias of open_input — old nickj muscle memory.
				["<leader>oa"] = { "open_input", desc = "Open opencode input" },
			},
		},
		ui = {
			position = "right",
			window_width = 0.4,
			input = {
				text = { wrap = true },
			},
			output = {
				compact_assistant_headers = true,
				tools = {
					-- Match CLI: session.thinking = hide
					show_reasoning_output = false,
					folding_threshold = 15,
				},
			},
		},
		context = {
			-- Deliberate context: current file + selection + closest diagnostics.
			-- cursor_data stays off (old go/goo was opt-in ranges).
			diagnostics = {
				enabled = true,
				info = false,
				warning = true,
				error = true,
				only_closest = true,
			},
			current_file = { enabled = true },
			selection = { enabled = true },
			cursor_data = { enabled = false },
		},
	},
	config = function(_, opts)
		require("opencode").setup(opts)
		vim.o.autoread = true
	end,
}
