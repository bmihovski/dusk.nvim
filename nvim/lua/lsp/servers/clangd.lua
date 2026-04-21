local function switch_source_header(bufnr, client)
	local method_name = "textDocument/switchSourceHeader"
	---@diagnostic disable-next-line:param-type-mismatch
	if not client or not client:supports_method(method_name) then
		return vim.notify(
			("method %s is not supported by any servers active on the current buffer"):format(method_name)
		)
	end
	local params = vim.lsp.util.make_text_document_params(bufnr)
	---@diagnostic disable-next-line:param-type-mismatch
	client:request(method_name, params, function(err, result)
		if err then
			error(tostring(err))
		end
		if not result then
			vim.notify("corresponding file cannot be determined")
			return
		end
		vim.cmd.edit(vim.uri_to_fname(result))
	end, bufnr)
end
vim.lsp.config.clangd = {
	cmd = {
		"clangd",
		"--completion-style=detailed",
		"--background-index=false",
		"--clang-tidy",
		"--query-driver=/usr/bin/g++",
		"--fallback-style=llvm",
		"--header-insertion=iwyu",
	},
	filetypes = {
		"c",
		"cc",
		"cpp",
		"h",
		"hpp",
		"ixx",
		"cppm",
		"inl",
		"objc",
		"objcpp",
		"cuda",
		"proto",
	},
	root_markers = {
		".clang-format",
		".git",
		"compile_commands.json",
		"CMakeLists.txt",
		".clangd",
		".clang-tidy",
		"compile_flags.txt",
	},
	capabilities = {
		textDocument = {
			completion = {
				editsNearCursor = true,
			},
		},
		offsetEncoding = { "utf-8", "utf-16" },
	},
	on_init = function(client, init_result)
		if init_result.offsetEncoding then
			client.offset_encoding = init_result.offsetEncoding
		end
	end,
	on_attach = function(client, bufnr)
		client.server_capabilities.semanticTokensProvider = nil

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
			switch_source_header(bufnr, client)
		end, { desc = "Switch between source/header" })
	end,
}

vim.lsp.enable("clangd")
