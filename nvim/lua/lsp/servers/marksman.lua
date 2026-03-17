vim.lsp.config.marksman = {
	cmd = { "marksman", "server" },
	filetypes = { "markdown.mdx", "md", "markdown" },
	root_markers = { ".git", ".marksman.toml" },
}

vim.lsp.enable("marksman")
