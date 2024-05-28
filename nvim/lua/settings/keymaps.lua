local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

--Doom emacs keymap for find file
keymap("n", "<leader><Space>", "<cmd>Telescope find_files hidden=true <cr>", opts)

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)
keymap("n", "<leader>ww", "<C-w>w", opts)

keymap("n", "<leader>x", ":BufferClose<CR>", opts)

-- go to  beginning and end
keymap("i", "<C-b>", "<ESC>^i", opts)
keymap("i", "<C-e>", "<End>", opts)

-- navigate within insert mode
keymap("i", "<C-h>", "<Left>", opts)
keymap("i", "<C-l>", "<Right>", opts)
keymap("i", "<C-j>", "<Down>", opts)
keymap("i", "<C-k>", "<Up>", opts)

-- Clear highlights
keymap("n", "<Esc>", "<cmd> noh <CR>", opts)
-- save
keymap("n", "<C-s>", "<cmd> w <CR>", opts)

-- Copy all
keymap("n", "<C-c>", "<cmd> %y+ <CR>", opts)

-- new buffer
keymap("n", "<leader>b", "<cmd> enew <CR>", opts)

-- toggle
keymap("n", "<C-n>", "<cmd> NvimTreeToggle <CR>", opts)

-- focus
keymap("n", "<leader>e", "<cmd> NvimTreeFocus <CR>", opts)

