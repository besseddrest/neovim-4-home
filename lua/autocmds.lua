local augroup = vim.api.nvim_create_augroup
local utils = require("utils")
local buf_map = utils.buf_map

-- Neovim 0.11 lsp autocomplete, etc
-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	callback = function(args)
-- 		local client = vim.lsp.get_client_by_id(args.data.client_id)
-- 		if not client then
-- 			return
-- 		end
-- 		---@diagnostic disable-next-line: missing-parameter
-- 		if client:supports_method("textDocument/formatting") then
-- 			-- Format the damn thing on save
-- 			vim.api.nvim_create_autocmd("BufWritePre", {
-- 				buffer = args.buf,
-- 				callback = function()
-- 					vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
-- 				end,
-- 			})
-- 		end
-- 		if client:supports_method("textDocument/completion") then
-- 			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = false })
-- 			vim.cmd("highlight @comment gui=italic cterm=italic")
-- 		end
-- 	end,
-- })
--
-- -- not autocmd but find a place for this later
-- vim.diagnostic.config({
-- 	-- virtual_text = true,
-- 	-- float = true,
-- })

-- autocmds from gale
vim.api.nvim_create_autocmd("Filetype", {
    desc = "Prevent <Tab>/<S-Tab> from switching specific buffers.",
    pattern = {
        "codecompanion",
        "lazy",
        "qf",
        "dbout",
        "dbui",
        "help",
    },
    group = augroup("PreventBufferSwap", { clear = true }),
    callback = function(event)
        local lhs_list = { "<Tab>", "<S-Tab>" }
        buf_map(event.buf, "n", lhs_list, "<nop>")
    end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
	desc = "Prevent auto-comment on new line.",
	pattern = "*",
	group = augroup("NoNewLineComment", { clear = true }),
	command = [[
    setlocal formatoptions-=c formatoptions-=r formatoptions-=o
  ]],
})

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight on yank.",
	group = augroup("HighlightOnYank", { clear = true }),
	callback = function()
		vim.hl.on_yank({ higroup = "YankVisual", timeout = 200, on_visual = true })
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	desc = "Remove trailing whitespaces on save.",
	group = augroup("TrimWhitespaceOnSave", { clear = true }),
	command = [[ %s/\s\+$//e ]],
})

-- Cursor line fill — base46 transparency zeros CursorLine; paint after scheme load.
local function paint_cursorline()
	local bg = "#2d2b38"
	local ok, base46 = pcall(require, "base46")
	if ok then
		local c = base46.get_theme_tb("base_30")
		if c and c.one_bg2 then
			bg = c.one_bg2
		end
	end
	vim.api.nvim_set_hl(0, "CursorLine", { bg = bg })
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
	desc = "Keep CursorLine bg filled (transparency-safe).",
	group = augroup("CursorLineFill", { clear = true }),
	callback = paint_cursorline,
})
vim.api.nvim_create_autocmd("User", {
	pattern = "NvThemeReload",
	group = "CursorLineFill",
	callback = paint_cursorline,
})

-- Inline messages come from tiny-inline-diagnostic (wrap + hanging indent).
-- Keep native VT off so they don't double up.
vim.diagnostic.config({
	virtual_text = false,
	float = { border = "rounded", source = "if_many" },
	underline = true,
	severity_sort = true,
})

-- Absolute line numbers in insert; restore previous relativenumber on leave.
vim.api.nvim_create_autocmd("InsertEnter", {
	desc = "Absolute line numbers in insert mode.",
	group = augroup("InsertAbsoluteNumbers", { clear = true }),
	callback = function()
		vim.w._rnu = vim.wo.relativenumber
		vim.wo.relativenumber = false
	end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
	desc = "Restore relativenumber after insert.",
	group = "InsertAbsoluteNumbers",
	callback = function()
		if vim.w._rnu ~= nil then
			vim.wo.relativenumber = vim.w._rnu
		end
	end,
})


-- NvimTree
-- vim.api.nvim_create_autocmd("BufWinEnter", {
--   desc = "Add numbers to NvimTree",
--   -- group = augroup("NvimTree", { clear = true }),
--   command = [[ setlocal rnu ]],
-- })

-- Dadbod
-- vim.api.nvim_create_autocmd("FileType", {
--   desc = "Automatically unfold query results",
--   pattern = { "dbout" },
--   callback = function()
--     vim.opt.foldenable = false
--   end,
-- })
