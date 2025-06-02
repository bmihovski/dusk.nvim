local cmp = require("cmp")
local cmp_autopairs = require("nvim-autopairs.completion.cmp")

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

-- import luasnip plugin safely
local luasnip_status, luasnip = pcall(require, "luasnip")
if not luasnip_status then
	return
end

-- load VSCode-like snippets from plugins (e.g., friendly-snippets)
require("luasnip/loaders/from_vscode").lazy_load()

local ts_utils = require("nvim-treesitter.ts_utils")

local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local f = luasnip.function_node

local function copy(args)
	return args[1]
end

local function get_class_name()
	local bufnr = vim.api.nvim_get_current_buf()
	local curr = ts_utils.get_node_at_cursor()
	local expr = curr
	while expr do
		if expr:type() == "class_specifier" or expr:type() == "struct_specifier" then
			break
		end
		expr = expr:parent()
	end
	if not expr then
		return ""
	end
	return vim.treesitter.get_node_text(expr:child(1), bufnr)
end

local c_cpp_snippets = {
	s("disablecopymove", {
		t({ "// disable copy and move", "" }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "(const " }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "&) = delete;", "" }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "(" }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "&&) = delete;", "" }),
		f(function()
			return get_class_name()
		end),
		t({ "& operator=(const " }),
		f(function()
			return get_class_name()
		end),
		t({ "&) = delete;", "" }),
		f(function()
			return get_class_name()
		end),
		t({ "& operator=(" }),
		f(function()
			return get_class_name()
		end),
		t({ "&&) = delete;", "" }),
	}),
	s("defaultcopymove", {
		t({ "// default copy and move", "" }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "(const " }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "&) = default;", "" }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "(" }),
		f(function()
			return get_class_name()
		end, {}, {}),
		t({ "&&) = default;", "" }),
		f(function()
			return get_class_name()
		end),
		t({ "& operator=(const " }),
		f(function()
			return get_class_name()
		end),
		t({ "&) = default;", "" }),
		f(function()
			return get_class_name()
		end),
		t({ "& operator=(" }),
		f(function()
			return get_class_name()
		end),
		t({ "&&) = default;", "" }),
	}),
	s({
		trig = "#ifdef condition",
		name = "Snippet for C/C++ condition macro",
	}, {
		t("#ifdef "),
		i(1, "condition"),
		t({ "", "", "" }),
		i(0),
		t({ "", "", "#endif  // " }),
		f(copy, { 1 }),
	}),
	s({
		trig = "if (condition)",
		name = "Snippet for C/C++ if statement",
	}, {
		t("if ("),
		i(1, "condition"),
		t(") {"),
		t({ "", "  " }),
		i(2),
		t({ "", "}", "" }),
		i(0),
	}),
	s({
		trig = "if-else",
		name = "Snippet for C/C++ if-else statement",
	}, {
		t("if ("),
		i(1, "condition"),
		t(") {"),
		t({ "", "  " }),
		i(2),
		t({ "", "} else {" }),
		t({ "", "  " }),
		i(3),
		t({ "", "}", "" }),
		i(0),
	}),
	s({
		trig = "if-elif",
		name = "Snippet for C/C++ if-elif statement",
	}, {
		t("if ("),
		i(1, "condition"),
		t(") {"),
		t({ "", "  " }),
		i(3),
		t({ "", "} else if (" }),
		i(2),
		t(") {"),
		t({ "", "  " }),
		i(4),
		t({ "", "} else {" }),
		t({ "", "  " }),
		i(5),
		t({ "", "}", "" }),
		i(0),
	}),
	s({
		trig = "elif",
		name = "Snippet for C/C++ elif statement",
	}, {
		t({ "else if (" }),
		i(1),
		t(") {"),
		t({ "", "  " }),
		i(2),
		t({ "", "}" }),
	}),
}

luasnip.add_snippets("cpp", c_cpp_snippets)

