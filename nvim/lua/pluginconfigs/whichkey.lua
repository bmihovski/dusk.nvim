local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	return
end

--------------------------------------
-- Custom Helper Functions --
--------------------------------------

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
	-- Use the current buffer's path as the starting point for the git search
	local current_file = vim.api.nvim_buf_get_name(0)
	local current_dir
	local cwd = vim.fn.getcwd()
	-- If the buffer is not associated with a file, return nil
	if current_file == "" then
		current_dir = cwd
	else
		-- Extract the directory from the current file's path
		current_dir = vim.fn.fnamemodify(current_file, ":h")
	end

	-- Find the Git root directory from the current file's path
	local git_root = vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		print("Not a git repository. Searching on current working directory")
		return cwd
	end
	return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
	local git_root = find_git_root()
	if git_root then
		require("telescope.builtin").live_grep({
			search_dirs = { git_root },
		})
	end
end

vim.api.nvim_create_user_command("LiveGrepGitRoot", live_grep_git_root, {})

local function telescope_live_grep_open_files()
	require("telescope.builtin").live_grep({
		grep_open_files = true,
		prompt_title = "Live Grep in Open Files",
	})
end

-- Function to toggle diagnostic virtual text
local function ToggleVirtualText()
	local config = vim.diagnostic.config()
	local new_value = not config.virtual_text
	vim.diagnostic.config({ virtual_text = new_value })
	print("Virtual text " .. (new_value and "enabled" or "disabled"))
end

vim.api.nvim_create_user_command("ToggleVirtualText", ToggleVirtualText, {})

local function CopilotChatAsk()
	local input = vim.fn.input("Ask AI: ")
	if input ~= "" then
		require("CopilotChat").ask(input)
	end
end
vim.api.nvim_create_user_command("CopilotChatAsk", CopilotChatAsk, {})

local function CopilotChatHelpActions()
	local actions = require("CopilotChat.actions").help_actions()
	if actions == nil then
		vim.notify("No help actions found.", "warn")
	else
		require("CopilotChat.integrations.fzflua").pick(actions)
	end
end
vim.api.nvim_create_user_command("CopilotChatHelpActions", CopilotChatHelpActions, {})

local function CopilotChatPromptActions()
	local actions = require("CopilotChat.actions").prompt_actions()
	require("CopilotChat.integrations.fzflua").pick(actions)
end
vim.api.nvim_create_user_command("CopilotChatPromptActions", CopilotChatPromptActions, {})

-- Ask the Perplexity agent a quick question
local function CopilotChatPerplexitySearch()
	local input = vim.fn.input("Perplexity: ")
	if input ~= "" then
		require("CopilotChat").ask(input, {
			agent = "perplexityai",
			selection = false,
		})
	end
end
vim.api.nvim_create_user_command("CopilotChatPerplexitySearch", CopilotChatPerplexitySearch, {})

-- Open test results after execution
local function print_test_results(items)
	if #items > 0 then
		vim.cmd([[Trouble quickfix]])
	else
		vim.cmd([[TroubleClose quickfix]])
	end
end

--remove unused imports from the whole project
local function remove_unused_imports_from_project()
	vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.WARN })
	vim.cmd("packadd cfilter")
	vim.cmd("Cfilter /main/")
	vim.cmd("Cfilter /The import/")
	vim.cmd("cdo normal dd")
	vim.cmd("cclose")
	vim.cmd("wa")
end

vim.api.nvim_create_user_command("RemoveUnusedImportsFromProject", remove_unused_imports_from_project, {})

--------------------------------------
-- Keymaps --
--------------------------------------

