-- Local QML type docs fallback when LSP hover is empty/stub.
-- Qt: scripts/qch2md.py from local qt6-doc .qch (qmlls Help plugin missing on Arch).
-- Quickshell: scripts/qs2md.py mirror.
-- On miss, auto-extracts a PascalCase type from .qch once, then shows it.
-- Display style: "card" (LSP-like layout) or "raw" (full markdown). Toggle with
--   :lua require("qml_docs").toggle_style()  or  vim.g.qml_docs_style
-- Data: stdpath("data")/qml-docs/{index.json,Type.md}.

local M = {}

local root = vim.fn.stdpath("data") .. "/qml-docs"
local script = vim.fn.stdpath("config") .. "/scripts/qch2md.py"
local index ---@type table<string, { body_file: string, summary: string, url: string }>|nil

--- Names we already tried and failed (no qch page). Avoid repeat work.
local miss_cache = {} ---@type table<string, true>
--- In-flight extracts so double-K does not spawn two processes.
local inflight = {} ---@type table<string, true>

---@return "card"|"raw"
local function style()
	local s = vim.g.qml_docs_style
	if s == "raw" or s == "card" then
		return s
	end
	return "card"
end

local function load_index()
	if index then
		return index
	end
	local path = root .. "/index.json"
	local fh = io.open(path, "r")
	if not fh then
		index = {}
		return index
	end
	local ok, data = pcall(vim.json.decode, fh:read("*a"))
	fh:close()
	index = {}
	if ok and type(data) == "table" then
		for _, row in ipairs(data) do
			if row.type_name then
				index[row.type_name] = row
			end
		end
	end
	return index
end

---@return string|nil
local function word_under_cursor()
	local word = vim.fn.expand("<cword>")
	if word == "" then
		return nil
	end
	return word
end

--- Only auto-extract things that look like QML type names (PascalCase).
---@param name string
---@return boolean
local function looks_like_type(name)
	return name:match("^[A-Z][A-Za-z0-9]+$") ~= nil
end

---@param name string
---@return string|nil markdown, table|nil entry
local function body_for(name)
	local entry = load_index()[name]
	if not entry or not entry.body_file then
		return nil, nil
	end
	local path = root .. "/" .. entry.body_file
	local fh = io.open(path, "r")
	if not fh then
		return nil, nil
	end
	local text = fh:read("*a")
	fh:close()
	return text, entry
end

