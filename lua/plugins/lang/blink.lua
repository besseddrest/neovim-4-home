-- Extends NvChad's blink.cmp setup: QML Class expansion + module label.
return {
	"saghen/blink.cmp",
	opts = function(_, opts)
		opts = opts or {}

		-- Transform runs for every buffer but configs.qml no-ops unless filetype is qml/qmljs.
		opts.sources = opts.sources or {}
		local prev = opts.sources.transform_items
		opts.sources.transform_items = function(ctx, items)
			if prev then
				items = prev(ctx, items)
			end
			local qml = require("configs.qml")
			if not qml.is_qml_buf(ctx.bufnr) then
				return items
			end
			return qml.transform_items(ctx, items)
		end

		-- After accepting a QML Class item, insert a missing import at the top of the file.
		opts.keymap = opts.keymap or {}
		opts.keymap["<CR>"] = {
			function(cmp)
				local qml = require("configs.qml")
				if not qml.is_qml_buf(0) or not cmp.is_visible() then
					return
				end
				local item = cmp.get_selected_item()
				if not item or item.kind ~= vim.lsp.protocol.CompletionItemKind.Class then
					return
				end
				return cmp.accept({
					callback = function()
						qml.ensure_import_on_accept(item)
					end,
				})
			end,
			"accept",
			"fallback",
		}

		-- Menu layout: kind chip | label + module desc | muted kind name.
		opts.completion = opts.completion or {}
		opts.completion.menu = opts.completion.menu or {}
		local menu = opts.completion.menu
		menu.border = "rounded"
		menu.draw = menu.draw or {}
		local draw = menu.draw

		draw.padding = { 0, 1 }
		draw.gap = 1
		draw.columns = {
			{ "kind_icon" },
			{ "label", "label_description", gap = 1 },
			{ "kind" },
		}

		draw.components = draw.components or {}

		-- Padded kind icon so it reads as a chip (NvChad atom-style without atom theme).
		draw.components.kind_icon = {
			ellipsis = false,
			text = function(ctx)
				local icons = require("nvchad.icons.lspkind")
				local icon = icons[ctx.kind] or ctx.kind_icon or "󰈚"
				return " " .. icon .. " "
			end,
			highlight = function(ctx)
				return { { group = ctx.kind_hl, priority = 20000 } }
			end,
		}

		draw.components.kind = {
			ellipsis = false,
			width = { fill = true },
			text = function(ctx)
				return ctx.kind
			end,
			highlight = "Comment",
		}

		draw.components.label_description = {
			width = { max = 30 },
			text = function(ctx)
				return ctx.label_description
			end,
			highlight = "BlinkCmpLabelDescription",
		}

		-- Match doc float border to the menu.
		opts.completion.documentation = opts.completion.documentation or {}
		opts.completion.documentation.window = opts.completion.documentation.window or {}
		opts.completion.documentation.window.border = "rounded"

		return opts
	end,
}
