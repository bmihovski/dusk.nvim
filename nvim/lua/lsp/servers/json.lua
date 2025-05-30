vim.lsp.config.json = {
	cmd = { "vscode-json-language-server", "--stdio" },
	init_options = { provideFormatter = true },
	filetypes = { "json", "jsonc" },
	settings = {
		json = {
			schemas = {
				{
					fileMatch = { "package.json" },
					url = "https://json.schemastore.org/package.json",
				},
				{
					fileMatch = { "tsconfig*.json" },
					url = "https://json.schemastore.org/tsconfig.json",
				},
				{
					fileMatch = {
						".prettierrc",
						".prettierrc.json",
						"prettier.config.json",
					},
					url = "https://json.schemastore.org/prettierrc.json",
				},
				{
					fileMatch = { ".eslintrc", ".eslintrc.json" },
					url = "https://json.schemastore.org/eslintrc.json",
				},
				{
					fileMatch = { "biome.json" },
					url = "https://biomejs.dev/schemas/1.8.3/schema.json",
				},
				{
					fileMatch = {
						".babelrc",
						".babelrc.json",
						"babel.config.json",
					},
					url = "https://json.schemastore.org/babelrc.json",
				},
				{
					fileMatch = { "lerna.json" },
					url = "https://json.schemastore.org/lerna.json",
				},
				{
					fileMatch = { "now.json", "vercel.json" },
					url = "https://json.schemastore.org/now.json",
				},
				{
					fileMatch = { "ecosystem.json" },
					url = "https://json.schemastore.org/pm2-ecosystem.json",
				},
				{
					fileMatch = { "turbo.json" }, -- turbopack
					url = "https://turbo.build/schema.json",
				},
				{
					fileMatch = { "components.json" }, -- shadcn
					url = "https://ui.shadcn.com/schema.json",
				},
			},
		},
	},
}

vim.lsp.enable("json")
