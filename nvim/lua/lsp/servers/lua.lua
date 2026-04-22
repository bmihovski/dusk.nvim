local common = require("lsp.common")
local handlers = common.handlers

vim.lsp.config.lua = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", "init.lua" },
	capabilities = common.capabilities,
	handlers = handlers,
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			completion = {
				callSnippet = "Both",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
				-- library = vim.api.nvim_get_runtime_file("", true),
				library = {
					-- vim.env.VIMRUNTIME,
					vim.fn.stdpath("config") .. "/lua",
					"${3rd}/luv/library",
				},
			},
		},
	},
}

vim.lsp.enable("lua")
