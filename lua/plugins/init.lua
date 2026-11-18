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

-- `{ import = "plugins" }` in init.lua only picks up this file and
-- overrides.lua -- lazy does not recurse into subdirectories without an
-- init.lua. So a spec under lang/ ui/ util/ base/ is only live if it is
-- listed above. These exist but are deliberately parked, not installed:
--
--   base/telescope.lua    overrides for the telescope NvChad already ships
--   util/which-key.lua    ditto for which-key
--   util/avante.lua       overlaps opencode
--   util/cd-project.lua
--   util/diffview.lua
--   util/neogit.lua       overlaps the Snacks lazygit maps
--   util/refactoring.lua
--   ui/smear-cursor.lua
--   ui/indent-blankline.lua  also disabled in overrides.lua; snacks.indent
--                            draws the guides instead

