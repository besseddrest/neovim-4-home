return {
	-- language / LSP
	{ import = "plugins.lang.ts-autotag" },
	{ import = "plugins.lang.ts-comments" },
	{ import = "plugins.lang.flutter-tools" },
	{ import = "plugins.lang.conform" },
	{ import = "plugins.base.mason" },
	{ import = "plugins.base.lspconfig" },
	{ import = "nvchad.blink.lazyspec" },

	-- ui
	{ import = "plugins.ui.snacks" },
	{ import = "plugins.ui.noice" },
	{ import = "plugins.ui.todo-comments" },
	{ import = "plugins.ui.floating-help" },
	{ import = "plugins.ui.incline" },
	{ import = "plugins.ui.tiny-inline-diagnostic" },
	{ import = "plugins.ui.render-markdown" },
	{ import = "plugins.ui.gitsigns" },
	{ import = "plugins.ui.colorizer" },

	-- util
	{ import = "plugins.util.mini-files" },
	{ import = "plugins.util.harpoon2" },
	{ import = "plugins.util.trouble" },
	{ import = "plugins.util.pr" },
	{ import = "plugins.util.opencode" },
	{ import = "plugins.util.vim-dadbod" },
	{ import = "plugins.util.vim-dadbod-ui" },
}
