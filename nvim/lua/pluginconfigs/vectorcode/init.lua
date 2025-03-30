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
				query_cb = require("vectorcode.utils").make_lsp_document_symbol_cb(),
				debounce = 30,
			},
			on_setup = {
				update = true, -- set to true to enable update when `setup` is called.
				lsp = true,
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
	config = function()
		local vectorcode_cacher = require("vectorcode.config").get_cacher_backend()
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			pattern = { "*.cpp", "*.hpp", "*.c", "*.h", "*.java", "*.py", "*.md" },
			callback = function(args)
				if not vectorcode_cacher.buf_is_registered(args.buf) then
					vectorcode_cacher.register_buffer(args.buf, {})
				end
			end,
		})

		vim.api.nvim_create_autocmd({ "BufDelete" }, {
			pattern = { "*.cpp", "*.hpp", "*.c", "*.h", "*.java", "*.py", "*.md" },
			callback = function(args)
				if vectorcode_cacher.buf_is_registered(args.buf) then
					vectorcode_cacher.deregister_buffer(args.buf)
				end
			end,
		})
	end,
}
