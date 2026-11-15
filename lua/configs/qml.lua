-- QML / Quickshell completion only (never runs for other filetypes).
-- Class items expand to Type { … } with required-property stubs.
-- Missing imports are inserted at the top of the file after accept (not via
-- additionalTextEdits — those were landing at EOF and duplicating on resolve).

local M = {}

local Class = vim.lsp.protocol.CompletionItemKind.Class
local Snippet = vim.lsp.protocol.InsertTextFormat.Snippet

--- True only for QML buffers. All public entry points gate on this.
function M.is_qml_buf(bufnr)
	bufnr = bufnr or 0
	local ft = vim.bo[bufnr].filetype
	return ft == "qml" or ft == "qmljs"
end

local defaults = {
	string = '""',
	url = '""',
	int = "0",
	real = "0",
	double = "0",
	number = "0",
	bool = "false",
	boolean = "false",
	color = '"#ffffff"',
	var = "null",
	-- C++ qmltypes names
	QString = '""',
	QUrl = '""',
	QColor = '"#ffffff"',
	QVariant = "null",
	float = "0",
	qreal = "0",
	uint = "0",
	qlonglong = "0",
}

-- module → type → { { name, type }, ... }
local qmltypes_cache = {}

--- Pending import after a Class accept. Cleared once applied.
M._pending_import = nil