local lspkind_format = require("lspkind").cmp_format({
	mode = "symbol_text",
	maxwidth = 50,

	symbol_map = {
		Text = "󰉿",
		Method = "",
		Function = "󰊕",
		Constructor = "",
		Field = "󰜢",
		Class = "󰠱",
		Interface = "",
		Module = "",
		Unit = "",
		Value = "󰎠",
		Enum = "",
		Keyword = "󰌋",
		Snippet = "",
		Color = "󰏘",
		File = "󰈙",
		Reference = "󰈇",
		Folder = " ",
		EnumMember = "",
		Constant = "󰏿",
		Struct = "󰙅",
		Event = "",
		Operator = "󰆕",
		TypeParameter = " ",
		Copilot = "",
		Number = "󰎠",
		Array = "",
		Variable = "",
		Property = "",
		Boolean = "⊨",
		Namespace = "",
		bazel = " ",
		Package = "",
		Codeium = "󰩂",
		claude = "󰋦",
		openai = "󱢆",
		codestral = "󱎥",
		mistral = "󱎥",
		gemini = "",
		Groq = "",
		Openrouter = "󱂇",
		Ollama = "󰳆",
		["Llama.cpp"] = "󰳆",
		deepseek = "",
		-- FALLBACK
		fallback = "",
	},
})
local source_icons = {
	bazel = " ",
	minuet = "󱗻",
	Copilot = "",
	orgmode = "",
	otter = "󰼁",
	nvim_lsp = "",
	lsp = "",
	buffer = "",
	luasnip = "",
	snippets = "",
	path = "",
	git = "",
	tags = "",
	cmdline = "󰘳",
	latex_symbols = "",
	cmp_nvim_r = "󰟔",
	codeium = "󰩂",
	-- FALLBACK
	fallback = "󰜚",
}
local border_opts = {
	border = "rounded",
	winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
}
cmp.setup({
	window = {
		completion = cmp.config.window.bordered(border_opts),
		documentation = cmp.config.window.bordered(border_opts),
	},
	completion = { keyword_length = 2 },
	sources = {
		{ name = "minuet", priority = 100, group_index = 1 },
		{
			name = "lazydev",
			-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
			group_index = 0,
		},
		{ name = "nvim_lsp" },
		{ name = "bazel" },
		{
			name = "cmp_yanky",
			max_item_count = 10,
			group_index = 1,
			option = {
				minLength = 3,
				onlyCurrentFiletype = false,
			},
		},
		{
			name = "nvim_lsp_signature_help",
		},
		{ name = "luasnip" },
		{ name = "buffer" },
		{
			name = "buffer-lines",
			option = { words = true, leading_whitespace = false, comments = true },
		},
		{ name = "avante_commands" },
		{ name = "avante_mentions" },
		{ name = "avante_files" },
		{ name = "path" },
		{ name = "calc" },
		{ name = "emoji" },
	},
	sorting = {
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			-- cmp.config.compare.scopes,
			cmp.config.compare.score,
			require("clangd_extensions.cmp_scores"),
			require("cmp-under-comparator").under,
			cmp.config.compare.recently_used,
			cmp.config.compare.locality,
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.order,
			cmp.config.compare.length,
		},
		priority_weight = 2,
	},
	---@class cmp.PerformanceConfig
	performance = {
		fetching_timeout = 2000,
		debounce = 150,
		throttle = 1000,
	},
	mapping = cmp.mapping.preset.insert({
		["<A-y>"] = require("minuet").make_cmp_map(),
		["<CR>"] = cmp.mapping(function(fallback)
			-- use the internal non-blocking call to check if cmp is visible
			if cmp.core.view:visible() then
				cmp.confirm({ select = true })
			else
				fallback()
			end
		end),
		["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
		["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-e>"] = cmp.mapping.abort(),
	}),
	---@class cmp.FormattingConfig
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, vim_item) -- Hide function arguments in the completion menu
			vim_item.menu = source_icons[entry.source.name] or source_icons.fallback
			if vim_item.kind == "Function" or vim_item.kind == "Method" or vim_item.kind == "Copilot" then
				vim_item.abbr = vim_item.abbr:gsub("%b()", "")
			end

			--vim_item.abbr = vim_item.word
			local kind = lspkind_format(entry, vim_item)
			local strings = vim.split(kind.kind, "%s", { trimempty = true })
			kind.kind = " " .. (strings[1] or source_icons.fallback) .. " "
			--kind.kind = '▍' -- instead of symbol
			kind.menu = " " .. (source_icons[entry.source.name] or strings[2] or source_icons.fallback)
			return kind
		end,
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
})

-- `/` cmdline setup.
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

-- `:` cmdline setup.
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{
			name = "cmdline",
			keyword_length = 3,
			option = {
				ignore_cmds = { "Man", "!" },
			},
		},
	}),
})
-- Set configuration for specific filetype.
require("cmp_git").setup()

cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, {
		{ name = "buffer" },
	}),
})

cmp.setup.filetype("markdown", {
	sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, {
		{
			name = "buffer",
			option = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
		{ name = "buffer-lines", keyword_length = 3 },
		{ name = "luasnip" },
		{ name = "context_nvim" },
	}),
})

cmp.setup.filetype("changelog", {
	snippet = {
		expand = function(_) end,
	},
	sources = cmp.config.sources({
		{ name = "calc" },
		{ name = "emoji" },
		{ name = "luasnip", keyword_length = 3 },
		{
			name = "buffer",
			keyword_length = 3,
			option = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
	}),
})

cmp.setup.filetype("copilot-chat", {
	sources = cmp.config.sources({ { name = "minuet" }, { name = "cmp_git" } }, {
		{
			name = "buffer",
			option = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
		{ name = "luasnip" },
		{ name = "context_nvim" },
	}),
})

cmp.setup.filetype("text", {
	sources = cmp.config.sources({
		{ name = "calc" },
		{ name = "emoji" },
		{
			name = "cmp_yanky",
			keyword_length = 4,
			option = {
				onlyCurrentFiletype = false,
				minLength = 3,
			},
		},
		{
			name = "buffer",
			keyword_length = 4,
			option = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
		},
	}),
})
-- Setup function to be called after Avante loads
local function setup_avante_completion()
	if not package.loaded["cmp"] then
		return
	end
	local cmp = require("cmp")

	-- Setup for AvanteInput filetype
	cmp.setup.filetype("AvanteInput", {
		enabled = true,
		completion = {
			autocomplete = {
				require("cmp.types").cmp.TriggerEvent.TextChanged,
			},
			keyword_length = 1, -- Auto-trigger after just 1 character
		},
		sources = cmp.config.sources({
			{ name = "minuet", priority = 100, group_index = 1 },
		}, {
			{ name = "avante_commands", priority = 90, group_index = 2 },
			{ name = "avante_mentions", priority = 90, group_index = 2 },
			{ name = "avante_files", priority = 90, group_index = 2 },
		}, {
			{ name = "nvim_lsp" },
			{ name = "buffer" },
			{ name = "luasnip" },
			{ name = "path" },
		}),
		mapping = cmp.mapping.preset.insert({
			-- Keep the manual trigger as a fallback option
			["<A-y>"] = require("minuet").make_cmp_map(),
			["<CR>"] = cmp.mapping(function(fallback)
				if cmp.core.view:visible() then
					cmp.confirm({ select = true })
				else
					fallback()
				end
			end),
			["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
			["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
			["<C-b>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-e>"] = cmp.mapping.abort(),
		}),
	})

	-- Similar setup for AvantePromptInput
	cmp.setup.filetype("AvantePromptInput", {
		enabled = true,
		completion = {
			autocomplete = {
				require("cmp.types").cmp.TriggerEvent.TextChanged,
			},
			keyword_length = 1,
		},
		sources = {
			{ name = "avante_prompt_mentions", priority = 100 },
			{ name = "minuet", priority = 90 },
		},
	})
end

-- Apply our configuration after Avante loads
vim.api.nvim_create_autocmd("User", {
	pattern = "AvanteLoaded",
	callback = setup_avante_completion,
})

-- Also run once during initial load in case Avante is already loaded
vim.defer_fn(function()
	if package.loaded["avante"] then
		setup_avante_completion()
	end
end, 100)

vim.cmd([[
        highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=#808080
        highlight! CmpItemAbbrMatch guibg=NONE guifg=#569CD6
        highlight! CmpItemAbbrMatchFuzzy guibg=NONE guifg=#569CD6
        highlight! CmpItemKindVariable guibg=NONE guifg=#9CDCFE
        highlight! CmpItemKindInterface guibg=NONE guifg=#9CDCFE
        highlight! CmpItemKindText guibg=NONE guifg=#9CDCFE
        highlight! CmpItemKindFunction guibg=NONE guifg=#C586C0
        highlight! CmpItemKindMethod guibg=NONE guifg=#C586C0
        highlight! CmpItemKindKeyword guibg=NONE guifg=#D4D4D4
        highlight! CmpItemKindProperty guibg=NONE guifg=#D4D4D4
        highlight! CmpItemKindUnit guibg=NONE guifg=#D4D4D4
      ]])
