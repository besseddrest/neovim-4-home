local map = vim.keymap.set

-- NOTE: general QOL
-- enter
map("n", ";", ":", { desc = "Enter command mode" })
map("i", "jk", "<ESC>", { desc = "Escape from current motion" })

-- Remap 'Q' to 'q' to quit application
vim.cmd("cabbrev Q q")
vim.cmd("cabbrev Qa qa")

-- Basic motions, but followed by `zz` to keep cursor centered
map("n", "}", "}zz", { desc = "Jump Down Blank Line" })
map("n", "{", "{zz", { desc = "Jump Up Blank Line" })
map("n", "<Up>", "<Up>zz", { desc = "Navigate Up" })
map("n", "<Down>", "<Down>zz", { desc = "Navigate Down" })
map("n", "k", "kzz", { desc = "Navigate Up" })
map("n", "j", "jzz", { desc = "Navigate Down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Jump Up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Jump Down" })

-- (n)o (h)ighlight
map("n", "<leader>nh", "<CMD>noh<CR>", { desc = "Hide Search Matches" })

-- (i)nlay hints
map("n", "<leader>i", function()
	local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
	vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
end, { desc = "Inlay Hint Toggle" })

-- (f)ind and (r)eplace in current file
map("n", "<leader>fr", ":%s/", { desc = "Find/Search and Replace" })

-- (o)pen (d)iagnostic
map("n", "<leader>od", function()
	return vim.diagnostic.open_float({ width = 50 })
end, { desc = "Opens Diagostic messages in a floated tooltip" })

-- gd is buffer-local on LspAttach (see configs/lspconfig.lua) so it wins over NvChad.
map("n", "K", function()
	vim.lsp.buf.hover({ max_width = math.floor(vim.o.columns * 0.5) })
end, { desc = "LSP Hover" })
map("n", "gr", function()
	Snacks.picker.lsp_references({ unique_lines = true })
end, { desc = "LSP References" })
map("n", "gi", function()
	Snacks.picker.lsp_implementations()
end, { desc = "LSP Implementation" })
map("n", "gy", function()
	Snacks.picker.lsp_type_definitions()
end, { desc = "LSP Type Definition" })
map("n", "gO", function()
	Snacks.picker.lsp_symbols()
end, { desc = "LSP Document Symbols" })
map("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "LSP Workspace Symbols" })
map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP Code Action" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP Rename" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = vim.v.count1, float = true })
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -vim.v.count1, float = true })
end, { desc = "Prev Diagnostic" })

-- greatest remap ever (ThePrimeagen)
map("x", "<leader>p", "_dP")

-- moves focus to different splits and or panes
map("n", "<C-Left>", "<C-w>h", { desc = "focus pane left" })
map("n", "<A-Down>", "<C-w>j", { desc = "focus pane down" })
map("n", "<A-Up>", "<C-w>k", { desc = "focus pane up" })
map("n", "<C-Right>", "<C-w>l", { desc = "focus pane right" })

-- comments
map("n", "<leader>/", "gcc", { desc = "comment toggle", remap = true })
map("v", "<leader>/", "gc", { desc = "comment toggle", remap = true })

-- Open a terminal
map({ "n", "t" }, "<A-t>", function()
	require("nvchad.term").toggle({ pos = "float", id = "floatTerm" })
end, { desc = "terminal toggle floating term" })

-- NOTE: PLUGIN SPECIFIC

map("n", "<leader><BS>", function()
	Snacks.bufdelete()
end, { desc = "Buffer close" })
map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "Buffer new" })
map("n", "<leader>bh", "<cmd>split | enew<CR>", { desc = "Buffer new horizontal split" })
map("n", "<leader>bv", "<cmd>vsplit | enew<CR>", { desc = "Buffer new vertical split" })

-- Close mini.files if open (no-op when plugin not loaded yet)
local function close_mini_files()
	local ok, mf = pcall(require, "mini.files")
	if ok then
		pcall(mf.close)
	end
end

-- Pickers (<C-n> MiniFiles lives on the plugin keys spec)
map("n", "<leader>G", function()
	close_mini_files()
	Snacks.picker.grep()
end, { desc = "Live Grep" })
map("n", "<leader>R", function()
	close_mini_files()
	Snacks.picker.recent()
end, { desc = "Recent Picker" })
map("n", "<leader>F", function()
	close_mini_files()
	Snacks.picker.files()
end, { desc = "Find Files" })
map("n", "<leader>B", function()
	close_mini_files()
	Snacks.picker.buffers()
end, { desc = "Buffers List" })
map("n", "<leader>L", function()
	close_mini_files()
	Snacks.picker.highlights()
end, { desc = "Highlights" })
map("n", "<leader>N", function()
	close_mini_files()
	Snacks.picker.notifications()
end, { desc = "Notifications" })
map("n", "<leader>C", function()
	close_mini_files()
	Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Nvim Config" })
map("n", "<leader>T", function()
	local wins_before = {}
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(w).relative ~= "" then
			wins_before[w] = true
		end
	end

	require("nvchad.themes").open({ border = true })

	local picker_win
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(w).relative ~= "" and not wins_before[w] then
			picker_win = w
			break
		end
	end

	if picker_win then
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(picker_win),
			once = true,
			callback = function()
				vim.schedule(function()
					for _, w in ipairs(vim.api.nvim_list_wins()) do
						local cfg = vim.api.nvim_win_get_config(w)
						if cfg.relative ~= "" then
							pcall(vim.api.nvim_win_close, w, true)
						end
					end
					Snacks.dashboard.open()
				end)
			end,
		})
	end
end, { desc = "Themes" })

-- Blame
map("n", "<leader>bt", "<cmd>BlameToggle<CR>", { desc = "Blame Toggle" })

-- Gitsigns
map("n", "<leader>hu", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Gitsigns Preview Hunk" })

-- DadBod