local function qml_import_roots()
	local roots = {
		"/usr/lib/qt6/qml",
		"/usr/lib/qt5/qml",
	}
	local env = vim.env.QML2_IMPORT_PATH or vim.env.QML_IMPORT_PATH
	if env and env ~= "" then
		for part in env:gmatch("[^:]+") do
			roots[#roots + 1] = part
		end
	end
	return roots
end

--- Map "QtQuick.Templates" → directory under a qml import root.
local function module_dir(module)
	local rel = module:gsub("%.", "/")
	for _, root in ipairs(qml_import_roots()) do
		local dir = root .. "/" .. rel
		if vim.fn.isdirectory(dir) == 1 then
			return dir
		end
	end
	return nil
end

--- Resolve the .qmltypes file for a module (via qmldir typeinfo, else first *.qmltypes).
function M.qmltypes_path(module)
	local dir = module_dir(module)
	if not dir then
		return nil
	end
	local qmldir = dir .. "/qmldir"
	if vim.fn.filereadable(qmldir) == 1 then
		for _, line in ipairs(vim.fn.readfile(qmldir)) do
			local info = line:match("^typeinfo%s+(%S+)")
			if info then
				local path = dir .. "/" .. info
				if vim.fn.filereadable(path) == 1 then
					return path
				end
			end
		end
	end
	local found = vim.fn.glob(dir .. "/*.qmltypes", false, true)
	if type(found) == "table" and found[1] then
		return found[1]
	end
	return nil
end

--- Normalize a qmltypes C++ type name to a stub default key.
local function default_for_type(typ)
	if not typ or typ == "" then
		return "null"
	end
	if defaults[typ] then
		return defaults[typ]
	end
	local lower = typ:lower()
	if defaults[lower] then
		return defaults[lower]
	end
	-- Pointers / QObject subclasses / unknown → null
	return "null"
end

local function brace_delta(line)
	local open = select(2, line:gsub("{", "{"))
	local close = select(2, line:gsub("}", "}"))
	return open - close
end

--- Parse every Component in a qmltypes file that has isRequired properties.
--- Returns map: exportName → list of { name, type }.
function M.parse_qmltypes_required(path)
	if not path or vim.fn.filereadable(path) == 0 then
		return {}
	end
	local lines = vim.fn.readfile(path)
	local by_export = {}

	local i = 1
	while i <= #lines do
		if not lines[i]:match("^%s*Component%s*{") then
			i = i + 1
			goto continue
		end

		local exports, props = {}, {}
		local depth = 1
		i = i + 1

		while i <= #lines and depth > 0 do
			local line = lines[i]

			-- Nested Property block: read fully, then apply its net brace delta once.
			if line:match("^%s*Property%s*{") then
				local pname, ptype, required = nil, nil, false
				local start = i
				local pd = 0
				while i <= #lines do
					local pl = lines[i]
					pd = pd + brace_delta(pl)
					local n = pl:match('name:%s*"([^"]+)"')
					if n and not pname then
						pname = n
					end
					local t = pl:match('type:%s*"([^"]+)"')
					if t and not ptype then
						ptype = t
					end
					if pl:match("isRequired:%s*true") then
						required = true
					end
					i = i + 1
					if i > start and pd <= 0 then
						break
					end
				end
				depth = depth + pd -- Property net is 0; Component depth unchanged
				if required and pname then
					props[#props + 1] = { name = pname, type = ptype or "var" }
				end
				goto continue_inner
			end

			-- exports: [ "Module/Name ver", ... ]
			if line:match("exports:") then
				local k = i
				while k <= #lines do
					for exp in lines[k]:gmatch('"([^"]+)"') do
						local name = exp:match("/([%w_]+)%s") or exp:match("/([%w_]+)$")
						if name then
							exports[#exports + 1] = name
						end
					end
					if lines[k]:match("%]") then
						break
					end
					k = k + 1
				end
			end

			depth = depth + brace_delta(line)
			i = i + 1
			::continue_inner::
		end

		if #props > 0 then
			-- Deduplicate export names (same type listed at multiple revisions).
			local seen = {}
			for _, exp in ipairs(exports) do
				if not seen[exp] then
					seen[exp] = true
					by_export[exp] = props
				end
			end
		end

		::continue::
	end
	return by_export
end

--- Required props for a module type, cached per qmltypes file.
function M.required_props_from_module(module, type_name)
	if not module or not type_name then
		return {}
	end
	local cache_key = module
	if not qmltypes_cache[cache_key] then
		local path = M.qmltypes_path(module)
		qmltypes_cache[cache_key] = path and M.parse_qmltypes_required(path) or {}
	end
	return qmltypes_cache[cache_key][type_name] or {}
end

--- @return string|nil module, string|nil rel_path
function M.parse_detail(detail)
	if not detail or detail == "" then
		return nil, nil
	end
	-- Go server uses an em-dash (—) between module and description.
	local left, right = detail:match("^(.-)%s*[—%-–]+%s*(.*)$")
	if not left then
		return nil, nil
	end
	left = vim.trim(left)
	right = vim.trim(right or "")
	if left == "workspace component" then
		return nil, right ~= "" and right or nil
	end
	if left:match("^[%w%.]+$") then
		return left, nil
	end
	return nil, nil
end

--- Don't expand when the type name is used as a type annotation.
function M.should_expand_class(line_before)
	if line_before:match(":%s*[%w_]*$") then
		return false
	end
	if line_before:match("%f[%w]property%s+[%w_%.]*$") then
		return false
	end
	if line_before:match("%f[%w]as%s+[%w_]*$") then
		return false
	end
	return true
end

--- True when a `{` body already follows the completion point (same line or next).
--- Stops re-accepting a partially deleted type name from nesting another expand.
function M.already_has_body(ctx)
	local col = ctx.cursor[2] -- 0-indexed
	local after = (ctx.line or ""):sub(col + 1)
	-- leftover id chars then `{`, e.g. cursor mid-"TreeViewDelegate {"
	if after:match("^[%w_]*%s*{") then
		return true
	end
	-- type on its own line; `{` on the next non-blank line
	if after:match("^[%w_]*%s*$") and ctx.bufnr and vim.api.nvim_buf_is_valid(ctx.bufnr) then
		-- blink cursor: row 1-indexed, col 0-indexed → next lines start at row (0-indexed)
		local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, ctx.cursor[1], ctx.cursor[1] + 3, false)
		for _, line in ipairs(lines) do
			if not line:match("^%s*$") then
				return line:match("^%s*{") ~= nil
			end
		end
	end
	return false
end

local function project_root(bufnr)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if client.root_dir and client.root_dir ~= "" then
			return client.root_dir
		end
	end
	return vim.fn.getcwd()
end

--- Parse `required property <type> <name>` from a workspace component file.
function M.required_props(bufnr, rel_path)
	if not rel_path or rel_path == "" then
		return {}
	end
	local path = project_root(bufnr) .. "/" .. rel_path
	if vim.fn.filereadable(path) == 0 then
		return {}
	end
	local props = {}
	for _, line in ipairs(vim.fn.readfile(path)) do
		local typ, name = line:match("^%s*required%s+property%s+([%w%.]+)%s+([%w_]+)")
		if typ and name then
			props[#props + 1] = { type = typ, name = name }
		end
	end
	return props
end

--- Scan whole buffer for existing imports (module name or "path").
function M.existing_imports(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local modules, paths = {}, {}
	local last_import_0 = -1 -- 0-indexed line of last import, or -1
	local last_pragma_0 = -1
	for i, line in ipairs(lines) do
		local idx = i - 1
		if line:match("^%s*pragma") then
			last_pragma_0 = idx
		end
		local mod = line:match("^%s*import%s+([%w%.]+)")
		if mod then
			modules[mod] = true
			last_import_0 = idx
		end
		local p = line:match('^%s*import%s+"([^"]+)"')
		if p then
			paths[p] = true
			last_import_0 = idx
		end
	end
	return modules, paths, last_import_0, last_pragma_0
end

--- Import line to insert, or nil if already present.
function M.import_line(bufnr, module, rel_path)
	local modules, paths = M.existing_imports(bufnr)
	if module then
		if modules[module] then
			return nil
		end
		return "import " .. module
	end
	if rel_path then
		local dir = rel_path:match("^(.+)/[^/]+%.qml$") or "."
		if paths[dir] then
			return nil
		end
		return 'import "' .. dir .. '"'
	end
	return nil
end

--- Insert import after the last import (or after pragmas, or at top).
--- Uses nvim_buf_set_lines — never LSP additionalTextEdits.
--- @return boolean applied, integer lines_inserted
function M.apply_import(bufnr, module, rel_path)
	if not M.is_qml_buf(bufnr) then
		return false, 0
	end
	local line = M.import_line(bufnr, module, rel_path)
	if not line then
		return false, 0
	end

	local _, _, last_import_0, last_pragma_0 = M.existing_imports(bufnr)
	-- Insert *after* this 0-indexed line → set_lines at row+1
	local after = last_import_0
	if after < 0 then
		after = last_pragma_0
	end
	local row = after + 1 -- 0-indexed row to insert at (push existing down)
	if row < 0 then
		row = 0
	end

	vim.api.nvim_buf_set_lines(bufnr, row, row, false, { line })
	return true, 1
end

function M.build_snippet(label, props)
	local parts = { label .. " {" }
	local n = 1
	for _, p in ipairs(props) do
		local def = default_for_type(p.type)
		parts[#parts + 1] = string.format("\t%s: ${%d:%s}", p.name, n, def)
		n = n + 1
	end
	parts[#parts + 1] = "\t$0"
	parts[#parts + 1] = "}"
	return table.concat(parts, "\n")
end

--- Resolve required props: workspace .qml source first, else module qmltypes.
function M.props_for_class(bufnr, label, module, rel)
	if rel then
		local props = M.required_props(bufnr, rel)
		if #props > 0 then
			return props
		end
	end
	if module and label then
		return M.required_props_from_module(module, label)
	end
	return {}
end

local function dedupe(items)
	local best, order = {}, {}
	for _, item in ipairs(items) do
		local key = tostring(item.kind or 0) .. "\0" .. (item.label or "")
		local prev = best[key]
		if not prev then
			best[key] = item
			order[#order + 1] = key
		elseif #(item.detail or "") > #(prev.detail or "") then
			best[key] = item
		end
	end
	local out = {}
	for _, key in ipairs(order) do
		out[#out + 1] = best[key]
	end
	return out
end

--- blink.cmp transform_items: QML Class → snippet body + label description.
--- Import is deferred to accept (see ensure_import_on_accept).
function M.transform_items(ctx, items)
	if not M.is_qml_buf(ctx.bufnr) then
		return items
	end
	if vim.g.qml_expand_on_accept == false then
		return dedupe(items)
	end

	local expand = M.should_expand_class(ctx.line:sub(1, ctx.cursor[2]))
		and not M.already_has_body(ctx)
	items = dedupe(items)

	for _, item in ipairs(items) do
		if item.kind == Class then
			local module, rel = M.parse_detail(item.detail)
			item.labelDetails = item.labelDetails or {}
			if module then
				item.labelDetails.description = module
			elseif rel then
				item.labelDetails.description = "workspace"
			end

			-- Stash for accept-time import. Custom field; blink ignores unknown keys.
			item._qml_module = module
			item._qml_rel = rel

			if expand then
				-- Only set snippet once so resolve/re-transform doesn't stack.
				if item.insertTextFormat ~= Snippet then
					local props = M.props_for_class(ctx.bufnr, item.label, module, rel)
					item.insertText = M.build_snippet(item.label, props)
					item.insertTextFormat = Snippet
					item.textEdit = nil
					-- Never use additionalTextEdits for imports.
					item.additionalTextEdits = nil
				end
			end
		end
	end

	return items
end

--- Call from blink accept path: after the item is inserted, add a missing import.
--- Does not touch pragmas — Bound vs Singleton is a file-level choice, not inferred.
function M.ensure_import_on_accept(item)
	if not item or item.kind ~= Class then
		return
	end
	if vim.g.qml_expand_on_accept == false then
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	if not M.is_qml_buf(bufnr) then
		return
	end
	local module, rel = item._qml_module, item._qml_rel
	if not module and not rel then
		module, rel = M.parse_detail(item.detail)
	end
	-- Defer so snippet expansion finishes first.
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		local win = vim.api.nvim_get_current_win()
		local cursor = vim.api.nvim_win_get_cursor(win)
		local _, _, last_import_0, last_pragma_0 = M.existing_imports(bufnr)
		local after = last_import_0 >= 0 and last_import_0 or last_pragma_0
		local insert_row = after + 1
		if insert_row < 0 then
			insert_row = 0
		end
		if not M.apply_import(bufnr, module, rel) then
			return
		end
		if insert_row < cursor[1] then
			pcall(vim.api.nvim_win_set_cursor, win, { cursor[1] + 1, cursor[2] })
		end
	end)
end

return M
