local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
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

luasnip.add_snippets(c_cpp_snippets)

local lspkind_format = require("lspkind").cmp_format({
	mode = "symbol_text",
	maxwidth = 50,

	symbol_map = {
		Text = "󰉿",
		Method = "",
		Function = "󰊕",
		Constructor = "",
		Field = "󰜢",
		Variable = "󰀫",
		Class = "󰠱",
		Interface = "",
		Module = "",
		Property = "󰜢",
		Unit = "  ",
		Value = "󰎠",
		Enum = "",
		Keyword = "󰌋",
		Snippet = "",
		Color = "󰏘",
		File = "󰈙",
		Reference = "󰈇",
		Folder = "  ",
		EnumMember = "",
		Constant = "󰏿",
		Struct = "󰙅",
		Event = "",
		Operator = "󰆕",
		TypeParameter = " ",
		Copilot = "",
	},
})

cmp.setup({
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	completion = {
		completeopt = "menu,menuone,noselect,noinsert",
	},
	sources = {
		{
			name = "lazydev",
			-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
			group_index = 0,
		},
		{ name = "nvim_lsp" },
		{
			name = "nvim_lsp_signature_help",
		},
		{ name = "luasnip" },
		{
			name = "buffer-lines",
			option = { words = true, leading_whitespace = false, comments = true },
		},
		{ name = "copilot" },
		{ name = "path" },
	},
	sorting = {
		comparators = {
			require("cmp_copilot.comparators").prioritize,
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			require("cmp_copilot.comparators").score,
			cmp.config.compare.recently_used,
			require("clangd_extensions.cmp_scores"),
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
		priority_weight = 2,
	},
	mapping = cmp.mapping.preset.insert({
		["<CR>"] = cmp.mapping.confirm({ select = false }), -- Enter confirms the autocompletion candidate
		["<Tab>"] = cmp_action.luasnip_supertab({ behavior = cmp.SelectBehavior.Select }),
		["<S-Tab>"] = cmp_action.luasnip_shift_supertab({ behavior = cmp.SelectBehavior.Select }),
	}),
	---@class cmp.FormattingConfig
	formatting = {
		--fields = { "kind", "abbr", "menu" },
		fields = { "kind", "abbr" },
		format = function(entry, vim_item)
			-- Hide function arguments in the completion menu
			vim_item.menu = vim_item.menu or ""
			if vim_item.kind == "Function" or vim_item.kind == "Method" or vim_item.kind == "Copilot" then
				vim_item.abbr = vim_item.abbr:gsub("%b()", "")
			end

			--vim_item.abbr = vim_item.word
			local kind = lspkind_format(entry, vim_item)
			local strings = vim.split(kind.kind, "%s", { trimempty = true })
			kind.kind = " " .. (strings[1] or "") .. " "
			--kind.kind = '▍' -- instead of symbol
			kind.menu = " " .. (strings[2] or "")
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
cmp.setup.cmdline("/", {
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
			option = {
				ignore_cmds = { "Man", "!" },
			},
		},
	}),
})
