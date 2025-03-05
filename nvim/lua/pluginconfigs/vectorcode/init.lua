return {
	"Davidyz/VectorCode",
	version = "*",
	build = "pipx upgrade vectorcode",
	opts = function()
		return {
			async_backend = "lsp",
			notify = false,
			n_query = 10,
			timeout_ms = -1,
			async_opts = {
				events = { "BufWritePost" },
				-- query_cb = require("vectorcode.utils").make_surrounding_lines_cb(40),
				debounce = 30,
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
