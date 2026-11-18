require("nvchad.configs.lspconfig").defaults()

-- see lua/options.lua
local indent = vim.g.indent_width or 4

local servers = {
	"html",
	"cssls",
	"ts_ls",
	"jsonls",
	"markdown_oxide",
	"qml-language-server",
	"qmlls",
	"dartls",
	"astro",
	"eslint",
	"bashls",
	"somesass_ls",
	"sqlls",
	"lua_ls",
}

local htmlSettings = {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html", "templ" },
	root_markers = { "package.json", ".git" },
	settings = {},
	init_options = {
		provideFormatter = true,
		embeddedLanguages = { css = true, javascript = true },
		configurationSection = { "html", "css", "javascript" },
	},
}

local cssSettings = {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	init_options = { provideFormatter = true },
	root_markers = { "package.json", ".git" },
	settings = {
		css = { validate = true },
		scss = { validate = true },
		less = { validate = true },
	},
}

local tsSettings = {
	init_options = { hostInfo = "neovim" },
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	},
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git", "manifest.json" },
	settings = {
		typescript = {
			format = {
				tabSize = indent,
				indentSize = indent,
			},
		},
		javascript = {
			format = {
				tabSize = indent,
				indentSize = indent,
			},
		},
	},
	handlers = {
		["_typescript.rename"] = function(_, result, ctx)
			local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
			vim.lsp.util.show_document({
				uri = result.textDocument.uri,
				range = {
					start = result.position,
					["end"] = result.position,
				},
			}, client.offset_encoding)
			vim.lsp.buf.rename()
			return vim.NIL
		end,
	},
	commands = {
		["editor.action.showReferences"] = function(command, ctx)
			local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
			local file_uri, position, references = unpack(command.arguments)

			local quickfix_items = vim.lsp.util.locations_to_items(references, client.offset_encoding)
			vim.fn.setqflist({}, " ", {
				title = command.title,
				items = quickfix_items,
				context = {
					command = command,
					bufnr = ctx.bufnr,
				},
			})

			vim.lsp.util.show_document({
				uri = file_uri,
				range = {
					start = position,
					["end"] = position,
				},
			}, client.offset_encoding)

			vim.cmd("botright copen")
		end,
	},
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, "LspTypescriptSourceAction", function()
			local source_actions = vim.tbl_filter(function(action)
				return vim.startswith(action, "source.")
			end, client.server_capabilities.codeActionProvider.codeActionKinds)

			vim.lsp.buf.code_action({
				context = {
					only = source_actions,
				},
			})
		end, {})
	end,
}

local jsonSettings = {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	init_options = {
		provideFormatter = true,
	},
	root_markers = { ".git" },
}

local markdownSettings = {
	cmd = { "markdown-oxide" },
	filetypes = { "markdown" },
	root_markers = { ".git", ".obsidian", ".moxide.toml" },
}

-- A Quickshell config is self contained: the directory that holds shell.qml is
-- the project root and everything under it (components/, utils/, ...) belongs to
-- that config alone. Rooting at the shared git repo instead would index every
-- shell config in one workspace.
local function qml_root(bufnr, on_dir)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	local dir = vim.fs.dirname(vim.fs.normalize(fname))
	on_dir(vim.fs.root(dir, { "shell.qml" }) or vim.fs.root(dir, { ".git" }) or dir)
end

-- Quickshell's QML plugins are statically linked into the quickshell binary, so
-- qmlls cannot load them to check that the types are creatable. Upstream
-- documents this ("PanelWindow in particular cannot be resolved").
local function drop_uncreatable(diagnostics)
	return vim.tbl_filter(function(d)
		return not (d.message or ""):find("[uncreatable-type]", 1, true)
	end, diagnostics)
end

-- Qt's official QML language server. Type aware, so it reports unknown
-- properties, wrong types and unresolved imports. This is the ts_ls of QML.
local qmllsSettings = {
	cmd = { "/usr/bin/qmlls6" },
	filetypes = { "qml" },
	root_dir = qml_root,
	on_attach = function(client)
		client.handlers["textDocument/publishDiagnostics"] = function(err, params, ctx)
			params.diagnostics = drop_uncreatable(params.diagnostics)
			vim.lsp.diagnostic.on_publish_diagnostics(err, params, ctx)
		end
		client.handlers["textDocument/diagnostic"] = function(err, result, ctx)
			if result and result.kind == "full" then
				result.items = drop_uncreatable(result.items)
			end
			vim.lsp.diagnostic.on_diagnostic(err, result, ctx)
		end
	end,
}

