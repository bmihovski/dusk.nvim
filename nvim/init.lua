-- disable netrw at the very start of the init.lua
-- Check https://github.com/nvim-tree/nvim-tree.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--- Set <space> as the leader key
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.keymap.set({ "n", "v" }, "-", "<Nop>", { silent = true })
vim.g.mapleader = "-"
vim.g.maplocalleader = "-"
local ft = {
	dap = { cppdbg = { "c", "cpp" } },
	doc = { "markdown", "asciidoc" },
	fmt = { sh = { "shfmt" } },
	lsp = { "c", "cpp", "lua", "python", "sh", "java", "hpp", "h" },
	sonar = {
		"java",
		"python",
		"c",
		"cpp",
		"hpp",
		"h",
		"typescript",
		"typescriptreact",
		"html",
		"text",
		"yaml",
		"yml",
		"toml",
		"xml",
	},
	ts = { "c", "cpp", "jsonc", "lua", "python", "java" },
}
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
require("utils.globals")

-- Load and Configure plugins
require("lazy").setup({
	concurrency = 50,
	rocks = {
		enabled = false,
		server = "https://lumen-oss.github.io/rocks-binaries/",
		hererocks = false,
	},
	spec = {

		--------------------------------------
		-- Optional Features --
		--------------------------------------

		-- Take a look at this file to see what features you need enabled
		{ import = "optional.optionalfeatures" },
		--------------------------------------
		-- UI --
		--------------------------------------

		-- Essential lua functions
		{ "nvim-lua/plenary.nvim", lazy = true },
		-- Functions for buffer management
		{
			-- shows yank history on telescope
			"gbprod/yanky.nvim",
			lazy = false,
			dependencies = { "kkharji/sqlite.lua" },
			config = function()
				local utils = require("yanky.utils")
				local mapping = require("yanky.telescope.mapping")

				require("yanky").setup({
					picker = {
						select = {
							action = nil, -- nil to use default put action
						},
						telescope = {
							use_default_mappings = false,
							mappings = {
								default = mapping.put("p"),
								i = {
									["<c-p>"] = mapping.put("p"),
									-- ["<c-k>"] = mapping.put("P"),
									["<c-x>"] = mapping.delete(),
									["<c-r>"] = mapping.set_register(utils.get_default_register()),
								},
								n = {
									p = mapping.put("p"),
									-- P = mapping.put("P"),
									d = mapping.delete(),
									r = mapping.set_register(utils.get_default_register()),
								},
							},
						},
					},
					highlight = {
						on_put = false,
						on_yank = false,
						timer = 1,
					},
				})

				vim.keymap.set("n", "<leader>p", "<cmd>Telescope yank_history<CR>")
			end,
		},
		{ "ojroques/nvim-bufdel", cmd = { "BufDel", "BufDelOthers" } },
		{ "nvim-tree/nvim-web-devicons", lazy = true },
		{ "echasnovski/mini.icons", version = false, lazy = true },
		{
			"stevearc/overseer.nvim",
			dependencies = { "stevearc/dressing.nvim" },
			opts = {},
			lazy = false,
			config = function()
				require("overseer").setup({
					templates = {
						"builtin",
						"vscode",
						"bazel",
					},
				})
			end,
		},
		{
			"stevearc/dressing.nvim",
			config = function()
				require("dressing").setup({
					input = { enabled = false },
				})
			end,
		},

		-- Shows available keys
		{
			"folke/which-key.nvim",
			event = "VeryLazy",
			config = function()
				require("pluginconfigs.whichkey")
			end,
		},

		--Dashboard
		{
			"goolord/alpha-nvim",
			config = function()
				require("pluginconfigs.dashboard")
			end,
		},
		{
			"folke/noice.nvim",
			event = "VeryLazy",
			enabled = true,
			opts = {},
			dependencies = {
				"MunifTanjim/nui.nvim",
				-- "rcarriga/nvim-notify",
			},
			config = function()
				require("pluginconfigs.noice")
			end,
		},

		-- Status Line
		{
			"nvim-lualine/lualine.nvim",
			dependencies = { "echasnovski/mini.icons", "catppuccin/nvim" },
			lazy = false,
			event = { "BufReadPost", "BufAdd", "BufNewFile" },
			config = function()
				require("lualine").setup({
					options = {
						component_separators = "|",
						section_separators = "",
						theme = "catppuccin",
					},
					extensions = { "aerial", "toggleterm", "quickfix" },

					sections = {
						lualine_b = {
							"branch",
						},
						lualine_x = {},
						lualine_y = {},
						lualine_z = { "location" },
					},
				})
			end,
		},

		-- Breadcrumbs
		{
			"LunarVim/breadcrumbs.nvim",
			event = "LspAttach",
			dependencies = {
				{
					"SmiteshP/nvim-navic",
					config = function()
						require("nvim-navic").setup({
							highlight = true,
							lsp = {
								auto_attach = true,
							},
						})
					end,
				},
			},
			config = function()
				require("breadcrumbs").setup()
			end,
		},

		--------------------------------------
		-- Colorschemes --
		--------------------------------------
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
			"xzbdmw/colorful-menu.nvim",
			opts = { max_width = 0.3 },
		},
		{
			"cormacrelf/dark-notify",
			dependencies = {
				"catppuccin/nvim",
			},

			config = function()
				require("dark_notify").run()
			end,
		},
		{
			"ibhagwan/fzf-lua",
			dependencies = { "echasnovski/mini.icons" },
			cmd = { "FzfLua" },
			opts = function(_, opts)
				return vim.tbl_deep_extend("force", opts or {}, {
					winopts = {
						border = "solid",
						width = 0.90,
						preview = {
							border = "solid",
							default = "bat",
							horizontal = "right:55%",
							vertical = "down:45%",
						},
					},
					files = { formatter = "path.dirname_first" },
					lsp = { code_actions = { previewer = "codeaction_native" } },
				})
			end,
			config = function(_, opts)
				require("fzf-lua").setup(opts)
				vim.api.nvim_set_hl(0, "FzfLuaBorder", { link = "FzfLuaNormal" })
				vim.api.nvim_set_hl(0, "FzfLuaTitle", { link = "FzfLuaBufName" })
				require("fzf-lua").register_ui_select(function(_, items)
					local min_h, max_h = 0.15, 0.70
					local h = (#items + 4) / vim.o.lines
					if h < min_h then
						h = min_h
					elseif h > max_h then
						h = max_h
					end
					return { winopts = { height = h, width = 0.60, row = 0.40 } }
				end)
			end,
		},
		{
			"catppuccin/nvim",
			name = "catppuccin",
			priority = 1000,
			config = function(_, opts)
				require("catppuccin").setup(opts)
				vim.cmd.colorscheme("catppuccin")
				vim.api.nvim_set_hl(0, "CursorColumn", { link = "CursorLine" })
				local status_ok, dark_notify = pcall(require, "dark_notify")
				if status_ok then
					dark_notify.run()
				end
				-- Options are automatically loaded before lazy.nvim startup
				-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
				-- Add any additional options here
				-- Execute the shell command and capture its output
				function GetTheme()
					local theme = vim.fn.system("getTheme")
					theme = string.gsub(theme, "\n", "")
					if theme ~= "dark" and theme ~= "light" then
						theme = "dark"
					end
					return theme
				end

				function SetTheme()
					vim.go.background = GetTheme()
				end
				-- Strip trailing newline characters from the output
				-- Set theme from the shell command output if not on mac
				SetTheme()
				vim.api.nvim_create_user_command("SetTheme", SetTheme, {})

				vim.api.nvim_set_hl(0, "DiffText", { fg = "#ffffff", bg = "#7d3b40" })
				vim.api.nvim_set_hl(0, "DiffAdd", { fg = "#ffffff", bg = "#1d3450" })

				function GetColorScheme()
					local theme = GetTheme()
					if theme == "dark" then
						return require("catppuccin.palettes").get_palette("mocha")
					else
						return require("catppuccin.palettes").get_palette("latte")
					end
				end
				local function blend_colors(fg, bg, alpha)
					local function hex_to_rgb(hex)
						return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
					end

					local function rgb_to_hex(r, g, b)
						return string.format("#%02x%02x%02x", r, g, b)
					end

					local fg_r, fg_g, fg_b = hex_to_rgb(fg)
					local bg_r, bg_g, bg_b = hex_to_rgb(bg)

					local blended_r = math.floor(bg_r + (fg_r - bg_r) * alpha)
					local blended_g = math.floor(bg_g + (fg_g - bg_g) * alpha)
					local blended_b = math.floor(bg_b + (fg_b - bg_b) * alpha)

					return rgb_to_hex(blended_r, blended_g, blended_b)
				end
				local scheme = GetColorScheme()
				local base = scheme.base
				-- https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md#diff--merge
				vim.api.nvim_set_hl(0, "AvanteConflictIncoming", {
					bg = blend_colors(scheme.green, scheme.base, 0.15),
					bold = true,
				})

				vim.api.nvim_set_hl(0, "AvanteConflictCurrent", {
					bg = blend_colors(scheme.red, scheme.base, 0.15),
					bold = true,
				})

				vim.api.nvim_set_hl(0, "AvanteConflictCurrentLabel", {
					fg = scheme.blue, -- Blue
					bold = true,
				})

				vim.api.nvim_set_hl(0, "AvanteConflictIncomingLabel", {
					fg = scheme.peach, -- Peach
					bold = true,
				})
			end,
			lazy = false,
			opts = function()
				local flavour = "mocha"
				return {
					flavour = flavour,
					term_colors = true,
					custom_highlights = function(colors)
						return {
							TelescopeNormal = {
								bg = colors.mantle,
								fg = colors.text,
							},
							TelescopeBorder = {
								bg = colors.mantle,
								fg = colors.mantle,
							},
							TelescopePromptNormal = {
								bg = colors.crust,
								fg = colors.lavender,
							},
							TelescopePromptBorder = {
								bg = colors.crust,
								fg = colors.crust,
							},
							TelescopePromptTitle = {
								bg = colors.crust,
								fg = colors.crust,
							},
							TelescopePreviewTitle = {
								bg = colors.mantle,
								fg = colors.mantle,
							},
							TelescopeResultsTitle = {
								bg = colors.mantle,
								fg = colors.mantle,
							},
							FloatBorder = { fg = colors.mantle, bg = colors.mantle },
							FloatTitle = { fg = colors.lavender, bg = colors.mantle },
							LspInfoBorder = { fg = colors.mantle, bg = colors.mantle },
							WinSeparator = { bg = colors.base, fg = colors.lavender },
							CmpBorder = { fg = colors.surface2 },
							Pmenu = { bg = colors.none },
							NeoTreeIndentMarker = { fg = colors.flamingo },
							NeoTreeExpander = { fg = colors.flamingo },
							NeoTreeNormal = { fg = colors.text, bg = colors.base },
							NeoTreeNormalNC = { fg = colors.text, bg = colors.base },
						}
					end,
					dim_inactive = { enabled = false },
					integrations = {
						avante = { enabled = true },
						cmp = true,
						dadbod_ui = true,
						dap = true,
						dap_ui = true,
						diffview = true,
						illuminate = {
							enabled = true,
							lsp = false,
						},
						fidget = true,
						lsp_saga = true,
						lsp_trouble = true,
						mason = true,
						mini = { enabled = true },
						native_lsp = {
							enabled = true,
							virtual_text = {
								errors = { "italic" },
								hints = { "italic" },
								warnings = { "italic" },
								information = { "italic" },
								ok = { "italic" },
							},
							underlines = {
								errors = { "underline" },
								hints = { "underline" },
								warnings = { "underline" },
								information = { "underline" },
								ok = { "underline" },
							},
							inlay_hints = {
								background = true,
							},
						},
						navic = { enabled = true },
						noice = true,
						notify = true,
						nvim_surround = true,
						nvimtree = true,
						rainbow_delimiters = true,
						telescope = { enabled = true },
						treesitter = true,
						render_markdown = true,
						which_key = true,
						fzf = true,
						gitsigns = true,
						overseer = true,
						aerial = true,
						alpha = true,
					},
				}
			end,
		},

		--------------------------------------
		-- File explorer and Finder --
		--------------------------------------

		-- Nvim Tree
		{
			"nvim-tree/nvim-tree.lua",
			dependencies = {
				-- Rename packages and imports also when renaming/moving files via nvim-tree.
				-- Currently works only for tsserver (used in Angular development)
				{
					"antosha417/nvim-lsp-file-operations",
					config = function()
						require("lsp-file-operations").setup()
					end,
				},
			},
			config = function()
				require("nvim-tree").setup({
					sync_root_with_cwd = true,
					respect_buf_cwd = true,
					git = {
						enable = false,
					},
					update_focused_file = {
						enable = true,
						update_root = false,
					},
					view = {
						width = 50,
					},
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
				"jvgrootveld/telescope-zoxide",
				{
					"ahmedkhalf/project.nvim",
					config = function()
						require("project_nvim").setup({
							-- Methods of detecting the root directory. **"lsp"** uses the native neovim
							-- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
							-- order matters: if one is not detected, the other is used as fallback. You
							-- can also delete or rearangne the detection methods.
							-- detection_methods = { "pattern", "lsp" },

							-- All the patterns used to detect root dir, when **"pattern"** is in
							-- detection_methods
							-- patterns = { ".git" },
						})
						require("telescope").load_extension("projects")
					end,
				},
			},
			config = function()
				require("telescope").setup({
					defaults = {
						path_display = { "filename_first" },
						file_ignore_patterns = { "%.jpg", "%.jpeg", "%.png", "%.otf", "%.ttf" },
						prompt_prefix = "   ",
						selection_caret = "  ",
						entry_prefix = "  ",
						layout_strategy = "flex",
						layout_config = {
							horizontal = {
								preview_width = 0.6,
							},
						},
					},
					pickers = {
						find_files = {
							theme = "dropdown",
							previewer = false,
						},
						oldfiles = {
							theme = "dropdown",
							previewer = false,
						},
						live_grep = {
							theme = "ivy",
						},
						buffers = {
							theme = "dropdown",
							previewer = false,
						},
						recent_files = {
							theme = "dropdown",
							previewer = false,
						},
					},
					extensions = { zoxide = {} },
				})
				require("telescope").load_extension("zoxide")
			end,
		},

		-- Search in file history
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

		--------------------------------------
		-- LSP & Autocompletion --
		--------------------------------------
		{ "folke/lazydev.nvim", ft = "lua" },
		{
			"stevearc/aerial.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require("aerial").setup({
					backends = { "treesitter", "lsp" },
				})
				local lualine_require = require("lualine_require")
				local modules = lualine_require.lazy_require({ config_module = "lualine.config" })
				local current_config = modules.config_module.get_config()
				current_config.sections.lualine_c = { "aerial" }
				require("lualine").setup(current_config)
			end,
		},
		{
			"mason-org/mason.nvim",
			lazy = false,
			config = function()
				require("mason").setup({
					registries = {
						"github:bmihovski/mason-registry",
						"github:mason-org/mason-registry",
					},
				})
			end,
		},
		{
			-- LSP Configuration & Plugins
			"neovim/nvim-lspconfig",
			lazy = true,
			dependencies = {
				-- Automatically install LSPs to stdpath for neovim
				"mason-org/mason-lspconfig.nvim",

				-- Additional lua configuration, makes nvim stuff amazing!
				{ "folke/neodev.nvim", opts = {} },
				setup = function()
					require("mason-lspconfig").setup({
						automatic_installation = true,
						handlers = {
							function(server_name)
								require("lspconfig")[server_name].setup({})
							end,

							-- Disable jdtls setup, is handled by nvim-jdtls
							["jdtls"] = function() end,
						},
					})
				end,
			},
		},

		-- Autocompletion
		{
			"hrsh7th/nvim-cmp",
			lazy = false,
			event = { "InsertEnter", "CmdLineEnter" },
			dependencies = {
				-- Snippet Engine & its associated nvim-cmp source
				"L3MON4D3/LuaSnip",
				"saadparwaiz1/cmp_luasnip",

				-- Adds LSP completion capabilities
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-cmdline",
				"hrsh7th/cmp-calc",
				"hrsh7th/cmp-emoji",
				"chrisgrieser/cmp_yanky",
				"amarakon/nvim-cmp-buffer-lines",
				{ "https://git.sr.ht/~p00f/clangd_extensions.nvim", config = true },
				"zaucy/cmp-bazel.nvim",
				"onsails/lspkind.nvim",
				"hrsh7th/cmp-nvim-lsp-signature-help",
				"lukas-reineke/cmp-under-comparator",
				"petertriho/cmp-git",
				"rcarriga/cmp-dap",

				-- Adds a number of user-friendly snippets
				"rafamadriz/friendly-snippets",
			},
			config = function()
				require("pluginconfigs.cmp")
			end,
		},

		-- Improves LSP UI
		{
			"nvimdev/lspsaga.nvim",
			event = "LspAttach",
			dependencies = {
				"nvim-treesitter/nvim-treesitter", -- optional
				"nvim-tree/nvim-web-devicons", -- optional
				"catppuccin/nvim",
			},
			opts = {
				lightbulb = {
					enable = false,
				},
				symbol_in_winbar = {
					enable = false,
					folder_level = 6,
				},
				outline = {
					auto_preview = false,
					win_width = 50,
				},
			},
			config = function()
				require("lspsaga").setup({
					ui = {
						kind = require("catppuccin.groups.integrations.lsp_saga").custom_kind(),
					},
				})
			end,
		},

		-- Shows signature as you type
		{
			"ray-x/lsp_signature.nvim",
			event = "VeryLazy",
			opts = {
				hint_enable = false,
				cursorhold_update = false, -- Fixes errors from some LSP servers (ex. angularls)
				zindex = 45, -- avoid overlap with nvim.cmp
			},
			config = function(_, opts)
				require("lsp_signature").setup(opts)
			end,
		},

		--LSP Diagnostics
		{
			"folke/trouble.nvim",
			lazy = true,
			cmd = "Trouble",
			opts = { auto_preview = false, focus = true }, -- automatically preview the location of the diagnostic
		},

		-- This plugin ensures that the necessary dependencies for Dusk.nvim get automatically installed
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			config = function()
				require("mason-tool-installer").setup({

					-- You can add more ensure installed servers based on the aliases on this list: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
					ensure_installed = {
						"jdtls",
						"ts_ls",
						"lua_ls",
						"jsonls",
						"lemminx",
						"marksman",
						"emmet_ls",
						"gradle_ls",
						"html",
						"cssls",
						"bashls",
						"angularls",
						"quick_lint_js",
						"pyright",
						"clangd",
						"helm_ls",
						"yamlls",
						"taplo",
						"cmake",
						"cucumber_language_server",
						"bash-language-server",
						"google-java-format",
						"stylua",
						"shellcheck",
						"shfmt",
						"java-test",
						"java-debug-adapter",
						"markdown-toc",
						"sonarlint-language-server",
						"vscode-java-decompiler",
						"clang-format",
						"codelldb",
						"cpptools",
						"checkstyle",
						"cpplint",
						"beautysh",
						"prettierd",
						"ruff",
						"prettier",
						"buf",
						"ktlint",
						"debugpy", -- debugger
						"black", -- formatter
						"isort", -- organize imports
						"ansible-language-server",
						"ansible-lint",
						"jq",
						"yamlfmt",
						"omnisharp",
						"vscode-spring-boot-tools",
						"json-lsp",
						"vscode-spring-boot-tools",
						"lombok-nightly", -- still not available with mason
						"kotlin-language-server",
						"lua-language-server",
						"emmet-language-server",
						"gopls",
						"prisma-language-server",
						"rust-analyzer",
						"tailwindcss-language-server",
						"biome",
						"vectorcode",
						"htmlbeautifier",
						"tree-sitter-cli",
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
					integrations = {
						["mason-lspconfig"] = true,
						["mason-null-ls"] = false,
						["mason-nvim-dap"] = true,
					},
				})
			end,
		},
		{
			"zapling/mason-lock.nvim",
			init = function()
				require("mason-lock").setup({
					lockfile_path = vim.fn.stdpath("config") .. "/mason-lock.json", -- (default)
				})
			end,
		},
		{
			"danymat/neogen",
			dependencies = { "nvim-treesitter/nvim-treesitter" },
			opts = { snippet_engine = "luasnip" },
			ft = ft.lsp,
			cmd = { "Neogen" },
		},

		-- The Java LSP server
		{
			"mfussenegger/nvim-jdtls",
			dependencies = { "mason-org/mason.nvim", "JavaHello/spring-boot.nvim", "mfussenegger/nvim-dap" },
			ft = "java",
		},

		-- Java Spring addons
		{
			"elmcgill/springboot-nvim",
			lazy = true,
			dependencies = {
				"neovim/nvim-lspconfig",
				"mfussenegger/nvim-jdtls",
			},
			config = function()
				-- gain acces to the springboot nvim plugin and its functions
				local springboot_nvim = require("springboot-nvim")

				-- set a vim motion to <Space> + <Shift>J + r to run the spring boot project in a vim terminal
				vim.keymap.set("n", "<leader>Jr", springboot_nvim.boot_run, { desc = "[J]ava [R]un Spring Boot" })
				-- set a vim motion to <Space> + <Shift>J + c to open the generate class ui to create a class
				vim.keymap.set("n", "<leader>Jc", springboot_nvim.generate_class, { desc = "[J]ava Create [C]lass" })
				-- set a vim motion to <Space> + <Shift>J + i to open the generate interface ui to create an interface
				vim.keymap.set(
					"n",
					"<leader>Ji",
					springboot_nvim.generate_interface,
					{ desc = "[J]ava Create [I]nterface" }
				)
				-- set a vim motion to <Space> + <Shift>J + e to open the generate enum ui to create an enum
				vim.keymap.set("n", "<leader>Je", springboot_nvim.generate_enum, { desc = "[J]ava Create [E]num" })

				-- run the setup function with default configuration
				springboot_nvim.setup()
			end,
		},
		{
			"niT-Tin/springboot-start.nvim",
			lazy = true,
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-telescope/telescope.nvim",
				"MunifTanjim/nui.nvim",
			},
			config = function()
				require("springboot-start").setup({
					-- your configuration comes here
					-- or leave it empty to use the default settings
					-- refer to the configuration section below
				})
			end,
		},

		{
			"JavaHello/spring-boot.nvim",
			ft = { "java", "yaml", "jproperties" },
			dependencies = {
				"mfussenegger/nvim-jdtls", -- or nvim-java, nvim-lspconfig
				"neovim/nvim-lspconfig",
				"ibhagwan/fzf-lua", -- optional
			},
		},

		-- Rename packages and imports also when renaming/moving files via nvim-tree (for Java)
		{
			"simaxme/java.nvim",
			ft = "java",
			dependencies = { "mfussenegger/nvim-jdtls" },
			config = function()
				require("simaxme-java").setup()
			end,
		},

		-- Sonarlint plugin
		{
			"https://gitlab.com/schrieveslaach/sonarlint.nvim",
			ft = ft.sonar,
			enabled = true,
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
							vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjs.jar"),
							vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarhtml.jar"),
							vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarxml.jar"),
							vim.fn.expand("$MASON/share/sonarlint-analyzers/sonartext.jar.jar"),
							vim.fn.expand("$MASON/share/sonarlint-analyzers/sonariac.jar"),
							vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjavasymbolicexecution.jar"),
						},
						flags = {
							debounce_text_changes = 1000,
						},
						settings = {
							sonarlint = {
								pathToCompileCommands = vim.fn.getcwd() .. "/compile_commands.json",
							},
						},
					},
					filetypes = ft.sonar,
				})
			end,
		},

		--------------------------------------
		-- DAP - Debuggers  --
		--------------------------------------

		-- You can configure the DAP for your language there
		{ import = "pluginconfigs.dap" },

		--------------------------------------
		-- Linters and Formatters --
		--------------------------------------

		-- Custom Formatters
		{
			"stevearc/conform.nvim",
			lazy = true,
			event = "LspAttach",
			config = function()
				require("conform").setup({
					formatters_by_ft = {
						lua = { "stylua" },
						c = { "clang-format" },
						cpp = { "clang-format" },
						objc = { "clang-format" },
						objcpp = { "clang-format" },
						cuda = { "clang-format" },
						python = function(bufnr)
							if require("conform").get_formatter_info("ruff_format", bufnr).available then
								return { "ruff_format" }
							else
								return { "isort", "black" }
							end
						end,
						javascript = { "prettierd", "prettier" },
						typescript = { "prettierd", "prettier" },
						javascriptreact = { "prettierd", "prettier" },
						typescriptreact = { "prettierd", "prettier" },
						-- json = { "jq" },
						graphql = { "prettierd", "prettier" },
						java = { "google-java-format" },
						kotlin = { "ktlint" },
						markdown = { "prettierd", "prettier" },
						erb = { "htmlbeautifier" },
						html = { "htmlbeautifier" },
						bash = { "beautysh" },
						proto = { "buf" },
						-- yaml = { "yamlfmt" },
						toml = { "taplo" },
						css = { "prettierd", "prettier" },
						scss = { "prettierd", "prettier" },
					},
					format_on_save = {
						-- These options will be passed to conform.format()
						timeout_ms = 500,
						lsp_fallback = true,
					},
				})
			end,
		},

		--------------------------------------
		-- Git --
		--------------------------------------
		{
			-- Adds git related signs to the gutter, as well as utilities for managing changes
			"lewis6991/gitsigns.nvim",
			event = "CursorHold",
			opts = {
				current_line_blame = true,
				current_line_blame_opts = { delay = 1200, virtual_text_pos = "eol" },
			},
		},

		{
			"akinsho/git-conflict.nvim",
			event = "CursorHold",
			config = function()
				require("git-conflict").setup({
					default_mappings = true, -- disable buffer local mapping created by this plugin
					default_commands = true, -- disable commands created by this plugin
					disable_diagnostics = true, -- This will disable the diagnostics in a buffer whilst it is conflicted
					list_opener = "copen", -- command or function to open the conflicts list
					highlights = { -- They must have background color, otherwise the default color will be used
						incoming = "AvanteConflictIncoming",
						current = "AvanteConflictCurrent",
					},
				})
				-- vim.keymap.set('n', '<leader>gc', ':GitConflictRefresh<CR>', {noremap = true, silent = true})
				-- vim.keymap.set('n', '<leader>gq', ':GitConflictQf<CR>', {noremap = true, silent = true})

				vim.api.nvim_create_autocmd("User", {
					pattern = "GitConflictDetected",
					callback = function()
						vim.notify("Conflict detected in file " .. vim.api.nvim_buf_get_name(0))
						vim.cmd("LspStop")
					end,
				})

				vim.api.nvim_create_autocmd("User", {
					pattern = "GitConflictResolved",
					callback = function()
						vim.cmd("LspRestart")
					end,
				})
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
			opts = {
				handlers = {},
			},
			config = function()
				require("lazygit.utils").project_root_dir()
				require("telescope").load_extension("lazygit")
			end,
		},

		--------------------------------------
		-- Editing Tools --
		--------------------------------------

		-- Syntax highliting
		{
			"nvim-treesitter/nvim-treesitter",
			event = "CursorHold",
			branch = "master",
			lazy = false,
			dependencies = {
				"nvim-treesitter/nvim-treesitter-textobjects",
				"JoosepAlviste/nvim-ts-context-commentstring",
				"andymass/vim-matchup",
			},
			build = ":TSUpdate",
			config = function()
				require("pluginconfigs.treesitter")
			end,
		},
		{
			"nvim-treesitter/nvim-treesitter-context",
			event = "VeryLazy",
			opts = {},
			dependencies = {
				"nvim-treesitter/nvim-treesitter",
			},
		},
		{
			"andymass/vim-matchup",
			event = { "BufReadPost", "BufNewFile" },
			init = function()
				vim.g.matchup_matchparen_offscreen = { method = "popup", fullwidth = 1, highlight = "Comment" }
				vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
					callback = function()
						vim.api.nvim_set_hl(0, "MatchWord", { bold = true, italic = true })
						vim.api.nvim_set_hl(0, "MatchupVirtualText", {
							bold = true,
							italic = true,
							fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg,
						})
					end,
				})
			end,
		},

		-- Move blocks
		{
			"booperlv/nvim-gomove",
			event = "VeryLazy",
			opts = {
				handlers = {},
			},
		},

		-- Code documentation
		{
			"folke/todo-comments.nvim",
			event = "InsertEnter",
			dependencies = { "nvim-lua/plenary.nvim" },
			opts = {},
		},

		-- Distraction free mode
		{
			"folke/zen-mode.nvim",
			event = "VeryLazy",
			dependencies = { "folke/twilight.nvim" },
			config = function()
				require("zen-mode").setup({
					plugins = {
						tmux = { enabled = true },
						gitsigns = { enabled = true },
						todo = { enabled = true },
						alacrity = { enabled = true, font = "14" },
					},
				})
			end,
		},

		--Terminal
		{ "akinsho/toggleterm.nvim", version = "*", lazy = true, cmd = "ToggleTerm", opts = {} },

		--Search & replace string
		{ "nvim-pack/nvim-spectre", lazy = true, cmd = "Spectre", opts = {} },

		-- Add/remove/change surrounding {}, (), "" etc
		{
			"kylechui/nvim-surround",
			version = "*", -- Use for stability; omit to use `main` branch for the latest features
			event = "VeryLazy",
			config = function()
				require("nvim-surround").setup({
					-- Configuration here, or leave empty to use defaults
				})
			end,
		},

		-- gcc to comment
		{
			"numToStr/Comment.nvim",
			event = "CursorHold",
			opts = {},
		},

		-- autoclose (), {} etc
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = true,
		},

		-- autoclose tags
		{
			"windwp/nvim-ts-autotag",
			event = { "InsertEnter" },
			opts = {},
		},

		--------------------------------------
		-- Developer Tools --
		--------------------------------------

		-- Docker
		-- LazyDocker app is required https://github.com/mgierada/lazydocker.nvim?tab=readme-ov-file#-installation
		{
			"mgierada/lazydocker.nvim",
			cmd = "LazyDocker",
			dependencies = { "akinsho/toggleterm.nvim" },
			config = function()
				require("lazydocker").setup({})
			end,
			event = "VeryLazy",
		},

		-- Database Management
		{
			"tpope/vim-dadbod",
			cmd = { "DBUIToggle", "DBUIFindBuffer", "DBUIRenameBuffer", "DBUILastQueryInfo" },
			dependencies = {
				"kristijanhusak/vim-dadbod-ui",
				"kristijanhusak/vim-dadbod-completion",
			},
			config = function()
				require("pluginconfigs.dadbod").setup()
			end,
		},

		--------------------------------------
		-- Language specific --
		--------------------------------------

		--Markdown
		{ "dkarter/bullets.vim", ft = "markdown" }, -- Automatic ordered lists. For reordering messed list, use :RenumberSelection cmd
		{ "jghauser/follow-md-links.nvim", ft = "markdown" }, --Follow md links with ENTER
		{
			"iamcco/markdown-preview.nvim",
			cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
			ft = { "markdown" },
			-- install without yarn or npm
			build = function()
				vim.fn["mkdp#util#install"]()
			end,
		},
	},
})
require("lsp")
