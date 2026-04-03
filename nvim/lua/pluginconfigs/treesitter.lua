local parsers = require("nvim-treesitter.parsers")
---@diagnostic disable-next-line: inject-field
parsers.bazelrc = {
	install_info = {
		url = "https://github.com/zaucy/tree-sitter-bazelrc.git",
		files = { "src/parser.c" },
		branch = "main",
	},
}
---@diagnostic disable-next-line: inject-field
parsers.cpp2 = {
	install_info = {
		url = "https://github.com/tsoj/tree-sitter-cpp2.git",
		files = { "src/parser.c", "src/scanner.c" },
		branch = "main",
	},
}
vim.api.nvim_create_autocmd("User", {
	pattern = "TSUpdate",
	callback = function()
		require("nvim-treesitter.parsers").lua.install_info.generate = true
	end,
})
-- In the new API this is done via autocmd (plugin no longer does it automatically)
local languages = {
	"c",
	"cpp",
	"python",
	"java",
	"xml",
	"yaml",
	"properties", -- application.properties
	"groovy", -- Gradle build files (build.gradle)
	"sql",
	"http",
	"graphql",
	"javascript",
	"typescript",
	"tsx",
	"html",
	"css",
	"scss",
	"styled", -- styled-components / css-in-js
	"json",
	"json5",
	"jsdoc",
	"regex",
	"toml",
	"ini",
	"editorconfig",
	"dockerfile",
	"bash",
	"diff",
	"gitcommit",
	"gitignore",
	"git_config",
	"gitattributes",
	"lua",
	"luadoc", -- LuaDoc comments
	"vim",
	"vimdoc",
	"query",
	"markdown",
	"markdown_inline",
	"latex",
	"csv",
	-- === Utilities ===
	"comment", -- TODO/FIXME/NOTE comments
	"csv", -- CSV files
}
require("nvim-treesitter").install(languages)

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter.setup", {}),
	callback = function(args)
		local buf = args.buf
		local filetype = args.match

		-- you need some mechanism to avoid running on buffers that do not
		-- correspond to a language (like oil.nvim buffers), this implementation
		-- checks if a parser exists for the current language
		local language = vim.treesitter.language.get_lang(filetype) or filetype
		if not vim.treesitter.language.add(language) then
			return
		end

		-- replicate `fold = { enable = true }`
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

		-- replicate `highlight = { enable = true }`
		vim.treesitter.start(buf, language)

		-- replicate `indent = { enable = true }`
		vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

		-- `incremental_selection = { enable = true }` covered by 0.12.0
	end,
})