local setup = {
	plugins = {
		marks = false, -- shows a list of your marks on ' and `
		registers = false, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
		spelling = {
			enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
			suggestions = 20, -- how many suggestions should be shown in the list?
		},
		-- the presets plugin, adds help for a bunch of default keybindings in Neovim
		-- No actual key bindings are created
		presets = {
			operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
			motions = false, -- adds help for motions
			text_objects = true, -- help for text objects triggered after entering an operator
			windows = false, -- default bindings on <c-w>
			nav = false, -- misc bindings to work with windows
			z = true, -- bindings for folds, spelling and others prefixed with z
			g = true, -- bindings for prefixed with g
		},
	},
	-- add operators that will trigger motion and text object completion
	-- to enable all native operators, set the preset / operators plugin above
	-- operators = { gc = "Comments" },
	replace = {
		-- override the label used to display some keys. It doesn't effect WK in any other way.
		-- For example:
		-- ["<space>"] = "SPC",
		-- ["<cr>"] = "RET",
		-- ["<tab>"] = "TAB",
	},
	icons = {
		breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
		separator = "➜", -- symbol used between a key and it's label
		group = "+", -- symbol prepended to a group
	},
	keys = {
		scroll_down = "<c-d>", -- binding to scroll down inside the popup
		scroll_up = "<c-u>", -- binding to scroll up inside the popup
	},
	win = {
		border = "none", -- none, single, double, shadow
		title_pos = "bottom", -- bottom, top
		padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
		wo = {
			winblend = 0,
		},
	},
	layout = {
		height = { min = 4, max = 25 }, -- min and max height of the columns
		width = { min = 20, max = 50 }, -- min and max width of the columns
		spacing = 3, -- spacing between columns
		align = "center", -- align columns left, center or right
	},
	show_help = true, -- show help message on the command line when the popup is visible
}

local opts = {
	mode = "n", -- NORMAL mode
	prefix = "<leader>",
	buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
	silent = true, -- use `silent` when creating keymaps
	noremap = true, -- use `noremap` when creating keymaps
	nowait = true, -- use `nowait` when creating keymaps
}

