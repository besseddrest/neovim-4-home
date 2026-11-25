return {
	"NvChad/nvim-colorizer.lua",
	event = "User FilePost",
	opts = {
		filetypes = {
			"*",
			-- conf/qml: #AARRGGBB (alpha first). CSS uses #RRGGBBAA — not both at once.
			conf = {
				parsers = {
					hex = {
						rrggbb = true,
						rrggbbaa = false,
						hash_aarrggbb = true,
					},
				},
			},
			qml = {
				parsers = {
					hex = {
						rrggbbaa = false,
						hash_aarrggbb = true,
					},
				},
			},
			qmljs = {
				parsers = {
					hex = {
						rrggbbaa = false,
						hash_aarrggbb = true,
					},
				},
			},
			css = {
				parsers = {
					hex = {
						rrggbbaa = true,
						hash_aarrggbb = false,
					},
				},
			},
			html = {
				parsers = {
					hex = {
						rrggbbaa = true,
						hash_aarrggbb = false,
					},
				},
			},
		},
		-- New structured opts (hash_aarrggbb is not available via legacy AARRGGBB —
		-- that flag only enables 0xAARRGGBB).
		options = {
			parsers = {
				names = { enable = false },
				hex = {
					rgb = true,
					rgba = true,
					rrggbb = true,
					rrggbbaa = false,
					hash_aarrggbb = true,
				},
			},
			display = {
				mode = "background",
			},
		},
	},
	config = function(_, opts)
		-- Composite alpha over a real bg. With transparency Normal.bg is NONE —
		-- fall back to theme black so #AARRGGBB still resolves.
		local color = require("colorizer.color")
		local bg_cache

		local function normal_bg()
			if bg_cache then
				return bg_cache
			end
			local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
			local bg = hl and hl.bg
			local hex
			if type(bg) == "number" then
				hex = string.format("%06x", bg)
			elseif type(bg) == "string" then
				hex = bg:gsub("^#", "")
			else
				local ok, base46 = pcall(require, "base46")
				if ok then
					local c = base46.get_theme_tb("base_30")
					hex = (c and c.black or "#000000"):gsub("^#", "")
				else
					hex = "000000"
				end
			end
			bg_cache = {
				tonumber(hex:sub(1, 2), 16) or 0,
				tonumber(hex:sub(3, 4), 16) or 0,
				tonumber(hex:sub(5, 6), 16) or 0,
			}
			return bg_cache
		end

		color.apply_alpha = function(r, g, b, alpha)
			local d = normal_bg()
			local inv = 1 - alpha
			return math.floor(r * alpha + d[1] * inv),
				math.floor(g * alpha + d[2] * inv),
				math.floor(b * alpha + d[3] * inv)
		end

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("ColorizerAlphaBg", { clear = true }),
			callback = function()
				bg_cache = nil
			end,
		})

		-- Background swatches only outside insert — detach clears extmarks.
		vim.api.nvim_create_autocmd("InsertEnter", {
			group = vim.api.nvim_create_augroup("ColorizerInsertMode", { clear = true }),
			callback = function()
				require("colorizer").detach_from_buffer(0)
			end,
		})
		vim.api.nvim_create_autocmd("InsertLeave", {
			group = "ColorizerInsertMode",
			callback = function()
				require("colorizer").attach_to_buffer(0)
			end,
		})

		require("colorizer").setup(opts)
		vim.defer_fn(function()
			require("colorizer").attach_to_buffer(0)
		end, 0)
	end,
}
