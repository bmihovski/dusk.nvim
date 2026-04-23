local bin_name = "gradle-language-server"
if vim.fn.has("win32") == 1 then
	bin_name = bin_name .. ".bat"
end

---@type vim.lsp.Config
vim.lsp.config.gradle = {
	filetypes = { "groovy" },
	root_markers = {
		"settings.gradle", -- Gradle (multi-project)
		"build.gradle", -- Gradle
	},
	cmd = { bin_name },
	-- gradle-language-server expects init_options.settings to be defined
	init_options = {
		settings = {
			gradleWrapperEnabled = true,
		},
	},
}

vim.lsp.enable("gradle")
