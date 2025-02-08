return {
	-- Autosave feature
	{
		"okuuva/auto-save.nvim",
		-- cmd = "ASToggle", -- Use this cmd if you want to enable or Space + t + s
		event = { "InsertLeave", "TextChanged" },
		opts = {
			execution_message = {
				enabled = false,
			},
			debounce_delay = 5000,
		},
	},

	-- Lsp server status updates
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},

	-- Electric indentation
	{
		"nmac427/guess-indent.nvim",
		lazy = true,
		event = { "BufReadPost", "BufAdd", "BufNewFile" },
		opts = {},
	},

	-- Highlight word under cursor
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

	-- Delete whitespaces automatically on save
	{
		"saccarosium/nvim-whitespaces",
		event = "BufWritePre",
		opts = {
			handlers = {},
		},
	},

	{
		"NStefan002/visual-surround.nvim",
		event = "VeryLazy",
		config = function()
			require("visual-surround").setup({
				-- your config
			})
		end,
	},

	-- Session management
	-- auto save and restore the last session
	{
		"folke/persistence.nvim",
		event = "BufReadPre", -- this will only start session saving when an actual file was opened
		opts = {
			-- add any custom options here
		},
	},
	{
		"tpope/vim-obsession",
		lazy = true,
	},

	{
		"https://gitlab.com/yorickpeterse/nvim-pqf.git",
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
		config = function()
			require("pqf").setup()
		end,
	},
	{
		"shortcuts/no-neck-pain.nvim",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	{
		"tris203/precognition.nvim",
		event = "VeryLazy",
		config = function()
			require("precognition").setup({
				startVisible = true,
				showBlankVirtLine = false,
				-- highlightColor = { link = "Comment"),
				-- hints = {
				--      Caret = { text = "^", prio = 2 },
				--      Dollar = { text = "$", prio = 1 },
				--      MatchingPair = { text = "%", prio = 5 },
				--      Zero = { text = "0", prio = 1 },
				--      w = { text = "w", prio = 10 },
				--      b = { text = "b", prio = 9 },
				--      e = { text = "e", prio = 8 },
				--      W = { text = "W", prio = 7 },
				--      B = { text = "B", prio = 6 },
				--      E = { text = "E", prio = 5 },
				-- },
				-- gutterHints = {
				--     -- prio is not currently used for gutter hints
				--     G = { text = "G", prio = 1 },
				--     gg = { text = "gg", prio = 1 },
				--     PrevParagraph = { text = "{", prio = 1 },
				--     NextParagraph = { text = "}", prio = 1 },
				-- },
			})
		end,
	},

	{
		"pteroctopus/faster.nvim",
		cmd = { "FasterDisableAllFeatures", "FasterEnableSonarlint", "FasterDisableSonarlint" },
		opts = {
			behaviours = {
				bigfile = {
					on = true,
					features_disabled = {
						"sonarlint",
						"matchparen",
						"lsp",
						"treesitter",
						"syntax",
						"filetype",
					},
					filesize = 5,
					pattern = "*",
					extra_patterns = {
						{ filesize = 0.5, pattern = "*.json" },
					},
				},
				fastmacro = {
					on = true,
					features_disabled = { "lualine" },
				},
			},
			-- Feature table contains configuration for features faster.nvim will disable
			-- and enable according to rules defined in behaviours.
			-- Defined feature will be used by faster.nvim only if it is on (`on=true`).
			-- Defer will be used if some features need to be disabled after others.
			-- defer=false features will be disabled first and defer=true features last.
      -- stylua: ignore
			features = {
				filetype = { on = true, defer = true },
				illuminate = { on = true, defer = false },
				indent_blankline = { on = true, defer = false },
				lsp = { on = true, defer = false },
				lualine = { on = true, defer = false },
				matchparen = { on = true, defer = false },
				syntax = { on = true, defer = true },
				treesitter = { on = true, defer = false },
				vimopts = { on = true, defer = false },
			},
		},
	},

	-- Tmux Integration
	{
		"alexghergh/nvim-tmux-navigation",
		lazy = false,
		config = function()
			require("nvim-tmux-navigation").setup({
				disable_when_zoomed = true, -- defaults to false
			})
		end,
	},

	-- GitHub copilot

	{
		"AndreM222/copilot-lualine",
		event = "VeryLazy",
	},

	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},

	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			highlight_headers = false,
			separator = "---",
			error_header = "> [!ERROR] Error",
			debug = false, -- Enable debugging
			model = "o3-mini",
			mappings = {
				reset = {
					normal = "<C-r>",
					insert = "<C-r>",
				},
			},
			context = "buffers",
			history_path = vim.fn.stdpath("data") .. "/copilotchat_history",
			auto_follow_cursor = false,
			prompts = {
				PullRequest = {
					prompt = "Please provide a pull request description for this git diff.",
					selection = function(source)
						local default_branch = require("lib.git").find_default_branch()

						local select = require("CopilotChat.select")
						local select_buffer = select.buffer(source)
						if not select_buffer then
							return nil
						end

						local dir = vim.fn.getcwd():gsub(".git$", "")

						local cmd = "git -C " .. dir .. " diff --no-color --no-ext-diff " .. default_branch
						local handle = io.popen(cmd)
						if not handle then
							return nil
						end

						local result = handle:read("*a")
						handle:close()
						if not result or result == "" then
							return nil
						end

						select_buffer.filetype = "diff"
						select_buffer.lines = result
						return select_buffer
					end,
				},
				Explain = "Please explain how the following code works.",
				Tests = "Please explain how the selected code works, then generate unit tests for it.",
				Review = "Please review the following code and provide suggestions for improvement.",
				Refactor = "Please refactor the following code to improve its clarity and readability.",
				FixCode = "Please fix the following code to make it work as intended.",
				FixError = "Please explain the error in the following text and provide a solution.",
				BetterNamings = "Please provide better names for the following variables and functions.",
				Documentation = "Please provide documentation for the following code.",
				Summarize = "Please summarize the following text.",
				Spelling = "Please correct any grammar and spelling errors in the following text.",
				Wording = "Please improve the grammar and wording of the following text.",
				Concise = "Please rewrite the following text to make it more concise.",
			},
		},
		-- See Commands section for default commands if you want to lazy load on them
		config = function(_, opts)
			local existing_prompts = require("CopilotChat.config").prompts

			-- Add existing_prompts to opts.prompts, if the key doesn't already exist
			for k, v in pairs(existing_prompts) do
				if not opts.prompts[k] then
					opts.prompts[k] = v
				elseif type(opts.prompts[k]) == "string" and type(v) == "table" then
					-- If our prompt is a string and the default prompt is a table, merge the two
					local prompt = opts.prompts[k]
					opts.prompts[k] = v
					opts.prompts[k].prompt = prompt
				end
			end

			require("CopilotChat").setup(opts)
		end,
	},
	-- codecompanion
	{ import = "pluginconfigs.codecompanion.init" },

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false, auto_trigger = false, debounce = 75 },
				panel = {
					enabled = false,

					layout = {
						position = "bottom", -- | top | left | right
						ratio = 0.4,
						event = { "BufEnter" },
					},
				},
				copilot_node_command = "node",
				server_opts_overrides = {},
			})
		end,
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = true,
		-- dev = true,
		version = false,
		build = "make",
		opts = {
			provider = "copilot",
			auto_suggestions_provider = "openai",
			openai = {
				endpoint = "https://api.deepseek.com/v1",
				model = "deepseek-chat",
				timeout = 30000,
				temperature = 0,
				max_tokens = 4096,
			},
			copilot = {
				model = "claude-3.5-sonnet",
				temperature = 0.5,
				timeout = 30000, -- Timeout in milliseconds
				max_tokens = 8192,
			},
			gemini = {
				model = "gemini-2.0-flash",
				temperature = 0.2,
				max_tokens = 16384,
			},
			dual_boost = {
				enabled = true,
				first_provider = "copilot",
				second_provider = "gemini",
				prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Provide brief explanation with highlighting the important points. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
				timeout = 60000, -- Timeout in milliseconds
			},
			windows = {
				sidebar_header = {
					enabled = false,
				},
			},
			behaviour = {
				auto_suggestions = false, -- Experimental stage
				auto_set_highlight_group = true,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				support_paste_from_clipboard = true,
				minimize_diff = true,
			},
			mappings = {
				sidebar = {
					switch_windows = "<C-Tab>",
					reverse_switch_windows = "<C-S-Tab>",
				},
			},
			file_selector = {
				--- @alias FileSelectorProvider "native" | "fzf" | "telescope" | string
				provider = "fzf",
				-- Options override for custom providers
				provider_opts = {},
			},
			suggestion = {
				dismiss = "<C-e>",
			},
			on_error = function(err)
				vim.notify("Avante error: " .. err, vim.log.levels.ERROR)
			end,
		},
		dependencies = {
			{ "stevearc/dressing.nvim", lazy = true },
			{ "nvim-lua/plenary.nvim", lazy = true },
			{ "MunifTanjim/nui.nvim", lazy = true },
			{ "nvim-tree/nvim-web-devicons", lazy = true },
			{ "hrsh7th/nvim-cmp", lazy = true },
			{ "zbirenbaum/copilot.lua", lazy = true },
			--- The below dependencies are optional,
			{ "echasnovski/mini.pick", lazy = true }, -- for file_selector provider mini.pick
			{ "nvim-telescope/telescope.nvim", lazy = true }, -- for file_selector provider telescope
			{ "hrsh7th/nvim-cmp", lazy = true }, -- autocompletion for avante commands and mentions
			{ "ibhagwan/fzf-lua", lazy = true }, -- for file_selector provider fzf
			{ "nvim-tree/nvim-web-devicons", lazy = true }, -- or echasnovski/mini.icons
			{ "zbirenbaum/copilot.lua", lazy = true }, -- for providers='copilot'
			{ "MeanderingProgrammer/render-markdown.nvim", lazy = true },
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						use_absolute_path = true,
					},
				},
			},
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			file_types = {
				"Avante",
				"codecompanion",
				"markdown",
				"copilot-chat",
			},
		},
		ft = {
			"Avante",
			"codecompanion",
			"markdown",
			"copilot-chat",
		},
		config = function(_, opts)
			require("render-markdown").setup(opts)
		end,
	},

	-- Python helpers
	{
		"AckslD/swenv.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
		},
		lazy = false,
		config = function()
			require("swenv").setup({
				venvs_path = vim.fn.expand("~/.cache/pypoetry/virtualenvs"),
				post_set_venv = function()
					vim.cmd("LspRestart")
				end,
			})
		end,
	},

	-- C++ build
	{
		"Civitasv/cmake-tools.nvim",
		ft = { "hpp", "h", "cpp" },
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
	},

	{
		"pogyomo/cppguard.nvim",
		dependencies = {
			"L3MON4D3/LuaSnip", -- If you're using luasnip.
		},
		config = function()
			local luasnip = require("luasnip")
			luasnip.add_snippets("cpp", {
				require("cppguard").snippet_luasnip("guard"),
			})
		end,
	},

	{
		"Badhi/nvim-treesitter-cpp-tools",
		ft = { "hpp", "h", "cpp" },
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
		"bfrg/vim-c-cpp-modern",
		ft = { "hpp", "h", "cpp" },
	},

	-- bazel
	{
		"mrheinen/bazelbub.nvim",
		version = "v0.2",
	},
	{ "bazelbuild/vim-bazel", dependencies = { "google/vim-maktaba" } },

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
		"aznhe21/actions-preview.nvim",
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-telescope/telescope.nvim" },
		opts = {
			handlers = {},
		},
		config = function()
			vim.keymap.set({ "v", "n" }, "gf", require("actions-preview").code_actions)
		end,
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup({
				prompt_func_return_type = {
					java = true,
					cpp = true,
					c = true,
					h = true,
					hpp = true,
					cxx = true,
				},
				prompt_func_param_type = {
					java = true,
					cpp = true,
					c = true,
					h = true,
					hpp = true,
					cxx = true,
				},
				show_success_message = true, -- shows a message with information about the refactor on success
				-- i.e. [Refactor] Inlined 3 variable occurrences
				-- load refactoring Telescope extension
				require("telescope").load_extension("refactoring"),
			})
		end,
	},
	-- misc
	{
		"norcalli/nvim-colorizer.lua",
		config = true,
		cmd = "ColorizerToggle",
	},
	{
		"EthanJWright/vs-tasks.nvim",
		dependencies = {
			"nvim-lua/popup.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("vstask").setup({
				json_parser = require("json5").parse,
			})
		end,
	},
	{
		"Joakker/lua-json5",
		build = "./install.sh && mv lua/json5.dylib lua/json5.so",
		lazy = false,
		priority = 1000,
	},
	-- rest client
	-- {
	--   "vhyrro/luarocks.nvim",
	--   priority = 1000,
	--   config = true,
	--   opts = {
	--     rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" }
	--   }
	-- },
	-- {
	--   "rest-nvim/rest.nvim",
	--   ft = "http",
	--   dependencies = { "luarocks.nvim", "nvim-telescope/telescope.nvim" },
	--   config = function()
	--     require("rest-nvim").setup()
	--     require("telescope").load_extension("rest")
	--   end,
	-- }
}
