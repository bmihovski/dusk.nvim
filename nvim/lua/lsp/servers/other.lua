local servers = {
	bash = {
		filetypes = { "sh", "bash" },
		cmd = { "bash-language-server", "start" },
	},
	emmet = {
		filetypes = { "html", "typescriptreact", "javascriptreact", "svelte" },
		cmd = { "emmet-language-server", "--stdio" },
	},
	go = {
		filetypes = { "go" },
		cmd = { "gopls" },
		sqlls = {
	},
		filetypes = { "sql", "mysql" },
		cmd = { "sql-language-server", "up", "--method", "stdio" },
	},
}

for server, opts in pairs(servers) do
	vim.lsp.config[server] = {
		cmd = opts.cmd,
		filetypes = opts.filetypes,
	}
	vim.lsp.enable(server)
end