-- Third party Go QML server. Knows Quickshell types, imports and snippets and
-- indexes workspace components across files. Its diagnostics are parse errors
-- only, so they are muted to avoid doubling up with qmlls.
local qmlSettings = {
	cmd = { "qml-language-server" },
	filetypes = { "qml" },
	root_dir = qml_root,
	settings = {
		qml = {
			format = {
				tabSize = vim.o.shiftwidth,
				insertSpaces = vim.o.expandtab,
			},
		},
	},
	on_attach = function(client, _)
		client.handlers["textDocument/publishDiagnostics"] = function() end
		client.handlers["textDocument/diagnostic"] = function() end
		-- upstream Go race in handler/inlayhints.go: concurrent map read/write
		client.server_capabilities.inlayHintProvider = false
	end,
}

local dartSettings = {
	cmd = { "dart", "language-server", "--protocol=lsp" },
	filetypes = { "dart" },
	root_markers = { "pubspec.yaml" },
	init_options = {
		onlyAnalyzeProjectsWithOpenFiles = true,
		suggestFromUnimportedLibraries = true,
		closingLabels = true,
		outline = true,
		flutterOutline = true,
	},
	settings = {
		dart = {
			completeFunctionCalls = true,
			showTodos = true,
		},
	},
}

local astroSettings = {
	cmd = { "astro-ls", "--stdio" },
	filetypes = { "astro" },
	root_markers = { "package.json", "tsconfig.json", "jsonconfig.json", ".git" },
}

local eslintSettings = {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"vue",
		"svelte",
		"astro",
	},
	root_markers = {
		".eslintrc",
		".eslintrc.json",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.yaml",
		".eslintrc.yml",
		"eslint.config.js",
		"eslint.config.mjs",
		"eslint.config.cjs",
		"package.json",
	},
	settings = {
		validate = "on",
		packageManager = "npm",
		useESLintClass = true,
		experimental = {
			useFlatConfig = true,
		},
		codeAction = {
			disableRuleComment = {
				enable = true,
				location = "separateLine",
			},
			showDocumentation = {
				enable = true,
			},
		},
		format = false,
	},
	on_attach = function(client, bufnr)
		-- Formatting handled by conform.nvim (prettier)
	end,
}

local luaSettings = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".git", "selene.toml", "stylua.toml" },
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "require" },
			},
			runtime = {
				version = "LuaJIT",
				path = vim.split(package.path, ";"),
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
				},
				checkThirdParty = false,
			},
			telemetry = {
				enable = false,
			},
		},
	},
}

local bashSettings = {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "bash", "zsh" },
	root_markers = { ".git", "package.json" },
}

local somesassSettings = {
	cmd = { "somesass-language-server", "--stdio" },
	filetypes = { "scss", "sass" },
	root_markers = { "package.json", ".git" },
}

local sqlSettings = {
	cmd = { "sql-language-server", "up", "--method", "stdio" },
	filetypes = { "sql", "mysql" },
	root_markers = { ".git", "package.json" },
}

vim.lsp.config("html", htmlSettings)
vim.lsp.config("cssls", cssSettings)
vim.lsp.config("ts_ls", tsSettings)
vim.lsp.config("jsonls", jsonSettings)
vim.lsp.config("markdown_oxide", markdownSettings)
vim.lsp.config("qml-language-server", qmlSettings)
vim.lsp.config("qmlls", qmllsSettings)
vim.lsp.config("dartls", dartSettings)
vim.lsp.config("astro", astroSettings)
vim.lsp.config("eslint", eslintSettings)
vim.lsp.config("lua_ls", luaSettings)
vim.lsp.config("bashls", bashSettings)
vim.lsp.config("somesass_ls", somesassSettings)
vim.lsp.config("sqlls", sqlSettings)
vim.lsp.enable(servers)

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		vim.cmd("highlight @comment gui=italic cterm=italic")
	end,
})

vim.diagnostic.config({})

