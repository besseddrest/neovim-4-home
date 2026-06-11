require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "ts_ls", "jsonls", "markdown_oxide", "qmlls", "dartls", "astro", "eslint", "bashls", "somesass_ls", "sqlls", "lua_ls" }

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
        tabSize = 4,
        indentSize = 4,
      },
    },
    javascript = {
      format = {
        tabSize = 4,
        indentSize = 4,
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
  on_attach = function(client, bufnr)
    for _, cmd in ipairs({ "today", "tomorrow", "yesterday" }) do
      vim.api.nvim_buf_create_user_command(
        bufnr,
        "Lsp" .. ("%s"):format(cmd:gsub("^%l", string.upper)),
        function()
          command_factory(client, bufnr, cmd)
        end,
        {
          desc = ("Open %s daily note"):format(cmd),
        }
      )
    end
  end,
}

local qmlSettings = {
  cmd = { "qmlls6" },
  filetypes = { "qml" },
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
    format = true,
  },
	on_attach = function(client, bufnr)
		-- Fixing handled by conform.nvim (prettier)
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
vim.lsp.config("qmlls", qmlSettings)
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