-- Toggle comment a line
keymap("n", "<leader>/", "<cmd> lua require('Comment.api').toggle.linewise.current()<cr>", opts)
keymap("v", "<leader>/", "<cmd> lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
-- Navigate buffers
keymap("n", "<TAB>", "<cmd>BufferNext<CR>", opts)
keymap("n", "<S-TAB>", "<cmd>BufferPrevious<CR>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Close Windows quickly with shift+Q
keymap("n", "Q", ":only<CR>", opts)

--Search for visually selected word
keymap("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]], opts)

-- Open file under cursor with system app
keymap("n", "gx", [[:silent execute '!$BROWSER ' . shellescape(expand('<cWORD>'), 1)<CR>]], opts)

keymap("n", "<C-f>", "<cmd> !tmux neww tmux-sessionizer <CR>", opts)
keymap("n", "<leader>zz", "<cmd> ZenMode<CR>", opts)
-- cmake run
keymap("n", "<leader>h", "<cmd> CMakeDebug <CR>", opts)
keymap("n", "<leader>m", "<cmd> CMakeRun <CR>", opts)
keymap("n", "<leader>s", "<cmd> CMakeCloseExecutor <CR><cmd> CMakeCloseRunner <CR>", opts)
-- copilot chat
keymap("n", "<leader>t", "<cmd> CopilotChatToggle <CR>", opts)
-- telescope
keymap("n", "<leader>;", "<cmd> Telescope git_files <CR>", opts)
keymap("n", "<leader>.", "<cmd> lua require('telescope').extensions.recent_files.pick() <CR>", opts)
keymap("n", "<leader>lw", "<cmd> Telescope lazygit <CR>", opts)
keymap("n", "<leader>8", "<cmd> Telescope live_grep <CR>", opts)
keymap("n", "<leader>7", "<cmd> Telescope current_buffer_fuzzy_find <CR>", opts)

-- outline symbols
keymap("n", "<F3>", "<Cmd>SymbolsOutline<CR>", opts)
-- java test
keymap("n", "<A-o>", "<Cmd>lua require'jdtls'.organize_imports()<CR>", opts)
keymap("n", "<leader>jv", "<Cmd>lua require('jdtls').extract_variable()<CR>", opts)
keymap("x", "<leader>jv", "<Cmd>lua require('jdtls').extract_variable(true)<CR>", opts)
keymap("n", "<leader>jw", "<Cmd>lua require('jdtls').extract_constant()<CR>", opts)
keymap("x", "<leader>jw", "<Cmd>lua require('jdtls').extract_constant(true)<CR>", opts)
keymap("n", "<leader>jt", "<Cmd>lua require('jdtls').test_nearest_method()<CR>", opts)
keymap("n", "<leader>jd", "<Cmd>lua require('jdtls').test_class()<CR>", opts)
keymap("n", "<leader>ju", "<Cmd>JdtUpdateConfig<CR>", opts)

keymap("v", "<leader>jv", "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", opts)
keymap("v", "<leader>jw", "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", opts)
keymap("v", "<leader>jm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", opts)
keymap("x", "<leader>jm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", opts)
keymap("n", "<leader>jl", "<Cmd>lua function() vim.lsp.buf.incoming_calls() end<CR>", opts)
keymap("n", "<leader>jp", "<Cmd>lua require('jdtls').super_implementation<CR>", opts)
keymap("n", "<leader>js", "<Cmd>lua require('jdtls').jshell()<CR>", opts)
-- markdown
keymap("n", "<F6>", "<cmd> MarkdownPreviewToggle<CR>", opts)
-- python
keymap("n", "<leader>vl", "<cmd>VenvSelect<CR>", opts)
keymap("n", "<leader>vh", "<cmd>VenvSelectCached<CR>", opts)
keymap("n", "<leader>kw", "<cmd>lua require('dap-python').test_method()<CR>", opts)
keymap("n", "<leader>kf", "<cmd>lua require('dap-python').test_class()<CR>", opts)
keymap("n", "<leader>ks", "<cmd>lua require('dap-python').debug_selection()<CR>", opts)

-- tmux
keymap("n", "<C-\\>", '<cmd>lua require("nvim-tmux-navigation").NvimTmuxNavigateLastActive<cr>', opts)
keymap("n", "<C-Space>", '<cmd>lua require("nvim-tmux-navigation").NvimTmuxNavigateNext<cr>', opts)
-- highlite
keymap("n", "<a-n>", '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>', opts)
keymap("n", "<a-p>", '<cmd>lua require("illuminate").next_reference{reverse=true,wrap=true}<cr>', opts)
-- linter
keymap("n", "<leader>ll", '<cmd>lua require("lint").try_lint<cr>', opts)
-- formatter
keymap(
	"n",
	"<leader>l",
	'<cmd>lua require("conform").conform.format{lsp_fallback = true,async = false,timeout_ms = 500,}<cr>',
	opts
)
keymap(
	"v",
	"<leader>l",
	'<cmd>lua require("conform").conform.format{lsp_fallback = true,async = false,timeout_ms = 500,}<cr>',
	opts
)
-- undo
keymap("n", "<leader>u", "<cmd>Telescope undo<cr>", opts)
-- DAP
keymap("n", "<F5>", "<cmd> DapToggleBreakpoint <cr>", opts)
keymap("n", "<leader>o", "<cmd> DapStepOut <cr>", opts)
keymap("n", "<F7>", "<cmd>DapStepInto<cr>", opts)
keymap("n", "<F8>", "<cmd>DapStepOver<cr>", opts)
keymap("n", "<F9>", "<cmd>DapContinue<cr>", opts)
keymap("n", "<leader>f", "<cmd>DapTerminate<cr>", opts)
keymap("n", "<leader>r", '<cmd>lua require("dap").clear_breakpoints()<cr>', opts)
keymap("n", "<leader>y", '<cmd>lua require("dap.ui.widgets").hover()<cr>', opts)
keymap("n", "<leader>w", '<cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<cr>', opts)
keymap(
	"n",
	"<leader>l",
	'<cmd>lua require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) <cr>',
	opts
)
-- check failed tests from dap repl
keymap("n", "<leader>xx", "<cmd> DapToggleRepl <CR>", opts)
-- ESC to clear highlights after search
keymap("n", "<Esc>", ":noh<CR> :helpclose<CR>", opts)
-- dap ui icons
vim.fn.sign_define(
	"DapBreakpoint",
	{ text = "🟤", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
)
vim.fn.sign_define(
	"DapBreakpointCondition",
	{ text = "▶️", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
)
vim.fn.sign_define(
	"DapBreakpointRejected",
	{ text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
)
vim.fn.sign_define(
	"DapLogPoint",
	{ text = "", texthl = "DapLogPoint", linehl = "DapLogPoint", numhl = "DapLogPoint" }
)
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })
-- error lens
vim.fn.sign_define({
	{
		name = "DiagnosticSignError",
		text = "",
		texthl = "DiagnosticSignError",
		linehl = "ErrorLine",
	},
	{
		name = "DiagnosticSignWarn",
		text = "",
		texthl = "DiagnosticSignWarn",
		linehl = "WarningLine",
	},
	{
		name = "DiagnosticSignInfo",
		text = "",
		texthl = "DiagnosticSignInfo",
		linehl = "InfoLine",
	},
	{
		name = "DiagnosticSignHint",
		text = "",
		texthl = "DiagnosticSignHint",
		linehl = "HintLine",
	},
})

--LSP basic keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	callback = function()
		local bufmap = function(mode, lhs, rhs)
			local lspopts = { buffer = true }
			vim.keymap.set(mode, lhs, rhs, lspopts)
		end

		-- Displays hover information about the symbol under the cursor
		bufmap("n", "K", "<cmd>Lspsaga hover_doc<cr>")

    -- Peek definition
    bufmap('n', 'gd', '<cmd>Lspsaga peek_definition<cr>')

    -- Jump to definition
    bufmap('n', 'gD', '<cmd>lua vim.lsp.buf.definition()<cr>')

		-- Lists all the implementations for the symbol under the cursor
		bufmap("n", "gi", "<cmd>Lspsaga finder imp<cr>")

		-- Jumps to the definition of the type symbol
		bufmap("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>")

		-- Lists all the references
		-- bufmap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>')
		bufmap("n", "gr", "<cmd>Lspsaga finder<cr>")

		-- Displays a function's signature information
		bufmap("n", "L", "<cmd>lua vim.lsp.buf.signature_help()<cr>")

		-- Renames all references to the symbol under the cursor
		bufmap("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>")

		-- Selects a code action available at the current cursor position
		bufmap("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
		bufmap("x", "<F4>", "<cmd>lua vim.lsp.buf.range_code_action()<cr>")

		-- Show diagnostics in a floating window
		bufmap("n", "gl", "<cmd>lua vim.diagnostic.open_float()<cr>")

    -- Move to the previous diagnostic
    bufmap('n', 'gp', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

    -- Move to the next diagnostic
    bufmap('n', 'gn', '<cmd>lua vim.diagnostic.goto_next()<cr>')
  end
})
