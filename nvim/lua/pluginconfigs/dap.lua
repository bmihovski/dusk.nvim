return {

	-- DAP
	{
		"miroshQa/debugmaster.nvim",
		dependencies = {
			"mfussenegger/nvim-dap",
			"jbyuki/one-small-step-for-vimkind",
		},
		enabled = false,
		config = function()
			local dm = require("debugmaster")
			vim.keymap.set({ "n", "v" }, "<leader>.", dm.mode.toggle, {
				nowait = true,
				desc = "Debug mode toggle",
			})
			vim.keymap.set("t", "<C-/>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
			vim.defer_fn(function()
				local Sidepanel = getmetatable(require("debugmaster.state").sidepanel).__index
				Sidepanel.set_active_with_open = function(self, comp)
					if self.active == comp and self:is_open() then
						self:close()
					else
						self:set_active(comp)
						self:open()
					end
				end
			end, 50)
			dm.keys.get("u").key = "<leader>du" -- conflict with undo
			dm.keys.get("U").key = "<leader>dU"
			dm.plugins.osv_integration.enabled = true
			dm.plugins.cursor_hl.enabled = false
			dm.plugins.ui_auto_toggle.enabled = true
		end,
	},
	{
		"igorlfs/nvim-dap-view",
		dependencies = {
			"stevearc/overseer.nvim",
			{ "theHamsta/nvim-dap-virtual-text", opts = { virt_text_pos = "eol" } },
		},
		lazy = true,
		init = function()
			local dap, dv = require("dap"), require("dap-view")
			dap.listeners.before.attach["dap-view-config"] = function()
				dv.open()
			end
			dap.listeners.before.launch["dap-view-config"] = function()
				dv.open()
			end
			dap.listeners.before.event_terminated["dap-view-config"] = function()
				dv.close()
			end
			dap.listeners.before.event_exited["dap-view-config"] = function()
				dv.close()
			end

			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "dap-view", "dap-view-term" },
				callback = function(evt)
					vim.keymap.set("n", "q", "<C-w>q", { buffer = evt.buf })
					vim.keymap.set("n", "h", "g?", { buffer = evt.buf })
				end,
			})
			require("overseer").patch_dap(true)
		end,
		opts = {
			winbar = {
				-- sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
				sections = { "console", "scopes", "breakpoints", "watches" },
				controls = {
					enabled = true,
					position = "right",
					buttons = {
						"play",
						"step_into",
						"step_over",
						"step_out",
						"step_back",
						"run_last",
						"terminate",
					},
				},
				default_section = "scopes",
			},
			windows = {
				position = "right",
				height = 18,
				terminal = {
					hide = { "go" },
				},
			},
			help = { border = "single" },
			switchbuf = "uselast",
		},
	},
	{
		"julianolf/nvim-dap-lldb",
		ft = "c,cpp,hpp,h,cpp,cc",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("dap-lldb").setup({})
		end,
	},

	-- Required to configure DAP for languages other than Java
	{
		"jay-babu/mason-nvim-dap.nvim",
		event = "VeryLazy",
		dependencies = {
			"mason-org/mason.nvim",
			"mfussenegger/nvim-dap",
			"julianolf/nvim-dap-lldb",
		},
		config = function()
			require("mason-nvim-dap").setup({
				ensure_installed = {
					"chrome",
					"node2",
					"js",
					"bash",
					"python",
					"javadbg",
					"javatest",
					"cpptools",
					"codelldb",
				},
				automatic_installation = true,
				handlers = {
					function(config)
						-- all sources with no handler get passed here

						-- Keep original functionality
						require("mason-nvim-dap").default_setup(config)
					end,
					-- Debug client side Javascript/Typescript
					chrome = function(config)
						config.configurations = {
							{
								name = "Launch & Debug Chrome",
								type = "chrome",
								request = "launch",
								url = function()
									local co = coroutine.running()
									return coroutine.create(function()
										vim.ui.input({
											prompt = "Enter URL: ",
											default = "http://localhost:4200",
										}, function(url)
											if url == nil or url == "" then
												return
											else
												coroutine.resume(co, url)
											end
										end)
									end)
								end,
								webRoot = "${workspaceFolder}",
								-- skip files from vite's hmr
								skipFiles = { "**/node_modules/**/*", "**/src/*" },
								port = 9222,
								protocol = "inspector",
								sourceMaps = true,
								-- userDataDir = false,
							},
						}

						require("mason-nvim-dap").default_setup(config) -- don't forget this!
					end,

					-- Debug server side Javascript/Typescript + single files
					node2 = function(config)
						config.configurations = {
							{
								name = "Node2: Launch",
								type = "node2",
								request = "launch",
								-- program = '${file}', -- This doesn't work
								cwd = vim.fn.getcwd(),
								sourceMaps = true,
								protocol = "inspector",
								console = "integratedTerminal",
								outFiles = {
									"${workspaceFolder}/**/*.js", -- This should be optional
								},
							},
						}
						require("mason-nvim-dap").default_setup(config) -- don't forget this!
					end,
				},
				-- automatic_installation = true,
			})
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		event = "LspAttach",
		enabled = false,
		dependencies = {
			{ "mfussenegger/nvim-dap" },
			{ "nvim-neotest/nvim-nio" },
			{ "theHamsta/nvim-dap-virtual-text", opts = {} },
		},
		opts = {},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			dap.adapters.lldb = {
				type = "executable",
				command = "lldb-dap-19",
				name = "lldb",
			}
			dapui.setup()
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.attach["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.launch["dapui_config"] = function()
				dapui.open()
			end
		end,
	},

	-- Python LSP
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			-- uses the debugypy installation by mason
			local path = require("mason-registry").get_package("debugpy"):get_install_path()
			require("dap-python").setup(path .. "/venv/bin/python")
		end,
	},
	{
		"linux-cultist/venv-selector.nvim",
		ft = "python",
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
		branch = "regexp", -- This is the regexp branch, use this for the new version
		opts = {
			-- Your options go here
			-- name = "venv",
			-- auto_refresh = false
		},
	},
}
