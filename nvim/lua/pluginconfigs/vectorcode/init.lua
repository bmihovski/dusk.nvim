return {
	"Davidyz/VectorCode",
	-- dir = "~/git/VectorCode/",
	version = "*",
	build = "/home/linuxbrew/.linuxbrew/bin/pipx upgrade vectorcode",
	opts = {
		notify = true,
		n_query = 10,
		timeout_ms = -1,
		debounce = 15,
		async_opts = { events = { "BufWritePost" }, single_job = true },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = "VectorCode",
	cond = function()
		return vim.fn.executable("vectorcode") == 1
	end,
}
