-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = "-"
vim.g.maplocalleader = "-"
vim.cmd([[silent! runtime plugin/rplugin.vim]])

-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

--Load Vim Settings
require("settings.options")
require("settings.keymaps")
require("settings.autocommands")

-- Load and Configure plugins
require("lazy").setup({

	--------------------------------------
	-- UI --
	--------------------------------------

	{
		"folke/which-key.nvim",
		lazy = false,
		config = function()
			require("pluginconfigs.whichkey")
		end,
	},

	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			vim.opt.termguicolors = true
			require("bufferline").setup()
		end,
	},

	{
		"tris203/hawtkeys.nvim",
		cmd = { "Hawtkeys", "HawtkeysAll", "HawtkeysDupes" },
		config = true,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
	},

	{
		"gen740/SmoothCursor.nvim",
		event = { "BufRead", "BufNewFile" },
		config = function()
			local default = {
				autostart = true,
				cursor = "", -- cursor shape (need nerd font)
				intervals = 35, -- tick interval
				linehl = nil, -- highlight sub-cursor line like 'cursorline', "CursorLine" recommended
				type = "exp", -- define cursor movement calculate function, "default" or "exp" (exponential).
				fancy = {
					enable = true, -- enable fancy mode
					head = { cursor = "▷", texthl = "SmoothCursor", linehl = nil },
					body = {
						{ cursor = "", texthl = "SmoothCursorRed" },
						{ cursor = "", texthl = "SmoothCursorOrange" },
						{ cursor = "●", texthl = "SmoothCursorYellow" },
						{ cursor = "●", texthl = "SmoothCursorGreen" },
						{ cursor = "•", texthl = "SmoothCursorAqua" },
						{ cursor = ".", texthl = "SmoothCursorBlue" },
						{ cursor = ".", texthl = "SmoothCursorPurple" },
					},
					tail = { cursor = nil, texthl = "SmoothCursor" },
				},
				priority = 10, -- set marker priority
				speed = 25, -- max is 100 to stick to your current position
				texthl = "SmoothCursor", -- highlight group, default is { bg = nil, fg = "#FFD400" }
				threshold = 3,
				timeout = 3000,
				disable_float_win = true, -- disable on float window
			}
			require("smoothcursor").setup(default)
		end,
	},

	{
		"RRethy/vim-illuminate",
		event = "VeryLazy",
		config = function()
			local illuminate = require("illuminate")
			vim.g.Illuminate_ftblacklist = { "NvimTree" }

			illuminate.configure({
				providers = {
					"lsp",
					"treesitter",
					"regex",
				},
				delay = 200,
				filetypes_denylist = {
					"dirvish",
					"fugitive",
					"alpha",
					"NvimTree",
					"packer",
					"neogitstatus",
					"Trouble",
					"lir",
					"Outline",
					"spectre_panel",
					"toggleterm",
					"DressingSelect",
					"TelescopePrompt",
					"sagafinder",
					"sagacallhierarchy",
					"sagaincomingcalls",
					"sagapeekdefinition",
				},
				filetypes_allowlist = {},
				modes_denylist = {},
				modes_allowlist = {},
				providers_regex_syntax_denylist = {},
				providers_regex_syntax_allowlist = {},
				under_cursor = true,
			})
		end,
	},

	{ "kyazdani42/nvim-web-devicons", lazy = true },

	{
		-- Theme inspired by Atom
		"navarasu/onedark.nvim",
		lazy = true,
		event = "CursorHold",
	},

	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = true,
		event = "CursorHold",
	},

	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		config = function()
			vim.cmd.colorscheme("vscode")
		end,
	},

	{
		"EdenEast/nightfox.nvim",
		lazy = true,
		event = "CursorHold",
	},

	{
		"nmac427/guess-indent.nvim",
		lazy = true,
		event = { "BufReadPost", "BufAdd", "BufNewFile" },
		opts = {},
	},

	{ "ojroques/nvim-bufdel", event = "CursorHold", opts = {} },
	{
		"folke/zen-mode.nvim",
		dependencies = { "folke/twilight.nvim" },
		event = "VeryLazy",
	},

	--Dashboard
	{
		"goolord/alpha-nvim",
		config = function()
			require("pluginconfigs.dashboard")
		end,
	},

	{
		"AndreM222/copilot-lualine",
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
		config = function()
			require("lualine").setup()
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		lazy = true,
		event = { "BufReadPost", "BufAdd", "BufNewFile" },
		opts = {
			options = {
				-- icons_enabled = false,
				-- theme = 'onedark',
				component_separators = "|",
				section_separators = "",
			},

			sections = {
				lualine_b = {
					"branch",
					"diff",
					{
						"diagnostics",
						sources = { "nvim_workspace_diagnostic" },
					},
				},
			},
		},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {},
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
		},
	},

	--------------------------------------
	-- File explorer and Finder --
	--------------------------------------

	-- Nvim Tree
	{
		"nvim-tree/nvim-tree.lua",
		lazy = true,
		cmd = "NvimTreeToggle",
		-- event = "CursorHold",
		config = function()
			require("nvim-tree").setup({
				sync_root_with_cwd = true,
				respect_buf_cwd = true,
				update_focused_file = {
					enable = true,
					update_root = true,
				},
				view = {
					width = 50,
				},
			})
		end,
	},
	-- auto save
	{
		"okuuva/auto-save.nvim",
		cmd = "ASToggle", -- optional for lazy loading on command
		event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
		opts = {
			execution_message = {
				enabled = false,
			},
			debounce_delay = 5000,
		},
	},
	-- save buffers
	{
		"olimorris/persisted.nvim",
		lazy = false,
		config = function()
			require("persisted").setup({
				ignored_dirs = {
					"~/.config",
					"~/.local/nvim",
					{ "/", exact = true },
					{ "/tmp", exact = true },
				},
				autoload = true,
				on_autoload_no_session = function()
					vim.notify("No existing session to load.")
				end,
			})
		end,
	},

	--Telescope Fuzzy Finder (files, commands, etc)
	{
		"nvim-telescope/telescope.nvim",
		-- lazy = true,
		-- cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"ahmedkhalf/project.nvim",
				event = { "BufReadPost", "BufAdd", "BufNewFile" },
				config = function()
					require("project_nvim").setup()
					require("telescope").load_extension("projects")
				end,
			},
		},
	},

	{
		"smartpde/telescope-recent-files",
		event = "VeryLazy",
		dependencies = { "nvim-telescope/telescope.nvim" },
		opts = {
			handlers = {},
		},
		config = function()
			require("telescope").load_extension("recent_files")
		end,
	},

	-- Tmux
	{
		"alexghergh/nvim-tmux-navigation",
		lazy = false,
		config = function()
			require("nvim-tmux-navigation").setup({
				disable_when_zoomed = true, -- defaults to false
			})
		end,
	},

	--------------------------------------
	-- LSP & Autocompletion --
	--------------------------------------

	{
		-- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",

			-- Additional lua configuration, makes nvim stuff amazing!
			"folke/neodev.nvim",
		},
	},

	{
		"VidocqH/lsp-lens.nvim",
		event = "VeryLazy",
		config = function()
			require("lsp-lens").setup({
				enable = true,
				include_declaration = false,
			})
		end,
	},

	-- Useful status updates for LSP
	{ "j-hui/fidget.nvim", event = "LspAttach", opts = {} },

	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			-- Adds LSP completion capabilities
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",

			-- Adds a number of user-friendly snippets
			"rafamadriz/friendly-snippets",
		},
	},
	{
		"zbirenbaum/copilot-cmp",
		event = "InsertEnter",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		event = "VeryLazy",
		branch = "canary",
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		opts = {
			debug = false, -- Disable debugging
		},
		build = function()
			vim.cmd("UpdateRemotePlugins") -- You need to restart to make it works
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},

	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		lazy = true,
		config = function()
			local lsp_zero = require("lsp-zero")
			lsp_zero.extend_lspconfig()

			lsp_zero.on_attach(function(client, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions
				lsp_zero.default_keymaps({ buffer = bufnr })
			end)

			require("mason").setup({})
			require("mason-lspconfig").setup({
				-- You can add more ensure installed servers based on the aliases on this list: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
				ensure_installed = {
					"jdtls",
					"tsserver",
					"lua_ls",
					"jsonls",
					"lemminx",
					"emmet_ls",
					"gradle_ls",
					"html",
					"cssls",
					"pyright",
					"clangd",
					"helm_ls",
					"yamlls",
					"taplo",
					"ruff_lsp",
					"cmake",
				},
				handlers = {
					lsp_zero.default_setup,
					jdtls = lsp_zero.noop, -- This means don't setup jdtls with default setup, because there is special config for it.
				},
			})
		end,
	},

	{
		"jay-babu/mason-nvim-dap.nvim",
		event = "VeryLazy",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {
			handlers = {},
		},
	},

	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		opts = {
			lightbulb = {
				enable = false,
			},
			symbol_in_winbar = {
				folder_level = 6,
			},
		},
	},
	{
		"rockerBOO/symbols-outline.nvim",
		event = "VeryLazy",
		config = function(_, opts)
			require("symbols-outline").setup(opts)
		end,
	},
	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		branch = "main",
		event = "BufEnter",
		config = function()
			require("lsp_lines").setup()
		end,
	},

	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {},
		config = function(_, opts)
			require("lsp_signature").setup(opts)
		end,
	},

	--LSP Diagnostics
	{
		"folke/trouble.nvim",
		branch = "dev",
		event = "VeryLazy",
		cmd = "Trouble",
		opts = { auto_preview = false }, -- automatically preview the location of the diagnostic
	},

	-- This plugin ensures that the necessary tools get automatically installed
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({

				ensure_installed = {
					"bash-language-server",
					"google-java-format",
					"stylua",
					"shellcheck",
					"shfmt",
					"java-test",
					"java-debug-adapter",
					"clang-format",
					"codelldb",
					"cpptools",
					"sonarlint-language-server",
					"checkstyle",
					"vscode-java-decompiler",
					"checkstyle",
					"cpplint",
					"beautysh",
					"yamlfix",
					"prettierd",
					"ruff",
					"prettier",
					"debugpy", -- debugger
					"black", -- formatter
					"isort", -- organize imports
				},
				-- if set to true this will check each tool for updates. If updates
				-- are available the tool will be updated. This setting does not
				-- affect :MasonToolsUpdate or :MasonToolsInstall.
				-- Default: false
				auto_update = true,
				-- set a delay (in ms) before the installation starts. This is only
				-- effective if run_on_start is set to true.
				-- e.g.: 5000 = 5 second delay, 10000 = 10 second delay, etc...
				-- Default: 0
				start_delay = 3000, -- 3 second delay
			})
		end,
	},

	-- Java LSP
	{ "mfussenegger/nvim-jdtls", ft = "java" },

	-- DAP (Required to run Java unit tests and Debugging)--
	{ "mfussenegger/nvim-dap", ft = { "c", "cpp", "hpp", "h", "objc", "objcpp", "cuda", "proto", "java" } },
	{
		"rcarriga/nvim-dap-ui",
		event = "VeryLazy",
		ft = { "c", "cpp", "hpp", "h", "objc", "objcpp", "cuda", "proto", "cpp", "java" },
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
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
		end,
	},
	-- Obsolete plugins, might use later
	-- { "Pocco81/dap-buddy.nvim",  ft = "java" },
	{
		"theHamsta/nvim-dap-virtual-text",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter", "mfussenegger/nvim-dap" },
		opts = {
			handlers = {},
		},
	},
	{
		"simaxme/java.nvim",
		event = "VeryLazy",
		config = function()
			require("java").setup()
		end,
	},
	-- Python LSP
	{
		"mfussenegger/nvim-dap-python",
		ft = { "python" },
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
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
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
		opts = {
			-- Your options go here
			-- name = "venv",
			-- auto_refresh = false
		},
		event = "VeryLazy", -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
	},
	--------------------------------------
	-- Git --
	--------------------------------------
	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		event = "CursorHold",
		opts = {},
	},

	{
		"akinsho/git-conflict.nvim",
		event = "CursorHold",
		config = function()
			require("git-conflict").setup()
		end,
	},

	{
		"sindrets/diffview.nvim",
		lazy = true,
		cmd = { "DiffviewOpen", "DiffviewClose" },
	},

	{
		"kdheepak/lazygit.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
		event = "VeryLazy",
		cmd = "LazyGit",
		config = function()
			require("lazygit.utils").project_root_dir()
			require("telescope").load_extension("lazygit")
		end,
	},

	--------------------------------------
	-- Tools --
	--------------------------------------

	-- Syntax highliting
	{
		"nvim-treesitter/nvim-treesitter",
		event = "CursorHold",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		config = function()
			require("pluginconfigs.treesitter")
		end,
	},

	{
		"Badhi/nvim-treesitter-cpp-tools",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter" },
		config = function()
			require("nt-cpp-tools").setup({
				header_extension = "h",
				source_extension = "cpp",
			})
		end,
		cmd = { "TSCppDefineClassFunc", "TSCppMakeConcreteClass", "TSCppRuleOf3", "TSCppRuleOf5" },
	},
	{
		"https://gitlab.com/schrieveslaach/sonarlint.nvim",
		dependencies = { "mfussenegger/nvim-jdtls" },
		event = { "BufRead", "BufNewFile" },
		opts = {
			handlers = {},
		},
		config = function()
			require("sonarlint").setup({
				server = {
					cmd = {
						"sonarlint-language-server",
						-- Ensure that sonarlint-language-server uses stdio channel
						"-stdio",
						"-analyzers",
						-- paths to the analyzers you need, using those for python and java in this example
						vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarpython.jar"),
						vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarcfamily.jar"),
						vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjava.jar"),
					},
					settings = {
						sonarlint = {
							pathToCompileCommands = vim.fn.getcwd() .. "/compile_commands.json",
						},
					},
				},
				filetypes = {
					-- Tested and working
					"python",
					"cpp",
					-- Requires nvim-jdtls, otherwise an error message will be printed
					"java",
				},
			})
		end,
	},

	-- Formatting tool to define your own custom formatters, besides the default LSP formatter

	{
		"mfussenegger/nvim-lint",
		event = {
			"BufReadPre",
			"BufNewFile",
		},
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				cpp = { "cpplint" },
				kotlin = { "ktlint" },
				terraform = { "tflint" },
				python = { "ruff" },
				java = { "checkstyle" },
			}
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					cpp = { "clang-format " },
					python = function(bufnr)
						if require("conform").get_formatter_info("ruff_format", bufnr).available then
							return { "ruff_format" }
						else
							return { "isort", "black" }
						end
					end,
					javascript = { { "prettierd", "prettier" } },
					typescript = { { "prettierd", "prettier" } },
					javascriptreact = { { "prettierd", "prettier" } },
					typescriptreact = { { "prettierd", "prettier" } },
					json = { { "prettierd", "prettier" } },
					graphql = { { "prettierd", "prettier" } },
					java = { "google-java-format" },
					kotlin = { "ktlint" },
					markdown = { { "prettierd", "prettier" } },
					erb = { "htmlbeautifier" },
					html = { "htmlbeautifier" },
					bash = { "beautysh" },
					proto = { "buf" },
					yaml = { "yamlfix" },
					toml = { "taplo" },
					css = { { "prettierd", "prettier" } },
					scss = { { "prettierd", "prettier" } },
				},
				format_on_save = {
					-- These options will be passed to conform.format()
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},
	{
		"saccarosium/nvim-whitespaces",
		lazy = false,
		opts = {
			handlers = {},
		},
	},

	--Terminal
	{ "akinsho/toggleterm.nvim", version = "*", lazy = true, cmd = "ToggleTerm", opts = {} },

	-- Code Runner
	{
		"is0n/jaq-nvim",
		lazy = true,
		cmd = "Jaq",
		config = function()
			require("pluginconfigs.jaq")
		end,
	},
	{
		"Civitasv/cmake-tools.nvim",
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
	},

	--Search & replace string
	{ "nvim-pack/nvim-spectre", lazy = true, cmd = "Spectre", opts = {} },

	--Handy package with many lightweight editing tools. Choose those that fit you.
	-- Check documentation at https://github.com/echasnovski/mini.nvim
	{
		"echasnovski/mini.nvim",
		event = "CursorHold",
		config = function()
			require("mini.ai").setup()
			require("mini.align").setup()
			require("mini.pairs").setup()
			require("mini.surround").setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},
	{
		"booperlv/nvim-gomove",
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
	},
	{
		"debugloop/telescope-undo.nvim",
		dependencies = { -- note how they're inverted to above example
			{
				"nvim-telescope/telescope.nvim",
				dependencies = { "nvim-lua/plenary.nvim" },
			},
		},
		opts = {
			-- don't use `defaults = { }` here, do this in the main telescope spec
			extensions = {
				undo = {
					-- telescope-undo.nvim config, see below
				},
				-- no other extensions here, they can have their own spec too
			},
		},
		config = function(_, opts)
			-- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
			-- configs for us. We won't use data, as everything is in it's own namespace (telescope
			-- defaults, as well as each extension).
			require("telescope").setup(opts)
			require("telescope").load_extension("undo")
		end,
	},

	--Markdown
	{ "dkarter/bullets.vim", ft = "markdown" }, -- Automatic ordered lists. For reordering messed list, use :RenumberSelection cmd
	{ "jghauser/follow-md-links.nvim", ft = "markdown" }, --Follow md links with ENTER
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
}, {})

--Load the rest of the plugin configurations that need to be loaded at the end
require("pluginconfigs.jdtls")
require("pluginconfigs.cmp")
