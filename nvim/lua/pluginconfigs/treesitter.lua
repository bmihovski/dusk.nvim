local parsers = require("nvim-treesitter.parsers").get_parser_configs()
---@diagnostic disable-next-line: inject-field
parsers.bazelrc = {
	install_info = {
		url = "https://github.com/zaucy/tree-sitter-bazelrc.git",
		files = { "src/parser.c" },
		branch = "main",
		requires_generate_from_grammar = false,
	},
}
---@diagnostic disable-next-line: inject-field
parsers.cpp2 = {
	install_info = {
		url = "https://github.com/tsoj/tree-sitter-cpp2.git",
		files = { "src/parser.c", "src/scanner.c" },
		branch = "main",
		generate_requires_npm = false,
		requires_generate_from_grammar = false,
	},
}
require("nvim-treesitter.install").prefer_git = true
require("nvim-treesitter.configs").setup({
	-- Add languages to be installed here that you want installed for treesitter

	-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
	auto_install = true,
	-- Install languages synchronously (only applied to `ensure_installed`)
	sync_install = false,
	-- List of parsers to ignore installing
	ignore_install = {},
	-- You can specify additional Treesitter modules here: -- For example: -- playground = {--enable = true,-- },
	modules = {},
	highlight = {
		enable = true,
		-- disable = { "markdown" }, -- list of language that highlighting will be disabled
		additional_vim_regex_highlighting = true,
		use_languagetree = true,
	},
	indent = { enable = true },
	autopairs = { enable = true },
	matchup = { enable = true },
	textobjects = {
		select = {
			enable = true,
			lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["al"] = "@loop.outer",
				["il"] = "@loop.inner",
				["ai"] = "@conditional.outer",
				["ii"] = "@conditional.inner",
				["a/"] = "@comment.outer",
				["i/"] = "@comment.inner",
				["as"] = "@statement.outer",
				["is"] = "@scopename.inner",
				["aA"] = "@attribute.outer",
				["iA"] = "@attribute.inner",
			},
		},
	},
})
