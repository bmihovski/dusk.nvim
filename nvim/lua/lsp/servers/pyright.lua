vim.lsp.config.pyright = {
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