--- Parse extracted markdown into structured fields (qch + qs shapes).
---@param md string
---@param name string
---@param entry table|nil
---@return table
local function parse_doc(md, name, entry)
	local lines = vim.split(md, "\n", { plain = true })
	local info = {
		name = name,
		module = nil,
		inherits = nil,
		summary = entry and entry.summary or nil,
		url = entry and entry.url or nil,
		description = {},
		example = nil,
		properties = {},
		functions = {},
		signals = {},
		other = {},
	}

	-- Strip trailing url block we sometimes append
	local body_lines = {}
	for i, line in ipairs(lines) do
		if line == "---" and i > 1 and lines[i + 1] and lines[i + 1]:match("^https?://") then
			info.url = info.url or lines[i + 1]
			break
		end
		body_lines[#body_lines + 1] = line
	end

	local section = "header" -- header | description | properties | functions | signals | other
	local i = 1
	local n = #body_lines

	local function heading_kind(line)
		local h = line:match("^#+%s+(.+)")
		if not h then
			return nil
		end
		local hl = h:lower()
		if hl:find("propert") then
			return "properties"
		end
		if hl:find("function") or hl:find("method") then
			return "functions"
		end
		if hl:find("signal") then
			return "signals"
		end
		if hl:find("detailed description") or hl:find("^description") or hl:find("example") then
			return "description"
		end
		if hl:find("see also") or hl:find("member") then
			return "other"
		end
		return "other"
	end

	-- Title line
	if body_lines[1] and body_lines[1]:match("^#%s+") then
		local title = body_lines[1]:gsub("^#%s+", ""):gsub("%s+QML Type%s*$", "")
		info.name = title ~= "" and title or name
		i = 2
	end

	while i <= n do
		local line = body_lines[i]
		local kind = heading_kind(line)
		if kind then
			section = kind
			i = i + 1
		elseif section == "header" then
			local trimmed = vim.trim(line)
			if trimmed == "" then
				i = i + 1
			elseif trimmed:match("^`import ") or trimmed:match("^import ") then
				info.module = trimmed:gsub("^`", ""):gsub("`$", ""):gsub("^import%s+", "")
				i = i + 1
			elseif trimmed:match("^[Ii]mport [Ss]tatement:") then
				info.module = trimmed:match("[Ii]mport [Ss]tatement:%s*import%s+(.+)") or trimmed
				i = i + 1
			elseif trimmed:match("^[Ii]nherits:") or trimmed:match("^Extends:") then
				info.inherits = trimmed:match(":%s*`?([^`]+)`?") or trimmed
				i = i + 1
			elseif trimmed:match("^- Import") then
				info.module = trimmed:match("import%s+(.+)") or info.module
				i = i + 1
			elseif trimmed:match("^- Inherits:") then
				info.inherits = trimmed:match("Inherits:%s*(.+)") or info.inherits
				i = i + 1
			elseif trimmed:match("^```") then
				-- unexpected code in header → example
				local code = { line }
				i = i + 1
				while i <= n and not body_lines[i]:match("^```") do
					code[#code + 1] = body_lines[i]
					i = i + 1
				end
				if i <= n then
					code[#code + 1] = body_lines[i]
					i = i + 1
				end
				info.example = table.concat(code, "\n")
				section = "description"
			elseif not info.summary or info.summary == "" then
				info.summary = trimmed
				i = i + 1
				section = "description"
			else
				section = "description"
			end
		elseif section == "description" then
			if line:match("^```") then
				local code = { line }
				i = i + 1
				while i <= n and not body_lines[i]:match("^```") do
					code[#code + 1] = body_lines[i]
					i = i + 1
				end
				if i <= n then
					code[#code + 1] = body_lines[i]
					i = i + 1
				end
				if not info.example then
					info.example = table.concat(code, "\n")
				else
					vim.list_extend(info.description, code)
					info.description[#info.description + 1] = ""
				end
			else
				info.description[#info.description + 1] = line
				i = i + 1
			end
		elseif section == "properties" or section == "functions" or section == "signals" then
			local t = vim.trim(line)
			if t:match("^%-") then
				info[section][#info[section] + 1] = t:gsub("^%- %s*", "")
			elseif t ~= "" and not t:match("^#") then
				-- continuation of previous bullet
				local list = info[section]
				if #list > 0 then
					list[#list] = list[#list] .. " " .. t
				end
			end
			i = i + 1
		else
			info.other[#info.other + 1] = line
			i = i + 1
		end
	end

	-- Clean description blanks
	while info.description[1] == "" do
		table.remove(info.description, 1)
	end
	while #info.description > 0 and info.description[#info.description] == "" do
		table.remove(info.description)
	end

	if (not info.summary or info.summary == "") and #info.description > 0 then
		info.summary = info.description[1]
	end

	return info
end

--- LSP-like card layout from structured doc (still full content, better ordered).
---@param info table
---@return string
local function format_card(info)
	local out = {}
	local function add(s)
		out[#out + 1] = s
	end

	add("**" .. info.name .. "** — type")
	if info.module then
		add("*" .. info.module:gsub("^import%s+", "") .. "*")
	end
	if info.inherits then
		add("inherits `" .. info.inherits:gsub("^Inherits:%s*", "") .. "`")
	end
	add("")

	if info.summary and info.summary ~= "" then
		add(info.summary)
		add("")
	end

	if info.example then
		add(info.example)
		add("")
	else
		add("```qml")
		add(info.name .. " { /* … */ }")
		add("```")
		add("")
	end

	-- Description minus the summary line if duplicated
	local desc = {}
	for _, line in ipairs(info.description) do
		if line ~= info.summary then
			desc[#desc + 1] = line
		end
	end
	while desc[1] == "" do
		table.remove(desc, 1)
	end
	if #desc > 0 then
		add("## Description")
		add("")
		for _, line in ipairs(desc) do
			add(line)
		end
		add("")
	end

	local function emit_list(title, items)
		if #items == 0 then
			return
		end
		add("## " .. title)
		add("")
		for _, item in ipairs(items) do
			-- "name : type rest" → **name** : `type` — rest
			local formatted = item
			local pname, rest = item:match("^([%w_.]+)%s*:?(.*)$")
			if pname and rest then
				rest = vim.trim(rest)
				local ty, more = rest:match("^`?([%w_.<>,%s%[%]%*]+)`?%s*[—%-%s]*(.*)$")
				if ty and #ty < 40 and more then
					formatted = string.format("**%s** : `%s`", pname, vim.trim(ty))
					more = vim.trim(more)
					if more ~= "" then
						formatted = formatted .. " — " .. more
					end
				else
					formatted = "**" .. pname .. "**" .. (rest ~= "" and (" " .. rest) or "")
				end
			end
			add("- " .. formatted)
		end
		add("")
	end

	emit_list("Properties", info.properties)
	emit_list("Functions", info.functions)
	emit_list("Signals", info.signals)

	if info.url and info.url ~= "" then
		add("---")
		add(info.url)
	end

	-- collapse excess blank lines
	local text = table.concat(out, "\n")
	text = text:gsub("\n\n\n+", "\n\n")
	return vim.trim(text) .. "\n"
end

---@param md string
---@param name string
---@param entry table|nil
---@return string
local function present(md, name, entry)
	if style() == "raw" then
		if entry and entry.url and entry.url ~= "" and not md:find(entry.url, 1, true) then
			return md .. "\n\n---\n" .. entry.url .. "\n"
		end
		return md
	end
	return format_card(parse_doc(md, name, entry))
end

local function open_md(md)
	local lines = vim.split(md, "\n", { plain = true })
	local max_width = math.floor(vim.o.columns * 0.5)
	local max_height = math.min(24, math.floor(vim.o.lines * 0.45))
	vim.lsp.util.open_floating_preview(lines, "markdown", {
		border = "rounded",
		max_width = max_width,
		max_height = max_height,
		focus_id = "qml_docs",
	})
end

--- Hover float for a type name. Returns true if shown.
---@param name string|nil
---@return boolean
function M.try_hover(name)
	name = name or word_under_cursor()
	if not name then
		return false
	end
	local md, entry = body_for(name)
	if not md then
		return false
	end
	open_md(present(md, name, entry))
	return true
end

--- Flatten LSP hover contents to plain text.
---@param contents any
---@return string
local function contents_text(contents)
	if contents == nil then
		return ""
	end
	if type(contents) == "string" then
		return contents
	end
	if type(contents) == "table" then
		if contents.value then
			return contents.value
		end
		if contents[1] then
			local parts = {}
			for _, c in ipairs(contents) do
				parts[#parts + 1] = type(c) == "string" and c or (c.value or "")
			end
			return table.concat(parts, "\n")
		end
		return ""
	end
	return tostring(contents)
end

--- True when LSP hover is empty, a one-line stub, or the Go server's short
--- type card ("Name - type" / `Name { … }` / one blurb). Those hide real
--- qch pages — treat as miss so local/auto-extract can win.
---@param contents any
---@return boolean
function M.is_stub(contents)
	local text = vim.trim(contents_text(contents) or "")
	if text == "" then
		return true
	end

	if #text < 500 then
		local lower = text:lower()
		if lower:find("%- type") or lower:find("— type") or lower:find("%*%*.*%*%*%s*[—%-]%s*type") then
			return true
		end
		if text:find("{%s*%.%.%.%s*}") then
			return true
		end
	end

	local lines = vim.split(text, "\n", { plain = true })
	local prose = 0
	for _, line in ipairs(lines) do
		local t = vim.trim(line)
		if t ~= "" and not t:match("^%*%*") and not t:match("^_") and not t:match("^```") then
			if not t:match("^[A-Za-z][A-Za-z0-9.]*$") then
				prose = prose + 1
			end
		end
	end
	return prose == 0
end

--- Extract one type from local .qch into qml-docs, then show it.
---@param name string
local function auto_extract(name)
	if miss_cache[name] or inflight[name] then
		return
	end
	if not looks_like_type(name) then
		vim.notify("No hover info", vim.log.levels.INFO)
		return
	end
	if vim.fn.filereadable(script) == 0 then
		vim.notify("No hover info (missing qch2md.py)", vim.log.levels.WARN)
		return
	end

	inflight[name] = true
	vim.notify("Extracting docs for " .. name .. "…", vim.log.levels.INFO)

	vim.system({ "python3", script, "--types", name, "--json" }, {
		text = true,
		timeout = 30000,
	}, function(obj)
		vim.schedule(function()
			inflight[name] = nil
			local ok_parse, payload = pcall(vim.json.decode, vim.trim(obj.stdout or ""))
			local succeeded = obj.code == 0 and ok_parse and type(payload) == "table" and payload.ok

			if succeeded then
				index = nil
				if M.try_hover(name) then
					return
				end
			end

			miss_cache[name] = true
			local err = (ok_parse and payload and payload.error) or "not in local qt6-doc"
			vim.notify("No hover info for '" .. name .. "' (" .. err .. ")", vim.log.levels.INFO)
		end)
	end)
end

--- After LSP miss: try local store, else auto-extract from qch.
local function fallback(name)
	name = name or word_under_cursor()
	if M.try_hover(name) then
		return
	end
	if name then
		auto_extract(name)
	else
		vim.notify("No hover info", vim.log.levels.INFO)
	end
end

--- K handler: LSP first (prefer qmlls), then local, then on-demand qch extract.
function M.hover()
	local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/hover" })

	if #clients == 0 then
		fallback()
		return
	end

	local enc = clients[1].offset_encoding or "utf-16"
	local params = vim.lsp.util.make_position_params(0, enc)

	vim.lsp.buf_request_all(0, "textDocument/hover", params, function(results)
		local name = word_under_cursor()

		if name then
			local local_md, entry = body_for(name)
			if local_md then
				local best_lsp
				local best_rank = -1
				for id, res in pairs(results) do
					if res.result and res.result.contents and not M.is_stub(res.result.contents) then
						local client = vim.lsp.get_client_by_id(id)
						local cname = client and client.name or ""
						local rank = (cname:find("qmlls", 1, true) or cname == "qmlls") and 2 or 1
						if rank > best_rank then
							best_lsp = res.result.contents
							best_rank = rank
						end
					end
				end
				local lsp_len = #contents_text(best_lsp)
				if not best_lsp or #local_md >= math.max(lsp_len, 600) then
					open_md(present(local_md, name, entry))
					return
				end
			end
		end

		local best
		local best_rank = -1
		for id, res in pairs(results) do
			if res.result and res.result.contents and not M.is_stub(res.result.contents) then
				local client = vim.lsp.get_client_by_id(id)
				local cname = client and client.name or ""
				local rank = (cname:find("qmlls", 1, true) or cname == "qmlls") and 2 or 1
				if rank > best_rank then
					best = res.result
					best_rank = rank
				end
			end
		end

		if best then
			local ms = vim.lsp.util.convert_input_to_markdown_lines(best.contents)
			while ms[1] == "" do
				table.remove(ms, 1)
			end
			while #ms > 0 and ms[#ms] == "" do
				table.remove(ms)
			end
			if not vim.tbl_isempty(ms) then
				vim.lsp.util.open_floating_preview(ms, "markdown", {
					border = "rounded",
					max_width = math.floor(vim.o.columns * 0.5),
					max_height = math.min(24, math.floor(vim.o.lines * 0.45)),
					focus_id = "textDocument/hover",
				})
				return
			end
		end

		fallback(name)
	end)
end

function M.reload()
	index = nil
	load_index()
end

function M.clear_miss_cache()
	miss_cache = {}
end

---@param mode "card"|"raw"|nil
function M.set_style(mode)
	if mode ~= "card" and mode ~= "raw" then
		vim.notify("qml_docs style must be 'card' or 'raw'", vim.log.levels.ERROR)
		return
	end
	vim.g.qml_docs_style = mode
	vim.notify("qml_docs style: " .. mode, vim.log.levels.INFO)
end

function M.toggle_style()
	local next = style() == "card" and "raw" or "card"
	M.set_style(next)
end

function M.get_style()
	return style()
end

vim.api.nvim_create_user_command("QmlDocsStyle", function(opts)
	local arg = opts.args
	if arg == "" or arg == "toggle" then
		M.toggle_style()
	else
		M.set_style(arg)
	end
end, {
	nargs = "?",
	complete = function()
		return { "card", "raw", "toggle" }
	end,
	desc = "QML local docs layout: card | raw | toggle",
})

return M
