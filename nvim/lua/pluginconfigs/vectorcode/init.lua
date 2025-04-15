return {
	"Davidyz/VectorCode",
	build = "pipx upgrade vectorcode",
	opts = function()
		return {
			async_backend = "lsp",
			notify = false,
			n_query = 10,
			timeout_ms = -1,
			async_opts = {
				events = { "BufWritePost" },
				single_job = true,
				query_cb = require("vectorcode.utils").make_lsp_document_symbol_cb(),
				debounce = -1,
				n_query = 30,
			},
			on_setup = {
				update = false, -- set to true to enable update when `setup` is called.
				lsp = false,
			},
		}
	end,
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = "VectorCode",
	cond = function()
		return vim.fn.executable("vectorcode") == 1
	end,
}
