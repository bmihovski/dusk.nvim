return {
	-- Autosave feature
	{
		"okuuva/auto-save.nvim",

		event = { "InsertLeave", "TextChanged" },
		opts = {

			debounce_delay = 5000,
			-- Use Neovim's built-in notification system instead of execution_message
			on_enable = function()
				vim.notify("Auto-save enabled", vim.log.levels.INFO, { title = "auto-save.nvim" })
			end,
			on_disable = function()
				vim.notify("Auto-save disabled", vim.log.levels.WARN, { title = "auto-save.nvim" })
			end,
		},
	},

	-- small formatting diagnostic
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = { "LspAttach" },
		dependencies = { "neovim/nvim-lspconfig" },
		init = function()
			vim.diagnostic.config({
				virtual_text = true,
			})
		end,
		main = "tiny-inline-diagnostic",
		opts = {
			preset = "nonerdfont",
			options = {
				multiple_diag_under_cursor = true,
				show_source = true,
			},
		},
	},
	{
		"shellRaining/hlchunk.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = function()
			local palette = require("catppuccin.palettes.mocha")
			local excluded_ft = { ["neo-tree"] = true, snacks_dashboard = true, fidget = true, help = true }

			local indent_colors = {
				palette.surface0,
				palette.surface1,
				palette.surface2,
				palette.overlay0,
				palette.overlay1,
				palette.overlay2,
				palette.subtext0,
				palette.subtext1,
				palette.text,
			}
			return {
				chunk = {
					delay = 100,
					enable = true,
					exclude_filetypes = excluded_ft,
					style = palette.lavender,
				},
				indent = {
					enable = true,
					exclude_filetypes = excluded_ft,
					style = indent_colors,
				},
			}
		end,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},

	-- Lsp server status updates
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		version = "*",
		opts = {
			notification = {
				window = {
					winblend = 0,
					align = "bottom",
					x_padding = 0,
					border = { "" },
				},
				view = { stack_upwards = false },
			},
		},
	},

	-- Electric indentation
	{
		"nmac427/guess-indent.nvim",
		lazy = true,
		event = { "BufReadPost", "BufAdd", "BufNewFile" },
		opts = {},
	},
	{
		"rmagatti/goto-preview",
		dependencies = { "rmagatti/logger.nvim" },
		event = "BufEnter",
		config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
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
	{
		"wintermute-cell/gitignore.nvim",
		cmd = "Gitignore",
		config = function()
			local gitignore = require("gitignore")
			local fzf = require("fzf-lua")

			gitignore.generate = function(opts)
				local picker_opts = {
					-- the content of opts.args may also be displayed here for example.
					prompt = "Select templates for gitignore file> ",
					winopts = {
						width = 0.4,
						height = 0.3,
					},
					actions = {
						default = function(selected, _)
							-- as stated in point (3) of the contract above, opts.args and
							-- a list of selected templateNames are passed.
							gitignore.createGitignoreBuffer(opts.args, selected)
						end,
					},
				}
				fzf.fzf_exec(function(fzf_cb)
					for _, prefix in ipairs(gitignore.templateNames) do
						fzf_cb(prefix)
					end
					fzf_cb()
				end, picker_opts)
			end
			vim.api.nvim_create_user_command("Gitignore", gitignore.generate, { nargs = "?", complete = "file" })
		end,
		dependencies = { "ibhagwan/fzf-lua" },
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
	{
		"kevinhwang91/nvim-ufo",
		dependencies = {
			"kevinhwang91/promise-async",
			"nvim-treesitter/nvim-treesitter",
			"neovim/nvim-lspconfig",
		},
		init = function()
			vim.o.foldenable = true
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldcolumn = "0"
		end,
		config = function(_, opts)
			require("ufo").setup(opts)
			vim.api.nvim_set_hl(0, "UfoCursorFoldedLine", { link = "CursorLine" })
			vim.api.nvim_set_hl(0, "UfoPreviewBg", { link = "TelescopePreviewBorder" })
			vim.api.nvim_set_hl(0, "UfoPreviewWinBar", { link = "TelescopePreviewBorder" })
			vim.api.nvim_set_hl(0, "UfoFoldedBg", { link = "CursorLine" })
		end,
		opts = {
			preview = {
				win_config = { winhighlight = "Normal:TelescopePreviewBorder", winblend = 0 },
			},
			fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate)
				local result = {}
				local _end = end_lnum - 1
				local final_text = vim.trim(vim.api.nvim_buf_get_text(0, _end, 0, _end, -1, {})[1])
				local suffix = final_text:format(end_lnum - lnum)
				local suffix_width = vim.fn.strdisplaywidth(suffix)
				local target_width = width - suffix_width
				local cur_width = 0
				for _, chunk in ipairs(virt_text) do
					local chunk_text = chunk[1]
					local chunk_width = vim.fn.strdisplaywidth(chunk_text)
					if target_width > cur_width + chunk_width then
						table.insert(result, chunk)
					else
						chunk_text = truncate(chunk_text, target_width - cur_width)
						local hl_group = chunk[2]
						table.insert(result, { chunk_text, hl_group })
						chunk_width = vim.fn.strdisplaywidth(chunk_text)
						-- str width returned from truncate() may less than 2nd argument, need padding
						if cur_width + chunk_width < target_width then
							suffix = suffix .. (" "):rep(target_width - cur_width - chunk_width)
						end
						break
					end
					cur_width = cur_width + chunk_width
				end
				table.insert(result, { "  ", "NonText" })
				table.insert(result, { suffix, "TSPunctBracket" })
				return result
			end,
			provider_selector = function(bufnum, _, _)
				if vim.bo.bt == "nofile" then
					return ""
				end
				local servers = vim.lsp.get_clients({ bufnr = bufnum })
				local any = function(array, func)
					if type(func) ~= "function" then
						func = function(item)
							return item
						end
					end
					for i, item in ipairs(array) do
						if func(item) then
							return true
						end
					end
					return false
				end
				if
					#servers > 0
					and any(servers, function(server)
						return server.server_capabilities.foldingRangeProvider == true
					end)
				then
					return { "lsp", "treesitter" }
				end
				return { "treesitter", "indent" }
			end,
		},
		event = { "LspAttach" },
	},

	{
		"hiphish/rainbow-delimiters.nvim",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local rainbow_delimiters = require("rainbow-delimiters")
			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
					vim = rainbow_delimiters.strategy["local"],
				},
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
				},
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				},
			}
			vim.api.nvim_set_hl(
				0,
				"MatchParen",
				---@diagnostic disable-next-line: param-type-mismatch
				vim.tbl_deep_extend("force", vim.api.nvim_get_hl(0, { name = "MatchParen" }), { fg = "NONE" })
			)
		end,
		dependencies = { "nvim-treesitter/nvim-treesitter" },
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
		"Davidyz/executable-checker.nvim",
		opts = {},
		event = "VeryLazy",
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
		"fei6409/log-highlight.nvim",
		config = function()
			require("log-highlight").setup({})
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

	{ import = "pluginconfigs.vectorcode.init" },
	{ import = "pluginconfigs.context-nvim" },
	{
		"YounesElhjouji/nvim-copy",
		lazy = false, -- disables lazy-loading so the plugin is loaded on startup
		config = function()
			-- Optional: additional configuration or key mappings
			vim.api.nvim_set_keymap("n", "<f16>cb", ":CopyBuffersToClipboard<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap(
				"n",
				"<f16>cc",
				":CopyCurrentBufferToClipboard<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap("n", "<f16>cg", ":CopyGitFilesToClipboard<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap(
				"n",
				"<f16>cq",
				":CopyQuickfixFilesToClipboard<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<f16>ch",
				":CopyHarpoonFilesToClipboard<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<f16>cd",
				":CopyDirectoryFilesToClipboard<CR>",
				{ noremap = true, silent = true }
			)

			vim.keymap.set("n", "<f16>cd", function()
				vim.ui.input({
					prompt = "Enter directory path: ",
					default = vim.fn.getcwd(), -- Default to current working directory
				}, function(input)
					if input then -- Only proceed if input wasn't cancelled
						vim.cmd(string.format("CopyDirectoryFilesToClipboard %s norecurse", input))
					end
				end)
			end, { noremap = true, silent = true })
		end,
	},

	{
		"milanglacier/minuet-ai.nvim",
		dependencies = { "yetone/avante.nvim" },
		event = "VeryLazy",
		config = function(_, opts)
			local has_vc, vectorcode_config = pcall(require, "vectorcode.config")
			local avante_llm_tools = require("avante.llm_tools")
			local vector_code_utils = require("vectorcode.utils")
			-- roughly equate to 2000 tokens for LLM
			local RAG_Context_Window_Size = 8000

			-- RAG Cache Management System
			local rag_cache = {
				result = "",
				last_context = "",
				last_update = 0,
				ttl = 60000, -- 1 minute TTL in milliseconds
			}

			-- Cache validation logic
			-- Debug flag to control notification verbosity
			local DEBUG_RAG_CACHE = false -- Set to true to enable debug notifications

			-- Cache validation logic
			local function should_update_cache(query_context)
				local current_time = vim.loop.now()

				-- Always update if cache is empty
				if rag_cache.result == "" then
					if DEBUG_RAG_CACHE then
						vim.notify(
							"Cache is empty, will perform new RAG search",
							vim.log.levels.DEBUG,
							{ title = "RAG Cache" }
						)
					end
					return true
				end

				-- Update if context has changed significantly
				if rag_cache.last_context ~= query_context then
					if DEBUG_RAG_CACHE then
						vim.notify("Context changed, will refresh cache", vim.log.levels.DEBUG, { title = "RAG Cache" })
					end
					return true
				end

				-- Update if TTL has expired
				if current_time - rag_cache.last_update > rag_cache.ttl then
					if DEBUG_RAG_CACHE then
						local age_seconds = math.floor((current_time - rag_cache.last_update) / 1000)
						vim.notify(
							string.format("Cache expired (%ds old), will refresh", age_seconds),
							vim.log.levels.DEBUG,
							{ title = "RAG Cache" }
						)
					end
					return true
				end

				if DEBUG_RAG_CACHE then
					local age_seconds = math.floor((current_time - rag_cache.last_update) / 1000)
					vim.notify(
						string.format("Using valid cache (%ds old)", age_seconds),
						vim.log.levels.DEBUG,
						{ title = "RAG Cache" }
					)
				end
				return false
			end

			-- Cache update utility
			local function update_cache(query_context, result)
				rag_cache.result = result or ""
				rag_cache.last_context = query_context
				rag_cache.last_update = vim.loop.now()

				if DEBUG_RAG_CACHE then
					local result_length = result and #result or 0
					vim.notify(
						string.format("Cache updated: %d chars", result_length),
						vim.log.levels.DEBUG,
						{ title = "RAG Cache" }
					)
				end
			end

			-- Source formatting utility
			local function format_rag_sources(sources)
				if not sources or #sources == 0 then
					if DEBUG_RAG_CACHE then
						vim.notify("No sources to format", vim.log.levels.DEBUG, { title = "RAG Formatter" })
					end
					return ""
				end

				local formatted_sources = {}
				local valid_sources_count = 0
				local temp_uri = ""

				for i, src in ipairs(sources) do
					if src.uri and src.content and src.uri ~= temp_uri then
						table.insert(formatted_sources, "<file_separator>" .. src.uri .. "\n" .. src.content)
						valid_sources_count = valid_sources_count + 1
						temp_uri = src.uri
					else
						-- Keep warning for invalid sources as it's critical
						vim.notify(
							string.format("Skipping invalid source %d: missing uri or content", i),
							vim.log.levels.WARN,
							{ title = "RAG Formatter" }
						)
					end
				end

				if #formatted_sources == 0 then
					-- Keep warning for no valid sources as it's critical
					if DEBUG_RAG_CACHE then
						vim.notify(
							"No valid sources found after filtering",
							vim.log.levels.WARN,
							{ title = "RAG Formatter" }
						)
					end
					return ""
				end

				local context = table.concat(formatted_sources, "")
				local original_length = #context
				local truncated_context = vim.fn.strcharpart(context, 0, RAG_Context_Window_Size)
				local final_length = #truncated_context

				if DEBUG_RAG_CACHE then
					vim.notify(
						string.format(
							"Formatted %d sources: %d -> %d chars",
							valid_sources_count,
							original_length,
							final_length
						),
						vim.log.levels.DEBUG,
						{ title = "RAG Formatter" }
					)
				end

				return "<repo_context>\n" .. truncated_context .. "\n</repo_context>"
			end

			-- Main RAG search function
			local function perform_rag_search(query_context, on_complete)
				if DEBUG_RAG_CACHE then
					vim.notify("Starting RAG search", vim.log.levels.DEBUG, { title = "RAG Search" })
				end

				-- Input validation
				if not query_context or query_context == "" then
					-- Keep warning for invalid input as it's critical
					vim.notify("Invalid query context provided", vim.log.levels.WARN, { title = "RAG Search" })
					on_complete("")
					return
				end

				if type(on_complete) ~= "function" then
					-- Keep error for invalid callback as it's critical
					vim.notify("Invalid callback function provided", vim.log.levels.ERROR, { title = "RAG Search" })
					return
				end

				-- Check if we should use cached result
				if not should_update_cache(query_context) then
					if DEBUG_RAG_CACHE then
						vim.notify("Using cached RAG result", vim.log.levels.DEBUG, { title = "RAG Search" })
					end
					on_complete(rag_cache.result)
					return
				end

				-- Completion handler with comprehensive logging
				local function complete_with_result(result, message, log_level)
					local level = log_level or vim.log.levels.DEBUG
					if message and (DEBUG_RAG_CACHE or level > vim.log.levels.WARN) then
						vim.notify(message, level, { title = "RAG Search" })
					end

					if result and result ~= "" and DEBUG_RAG_CACHE then
						local char_count = #result
						vim.notify(
							string.format("Generated RAG context: %d chars", char_count),
							vim.log.levels.INFO,
							{ title = "RAG Search" }
						)
					end

					-- Update cache with new result
					update_cache(query_context, result or "")
					on_complete(result or "")
				end

				-- Perform RAG retrieval with comprehensive error handling
				if DEBUG_RAG_CACHE then
					vim.notify("Calling avante_llm_tools.rag_search", vim.log.levels.DEBUG, { title = "RAG Search" })
				end
				avante_llm_tools.rag_search({ query = query_context }, {
					on_log = nil,
					on_complete = function(resp, err)
						-- Handle errors
						if err then
							if DEBUG_RAG_CACHE then
								local error_msg = "RAG search error: " .. tostring(err)
								-- Keep error notifications as they're critical
								vim.notify(error_msg, vim.log.levels.ERROR, { title = "RAG Search" })
							end
							complete_with_result("", "RAG search failed due to error", vim.log.levels.INFO)
							return
						end

						-- Handle empty response
						if not resp then
							complete_with_result("", "Empty RAG response received", vim.log.levels.INFO)
							return
						end
						local ok, decoded = pcall(vim.json.decode, resp)
						if not ok then
							complete_with_result("", "Response JSON decoding failed", vim.log.levels.INFO)
							return
						end

						if DEBUG_RAG_CACHE then
							vim.notify(
								string.format(
									"RAG response received with %d sources",
									decoded.sources and #decoded.sources or 0
								),
								vim.log.levels.DEBUG,
								{ title = "RAG Search" }
							)
						end

						-- Handle response with sources
						if decoded.sources and #decoded.sources > 0 then
							local formatted_result = format_rag_sources(decoded.sources)
							if formatted_result ~= "" then
								complete_with_result(
									formatted_result,
									"RAG context generated successfully",
									vim.log.levels.DEBUG
								)
							else
								complete_with_result("", "No valid sources found in RAG response", vim.log.levels.WARN)
							end
						else
							complete_with_result("", "No sources in RAG response", vim.log.levels.WARN)
						end
					end,
				})
			end

			-- Smart cache retrieval with background refresh
			local function get_cached_repo_context(query_context)
				local current_time = vim.loop.now()

				-- Return cached result if valid
				if
					rag_cache.result ~= ""
					and rag_cache.last_context == query_context
					and current_time - rag_cache.last_update < rag_cache.ttl
				then
					if DEBUG_RAG_CACHE then
						local age_seconds = math.floor((current_time - rag_cache.last_update) / 1000)
						vim.notify(
							string.format("Returning valid cache (%ds old, %d chars)", age_seconds, #rag_cache.result),
							vim.log.levels.DEBUG,
							{ title = "RAG Cache" }
						)
					end
					return rag_cache.result
				end

				if DEBUG_RAG_CACHE then
					vim.notify(
						string.format(
							"Cache validation result: has_result=%s, context_match=%s, ttl_valid=%s",
							tostring(rag_cache.result ~= ""),
							tostring(rag_cache.last_context == query_context),
							tostring(current_time - rag_cache.last_update < rag_cache.ttl)
						),
						vim.log.levels.DEBUG,
						{ title = "RAG Cache" }
					)
				end

				-- Cache invalid - trigger async refresh but return stale data immediately
				if rag_cache.result ~= "" then
					if DEBUG_RAG_CACHE then
						vim.notify(
							"Triggering background cache refresh while returning stale data",
							vim.log.levels.DEBUG,
							{ title = "RAG Cache" }
						)
					end
					-- Background refresh with stale cache
					vim.defer_fn(function()
						perform_rag_search(query_context, function(new_result)
							update_cache(query_context, new_result)
							if DEBUG_RAG_CACHE then
								vim.notify(
									"Background cache refresh completed",
									vim.log.levels.DEBUG,
									{ title = "RAG Cache" }
								)
							end
						end)
					end, 0)
					return rag_cache.result -- Return stale but usable data
				end

				if DEBUG_RAG_CACHE then
					vim.notify(
						"No cache available, returning empty context",
						vim.log.levels.DEBUG,
						{ title = "RAG Cache" }
					)
				end
				return "" -- No cache available
			end
			-- Utility function to format query context
			local function format_query_context(query_context)
				if type(query_context) ~= "table" then
					query_context = vim.split(query_context, "\n")
				end

				local formatted_context = {}
				for _, line in ipairs(query_context) do
					-- Handle EOF, empty line, or empty string - continue processing
					if not line or line == " " or line == "" or line == "  " or line == "\n" or line == "\r\n" then
						goto continue
					end

					-- Remove or escape JSON problematic characters
					line = line:gsub("  ", " ") -- Replace double spaces
					line = line:gsub('"', " ") -- Replace double quotes
					line = line:gsub("'", " ") -- Replace single quotes
					line = line:gsub(",", " ") -- Replace commas
					line = line:gsub(";", " ") -- Replace semicolons
					line = line:gsub(":", " ") -- Replace colons
					line = line:gsub("%[", " ") -- Replace left brackets
					line = line:gsub("%]", " ") -- Replace right brackets
					line = line:gsub("{", " ") -- Replace left braces
					line = line:gsub("}", " ") -- Replace right braces
					line = line:gsub("%(", " ") -- Replace left parentheses
					line = line:gsub("%)", " ") -- Replace right parentheses
					line = line:gsub("&", " ") -- Replace ampersands
					line = line:gsub("<", " ") -- Replace less than
					line = line:gsub(">", " ") -- Replace greater than
					line = line:gsub("|", " ") -- Replace pipes
					line = line:gsub("%%", " ") -- Replace percent signs
					line = line:gsub("%$", " ") -- Replace dollar signs
					line = line:gsub("#", " ") -- Replace hash symbols
					line = line:gsub("@", " ") -- Replace at symbols
					line = line:gsub("!", " ") -- Replace exclamation marks
					line = line:gsub("%?", " ") -- Replace question marks
					line = line:gsub("%*", " ") -- Replace asterisks
					line = line:gsub("%+", " ") -- Replace plus signs
					line = line:gsub("%-", " ") -- Replace hyphens/minus signs
					line = line:gsub("=", " ") -- Replace equals signs
					line = line:gsub("/", "") -- Escape forward slashes
					line = line:gsub("\\", "") -- Escape backslashes
					line = line:gsub("\n", " ") -- Replace newlines with spaces
					line = line:gsub("\r", " ") -- Replace carriage returns with spaces
					line = line:gsub("\t", " ") -- Replace tabs with spaces
					line = line:gsub("\b", " ") -- Replace backspace with space
					line = line:gsub("\f", " ") -- Replace form feed with space
					line = line:gsub("\v", " ") -- Replace vertical tab with space
					line = line:gsub("%z", " ") -- Replace null characters
					line = line:gsub("%s+", " ") -- Collapse multiple spaces into single space

					-- Only add non-empty lines after processing
					if line and line ~= "" and line ~= " " then
						table.insert(formatted_context, line)
					end

					::continue::
				end

				local final_context = ""
				-- Join with single space and ensure single line
				final_context = table.concat(vim.tbl_map(tostring, formatted_context), " ")

				-- Final cleanup to ensure single line and JSON compatibility
				final_context = final_context
					:gsub("\n", " ")
					:gsub("\r", " ")
					:gsub("%s+", " ")
					:gsub("\t", " ")
					:gsub("^%s+", "") -- Remove leading spaces
					:gsub("%s+$", "") -- Remove trailing spaces
				return final_context
			end

			-- Auto-refresh triggers for RAG cache
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
				pattern = { "*.lua", "*.py", "*.js", "*.ts", "*.java", "*.cpp", "*.hpp" },
				callback = function()
					if DEBUG_RAG_CACHE then
						vim.notify(
							"Auto-refresh trigger activated",
							vim.log.levels.DEBUG,
							{ title = "RAG Auto-refresh" }
						)
					end

					local ok, query_context = pcall(vector_code_utils.make_surrounding_lines_cb(20), 0)
					if ok and query_context ~= "" then
						query_context = format_query_context(query_context)
						if DEBUG_RAG_CACHE then
							vim.notify(
								string.format("Generated query context: %d chars", #query_context),
								vim.log.levels.DEBUG,
								{ title = "RAG Auto-refresh" }
							)
						end
						vim.defer_fn(function()
							perform_rag_search(query_context, function(result)
								update_cache(query_context, result)
								if DEBUG_RAG_CACHE then
									vim.notify(
										"Auto-refresh completed",
										vim.log.levels.DEBUG,
										{ title = "RAG Auto-refresh" }
									)
								end
							end)
						end, 500) -- 500ms debounce
					else
						if DEBUG_RAG_CACHE then
							vim.notify(
								"Failed to generate query context",
								vim.log.levels.DEBUG,
								{ title = "RAG Auto-refresh" }
							)
						end
					end
				end,
			})

			opts = {
				cmp = {
					enable_auto_complete = true,
				},
				blink = {
					enable_auto_complete = false,
				},
				add_single_line_entry = false,
				n_completions = 1,
				-- notify = "debug",
				notify = "error",
				provider = "gemini",
				-- provider = "openai_fim_compatible",
				request_timeout = 15,
				provider_options = {
					openai_fim_compatible = {
						api_key = "DEEPSEEK_CHAT_API_KEY",
						name = "deepseek",
						template = {
							prompt = function(pref, suff)
								local prompt_message = ([[Perform fill-in-middle from the following snippet of a %s code. Respond with only the filled-in code.]]):format(
									vim.bo.filetype
								)
								if has_vc then
									local cache_result = vectorcode_config.get_cacher_backend().query_from_cache(0)
									for _, file in ipairs(cache_result) do
										prompt_message = prompt_message
											.. "<|file_sep|>"
											.. file.path
											.. "\n"
											.. file.document
									end
									prompt_message = vim.fn.strcharpart(prompt_message, 0, RAG_Context_Window_Size)
								end
								return prompt_message
									.. "<|fim_begin|>"
									.. pref
									.. "<|fim_hole|>"
									.. suff
									.. "<|fim_end|>"
							end,
							suffix = false,
						},
						optional = {
							max_tokens = 256,
							stop = { "\n\n" },
						},
					},
					openai = {
						optional = {
							max_tokens = 256,
							top_p = 0.9,
						},
					},
					gemini = {
						model = "gemini-2.5-flash-lite-preview-06-17",
						-- model = "gemini-2.0-flash-lite",
						system = {
							template = "{{{prompt}}}\n{{{guidelines}}}\n{{{n_completion_template}}}\n{{{repo_context}}}",
							repo_context = [[9. Additional context from other files in the repository will be enclosed in <repo_context> tags. Each file will be separated by <file_separator> tags, containing its relative path and content.]],
						},
						chat_input = {
							template = "{{{repo_context}}}\n{{{language}}}\n{{{tab}}}\n<contextBeforeCursor>\n{{{context_before_cursor}}}<cursorPosition>\n<contextAfterCursor>\n{{{context_after_cursor}}}",
							repo_context = function(_, _, _)
								local ok, query_context = pcall(vector_code_utils.make_surrounding_lines_cb(20), 0)
								if not ok or not query_context then
									return rag_cache.result -- Return whatever cache we have
								end

								query_context = format_query_context(query_context)
								-- Trigger async refresh if cache is stale
								if should_update_cache(query_context) then
									vim.defer_fn(function()
										perform_rag_search(query_context, function(result)
											update_cache(query_context, result)
										end)
									end, 0)
								end

								return get_cached_repo_context(query_context)
							end,
						},
						-- chat_input = {
						-- 	template = "{{{repo_context}}}\n{{{language}}}\n{{{tab}}}\n<contextBeforeCursor>\n{{{context_before_cursor}}}<cursorPosition>\n<contextAfterCursor>\n{{{context_after_cursor}}}",
						-- 	repo_context = function(_, _, _)
						-- 		local prompt_message = ""
						-- 		if has_vc then
						-- 			local cache_result = vectorcode_config.get_cacher_backend().query_from_cache(0)
						-- 			for _, file in ipairs(cache_result) do
						-- 				prompt_message = prompt_message
						-- 					.. "<file_separator>"
						-- 					.. file.path
						-- 					.. "\n"
						-- 					.. file.document
						-- 			end
						-- 		end
						--
						-- 		prompt_message = vim.fn.strcharpart(prompt_message, 0, RAG_Context_Window_Size)
						--
						-- 		if prompt_message ~= "" then
						-- 			prompt_message = "<repo_context>\n" .. prompt_message .. "\n</repo_context>"
						-- 		end
						-- 		return prompt_message
						-- 	end,
						-- },
						optional = {
							generationConfig = {
								stop_sequences = { "<|file_separator|>" },
								maxOutputTokens = 256,
								topP = 0.9,
								thinkingConfig = {
									thinkingBudget = 0,
								},
							},
							safetySettings = {
								{
									category = "HARM_CATEGORY_DANGEROUS_CONTENT",
									threshold = "BLOCK_NONE",
								},
								{
									category = "HARM_CATEGORY_HATE_SPEECH",
									threshold = "BLOCK_NONE",
								},
								{
									category = "HARM_CATEGORY_HARASSMENT",
									threshold = "BLOCK_NONE",
								},
								{
									category = "HARM_CATEGORY_SEXUALLY_EXPLICIT",
									threshold = "BLOCK_NONE",
								},
							},
						},
					},
				},
			}

			require("minuet").setup(opts)
		end,
	},

	{ "mawkler/modicator.nvim", opts = {}, event = { "BufReadPost", "BufNewFile" } },

	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			"zbirenbaum/copilot.lua", -- or github/copilot.vim
			"nvim-lua/plenary.nvim", -- for curl, log wrapper
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = function()
			local user = vim.env.USER or "User"
			user = user:sub(1, 1):upper() .. user:sub(2)

			-- Base commit prompt template
			local commit_prompt =
				"Take a deep breath and analyze the changes made in the git diff. Then, write a commit message for the %s with commitizen convention, only use lower-case letters. Output the full multi-line command starting with `git commit -m` ready to be pasted into the terminal. If there are references to filenames or the backtics in the commit message, escape them with backslashes. i.e. \\` text with backticks \\`"

			return {
				separator = "---",
				debug = false, -- Enable debugging
				model = "gpt-4.1",
				mappings = {
					reset = {
						normal = "<C-r>",
						insert = "<C-r>",
					},
				},
				history_path = vim.fn.stdpath("data") .. "/copilotchat_history",
				auto_follow_cursor = false,
				chat_autocomplete = true,

				auto_insert_mode = false,
				question_header = "  " .. user .. " ",
				answer_header = "  Copilot ",
				error_header = "## Error ",
				window = {
					width = 0.4,
				},
				sticky = {
					"Using the model $gpt-4.1",
					"#vectorcode",
				},
				-- Register custom contexts
				contexts = {
					pr_diff = {
						description = "Get the diff between the current branch and target branch",
						resolve = function()
							local Job = require("plenary.job")

							-- Check if we're in a git repository
							local is_git_job = Job:new({
								command = "git",
								args = { "rev-parse", "--is-inside-work-tree" },
								enable_recording = true,
							})

							local ok, output = pcall(function()
								return is_git_job:sync()[1] == "true"
							end)

							if not ok or not output then
								return { { content = "Not in a git repository", filename = "error", filetype = "text" } }
							end

							-- Get target branch (main/master/develop)
							local target_branch_job = Job:new({
								command = "git",
								args = { "for-each-ref", "--format=%(refname:short)", "refs/heads/" },
								enable_recording = true,
							})

							local target_branch
							ok, output = pcall(function()
								local branches = target_branch_job:sync()
								if type(branches) ~= "table" then
									return nil
								end
								for _, branch in ipairs(branches) do
									if
										type(branch) == "string"
										and (
											branch:match("^main$")
											or branch:match("^master$")
											or branch:match("^develop$")
										)
									then
										return branch
									end
								end
								return nil
							end)

							if not ok or not output then
								return {
									{
										content = "Failed to determine target branch",
										filename = "error",
										filetype = "text",
									},
								}
							end
							target_branch = output

							-- Fetch the latest changes from the remote repository
							local fetch_job = Job:new({
								command = "git",
								args = { "fetch", "origin", target_branch },
								enable_recording = true,
							})

							ok = pcall(function()
								fetch_job:sync()
							end)
							if not ok then
								return {
									{
										content = "Failed to fetch from remote",
										filename = "error",
										filetype = "text",
									},
								}
							end

							-- Get current branch
							local current_branch_job = Job:new({
								command = "git",
								args = { "rev-parse", "--abbrev-ref", "HEAD" },
								enable_recording = true,
							})

							local current_branch
							ok, output = pcall(function()
								return current_branch_job:sync()[1]
							end)
							if not ok or not output then
								return {
									{ content = "Failed to get current branch", filename = "error", filetype = "text" },
								}
							end
							current_branch = output
							-- Get the diff
							local diff_job = Job:new({
								command = "git",
								args = {
									"diff",
									"--no-color",
									"--no-ext-diff",
									string.format("origin/%s...%s", target_branch, current_branch),
								},
								enable_recording = true,
							})

							local diff_result
							ok, output = pcall(function()
								return diff_job:sync()
							end)
							if not ok or not output or #output == 0 then
								return {
									{
										content = "No changes found between current branch and " .. target_branch,
										filename = "info",
										filetype = "text",
									},
								}
							end
							diff_result = output

							local result = table.concat(diff_result, "\n")

							-- If there's no diff, return a meaningful message
							if not result or result == "" then
								return {
									{
										content = "No changes found between current branch and " .. target_branch,
										filename = "info",
										filetype = "text",
									},
								}
							end

							return {
								{
									content = result,
									filename = "pr_diff",
									filetype = "diff",
								},
							}
						end,
					},
					vectorcode = require("vectorcode.integrations.copilotchat").make_context_provider({
						-- Optional: customize the integration
						prompt_header = "Here's some relevant code from the repository:",
						prompt_footer = "\nBased on this context, please: \n",
						skip_empty = true, -- Skip when there are no results
					}),
				},
				-- Custom prompts incorporating git staged/unstaged functionality
				prompts = {
					-- Code related prompts
					Explain = {
						prompt = "Please explain how the following code works.",
						system_prompt = "You are an expert software developer and teacher. Explain the code in a clear, concise way.",
					},
					Review = {
						prompt = "Please review the following code and provide suggestions for improvement.",
						system_prompt = "You are an expert code reviewer. Focus on best practices, performance, and potential issues.",
					},

					GitHubReview = {
						prompt = "> #pr_diff\n\nPerform a comprehensive code review of the following git diff. Provide specific, actionable feedback in the form of individual comments targeted at specific lines and files. This review should cover code in Java (with a strong focus on Spring Boot), C++, Python, build systems (with a strong focus on Bazel), and infrastructure-as-code (IaC) configurations (e.g., GitHub Actions, YAML, JSON, Terraform, CloudFormation, Dockerfiles, Kubernetes manifests). Do NOT provide a general summary; focus on line-by-line analysis.",
						system_prompt = [[You are a senior software engineer/DevOps engineer performing a thorough code and infrastructure review. Your goal is to provide actionable feedback that improves quality, maintainability, performance, security, and reliability. You are reviewing changes for a colleague, so maintain a constructive and professional tone. You are an expert in a wide range of programming languages, scripting languages, build systems, and infrastructure-as-code technologies, with *deep expertise* in Java/Spring Boot, C++, Python, and Bazel.

    Input: You will receive a git diff representing changes in a pull request. The changes may include:

    *   Code in Java (especially Spring Boot), C++, Python, and other languages.
    *   Build system configurations (especially Bazel BUILD files).
    *   Infrastructure-as-Code configurations (e.g., GitHub Actions, YAML, JSON, Terraform, CloudFormation, Dockerfiles, Kubernetes manifests).
    *   Configuration files.
    *   Documentation.

    Output: Your output MUST be a series of individual comments, each formatted as follows:

    ```
    File: [File Path and Name]
    Line: [Line Number]
    Comment: [Your detailed review comment. Be specific and explain the reasoning behind your suggestion. Consider not only syntax and best practices, but also potential functional bugs, architectural improvements, maintainability, security, and operational concerns.]
    ```

    Examples (Illustrative - Adapt to the specific diff and technology):

    **Java (Spring Boot) - Dependency Injection:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Line: 25
    Comment: Instead of directly instantiating `MyDependency`, use constructor injection with `@Autowired` (or better, use constructor injection without `@Autowired` in modern Spring Boot). This improves testability and follows dependency injection best practices.
    ```

    **Java (Spring Boot) - REST Controller:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyController.java
    Line: 42
    Comment: Consider using `@Validated` on the request body and adding validation annotations (e.g., `@NotBlank`, `@Size`, `@Email`) to the `User` class (or a dedicated DTO) to ensure input is valid.  Add a `@RestControllerAdvice` to handle `MethodArgumentNotValidException` globally for consistent error responses.
    ```

    **Java (Spring Boot) - Exception Handling:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Line: 68
    Comment:  Catching `Exception` is generally too broad.  Catch more specific exceptions (e.g., `IOException`, `SQLException`) or create custom exceptions to handle different error scenarios appropriately.  Consider whether this method should throw a checked exception or wrap it in an unchecked exception (like `RuntimeException`).
    ```

    **Java - Variable Naming:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Line: 45
    Comment: The variable name `temp` could be more descriptive. Consider renaming it to something like `processedData` to improve readability.
    ```

    **Java - Missing Assertion:**
]]
							.. "    ```\n"
							.. [[    File: src/test/java/com/example/MyServiceTest.java
    Line: 120
    Comment: This test seems to be missing an assertion. Make sure to verify the expected outcome of the `processData` method. Consider adding an `assertEquals` or similar assertion.
    ```

   **Java/YAML - Hardcoded Secrets**
]]
							.. "    ```\n"
							.. [[    File: config/application.yml
    Line: 12
    Comment: The database password is hardcoded here. It is recomended to store secrets safely, consider using a secrets manager or environment variables.
    ```

    **C++ - Smart Pointers:**
]]
							.. "    ```\n"
							.. [[    File: src/engine/Renderer.cpp
    Line: 125
    Comment: Raw pointers are used here without explicit ownership semantics.  Use `std::unique_ptr` if ownership is exclusive, `std::shared_ptr` if ownership is shared, or `std::weak_ptr` to observe without owning. This prevents memory leaks and dangling pointers.
    ```

     **C++ - const correctness:**
]]
							.. "    ```\n"
							.. [[    File: include/utils/Math.h
    Line: 30
    Comment: The `calculateDistance` function does not modify the input vectors. Mark the parameters as `const` references (`const std::vector<double>&`) to improve code clarity and allow the function to accept `const` vectors.
    ```

    **C++ - Rule of Five/Zero:**
]]
							.. "    ```\n"
							.. [[    File: src/data/MyResource.cpp
    Line: 15
    Comment:  This class manages a resource (e.g., a dynamically allocated array).  You should implement the Rule of Five (or Rule of Zero if possible by using smart pointers).  Define (or delete) the copy constructor, copy assignment operator, move constructor, move assignment operator, and destructor to ensure proper resource management.
    ```

    **Python - List Comprehension:**
]]
							.. "     ```\n"
							.. [[    File: src/app.py
    Line: 22
    Comment:  Use a list comprehension for conciseness and often better performance: `squares = [x**2 for x in numbers if x > 0]`.
    ```

    **Python - Type Hints:**
]]
							.. "    ```\n"
							.. [[    File: src/utils/helper.py
    Line: 10
    Comment: Add type hints to the function signature to improve code readability and allow for static analysis: `def process_data(data: List[int], threshold: float) -> List[float]:`
    ```

    **Bazel - Dependency Management:**
]]
							.. "    ```\n"
							.. [[    File: BUILD
    Line: 20
    Comment: The `java_library` rule doesn't explicitly declare all its dependencies in the `deps` attribute.  List *all* direct dependencies (e.g., `@maven//:com_google_guava_guava`, `//src/main/java/com/example/lib:my_lib`).  Avoid relying on transitive dependencies for better build reproducibility and to prevent unexpected breakages.
    ```

     **Bazel - Visibility:**
]]
							.. "    ```\n"
							.. [[    File: BUILD
    Line: 35
    Comment: Consider making this target more restrictive. If it's only used within this package, use `visibility = ["//visibility:private"]`. If it's used by other packages within your project, use `visibility = ["//my_project/..."]`.  Avoid `//visibility:public` unless absolutely necessary.
    ```

    **Bazel - glob:**
]]
							.. "     ```\n"
							.. [[    File: BUILD
    Line: 12
    Comment: Using `glob` can lead to unexpected behavior if files are added or removed.  Consider explicitly listing source files or using `filegroup` for better control over the build graph. If you must use `glob`, be very specific with the patterns used.
    ```

    **GitHub Actions Example:**
]]
							.. "    ```\n"
							.. [[    File: .github/workflows/ci.yml
    Line: 35
    Comment: The `checkout` action uses the default depth. Consider using `fetch-depth: 0` to fetch the entire history, which may be necessary for some tools (e.g., linters that analyze commit history) or for accurate versioning (e.g., if you're using Git tags for releases).
    ```

    **Terraform Example:**
]]
							.. "    ```\n"
							.. [[    File: main.tf
    Line: 15
    Comment: The `aws_instance` resource does not have termination protection enabled. Consider setting `disable_api_termination = true` to prevent accidental deletion. Also, consider adding tags for better resource management and cost tracking.
    ```
     **JavaScript Example:**
]]
							.. "     ```\n"
							.. [[    File: src/components/MyComponent.jsx
    Line: 52
    Comment:  The state update here (`setCount(count + 1)`) might lead to unexpected behavior if multiple updates happen in quick succession.  Consider using the functional form of `setState`: `setCount(prevCount => prevCount + 1)` to ensure you're always working with the latest state.
    ```

    **Dockerfile Example:**
]]
							.. "     ```\n"
							.. [[    File: Dockerfile
    Line: 12
    Comment: Consider using a multi-stage build to reduce the final image size. A separate build stage can be used for compilation, and then only the necessary artifacts copied to the final runtime image.
    ```
 **Spring Boot Test Example:**
]]
							.. "     ```\n"
							.. [[    File: src/test/java/com/example/MyServiceTest.java
    Line: 30
    Comment:  `@SpringBootTest` loads the entire application context, which can make tests slow and introduce dependencies between tests.  Consider using more focused testing annotations like `@DataJpaTest` (for testing JPA repositories), `@WebMvcTest` (for testing Spring MVC controllers), or `@MockBean` to mock specific dependencies.  Only use `@SpringBootTest` when absolutely necessary for integration testing.
    ```
 **Spring Boot Test Example:**
]]
							.. "     ```\n"
							.. [[    File: src/test/java/com/example/RepositoryTest.java
    Line: 18
    Comment: Using TestBase Classes is not recomended, consider creating individual test classes to keep tests isolated.
    ```

    Key Considerations:

    *   Line-Specific Feedback: Each comment *must* be associated with a specific file and line number.
    *   Actionable Suggestions: Don't just point out problems; suggest concrete solutions.
    *   Beyond Syntax: Go beyond basic syntax checks. Consider:
        *   Functional Bugs: Look for logic errors, edge cases, and potential unexpected behavior.
        *   Architectural Improvements: Suggest better design patterns, improved modularity.
        *   Performance: Identify potential bottlenecks, inefficient algorithms or data structures.
        *   Maintainability: Assess code clarity, readability, documentation, and adherence to coding conventions.
        *   Security: Look for vulnerabilities (e.g., injection, cross-site scripting, insecure configurations, dependency vulnerabilities).
        *   Testing:  **Strong emphasis on test quality:**
            *   Check for adequate test coverage, missing test cases, well-written assertions, and appropriate mocking/stubbing.
            *   **Avoid `@SpringBootTest` overuse:**  Warn against using `@SpringBootTest` unless strictly necessary for integration testing.  Promote the use of more focused testing annotations like `@DataJpaTest`, `@WebMvcTest`, etc.
            *  **Discourage TestBaseclasses**: Warn about using TestBase classes.
            *   **Promote Mocking:** Encourage the use of mocking frameworks (like Mockito) to isolate units under test.
            *   **Verify Test Isolation:** Ensure that tests are truly isolated and do not depend on shared state or external resources.
        *   Operational Concerns (for IaC): Consider reliability, scalability, cost, and deployment/management.
        *   Build System Best Practices (especially Bazel):  Focus on dependency management (explicit `deps`), visibility control, efficient build rules, avoiding `glob` overuse, and hermeticity.
        *   Language-Specific Best Practices:
            *   **Java/Spring Boot:** Dependency injection, proper exception handling, validation, REST API best practices, use of Spring Boot features (e.g., `@ConfigurationProperties`, `@Enable*` annotations), efficient data access (e.g., using Spring Data JPA), security best practices (e.g., Spring Security).  **Emphasize appropriate use of Spring testing annotations.**
            *   **C++:**  Memory management (smart pointers), const correctness, Rule of Five/Zero, modern C++ features (C++11/14/17/20/23), avoiding undefined behavior, exception safety.
            *  **Python**: List comprehension, type hints.
        *   Professional Tone: Be constructive and respectful.
        *   Context Awareness: Understand the overall purpose of the changes.
       * **Microservices Considerations**: If you detect inter-service communication (like gRPC calls), make sure to check the contract.
       * **Gradle Build**: When adding dependecies, remind to use version catalog.
       * **Synchronous Remote Calls**: When detecting synchronous remote calls (e.g., gRPC), remind the developer about the implications and to be mindful of the performance and potential for cascading failures.

    Optimization for Gemini 2.0 Flash:

    *   Clear, Concise Instructions: The prompt is structured clearly.
    *   Specific Output Format: The required format is explicitly defined.
    *   Emphasis on Actionable Feedback: Stress the need for concrete suggestions.
    * Avoid Summaries: Explicitly avoid providing general summaries.
    * Multiple, Detailed Examples: Provide numerous examples for each key area, showing the desired level of detail and specificity.
    ]],
					},
					TaskHandoverReview = {
						prompt = "> #pr_diff\n\nAnalyze the provided git diff with the goal of understanding the implemented solution. For each changed file, and within each file for significant code blocks (a group of related lines), provide two explanations: one focusing on the *coding changes* (what was changed in the code itself) and another on the *functional changes* (how the user-facing behavior or system operation is affected, or the purpose of the change). After these explanations, generate targeted questions for the original author, particularly focusing on any unconventional, complex, or potentially problematic aspects of the solution. Do not provide a general summary.  Focus on detailed explanations per file and, within each file, per code block.",
						system_prompt = [[You are a senior software engineer taking over a partially completed task. Your goal is to thoroughly understand the existing solution so you can continue development effectively. You are reviewing changes made by a colleague, so maintain a constructive and professional tone. You are an expert in a wide range of programming languages, scripting languages, build systems, and infrastructure-as-code technologies, with deep expertise in Java/Spring Boot, C++, Python, and Bazel.

    Input: A git diff representing changes made to the codebase. The changes may include:

    *   Code in Java (especially Spring Boot), C++, Python, and other languages.
    *   Build system configurations (especially Bazel BUILD files).
    *   Infrastructure-as-Code configurations (e.g., GitHub Actions, YAML, JSON, Terraform, CloudFormation, Dockerfiles, Kubernetes manifests).
    *   Configuration files.
    *   Documentation.

    Output: Your output MUST be a series of individual entries, each formatted as follows:

    ```
    File: [File Path and Name]
    Code Block: [Line Numbers, or a range like 10-20] (Use a range for multi-line changes.  Use a single line number for single-line changes, or when focusing on a specific line within a larger context.)
    Coding Explanation: [Detailed explanation of the code changes. Describe *what* was changed at the code level. Be precise and refer to specific lines, variable names, function calls, etc.]
    Functional Explanation: [Detailed explanation of the functional impact. Describe *how* the changes affect the user, system behavior, or external interactions. Explain the purpose or reason *why* the change was made.]
    Questions:
        - [Question 1 about a specific, potentially unclear, or non-standard aspect of this code block or file.  Focus on the *intent* or *reasoning* behind the code.]
        - [Question 2, if applicable, about another specific aspect (e.g., potential edge cases, performance implications, alternative solutions considered).]
        ... (Continue with more questions as needed)
    ```

    Examples (Illustrative - Adapt to the specific diff and technology):

    **Java (Spring Boot) - New Endpoint:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyController.java
    Code Block: 25-35
    Coding Explanation: A new REST endpoint `/api/users/{id}` (GET request) was added. It retrieves a user by ID from `MyService` and returns it. The new method `getUserById` was added to the controller, using Spring's `@GetMapping` and `@PathVariable` annotations.
    Functional Explanation: This exposes a new API endpoint allowing clients to retrieve user details by providing a user ID in the URL. This enables user data retrieval by ID.
    Questions:
        - Is there error handling in `MyService.getUserById` if the user is not found? Should this endpoint return a 404 Not Found in that case?
        - Are there any security considerations for this endpoint (e.g., authentication, authorization)? Should access be restricted?
    ```

    **Java (Spring Boot) - Service Logic Change:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Code Block: 42-50
    Coding Explanation: The `processData` method now includes an additional check for `data.isEmpty()` before the main processing logic. If the data is empty, it logs a warning and returns an empty list.
    Functional Explanation: The system now handles cases where input data is empty gracefully, preventing potential errors. The change avoids processing of empty data sets, which might have been unintentional or erroneous.
    Questions:
        - Is returning an empty list the *best* way to handle empty input data? Should an exception be thrown, or a different return value (e.g., null, or a special object) be used?
        - What is the upstream source of `data`? Could the emptiness be handled earlier?
    ```

    **C++ - Algorithm Change:**
]]
							.. "    ```\n"
							.. [[    File: src/engine/Calculator.cpp
    Code Block: 100-115
    Coding Explanation: The `calculateDistance` function was modified to use a different algorithm. Instead of Euclidean distance, it now uses Manhattan distance. The code sums the absolute differences of the coordinates.
    Functional Explanation: The calculated distance between two points will now be different, reflecting a "city block" distance rather than a straight-line distance. This impacts any feature relying on this distance calculation (e.g., pathfinding).
    Questions:
        - Why was Manhattan distance chosen over Euclidean distance? What requirement or use case motivated this change?
        - Are there unit tests covering this change, and were the expected values updated?
    ```

    **Bazel - New Dependency:**
]]
							.. "    ```\n"
							.. [[    File: BUILD
    Code Block: 15-18
    Coding Explanation: A new dependency, `@maven//:com_google_guava_guava`, was added to the `java_library` rule for `//src/main/java/com/example/mylib:my_library`.
    Functional Explanation: The `my_library` code can now use classes from the Guava library. This might introduce new functionality or change existing behavior if Guava is used to replace existing logic.
    Questions:
        - What specific parts of Guava are being used, and for what purpose? (Knowing this helps understand the scope.)
        - Was there a reason for choosing Guava over other libraries or built-in functionality?
    ```

	**Terraform - Resource Modification:**
]]
							.. "	```\n"
							.. [[	File: main.tf
	Code Block: 20-25
	Coding Explanation: The `aws_instance` resource named `my_instance` now has `instance_type` set to `t3.small` and `disable_api_termination` set to `true`.
	Functional Explanation: Newly created EC2 instances will be of type `t3.small`. The instance is protected against accidental termination via the API or console.
	Questions:
		- Why was the instance type changed to `t3.small`? Was the previous instance type under- or over-provisioned?
		- Were there any instances created before `disable_api_termination` was set, and are they also protected?
	```

    **GitHub Actions - Workflow Change:**
]]
							.. "    ```\n"
							.. [[    File: .github/workflows/ci.yml
    Code Block: 30-40
    Coding Explanation: The `checkout` action now includes `fetch-depth: 0`. The build step now uses `bazel build //... --test_output=errors`.
    Functional Explanation: The workflow now fetches the complete Git history. The build process only prints test errors, making the logs less verbose.
    Questions:
        - Why is fetching the entire Git history necessary now? Is a tool being used that depends on it (e.g., versioning)?
        - What motivated the change to `--test_output=errors`? Was the build output too noisy?
    ```
	**JavaScript Example - React Component:**
]]
							.. "    ```\n"
							.. [[    File: src/components/MyComponent.jsx
    Code Block: 40-55
	Coding Explanation: The component's state management changed. It was refactored from a simple `useState` to handling the previous state in the update function.
    Functional Explanation: The component can now correctly manage state updates, even with rapid updates, avoiding race conditions.
    Questions:
        - What specific scenario prompted this change to use the functional form of `setState`?
		- Are there any asynchronous operations affecting this component's state?
    ```
	**Python Example - List Comprehension:**
]]
							.. "    ```\n"
							.. [[    File: src/utils/data_processing.py
    Code Block: 18-22
	Coding Explanation: A for loop that iterated through data and calculated filtered squares was replaced with a list comprehension.
    Functional Explanation: This improves code conciseness and potentially readability, and may offer performance benefits in some cases.
    Questions:
        - Was there a performance benchmark done between the for loop and list comprehension?
		- Could the previous logic have returned unexpected values in any edge cases?
    ```

    **C++ - Include and Function Signature Change (from provided diff):**
]]
							.. "    ```\n"
							.. [[    File: include/some_header.hpp
    Code Block: 5
    Coding Explanation: The `#include <some_container>` directive was changed to `#include <another_container>`.
    Functional Explanation: This suggests a change in the underlying data structure used. Different containers have different performance characteristics for insertion, deletion, search, and iteration. The choice impacts how data is stored and accessed.
    Questions:
        - Why was `another_container` chosen over `some_container`? What specific properties of `another_container` are beneficial here (e.g., ordering, constant-time lookup, memory usage)?
        - Does this change require modifications in other parts of the code that use this header file?
    ```
]]
							.. "    ```\n"
							.. [[    File: include/data_processor.hpp
    Code Block: 30
    Coding Explanation: The return type of the `processData` method was changed from `void` to `DataType`. The method signature now also receives a `ConfigObject` as input parameter.
    Functional Explanation: The function now returns a value of type `DataType`, indicating that the processing now generates and returns data. It also receives configuration, suggesting its behavior can be customized.
    Questions:
        - What does the `DataType` value represent? What information does it contain?
        - How is the returned `DataType` used by the caller of `processData`?
        - What aspects of the processing are controlled by the `ConfigObject`?
    ```
]]
							.. "    ```\n"
							.. [[    File: src/data_processor.cpp
    Code Block: 50-60
    Coding Explanation: The constructor of `DataProcessor` now calls `processData` and stores the result in a member variable `processed_data_`. This member variable is then passed to another function, `externalFunction`.
    Functional Explanation: The `DataProcessor` is now using the result of `processData` to initialize its internal state and to interact with `externalFunction`. This suggests that `externalFunction` depends on the processed data.
    Questions:
        - What is the role of `externalFunction`? How does the `processed_data_` affect its behavior?
        - Is there a performance implication of storing `processed_data_`? Could it be large, and is it needed for the lifetime of the `DataProcessor` object?
    ```

]]
							.. "    ```\n"
							.. [[    File: src/utility_functions.cpp
    Code Block: 75-85
    Coding Explanation: The `helperFunction` method now initializes a local variable `result` of type `ContainerType`. The method's core logic remains the same, however at the end of the method execution, `result` is returned.
    Functional Explanation: This change makes the method return a collection of data. The internal processing logic hasn't changed in purpose, but the method now provides its output as a return value rather than through (for example) modifying a passed-in parameter.
    Questions:
      - Why does `helperFunction` return `result` and what plans are there for future implementation. It is currently not filled.
      - The old return type was `void`. Was this method performing some side effect, that has now moved to a different place? Or was it refactored to be more functional, avoiding side effects?
    ```

]]
							.. "    ```\n"
							.. [[    File: include/converter.hpp
    Code Block: 8
    Coding Explanation: The `#include <set>` directive was changed to `#include <unordered_set>`.
    Functional Explanation: This suggests a potential change in how a set of data is stored and accessed.  `std::set` uses a sorted tree structure (typically a red-black tree), providing logarithmic time complexity for insertion, deletion, and search. `std::unordered_set` uses a hash table, providing average constant-time complexity for these operations, but without maintaining any specific order.  The choice between them impacts performance characteristics.
    Questions:
        - Why was `unordered_set` chosen over `set`?  Was the ordering of elements not needed, and was the potential performance gain of hashing considered significant?
        - Does this change have any implications for the rest of the code that uses this header?
    ```
]]
							.. "    ```\n"
							.. [[    File: include/converter.hpp
    Code Block: 26
    Coding Explanation: The `SetupConversionConfiguration` method's return type was changed from `void` to `std::unordered_set<std::uint32_t>`. The method signature now receives a `std::vector<io::ConversionMap>` as input.
    Functional Explanation: The function now returns a set of 32-bit unsigned integers, likely representing some form of IDs or identifiers. This indicates that the setup process is now generating and returning some data, where previously it did not return anything.
    Questions:
        - What do the `uint32_t` values in the returned `unordered_set` represent?  Are these message IDs, filter IDs, or something else?
        - How is this returned `unordered_set` used by the caller of `SetupConversionConfiguration`?
        - Was the method changed to avoid side effects and make the data flow more explicit?
    ```
]]
							.. "    ```\n"
							.. [[    File: src/converter.cpp
    Code Block: 117-121
    Coding Explanation: The `Converter` constructor now calls `SetupConversionConfiguration` and stores the returned value in a variable named `raw_data_values`. This variable is then passed as the last argument to `codec::CodecFactory::GetCodec`. The arguments for the `GetCodec` are now on separate lines for better readability.
    Functional Explanation: The `Converter` is now using the result of `SetupConversionConfiguration` (presumably a set of values) to configure the codec.  This suggests that the codec's behavior is being customized based on the conversion configuration.
    Questions:
        - What is the role of `raw_data_values` in the `Codec`?  How does this set of IDs affect the codec's behavior?  Does it values data, or control some other aspect of encoding/decoding?
        - Is there a performance impact of passing a potentially large `unordered_set` to `GetCodec`? Could this be optimized if needed?
    ```

]]
							.. "    ```\n"
							.. [[    File: src/converter.cpp
    Code Block: 123-128
    Coding Explanation: The `SetupConversionConfiguration` method now declares a local variable `message_ids_to_convert` of type `std::unordered_set<std::uint32_t>`. The method still has the same logic for calculating `required_source_message_ids_per_trigger_id_`, `required_source_messages_for_buffer_` and `message_buffer_required_`, but returns the new local variable in the end.
    Functional Explanation:  This change prepares the method to return a set of message IDs. The core logic of determining required messages and buffer requirements remains unchanged, but the method's output now includes this additional information.
    Questions:
      - Why does `SetupConversionConfiguration` now return `message_ids_to_convert` and what are the future plans to fill this value? It is currently empty.
      -  The old return type was `void`. Was this method performing some side effect, that has now moved to a different place? Or was it refactored to be more functional, avoiding side effects?
    ```

    Key Considerations:

    *   **Granularity:** Provide explanations at a level of detail appropriate for understanding each change, down to individual lines or groups of lines.
    *   **Coding vs. Functional:** Clearly separate the *code-level* changes from the *functional* impact.
    *   **Targeted Questions:** Focus questions on the *intent*, *reasoning*, and *potential implications* of changes. Ask "why" questions.
    *   **Contextual Awareness:** Consider the surrounding code and the overall system.
    *   **Professional Tone:** Maintain a constructive and respectful tone.
    *   **Microservices Considerations:** If inter-service communication (like gRPC calls) is detected, focus on data exchange and consistency.
    * **Gradle Build:** When adding dependencies, focus questions on the purpose of the new dependency.
    * **Synchronous Remote Calls:** Focus questions on the purpose of these calls and their impact on performance.
    * **Assumptions:** If you have to *guess* at the purpose, state your assumption and frame questions to confirm or refute it.
	* **Diff navigation**: The prompt is designed to be used with diff hunks, one at a time, or potentially with an entire diff file (if the model's context window allows).

    Optimization for Gemini 2.0 Flash:

    *   **Clear, Concise Instructions:** The prompt is structured logically, with clear sections.
    *   **Specific Output Format:** The required output format is precisely defined.
    *   **Separate Explanations:** The distinct coding and functional explanations are key.
    *   **Question Generation:** Explicitly requesting focused questions is crucial.
    *   **Multiple, Diverse Examples:** The examples cover many scenarios and help guide the model. The new examples based on the provided diff are *very* important, as they show the model exactly what kind of analysis is expected for C++ code.
    ]],
					},
					Tests = {
						prompt = "Please explain how the selected code works, then generate unit tests for it.",
						system_prompt = "You are an expert in software testing. Generate thorough test cases covering edge cases.",
					},
					Refactor = {
						prompt = "Please refactor the following code to improve its clarity and readability.",
						system_prompt = "You are an expert in code refactoring. Focus on making the code more maintainable and easier to understand.",
					},
					FixCode = {
						prompt = "Please fix the following code to make it work as intended.",
						system_prompt = "You are an expert programmer. Help fix code issues while maintaining code style and best practices.",
					},
					FixError = {
						prompt = "Please explain the error in the following text and provide a solution.",
						system_prompt = "You are an expert in debugging. Help identify and fix the error while explaining the solution.",
					},
					BetterNamings = {
						prompt = "Please provide better names for the following variables and functions.",
						system_prompt = "You are an expert in code readability. Suggest clear, descriptive names following naming conventions.",
					},
					Documentation = {
						prompt = "Please provide documentation for the following code.",
						system_prompt = "You are an expert technical writer. Create clear, comprehensive documentation.",
					},
					SwaggerApiDocs = {
						prompt = "Please provide documentation for the following API using Swagger.",
						system_prompt = "You are an expert in API documentation. Create comprehensive Swagger/OpenAPI documentation.",
					},
					SwaggerJsDocs = {
						prompt = "Please write JSDoc for the following API using Swagger.",
						system_prompt = "You are an expert in JavaScript documentation. Create comprehensive JSDoc with Swagger annotations.",
					},
					SwaggerApiSpringDocs = {
						prompt = "Please generate Spring Boot REST controller method annotations (for OpenAPI 3 specification) for the following Java method. Include annotations for request parameters, response types, and descriptions. Consider the method's purpose and parameters to create appropriate annotations.",
						system_prompt = [[You are an expert in Java and Spring Boot REST API documentation using OpenAPI 3.  You will be provided with a Java method signature and potentially some surrounding context. Your task is to generate the appropriate Spring Boot annotations to fully document that method for OpenAPI generation using a library like springdoc-openapi-ui.

                        Focus on these key annotations:

                        *   `@Operation`:  Provide a `summary` (short description) and a more detailed `description`.
                        *   `@Parameter`: For each method parameter, use `@Parameter` to describe it.  Include `description`, `required` (if applicable), and `in` (e.g., `ParameterIn.PATH`, `ParameterIn.QUERY`, `ParameterIn.HEADER`, `ParameterIn.COOKIE`).
                        *   `@ApiResponses`: Define possible API responses. Use `@ApiResponse` for each status code (e.g., 200, 400, 404, 500). Include a `description` and, importantly, a `content` attribute specifying the `@Content` (media type and schema).
                        *   `@RequestBody`: If the method accepts a request body, use `@RequestBody` to describe it.  Include a `description` and `content` (with media type and schema).
                        * `@Schema`: Use to fully define return types.
                        *   `@PathVariable`: Use as needed with `@Parameter` for path variables.
                        *   `@RequestParam`: Use as needed with `@Parameter` for query parameters.
                        *   `@RequestHeader`:  Use as needed with `@Parameter` for header parameters.
                        *  Consider adding the annotation @Tag to improve documentation.

                        Example:

                        Input Java Method:
                        ```java
                        public ResponseEntity<User> getUserById(long id) {
                            // ... implementation ...
                        }
                        ```

                        Desired Output Annotations:
                        ```java
                        @Operation(summary = "Get a user by ID", description = "Retrieves a user based on their unique identifier.")
                        @ApiResponses(value = {
                            @ApiResponse(responseCode = "200", description = "Successful operation",
                                    content = @Content(mediaType = "application/json",
                                            schema = @Schema(implementation = User.class))),
                            @ApiResponse(responseCode = "404", description = "User not found",
                                    content = @Content)
                        })
                        public ResponseEntity<User> getUserById(
                            @Parameter(description = "The ID of the user to retrieve.", required = true, in = ParameterIn.PATH)
                            @PathVariable long id
                        ) {
                            // ... implementation ...
                        }
                        ```
                    ]],
					},
					-- Git related prompts
					Commit = {
						prompt = "> #git:staged\n\n" .. string.format(commit_prompt, "change"),
						system_prompt = "You are an expert in writing clear, concise git commit messages following best practices.",
					},
					CommitStaged = {
						prompt = "> #git:staged\n\n" .. string.format(commit_prompt, "staged changes"),
						system_prompt = "You are an expert in writing clear, concise git commit messages following best practices.",
					},
					CommitUnstaged = {
						system_prompt = "You are an expert in writing clear, concise git commit messages following best practices.",
					},
					PullRequest = {
						prompt = "> #pr_diff\n\nWrite a pull request description for these changes. Include a clear title, summary of changes, and any important notes.",
						system_prompt = [[You are an experienced software engineer about to open a PR. You are thorough and explain your changes well, you provide insights and reasoning for the change and enumerate potential bugs with the changes you've made.

          Your task is to create a pull request for the given code changes. Follow these steps:

          1. Analyze the git diff changes provided.
          2. Draft a comprehensive description of the pull request based on the input.
          3. Create the gh CLI command to create a GitHub pull request.

          Output Instructions:
          - The command should start with `gh pr create`.
          - Do not use the new line character in the command since it does not work
          - Output needs to be a multi-line command
          - Include the `--base $(git parent)` flag
          - Use the `--title` flag with a concise, descriptive title matching the commitzen convention.
          - Use the `--body` flag for the PR description.
          - Include the following sections in the body:
            - '## Summary' with a brief overview of changes
            - '## Changes' listing specific modifications
            - '## Additional Notes' for any extra information
          - Escape any backticks in the message body to avoid shell interpretation issues
          - Wrap the entire command in a code block for easy copy-pasting.

          Desired Output:
          ```sh
          gh pr create \
            --base $(git parent) \
            --title "feat: your title here" \
            --body "## Summary
          Your summary here

          ## Changes
          - Change 1
          - Change 2
          - Change 3 \`with backticks\`

          ## Additional Notes
          Your notes here"
          ```]],
					},
					CustomPullRequest = {
						prompt = "> #pr_diff\n\nWrite a pull request description for these changes. Include a clear title, summary of changes, and any important notes.",
						system_prompt = [[You are an experienced software engineer about to open a PR. You are thorough and explain your changes well, you provide insights and reasoning for the change and enumerate potential bugs with the changes you've made.

    Your task is to create a pull request for the given code changes. Follow these steps:

    1. Analyze the git diff changes provided.
    2. Draft a comprehensive description of the pull request based on the input.  **Crucially, structure the description according to the template below.**
    3. Create the gh CLI command to create a GitHub pull request.

    Output Instructions:
    - The command should start with `gh pr create`.
    - Do not use the new line character in the command since it does not work
    - Output needs to be a multi-line command
    - Include the `--base $(git parent)` flag
    - Use the `--title` flag with a concise, descriptive title matching the commitzen convention.
    - Use the `--body` flag for the PR description.
    - Include the following sections in the body:
      - '#### Why?' explaining the *reason* for the proposed change.  Why is this change necessary or beneficial?
      - '#### What?' providing a *high-level overview* of what the PR changes.  Don't just repeat the diff, but describe the changes conceptually.
    - Escape any backticks in the message body to avoid shell interpretation issues
    - Wrap the entire command in a code block for easy copy-pasting.

    Desired Output:
    ```sh
    gh pr create \
      --base $(git parent) \
      --title "feat: your title here" \
      --body "#### Why?

    _Your reasoning for the changes goes here._

    #### What?

    _A high-level description of the changes goes here.  Example:  This PR refactors the user authentication module to improve security and maintainability. It replaces the old hashing algorithm with a more robust one and adds input validation to prevent common injection attacks._
    "
    ```]],
					},
					-- Text related prompts
					Summarize = {
						prompt = "Please summarize the following text.",
						system_prompt = "You are an expert in technical writing. Create clear, concise summaries.",
					},
					Spelling = {
						prompt = "Please correct any grammar and spelling errors in the following text.",
						system_prompt = "You are an expert editor. Fix grammar and spelling while maintaining the original meaning.",
					},
					Wording = {
						prompt = "Please improve the grammar and wording of the following text.",
						system_prompt = "You are an expert writer. Improve clarity and readability while maintaining the original meaning.",
					},
					Concise = {
						prompt = "Please rewrite the following text to make it more concise.",
						system_prompt = "You are an expert in technical writing. Make the text more concise while preserving key information.",
					},
				},
			}
		end,
		config = function(_, opts)
			local chat = require("CopilotChat")
			local select = require("CopilotChat.select")

			-- Disable line numbers in chat window
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "copilot-chat",
				callback = function()
					vim.opt_local.relativenumber = false
					vim.opt_local.number = false
				end,
			})

			-- Create commands for visual mode
			vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
				chat.ask(args.args, { selection = select.visual })
			end, { nargs = "*", range = true })

			-- Inline chat with Copilot
			vim.api.nvim_create_user_command("CopilotChatInline", function(args)
				chat.ask(args.args, {
					selection = select.visual,
					window = {
						layout = "float",
						relative = "cursor",
						width = 1,
						height = 0.4,
						row = 1,
					},
				})
			end, { nargs = "*", range = true })

			chat.setup(opts)
		end,
	},
	{
		"ravitemer/mcphub.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		cmd = { "MCPHub" },
		build = "npm install -g mcp-hub@latest",
		config = function()
			require("mcphub").setup({
				port = 3000,
				auto_approve = true,
				extensions = {
					avante = {
						auto_approve_mcp_tool_calls = true, -- Auto approves mcp tool calls.
					},
				},
				-- log = {
				-- 	level = vim.log.levels.DEBUG,
				-- 	to_file = true,
				-- 	file_path = "~/mcphub.log",
				-- },
			})
		end,
	},

	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		build = "make",
		opts = {
			debug = false,
			behaviour = {
				support_paste_from_clipboard = true,
				enable_token_counting = false,
			},
			disabled_tools = {
				"list_files",
				"search_files",
				"read_file",
				"create_file",
				"rename_file",
				"delete_file",
				"create_dir",
				"rename_dir",
				"delete_dir",
				"bash",
				"fetch",
				"git_diff",
				"git_commit",
				"execute_command",
				"write_file",
			},
			-- Using function prevents requiring mcphub before it's loaded
			custom_tools = function()
				return {
					require("mcphub.extensions.avante").mcp_tool(),
				}
			end,
			-- system_prompt as function ensures LLM always has latest MCP server state
			-- This is evaluated for every message, even in existing chats
			system_prompt = function()
				local hub = require("mcphub").get_hub_instance()
				if not hub then
					os.execute("sleep 60")
				else
					return hub:get_active_servers_prompt()
				end
			end,
			provider = "copilot",
			mode = "legacy",
			cursor_applying_provider = "groq",
			auto_suggestions_provider = "gemini",
			providers = {
				deepseek = {
					__inherited_from = "openai",
					api_key_name = "DEEPSEEK_CHAT_API_KEY",
					endpoint = "https://api.deepseek.com",
					model = "deepseek-chat",
					timeout = 1200000,
					extra_request_body = {
						max_tokens = 8192,
						temperature = 0.5,
						stream = true,
						stream_options = {
							include_usage = false,
						},
					},
				},
				groq = { -- define groq provider
					__inherited_from = "openai",
					api_key_name = "GROQ_API_KEY",
					endpoint = "https://api.groq.com/openai/v1/",
					model = "llama-3.3-70b-versatile",
					extra_request_body = {
						max_completion_tokens = 32768, -- remember to increase this value, otherwise it will stop generating halfway
					},
				},
				mercury = {
					__inherited_from = "openai",
					api_key_name = "MERCURY_API_KEY",
					endpoint = "https://api.inceptionlabs.ai/v1",
					model = "mercury-coder",
					extra_request_body = {
						-- max_tokens = 32000, -- remember to increase this value, otherwise it will stop generating halfway
						max_tokens = 2600,
						temperature = 0,
						stream = true,
						diffusing = false,
						stream_options = {
							include_usage = false,
						},
					},
				},
				openai = {
					-- model = "gpt-4.1-nano",
					model = "gpt-4.1-mini",
					-- model = "gpt-4.1",
					-- model = "o3",
					timeout = 1200000,
					extra_request_body = {
						temperature = 0.7,
						max_completion_tokens = 32768,
						-- reasoning_effort = "high",
					},
				},
				copilot = {
					-- model = "gpt-4.1",
					model = "claude-sonnet-4",
					timeout = 1200000,
					extra_request_body = {
						temperature = 0.2,
						max_tokens = 32768,
					},
				},
				gemini = {
					model = "gemini-2.0-flash-lite",
					timeout = 1200000,
					extra_request_body = {
						temperature = 0.7,
					},
				},
			},
			rag_service = {
				enabled = false, -- Enables the RAG service
				llm = {
					host_mount = os.getenv("HOME") .. "/Workspace/py-adp/", -- Host mount path for the rag service
					provider = "openai", -- The provider to use for RAG service (e.g. openai or ollama)
					extra = { -- Extra configuration options for the LLM (optional)
						max_completion_tokens = 32768,
						temperature = 0.3, -- Controls the randomness of the output. Lower values make it more deterministic.
						timeout = 120, -- Request timeout in seconds.
					},
				},
				embed = {
					model = "text-embedding-3-large", -- The embedding model to use for RAG service
					dimensions = 1024,
				},
			},
			dual_boost = {
				enabled = true,
				first_provider = "deepseek",
				second_provider = "mercury",
				timeout = 3600000, -- Timeout in milliseconds
			},
			windows = {
				width = 45, -- Width of the sidebar
				height = 40, -- Height of the sidebar
				sidebar_header = {
					enabled = false,
				},
				ask = {
					start_insert = false,
				},
			},
			selector = {
				provider = "fzf_lua",
			},
			on_error = function(err)
				vim.notify("Avante error: " .. err, vim.log.levels.INFO)
			end,
		},
		dependencies = {
			"ravitemer/mcphub.nvim",
			"augmentcode/augment.vim",
			"catppuccin/nvim",
			{ "stevearc/dressing.nvim", lazy = true },
			{ "nvim-lua/plenary.nvim", lazy = true },
			{ "MunifTanjim/nui.nvim", lazy = true },
			{ "nvim-tree/nvim-web-devicons", lazy = true },
			"hrsh7th/nvim-cmp",
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
		"augmentcode/augment.vim",
		event = { "InsertEnter" },
		config = function()
			local cwd = vim.loop.cwd()
			vim.g.augment_workspace_folders = { cwd }

			-- Disable auto-complete to use copilot for auto-complete
			-- 1) disable the entire suggestion engine:
			vim.g.augment_disable_completions = true
			-- 2) turn off Augment’s Tab-to-accept mapping:
			-- vim.g.augment_disable_tab_mapping = true

			-- Chat commands
			vim.keymap.set("n", "<leader>ac", ":Augment chat<CR>", { desc = "Augment chat" })
			vim.keymap.set(
				"v",
				"<leader>ac",
				":Augment chat<CR>",
				{ desc = "Argument chat buffer", noremap = true, silent = true }
			)
			vim.keymap.set("n", "<leader>an", ":Augment chat-new<CR>", { desc = "Augment new chat" })
			vim.keymap.set("n", "<leader>at", ":Augment chat-toggle<CR>", { desc = "Augment toggle chat" })

			-- Accept completion with Ctrl-y
			vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<cr>", { desc = "Accept Augment suggestion" })
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			file_types = {
				"Avante",
				"markdown",
				"copilot-chat",
			},
		},
		ft = {
			"Avante",
			"markdown",
			"copilot-chat",
		},
		config = function(_, opts)
			require("render-markdown").setup(opts)
		end,
	},

	{
		"toppair/peek.nvim",
		ft = { "markdown" },
		build = "deno task --quiet build:fast",
		opts = { theme = "dark", filetype = { "markdown", "pandoc" }, app = "firefox" },
		main = "peek",
		keys = {
			{
				"mp",
				function()
					local peek = require("peek")
					if peek.is_open() then
						peek.close()
					else
						peek.open()
					end
				end,
			},
			mode = "n",
		},
		cond = function()
			return vim.fn.executable("deno") ~= 0
		end,
	},
	{
		"hedyhli/markdown-toc.nvim",
		ft = { "markdown" },
		opts = { headings = { before_toc = false } },
	},
	{
		"Myzel394/easytables.nvim",
		cmd = { "EasyTablesCreateNew", "EasyTablesImportThisTable" },
		opts = {},
	},
	{
		"cameron-wags/rainbow_csv.nvim",
		config = true,
		ft = {
			"csv",
			"tsv",
			"csv_semicolon",
			"csv_whitespace",
			"csv_pipe",
			"rfc_csv",
			"rfc_semicolon",
		},
		cmd = {
			"RainbowDelim",
			"RainbowDelimSimple",
			"RainbowDelimQuoted",
			"RainbowMultiDelim",
		},
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
			on_error = function(err)
				vim.notify("CMake Tools error: " .. err, vim.log.levels.ERROR)
			end,
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
				header_extension = "hpp",
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
	{
		"zaucy/bazel.nvim",
		opts = {},
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
