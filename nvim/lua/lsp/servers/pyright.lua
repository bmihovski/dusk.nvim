vim.lsp.config.pyright = {
	filetypes = { "python" },
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "strict",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				logLevel = "Error",
			},
		},
	},
}

vim.lsp.enable("pyright")