local mappings = {
	{ "<leader>R", ":%d+<cr>", desc = "Remove All Text" },
	{ "<leader>a", group = "AI" },
	{
		"<leader>aca",
		"<cmd>CopilotChatAsk",
		desc = "CopilotChat: Ask AI",
	},
	{ "<leader>acw", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat: Toggle chat window." },
	{ "<leader>acda", "<cmd>CopilotChatHelpActions<cr>", desc = "CopilotChat: Diagnostic help actions" },
	{
		"<leader>acp",
		"<cmd>CopilotChatPromptActions<cr>",
		desc = "CopilotChat: Prompt actions",
	},
	{
		"<leader>acsp",
		"<cmd>CopilotChatPerplexitySearch<cr>",
		desc = "CopilotChat - Perplexity Search",
	},
	-- Code related commands
	{ "<leader>ace", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code" },
	{ "<leader>act", "<cmd>CopilotChatTests<cr>", desc = "Generate Tests" },
	{ "<leader>acr", "<cmd>CopilotChatReview<cr>", desc = "Review Code" },
	{ "<leader>acR", "<cmd>CopilotChatRefactor<cr>", desc = "Refactor Code" },
	{ "<leader>acn", "<cmd>CopilotChatBetterNamings<cr>", desc = "Better Naming" },
	-- Git related commands
	{ "<leader>acc", "<cmd>CopilotChatCommit<cr>", desc = "Generate Commit Message" },
	{ "<leader>acs", "<cmd>CopilotChatCommitStaged<cr>", desc = "Commit Staged Changes" },
	{ "<leader>acu", "<cmd>CopilotChatCommitUnstaged<cr>", desc = "Commit Unstaged Changes" },
	{ "<leader>acpp", "<cmd>CopilotChatPullRequest<cr>", desc = "Generate Pull Request" },
	-- Debug and fix
	{ "<leader>acd", "<cmd>CopilotChatDebugInfo<cr>", desc = "Debug Info" },
	{ "<leader>acf", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "Fix Diagnostic" },
	-- Models
	{ "<leader>am", "<cmd>CopilotChatModels<cr>", desc = "Select Models" },
	-- VectorCode register buffer
	{ "<leader>av", "<cmd>VectorCode register<cr>", desc = "VectorCode Register Buffer" },
	{ "<leader>C", group = "Containers - Docker" },
	{ "<leader>Cd", "<cmd>Lazydocker<cr>", desc = "Run LazyDocker" },
	{ "<leader>D", group = "Database" },
	{ "<leader>Db", "<cmd>DBUIFindBuffer<cr>", desc = "Find Buffer" },
	{ "<leader>Di", "<cmd>DBUILastQueryInfo<cr>", desc = "Last Query Info" },
	{ "<leader>Dr", "<cmd>DBUIRenameBuffer<cr>", desc = "Rename Buffer" },
	{ "<leader>Dt", "<cmd>DBUIToggle<cr>", desc = "Toggle UI" },
	{ "<leader>P", group = "Python" },
	{
		"<leader>PT",
		"<Cmd>lua require('dap-python').test_class()<CR>",
		desc = "Test Class",
	},
	{
		"<leader>Pc",
		"<Cmd>VenvSelectCached<CR>",
		desc = "Select Cached Virtual Environment",
	},
	{
		"<leader>Pd",
		"<Cmd>lua require('dap-python').debug_selection()<CR>",
		desc = "Debug Selection",
	},
	{
		"<leader>Pt",
		"<Cmd>lua require('dap-python').test_method()<CR>",
		desc = "Test Method",
	},
	{ "<leader>Pv", "<Cmd>VenvSelect<CR>", desc = "Select New Virtual Environment" },
	{ "<leader>PC", "<cmd>lua require('swenv.api').pick_venv()<cr>", desc = "Choose Venv" },
	{ "<leader>S", group = "C++" },
	{ "<leader>Sa", "<cmd>ClangdAST<cr>", desc = "Display AST" },
	{
		"<leader>Sc",
		"<cmd>CMakeCloseExecutor <CR><cmd>CMakeCloseRunner<cr>",
		desc = "Close and stop cmake Runner",
	},
	{ "<leader>Sd", "<cmd>CMakeDebug<cr>", desc = "Run Debug cmake" },
	{ "<leader>Sh", "<cmd>ClangdToggleInlayHints<cr>", desc = "Toggle Inlay Hints" },
	{ "<leader>Sm", "<cmd>ClangdMemoryUsage<cr>", desc = "Display Memory Usage" },
	{ "<leader>Sr", "<cmd>CMakeRun<cr>", desc = "Run code cmake" },
	{ "<leader>Ss", "<cmd>ClangdSymbolInfo<cr>", desc = "Display Symbol Info" },
	{ "<leader>St", "<cmd>ClangdTypeHierarchy<cr>", desc = "Display Type Hierarchy" },
	{ "<leader>Sw", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header" },
	{ "<leader>Sy", "<cmd>ClangdCallHierarchy<cr>", desc = "Display Call Hierarchy" },
	{ "<leader>add", ":Alpha", desc = "Dashboard" },
	{ "<leader>b", group = "Buffer" },
	{ "<leader>bK", "<cmd>BufDelOthers<cr>", desc = "Close all buffers except current" },
	{ "<leader>bb", "<cmd>Telescope buffers theme=dropdown<cr>", desc = "Buffer List" },
	{ "<leader>bk", "<Cmd>bd<Cr>", desc = "Close current buffer" },
	{ "<leader>bn", "<Cmd>bnext<cr>", desc = "Next buffer" },
	{ "<leader>bp", "<Cmd>bprevious<cr>", desc = "Previous buffer" },
	{ "<leader>c", group = "Code" },
	{ "<leader>cR", ":Lspsaga rename ++project<cr>", desc = "Rename in Project" },
	{
		"<leader>cX",
		":Trouble diagnostics toggle filter.buf=0 focus = true<cr>",
		desc = "Current buffer Diagnostics",
	},
	{ "<leader>ca", ":lua vim.lsp.buf.code_action()<cr>", desc = "Code Action" },
	{ "<leader>cd", ":Neogen<cr>", desc = "generate code docs" },
	{
		"<leader>ce",
		":Trouble diagnostics filter.severity=vim.diagnostic.severity.ERROR<cr>",
		desc = "Show Workspace Errors",
	},
	{ "<leader>cf", "<cmd>lua require('conform').format({async = true})<CR>", desc = "Format Document" },
	{ "<leader>cn", ":Lspsaga diagnostic_jump_next<cr>", desc = "Next Diagnostic" },
	{ "<leader>co", ":Lspsaga outline<cr>", desc = "Code Outline" },
	{ "<leader>cp", ":Lspsaga diagnostic_jump_prev<cr>", desc = "Prev Diagnostic" },
	{ "<leader>cq", ":Trouble quickfix focus = true<cr>", desc = "Diagnostics Quickfix" },
	{ "<leader>cr", ":Lspsaga rename<cr>", desc = "Rename in current buffer" },
	{ "<leader>cs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Documents Symbols" },
	{ "<leader>cW", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },
	{
		"<leader>cx",
		":Trouble diagnostics toggle focus = true<cr>",
		desc = "Workspace Diagnostics",
	},
	{ "<leader>ct", ":lua require('telescope').extensions.vstask.tasks()<CR>", desc = "List vscode tasks" },
	{ "<leader>ci", ":lua require('telescope').extensions.vstask.inputs()<CR>", desc = "List vscode inputs" },
	{ "<leader>ch", ":lua require('telescope').extensions.vstask.history()<CR>", desc = "List vscode history" },
	{ "<leader>cl", ":lua require('telescope').extensions.vstask.launch()<cr>", desc = "Lauch vscode debug conf" },
	{ "<leader>cj", ":lua require('telescope').extensions.vstask.jobs()<CR>", desc = "List vscode jobs" },
	{ "<leader>ck", ":lua require('telescope').extensions.vstask.jobhistory()<CR>", desc = "List vscode job history" },
	{ "<leader>d", group = "Debug" },
	{ "<leader>db", ":lua require'dap'.toggle_breakpoint()<cr>", desc = "Breakpoint" },
	{ "<leader>dc", ":lua require'dap'.continue()<cr>", desc = "Start/Continue" },
	{ "<leader>dd", ":lua require'dapui'.toggle()<cr>", desc = "Dap UI" },
	{
		"<leader>de",
		":lua require'dapui'.eval(vim.fn.input('eval: '))<cr>",
		desc = "Evaluate expression",
	},
	{ "<leader>di", ":lua require'dap'.step_into()<cr>", desc = "Step Into" },
	{ "<leader>do", ":lua require'dap'.step_over()<cr>", desc = "Step Over" },
	{ "<leader>dr", ":lua require'dap'.repl.open()<cr>", desc = "Repl Console" },
	{ "<leader>dt", ":lua require'dap'.terminate()<cr>", desc = "Terminate session" },
	{ "<leader>du", ":lua require'dap'.step_out()<cr>", desc = "Step Out" },
	{ "<leader>e", ":NvimTreeToggle<cr>", desc = "Tree Explorer" },
	{ "<leader>f", group = "Find" },
	{ "<leader>fC", "<cmd>Telescope commands<cr>", desc = "Commands" },
	{ "<leader>fa", ":Telescope autocommands<cr>", desc = "Autocommmands" },
	{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
	{ "<leader>fc", "<cmd>Telescope colorscheme<cr>", desc = "Colorschemes" },
	{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
	{ "<leader>ff", "<cmd>Telescope find_files hidden=true <cr>", desc = "Files" },
	{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
	{ "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
	{ "<leader>fp", "<cmd>Telescope projects <CR>", desc = "Projects" },
	{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
	{ "<leader>fR", "<cmd>Telescope resume<cr>", desc = "Telescope Resume" },
	{ "<leader>fz", "<cmd>Telescope zoxide list<cr>", desc = "zoxide list" },
	{ "<leader>g", group = "Git" },
	{ "<leader>gD", ":DiffviewClose<cr>", desc = "Close Diff" },
	{ "<leader>gP", ":lua require 'gitsigns'.preview_hunk()<cr>", desc = "Preview Hunk" },
	{ "<leader>gR", ":lua require 'gitsigns'.reset_buffer()<cr>", desc = "Reset Buffer" },
	{ "<leader>gb", ":Telescope git_branches<cr>", desc = "Checkout branch" },
	{ "<leader>gc", ":Telescope git_commits<cr>", desc = "Checkout commit" },
	{ "<leader>gd", ":DiffviewOpen<cr>", desc = "Open Diff" },
	{ "<leader>gg", ":LazyGit<cr>", desc = "Lazygit" },
	{ "<leader>gl", ":lua require 'gitsigns'.blame_line()<cr>", desc = "Blame" },
	{ "<leader>gn", ":lua require 'gitsigns'.next_hunk()<cr>", desc = "Next Hunk" },
	{ "<leader>go", ":Telescope git_status<cr>", desc = "Open changed file" },
	{ "<leader>gp", ":lua require 'gitsigns'.prev_hunk()<cr>", desc = "Prev Hunk" },
	{ "<leader>gr", ":lua require 'gitsigns'.reset_hunk()<cr>", desc = "Reset Hunk" },
	{ "<leader>gs", ":lua require 'gitsigns'.stage_hunk()<cr>", desc = "Stage Hunk" },
	{
		"<leader>gu",
		":lua require 'gitsigns'.undo_stage_hunk()<cr>",
		desc = "Undo Stage Hunk",
	},
	{ "<leader>j", group = "Java" },
	{ "<leader>jC", "<Cmd>JdtCompile full<CR>", desc = "Compile Java" },
	{
		"<leader>jR",
		"<cmd>JdtWipeDataAndRestart<cr>",
		desc = "Wipe project data and Restart server",
	},
	{
		"<leader>jT",
		"<Cmd>lua require'jdtls'.test_class({ config = { console = 'console' }})<CR>",
		desc = "Test/Debug Class",
	},
	{
		"<leader>jc",
		"<Cmd>lua require('jdtls').extract_constant()<CR>",
		desc = "Extract Constant",
	},
	{
		"<leader>jd",
		":lua require('jdtls').setup_dap({ hotcodereplace = 'auto' })<cr>; :lua require'jdtls.dap'.setup_dap_main_class_configs()<cr>",
		desc = "Refresh DAP Debugger",
	},
	{ "<leader>je", "<Cmd>JdtSetRuntime<CR>", desc = "Choose Java Runtime" },
	{
		"<leader>jf",
		"<cmd>lua require('conform').format({async = true})<cr>",
		desc = "Format with Google Java Format",
	},
	{
		"<leader>jg",
		"<cmd>lua require('jdtls.tests').generate()<cr>",
		desc = "Generate tests for current Class",
	},
	{ "<leader>jl", ":FzfLua lsp_live_workspace_symbols<CR>", desc = "Find Beans" },
	{
		"<leader>ji",
		"<cmd>lua require('jdtls.tests').goto_subjects()<cr>",
		desc = "Go to corresponding Test/Subject Class",
	},
	{
		"<leader>jo",
		"<Cmd>lua require'jdtls'.organize_imports()<CR>",
		desc = "Organize Imports",
	},
	{
		"<leader>jr",
		function()
			require("jdtls").pick_test({ after_test = print_test_results })
		end,
		desc = "Run test and open results",
	},
	{
		"<leader>jt",
		"<Cmd>lua require'jdtls'.test_nearest_method({ config = { console = 'console' }})<CR>",
		desc = "Test/Debug Method",
	},
	{
		"<leader>ju",
		"<Cmd>lua require('jdtls').update_project_config()<CR>",
		desc = "Refresh java config",
	},
	{
		"<leader>jv",
		"<Cmd>lua require('jdtls').extract_variable()<CR>",
		desc = "Extract Variable",
	},
	{
		"<leader>jx",
		"<Cmd>RemoveUnusedImportsFromProject<CR>",
		desc = "Remove unused imports from whole project",
	},
	{ "<leader>l", group = "LSP - Language" },
	{ "<leader>lf", ":lua vim.lsp.buf.format({ async = true })<cr>", desc = "Format" },
	{ "<leader>li", ":LspInfo<cr>", desc = "Info" },
	{ "<leader>lm", ":Mason<cr>", desc = "Install Language" },
	{ "<leader>lw", group = "LSP Workspace" },
	{
		"<leader>lwl",
		function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end,
		desc = "List Workspace Folders",
	},
	{ "<leader>m", group = "Markdown" },
	{ "<leader>mp", ":MarkdownPreview<CR>", desc = "Preview in browser" },
	{ "<leader>ms", ":MarkdownPreviewStop<CR>", desc = "Stop Preview" },
	{ "<leader>o", group = "Open" },
	{ "<leader>of", ":ToggleTerm direction=float<cr>", desc = "Float Terminal" },
	{
		"<leader>ot",
		":ToggleTerm size=16 direction=horizontal<cr>",
		desc = "Horizontal Terminal",
	},
	{
		"<leader>ov",
		":ToggleTerm size=50 direction=vertical<cr>",
		desc = "Vertical Terminal",
	},
	{ "<leader>p", group = "Package Manager" },
	{ "<leader>pC", ":Lazy check<cr>", desc = "Check" },
	{ "<leader>pH", ":Lazy help<cr>", desc = "Help" },
	{ "<leader>pd", ":Lazy debug<cr>", desc = "Debug" },
	{ "<leader>ph", ":Lazy home<cr>", desc = "Home" },
	{ "<leader>pi", ":Lazy install<cr>", desc = "Install" },
	{ "<leader>pl", ":Lazy log<cr>", desc = "Log" },
	{ "<leader>pp", ":Lazy profile<cr>", desc = "Profile" },
	{ "<leader>ps", ":Lazy sync<cr>", desc = "Sync" },
	{ "<leader>pu", ":Lazy update<cr>", desc = "Update" },
	{ "<leader>px", ":Lazy clean<cr>", desc = "Clean" },
	{ "<leader>r", group = "Replace" },
	{
		"<leader>rb",
		"<cmd>lua require('spectre').open_file_search()<cr>",
		desc = "Replace in the current Buffer",
	},
	{ "<leader>rr", "<cmd>lua require('spectre').open()<cr>", desc = "Replace in path" },
	{
		"<leader>rw",
		"<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
		desc = "Replace Word",
	},
	{ "<leader>s", group = "Search String" },
	{
		"<leader>sb",
		function()
			-- You can pass additional configuration to telescope to change theme, layout, etc.
			require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 10,
				previewer = false,
			}))
		end,
		desc = "In current buffer",
	},
	{
		"<leader>sc",
		"<cmd>Telescope live_grep theme=ivy<cr>",
		desc = "In current working directory",
	},
	{ "<leader>so", telescope_live_grep_open_files, desc = "In currently open files" },
	{ "<leader>sp", "<cmd>LiveGrepGitRoot<cr>", desc = "In Git root (Project)" },
	{ "<leader>sr", "<cmd>Telescope resume<cr>", desc = "Resume last Search" },
	{ "<leader>su", "<cmd>Telescope undo<cr>", desc = "In File History" },
	{ "<leader>t", group = "Toggle option" },
	{
		"<leader>ta",
		'<cmd>lua require("settings.options").toggle_option("number")<cr>',
		desc = "Absolute Code Line Numbers",
	},
	{
		"<leader>tc",
		"<cmd>let &cole=(&cole == 2) ? 0 : 2 <bar> echo 'conceallevel ' . &cole <CR>",
		desc = "ConcealLevel",
	},
	{
		"<leader>tl",
		'<cmd>lua require("lsp_lines").toggle()<cr>',
		desc = "Toggle Lsp_Lines plugin",
	},
	{
		"<leader>tr",
		'<cmd>lua require("settings.options").toggle_option("relativenumber")<cr>',
		desc = "Relative Code Line Numbers",
	},
	{ "<leader>ts", "<cmd>ASToggle<cr>", desc = "Toggle Autosave" },
	{
		"<leader>tv",
		"<cmd>ToggleVirtualText<cr>",
		desc = "Toggle Diagnostic Virtual Lines",
	},
	{
		"<leader>tw",
		'<cmd>lua require("settings.options").toggle_option("wrap")<cr>',
		desc = "Wrap Text",
	},
	{ "<leader>w", group = "Window" },
	{ "<leader>wq", "<cmd>q!<cr>", desc = "Kill window" },
	{ "<leader>ww", "<C-w>w", desc = "Last window" },
	{ "<leader>y", ":%y+<cr>", desc = "Yank All Text" },
	{ "<leader>z", ":ZenMode<cr>", desc = "Zen Mode" },
	{ "<leader>n", ":NoNeckPain<cr>", desc = "Center buffer no ZenMode" },
	{ "<leader>J", group = "Java Spring Helpers" },
	-- set a vim motion to <Space> + <Shift>J + r to run the spring boot project in a vim terminal
	{ "<leader>Jr", '<cmd>:lua require("springboot-nvim").boot_run()<cr>', desc = "[J]ava [R]un Spring Boot" },
	-- set a vim motion to <Space> + <Shift>J + c to open the generate class ui to create a class
	{ "<leader>Jc", '<cmd>:lua require("springboot-nvim").generate_class()<cr>', desc = "[J]ava Create [C]lass" },
	-- set a vim motion to <Space> + <Shift>J + i to open the generate interface ui to create an interface
	{
		"<leader>Ji",
		'<cmd>:lua require("springboot-nvim").generate_interface()<cr>',
		desc = "[J]ava Create [I]nterface",
	},
	-- set a vim motion to <Space> + <Shift>J + e to open the generate enum ui to create an enum
	{ "<leader>Je", '<cmd>:lua require("springboot-nvim").generate_enum()<cr>', desc = "[J]ava Create [E]num" },
	{ "<leader>O", group = "Run tasks" },
	-- overseer.nvim
	{ "<leader>Os", "<cmd>OverseerRun<cr>", desc = "Overseer Run" },
	{ "<leader>OS", "<cmd>OverseerToggle!<cr>", desc = "Overseer Toggle" },
	{ "<leader>Oa", "<cmd>OverseerQuickAction<cr>", desc = "Overseer Quick Action" },
	{ "<leader>OA", "<cmd>OverseerTaskAction<cr>", desc = "Overseer Task Action" },
}
which_key.setup(setup)
which_key.add(mappings, opts)
