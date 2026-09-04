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

-- Removed 2026-09-02: CopilotChatHelpActions and CopilotChatPromptActions
-- required CopilotChat.actions and CopilotChat.integrations.fzflua, both of
-- which no longer exist upstream. CopilotChatPerplexitySearch passed
-- agent="perplexityai", a GitHub-Copilot concept with no meaning against a
-- local oMLX provider. Use <leader>acp (CopilotChatPrompts) instead of the
-- prompt picker, and /Docs7 in the chat for current documentation.

-- CopilotChat's prompt commands (:CopilotChatGraph and friends) are created by
-- its setup, so they do not exist before the plugin loads and a plain
-- <cmd>...<cr> mapping would fail with "Not an editor command". Load on demand,
-- then run. One helper beats maintaining the spec's `cmd` list per prompt.
-- Repo root for the tools that want an absolute path, not a filename.
local function repo_root()
	return vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
end

-- The code buffer these mappings are ABOUT, which is not necessarily the
-- current one: pressing a key with the CopilotChat window focused made
-- expand("%:.") return "copilot-chat", and serena was asked to outline a file
-- that does not exist. Prefer the current buffer when it is a real file, else
-- the first file buffer visible in this tab, else the alternate buffer.
local function code_path()
	local function usable(b)
		return b > 0
			and vim.api.nvim_buf_is_valid(b)
			and vim.bo[b].buftype == ""
			and vim.api.nvim_buf_get_name(b) ~= ""
	end
	local buf = vim.api.nvim_get_current_buf()
	if not usable(buf) then
		buf = nil
		for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local b = vim.api.nvim_win_get_buf(w)
			if usable(b) then
				buf = b
				break
			end
		end
		if not buf then
			local alt = vim.fn.bufnr("#")
			buf = usable(alt) and alt or nil
		end
	end
	if not buf then
		vim.notify("No file buffer to work on -- open the file first", vim.log.levels.WARN)
		return nil
	end
	return vim.api.nvim_buf_get_name(buf)
end

-- Relative to `root`: serena wants repo-relative, and expand("%:.") is relative
-- to cwd, which is not always the repo root.
local function rel_to(root, path)
	if root and path:sub(1, #root + 1) == root .. "/" then
		return path:sub(#root + 2)
	end
	return vim.fn.fnamemodify(path, ":t")
end

local function cc(command, arg)
	return function()
		require("lazy").load({ plugins = { "CopilotChat.nvim" } })
		vim.cmd(arg and (command .. " " .. arg()) or command)
	end
end

-- Individual :Ai* commands, so a mapping composes them the ordinary way:
--   "<cmd>AiIndex<cr><cmd>AiGraph<cr>"
-- Each command resolves what its prompt needs from the buffer (repo root, file
-- relative to it, symbol under the cursor), so the mappings stay plain strings
-- and every command is usable on its own from :.
--
-- Only AiIndex blocks. It is a dependency, and one submit is one tool round
-- (init.lua:638-665), so a query issued in the same tick would be sent while the
-- index was still building -- the stale-input failure that made the model invent
-- descriptions for 84 symbols. The completion signal is the chat buffer's
-- modifiable flag: Chat:start() clears it, Chat:finish() restores it
-- (chat.lua:467-485). AiIndex ERRORS on timeout, interrupt or a tool left
-- pending, and an error aborts the remaining commands in the mapping -- so a
-- failed dependency stops the sequence instead of feeding it a stale index.
-- Index freshness, per repo. Keyed by root, so several projects each keep their
-- own state and switching between them needs nothing extra.
--
-- A plain "already done this session" flag was wrong three ways: a checkout
-- replaces the code wholesale, a pull moves the ref without touching
-- .git/HEAD, and your own edits change files under a graph that still claims
-- to describe them. So the record carries the commit it was built from and is
-- compared, not just checked.
local indexed = {} -- root -> { head = <sha>, dirty = bool }
local last_head_check = {} -- root -> uv.now() ms, to throttle the subprocess

-- Resolved HEAD rather than the branch name: `git pull` and `git rebase` move
-- the ref while .git/HEAD keeps saying "ref: refs/heads/main", and the code
-- changed just as much as it does on a checkout. Empty string when this is not
-- a git repo, which then relies on writes alone.
local function git_head(root)
	local out = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "HEAD" })
	if vim.v.shell_error ~= 0 or not out[1] then
		return ""
	end
	return out[1]
end

-- Reported by AiFreshStatus only. Never used for staleness: a branch name
-- change at the SAME commit means the code on disk is byte-identical, so
-- re-indexing would be pure waste. `git checkout -b new` is exactly that case,
-- and watching .git/HEAD instead of the resolved SHA would fire a full re-index
-- of the whole repo for no change at all.
local function git_branch(root)
	local out = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" })
	if vim.v.shell_error ~= 0 or not out[1] then
		return "?"
	end
	return out[1]
end

local function index_stale(root)
	local rec = indexed[root]
	if not rec then
		return true, "not indexed yet"
	end
	-- A reason recorded at detection time wins, so the message you get when the
	-- index is rebuilt matches the message you got when the change was noticed.
	-- Clearing the record instead would report "not indexed yet" for a checkout,
	-- which is true but contradicts what the notification just said.
	if rec.stale_reason then
		return true, rec.stale_reason
	end
	if rec.dirty then
		return true, "files written since the last index"
	end
	if git_head(root) ~= rec.head then
		return true, "git HEAD moved since the last index"
	end
	return false
end

-- Notice a checkout as it happens rather than at query time, so the message
-- arrives while you still remember switching. This only marks the index stale;
-- the re-index itself runs on the next codebase-memory query.
--
-- It does NOT re-index here, and that is deliberate: a non-headless ask calls
-- M.open() when the chat is not focused (init.lua:451-458), so an auto-fired
-- reindex would pop the chat window open over the file you are editing. The
-- headless path does not open anything, but its completion is unobservable --
-- config.callback fires at init.lua:574, BEFORE the tool round runs at :605 --
-- so there would be no way to know when the index was actually built. Marking
-- it stale means you never type <leader>agi, and the wait lands when you have
-- asked a question and are already waiting for an answer.
local function head_changed(root, throttle_ms)
	if root == "" or vim.fn.isdirectory(root .. "/.git") == 0 then
		return
	end
	local rec = indexed[root]
	if not rec then
		return -- nothing indexed yet, so nothing to invalidate
	end
	local now = vim.uv.now()
	if throttle_ms and last_head_check[root] and (now - last_head_check[root]) < throttle_ms then
		return
	end
	last_head_check[root] = now
	local head = git_head(root)
	if head ~= rec.head then
		local short = head ~= "" and head:sub(1, 7) or "unknown"
		rec.stale_reason = "HEAD moved to " .. short
		vim.notify(
			vim.fs.basename(root)
				.. ": HEAD moved to "
				.. short
				.. " -- the graph will re-index on the next codebase query",
			vim.log.levels.INFO
		)
	end
end

local ai_fresh = vim.api.nvim_create_augroup("AiIndexFreshness", { clear = true })

-- A write under an indexed repo invalidates it. auto-save.nvim covers most
-- writes on its own; this fires for those too, since it is the write that
-- matters and not who asked for it.
vim.api.nvim_create_autocmd("BufWritePost", {
	group = ai_fresh,
	callback = function(ev)
		local file = ev.file or ""
		for root, rec in pairs(indexed) do
			if file:sub(1, #root + 1) == root .. "/" then
				rec.dirty = true
			end
		end
	end,
})

-- FocusGained catches a checkout made in another terminal, which is the common
-- one. DirChanged catches moving between projects. BufEnter catches a checkout
-- made inside nvim (fugitive, gitsigns) and is throttled, because it fires
-- constantly and each check is a git subprocess.
vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
	group = ai_fresh,
	callback = function()
		head_changed(repo_root())
	end,
})
vim.api.nvim_create_autocmd("BufEnter", {
	group = ai_fresh,
	callback = function()
		head_changed(repo_root(), 3000)
	end,
})

local function chat_idle()
	local cc = package.loaded["CopilotChat"]
	local buf = cc and cc.chat and cc.chat.bufnr
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return true
	end
	return vim.bo[buf].modifiable
end

-- finish() also ends a round when a tool needs approval, writing a #name:id
-- marker for <CR> to resume (init.lua:177-182). The modifiable flag cannot tell
-- that from success, so it is checked separately.
local function chat_pending()
	local cc = package.loaded["CopilotChat"]
	local ok, msg = pcall(function()
		return cc.chat:get_message("user")
	end)
	return ok and msg and (msg.content or ""):match("#[%w_]+:%S") ~= nil
end

-- MCP tools must EXIST before a prompt that grants them is submitted, and
-- nothing guarantees that on its own.
--
-- mcphub is `cmd = { "MCPHub" }`, so it loads only when you run :MCPHub. Its
-- CopilotChat extension is what writes MCP tools into
-- CopilotChat.config.functions (extensions/copilotchat/functions.lua:315-328),
-- registering on setup and again on every servers_updated. Two consequences:
--   * the extension early-returns when CopilotChat is not loaded yet
--     (extensions/copilotchat/init.lua:18-21), so CopilotChat must load FIRST
--   * the tools only exist once the MCP servers have connected, which is async
--
-- Miss either and the failure is SILENT: resolve_tools matches names against
-- config.functions and drops whatever it cannot find (prompts.lua:74-89), so
-- the model is handed a prompt telling it to call a tool it has no schema for
-- -- and it invents the answer. Measured, not hypothetical: an AiIndex run
-- reported 12 nodes / 8 edges for a repo whose real index is 286 nodes / 748
-- edges, with no tool message anywhere in the transcript.
-- `needs` is a "are the MCP tools registered at all" gate, not a manifest of
-- everything a prompt grants. One representative name per server is enough --
-- requiring all of them would let a single absent optional tool block the
-- command forever, and a tool missing from a prompt's own `tools` list is
-- dropped silently by resolve_tools, which is the pre-existing behaviour.
local function tools_ready(names, timeout_ms)
	require("lazy").load({ plugins = { "CopilotChat.nvim" } })
	require("lazy").load({ plugins = { "mcphub.nvim" } })
	if not names or #names == 0 then
		return
	end
	local function have()
		local cc = package.loaded["CopilotChat"]
		local fns = cc and cc.config and cc.config.functions
		if not fns then
			return false
		end
		for _, n in ipairs(names) do
			if not fns[n] then
				return false
			end
		end
		return true
	end
	if have() then
		return
	end
	vim.notify("waiting for MCP servers to register their tools...", vim.log.levels.INFO)
	if not vim.wait(timeout_ms or 20000, have, 200) then
		local cc = package.loaded["CopilotChat"]
		local fns = (cc and cc.config and cc.config.functions) or {}
		local missing = {}
		for _, n in ipairs(names) do
			if not fns[n] then
				table.insert(missing, n)
			end
		end
		error(
			"MCP tools never registered: "
				.. table.concat(missing, ", ")
				.. ". Run :MCPHub and check the servers are connected. Refusing to ask "
				.. "without them -- the model would invent the answer.",
			0
		)
	end
end

-- How many tool results the conversation holds. Compared across a submit, this
-- is the only proof a tool actually RAN: a model that was granted no tool
-- answers in prose that looks identical to a real result, and the chat goes
-- busy then idle either way.
local function tool_message_count()
	local cc = package.loaded["CopilotChat"]
	local ok, msgs = pcall(function()
		return cc.chat:get_messages()
	end)
	if not ok or not msgs then
		return 0
	end
	local n = 0
	for _, m in ipairs(msgs) do
		if m.role == "tool" then
			n = n + 1
		end
	end
	return n
end

local function ai(name, fn, opts)
	opts = opts or {}
	local needs = opts.needs
	opts.needs = nil
	vim.api.nvim_create_user_command("Ai" .. name, function(a)
		tools_ready(needs)
		fn(a)
	end, opts)
end

-- Bail loudly rather than send an empty argument, which the model would then
-- invent a target for.
-- Every reader here works from DISK, never from your buffers: serena opens the
-- file, and index_repository walks the tree.
--
-- auto-save.nvim is configured with debounce_delay = 5000, so there is a FIVE
-- SECOND window after you stop typing where the file on disk is still the old
-- one. "Change something and immediately ask about it" lands inside that
-- window every time, and the answer is then about the previous version -- with
-- correct line numbers for it, which is what makes it convincing. So this is
-- not redundant with autosave; it closes autosave's debounce gap and is a
-- no-op the rest of the time. Silent, because it does exactly what autosave
-- would have done a few seconds later.
--
-- Called at the TOP of AiIndex as well, not only from need_file: in
-- "<cmd>AiIndex<cr><cmd>AiGraph<cr>" the index is built first, so a write that
-- happened inside AiGraph would land after the graph was already built from the
-- old code -- answering from a stale index it had just refreshed.
local function write_modified(under)
	local wrote = {}
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) or ""
		local match = name ~= "" and (name == under or name:sub(1, #under + 1) == under .. "/")
		if match and vim.bo[b].modified and vim.bo[b].buftype == "" then
			vim.api.nvim_buf_call(b, function()
				vim.cmd("silent write")
			end)
			table.insert(wrote, vim.fn.fnamemodify(name, ":t"))
		end
	end
	return wrote
end

local function need_file()
	local p = code_path()
	if not p then
		error("no file buffer to work on", 0)
	end
	write_modified(p)
	return repo_root(), p
end

-- codebase-memory's project id, derived from the repo root: leading "/" dropped,
-- every "/" turned into "-". Verified against all four indexed projects as
-- list_projects reports them (omlx-gates, ansible, osgi-gateway, mini-orm).
--
-- This used to be HARDCODED in the Graph, Trace and Coverage prompts, which
-- meant pressing those keys in any other repo queried omlx-gates' graph and
-- described a different codebase without saying so. If the slug rule ever stops
-- matching, the tool answers "project is required" and lists the real ids --
-- an error, not a wrong answer, which is the failure mode to prefer.
local function project_id()
	local root = repo_root()
	return (root:gsub("^/", ""):gsub("/", "-"))
end

-- A regex matching top-level definitions, per language, for search_code's
-- freshness oracle. Deliberately free of literal spaces so the whole thing can
-- travel as one key=value token.
--
-- The pattern used to be hardcoded to Python's `^(def|class) ` in the Graph and
-- Coverage prompts. On a Java or YAML repo that matches nothing, so the raw:
-- section comes back empty -- and an empty raw: is what those prompts read as
-- "the index is current". The staleness oracle would have reported fresh on
-- every non-Python project, permanently. Absence of evidence read as evidence.
--
-- Returns nil for a language with no usable pattern, and the prompts then say
-- freshness could not be assessed instead of assuming it passed.
local DEF_PATTERNS = {
	python = "^[ \t]*(def|class)[ \t]",
	lua = "^[ \t]*(local[ \t]+)?function[ \t]",
	go = "^(func|type)[ \t]",
	rust = "^[ \t]*(pub[ \t]+)?(fn|struct|enum|impl|trait)[ \t]",
	java = "^[ \t]*(public|private|protected|static|final|abstract|class|interface|enum)[ \t]",
	kotlin = "^[ \t]*(fun|class|object|interface)[ \t]",
	c = "^[a-zA-Z_].*[(]",
	cpp = "^[a-zA-Z_].*[(]",
	ruby = "^[ \t]*(def|class|module)[ \t]",
	sh = "^[a-zA-Z_][a-zA-Z0-9_]*[(][)]",
	bash = "^[a-zA-Z_][a-zA-Z0-9_]*[(][)]",
}
DEF_PATTERNS.javascript = "^[ \t]*(function|class|export|const|let)[ \t]"
DEF_PATTERNS.typescript = DEF_PATTERNS.javascript
DEF_PATTERNS.typescriptreact = DEF_PATTERNS.javascript
DEF_PATTERNS.javascriptreact = DEF_PATTERNS.javascript

local function def_pattern(path)
	local ft = vim.filetype.match({ filename = path }) or ""
	return DEF_PATTERNS[ft]
end

-- <cword> is wherever the CURSOR is, which is not necessarily code. Pressed with
-- the chat window focused it once sent "copilot-chat" as a symbol name, and
-- with the cursor in a path it sent "usr" -- a plausible-looking identifier that
-- passes the %w_ check and costs a whole round. So the word is only taken from a
-- real file buffer; anywhere else, ask.
local function need_symbol(what)
	local in_code = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= ""
	local w = in_code and vim.fn.expand("<cword>") or ""
	if not w:match("^[%w_]+$") then
		w = vim.fn.input(what .. " which symbol: ")
	end
	if w == "" then
		error("no symbol given", 0)
	end
	return w
end

ai("Index", function(a)
	local root = repo_root()
	-- Flush before the staleness check, not after: an unwritten buffer IS
	-- staleness, and the BufWritePost autocmd above turns the write into the
	-- dirty flag that index_stale reads. Doing it the other way round indexes
	-- the old file and then writes the new one.
	write_modified(root)
	local stale, why = index_stale(root)
	if not stale and not a.bang then
		return -- index still matches this HEAD and nothing has been written since
	end
	vim.notify(
		"re-indexing " .. vim.fs.basename(root) .. ": " .. (why or "forced"),
		vim.log.levels.INFO
	)
	local tools_before = tool_message_count()
	vim.cmd("CopilotChatReindex " .. root)
	-- vim.wait pumps the event loop but blocks input: nvim is unresponsive while
	-- a large repo indexes. <C-c> interrupts, and that aborts the sequence.
	if not vim.wait(15000, function()
		return not chat_idle()
	end, 100) then
		error("AiIndex: reindex never started", 0)
	end
	if not vim.wait(900000, chat_idle, 250) then
		error("AiIndex: reindex did not finish (interrupted or timed out)", 0)
	end
	if chat_pending() then
		error("AiIndex: index_repository is waiting for approval -- press <CR> in the chat", 0)
	end
	-- The round finishing proves nothing about the tool having run. A model with
	-- no tool schema writes a plausible JSON reply instead, and the chat goes
	-- busy then idle exactly as it would on success. Only a NEW tool-role message
	-- proves it. Without this the stamp records a fabricated index, which is
	-- strictly worse than having no freshness tracking at all.
	if tool_message_count() <= tools_before then
		error(
			"AiIndex: the round finished with no tool result -- index_repository did "
				.. "not run, and the reply in the chat is invented. Index NOT marked fresh.",
			0
		)
	end
	-- Stamp with the HEAD read AFTER indexing: if the checkout moved while the
	-- index was building, the stamp records what was actually read, so the next
	-- press re-indexes rather than trusting a half-old graph.
	indexed[root] = { head = git_head(root), dirty = false }
end, { bang = true, needs = { "codebase_memory_mcp_index_repository" },
	desc = "Re-index if HEAD moved or files were written (! always). Blocks." })

-- Self-test for the assumption the chains rest on.
--
-- "<cmd>AiIndex<cr><cmd>AiGraph<cr>" is only safe if an error in the first
-- command aborts the rest of the sequence -- otherwise a failed index is
-- followed by a query against it, which is the whole thing this was built to
-- prevent. That abort is Vim typeahead behaviour, not something this config
-- controls, so it can change under an nvim upgrade and should be re-checkable.
--
-- The verdict is reported from vim.schedule, which runs after the typeahead has
-- been processed: by then the marker either ran or it did not. Reporting from
-- inside the sequence cannot work, because if the abort DOES happen nothing
-- later in the sequence gets to report anything.
local abort_probe_reached = false

-- Why did (or did not) a checkout get noticed? This prints the whole freshness
-- state rather than leaving you to infer it from an absent notification.
--
-- The common answer is "no stamp": head_changed() early-returns when the repo
-- has not been indexed in THIS nvim session, because there is no HEAD to
-- compare against and it avoids a git subprocess on every BufEnter in repos you
-- never query. Reloading this file resets the table, so a reload counts as a
-- new session. Silence in that state is correct, not broken -- and harmless,
-- because the first AiIndex of any session re-indexes anyway ("not indexed
-- yet"), so a checkout made between sessions is covered without detection.
vim.api.nvim_create_user_command("AiFreshStatus", function()
	local root = repo_root()
	local rec = indexed[root]
	local out = {
		"repo_root()  " .. root,
		"project_id() " .. project_id(),
		"git HEAD     " .. (git_head(root) ~= "" and git_head(root) or "(not a git repo)"),
		"git branch   " .. git_branch(root) .. "   (name is NOT what staleness compares)",
		"code_path()  " .. (code_path() or "(no file buffer)"),
		"defs=        " .. (code_path() and (def_pattern(code_path()) or "none") or "-"),
		"",
	}
	if rec then
		table.insert(out, "stamped head  " .. (rec.head ~= "" and rec.head or "(empty)"))
		table.insert(out, "dirty         " .. tostring(rec.dirty))
		table.insert(out, "stale_reason  " .. (rec.stale_reason or "(none)"))
		local stale, why = index_stale(root)
		table.insert(out, "index_stale   " .. tostring(stale) .. (why and (" -- " .. why) or ""))
		table.insert(out, "=> a checkout WOULD be noticed on FocusGained/DirChanged/BufEnter")
		table.insert(out, "   ...but only if it moves the COMMIT. `git checkout -b foo` points a")
		table.insert(out, "   new name at the same commit, so the code is identical and nothing")
		table.insert(out, "   fires -- correctly. To exercise detection, move HEAD:")
		table.insert(out, "     git -C <repo> commit --allow-empty -m probe   (undo: reset --soft HEAD~1)")
	else
		table.insert(out, "NO STAMP for this repo in this nvim session.")
		table.insert(out, "=> checkout detection is disabled here until you index once.")
		table.insert(out, "   Run <leader>agg first, THEN switch branch, then come back.")
		table.insert(out, "   (Harmless: the first AiIndex of a session re-indexes regardless.)")
	end
	table.insert(out, "")
	local n = #vim.api.nvim_get_autocmds({ group = "AiIndexFreshness" })
	table.insert(out, "freshness autocmds registered: " .. n .. " (expect 4)")
	table.insert(out, "other repos stamped this session:")
	local any = false
	for r, v in pairs(indexed) do
		if r ~= root then
			any = true
			table.insert(out, "  " .. r .. "  head=" .. (v.head or ""):sub(1, 7) .. " dirty=" .. tostring(v.dirty))
		end
	end
	if not any then
		table.insert(out, "  (none)")
	end
	vim.api.nvim_echo({ { table.concat(out, "\n") } }, true, {})
end, { desc = "Print index-freshness state: stamps, HEAD, autocmds" })

vim.api.nvim_create_user_command("AiAbortMark", function()
	abort_probe_reached = true
end, { desc = "Marker used by AiAbortProbe; meaningless on its own" })

vim.api.nvim_create_user_command("AiAbortProbe", function()
	abort_probe_reached = false
	vim.schedule(function()
		local verdict, hl, level
		if abort_probe_reached then
			verdict = "AiAbortProbe FAIL: a <cmd> sequence CONTINUES past an error. "
				.. "AiIndex failing does NOT stop AiGraph -- the chain guard is "
				.. "decorative and needs replacing with an explicit flag."
			hl, level = "ErrorMsg", vim.log.levels.ERROR
		else
			verdict = "AiAbortProbe PASS: a <cmd> sequence aborts at the first error, "
				.. "so AiIndex failing really does stop AiGraph. The error above it was "
				.. "deliberate."
			hl, level = "MoreMsg", vim.log.levels.INFO
		end
		-- Both, on purpose. notify() may be routed through a plugin (noice) and
		-- shown as a transient popup that the deliberate error immediately
		-- replaces; nvim_echo with history=true always lands in :messages, so the
		-- verdict survives being missed. A self-test whose result you cannot find
		-- is not a self-test.
		vim.api.nvim_echo({ { verdict, hl } }, true, {})
		vim.notify(verdict, level)
	end)
	-- The traceback this prints is unavoidable and expected. nvim wraps ANY
	-- error raised in a :command callback with one, and the abort depends on a
	-- real error being raised -- nvim_err_writeln prints without aborting, which
	-- would break the test. Routing it through vim.cmd("throw ...") was tried and
	-- is worse: the Vimscript error comes back through nvim_exec2 as a Lua error
	-- anyway, adding two frames rather than removing the traceback. Read the
	-- PASS/FAIL line below it; that is the result.
	error("AiAbortProbe: deliberate error -- this IS the test", 0)
end, { desc = "Self-test: does an error abort the rest of a <cmd> sequence?" })

ai("Graph", function()
	local _, p = need_file()
	vim.cmd(
		"CopilotChatGraph project="
			.. project_id()
			.. " file="
			.. vim.fn.fnamemodify(p, ":t")
			.. " defs="
			.. (def_pattern(p) or "none")
	)
end, { needs = { "codebase_memory_mcp_search_graph" }, desc = "Graph the current file (codebase-memory)" })

ai("Trace", function()
	vim.cmd("CopilotChatTrace " .. project_id() .. " " .. need_symbol("Trace"))
end, { needs = { "codebase_memory_mcp_search_graph" }, desc = "Trace the symbol under the cursor" })

ai("Arch", function()
	vim.cmd("CopilotChatArchitecture project=" .. project_id())
end, { needs = { "codebase_memory_mcp_get_architecture" }, desc = "Project architecture" })

ai("Coverage", function()
	local _, p = need_file()
	vim.cmd(
		"CopilotChatCoverage project="
			.. project_id()
			.. " file="
			.. vim.fn.fnamemodify(p, ":t")
			.. " defs="
			.. (def_pattern(p) or "none")
	)
end, { needs = { "codebase_memory_mcp_index_status" }, desc = "Is the graph current?" })

ai("Outline", function()
	local root, p = need_file()
	vim.cmd("CopilotChatOutline " .. root .. " " .. rel_to(root, p))
end, { needs = { "serena_get_symbols_overview" }, desc = "Name index for the current file (serena)" })

ai("Where", function()
	local root, p = need_file()
	vim.cmd("CopilotChatWhere " .. root .. " " .. rel_to(root, p) .. " " .. need_symbol("Where"))
end, { needs = { "serena_find_symbol" }, desc = "What is this symbol (serena)" })

ai("How", function()
	local root, p = need_file()
	vim.cmd("CopilotChatHow " .. root .. " " .. rel_to(root, p) .. " " .. need_symbol("Explain"))
end, { needs = { "serena_find_symbol" }, desc = "How this symbol works, from source (serena)" })

-- CopilotChat history lives here; one picker loads or deletes, save names by repo
local CHAT_HISTORY = vim.fn.stdpath("data") .. "/copilotchat_history"

local function chat_save()
	vim.ui.input({ prompt = "Save chat as: ", default = vim.fs.basename(repo_root()) }, function(name)
		if name and name ~= "" then
			require("lazy").load({ plugins = { "CopilotChat.nvim" } })
			vim.cmd("CopilotChatSave " .. name)
		end
	end)
end

local function chat_history()
	local names = vim.tbl_map(function(f)
		return vim.fn.fnamemodify(f, ":t:r")
	end, vim.fn.glob(CHAT_HISTORY .. "/*.json", true, true))
	if #names == 0 then
		return vim.notify("no saved chats in " .. CHAT_HISTORY, vim.log.levels.INFO)
	end
	require("fzf-lua").fzf_exec(names, {
		prompt = "chats> ",
		fzf_opts = { ["--multi"] = "" },
		actions = {
			["default"] = function(sel)
				require("lazy").load({ plugins = { "CopilotChat.nvim" } })
				vim.cmd("CopilotChatLoad " .. sel[1])
				vim.cmd("CopilotChatOpen")
			end,
			["ctrl-x"] = function(sel)
				for _, n in ipairs(sel) do
					os.remove(CHAT_HISTORY .. "/" .. n .. ".json")
				end
				vim.notify("deleted " .. #sel .. " chat(s)")
			end,
		},
	})
end

-- Compact the live chat: summarise it, then replace the buffer with the summary.
-- CopilotChat has no compaction of its own. Two things shape this:
--   * headless=true sends NO chat history (init.lua:536-538), so the transcript
--     goes in the prompt body and nothing is sent twice.
--   * M.load() already does clear -> add_message -> finish correctly
--     (init.lua:740), so the summary is written as a history file and loaded,
--     rather than reimplementing that sequence by hand.
local COMPACT_BUDGET = 60000 -- chars of transcript, ~15k tokens, fits 49152 input

local function chat_compact()
	local cc = package.loaded["CopilotChat"]
	if not cc then
		return vim.notify("CopilotChat is not loaded", vim.log.levels.WARN)
	end
	local msgs = cc.chat:get_messages()
	if #msgs < 2 then
		return vim.notify("nothing to compact", vim.log.levels.INFO)
	end

	-- Newest first until the budget runs out, so a long chat keeps its recent end.
	-- Tool results are the bulk -- a /Graph map is ~14k tokens -- so each keeps only
	-- a stub: enough for the summary to say what ran, not to carry the payload.
	local parts, used, dropped = {}, 0, 0
	for i = #msgs, 1, -1 do
		local m = msgs[i]
		local cap = (m.role == "tool" or m.tool_call_id) and 400 or 4000
		local c = m.content or ""
		if #c > cap then
			c = c:sub(1, cap) .. "\n[truncated]"
		end
		local block = ("## %s\n%s"):format(m.role, c)
		if used + #block > COMPACT_BUDGET then
			dropped = dropped + 1
		else
			table.insert(parts, 1, block)
			used = used + #block
		end
	end

	local stamp = os.date("%Y%m%d-%H%M")
	cc.save("precompact-" .. stamp) -- full fidelity on disk BEFORE anything destructive

	-- ponytail: a sticky tool grant from /How or /Where can still ride along on this
	-- ask; the config has no way to say "no tools". Harmless for a summarise prompt
	-- with no repo context. If it ever fires a tool round, reset before compacting.
	cc.ask(
		"Below is a transcript of a working conversation, oldest first. Compact it "
			.. "into a handoff another session can pick up from.\n"
			.. "Keep: decisions and what they rested on; findings with the file, line or "
			.. "number they came from; anything still open.\n"
			.. "Keep corrections AS corrections. If something was claimed and later "
			.. "disproved, record both -- \"thought X, disproved by Y\" -- never the claim "
			.. "alone. A summary that preserves a retracted claim is worse than no "
			.. "summary, because the next reader cannot tell it was retracted.\n"
			.. "Drop: tool payloads, restated code, anything already superseded.\n"
			.. "Omit any section that has nothing in it.\n"
			.. "OUTPUT FORMAT, and this part is mechanical: put the handoff between "
			.. "<handoff> and </handoff> and put NOTHING outside those tags. No "
			.. "preamble, no restating these instructions, no working out, no draft "
			.. "followed by a final version, no checklist of whether you followed the "
			.. "rules. Everything outside the tags is discarded, so anything you write "
			.. "there is wasted. The first thing after <handoff> is the first line of "
			.. "the summary.\n\n---\n\n"
			.. table.concat(parts, "\n\n"),
		{
			headless = true,
			remember_as_sticky = false,
			callback = function(response)
				local raw = vim.trim(response and response.content or "")
				-- Extract between the tags. The first attempt asked for "no preamble"
				-- and got the model's entire deliberation -- "I need to extract... I
				-- will structure... Draft: ... Final check against constraints...
				-- Ready." -- followed by the summary twice, about three times the
				-- size of the thing it was compacting. A delimiter makes the
				-- extraction deterministic instead of a matter of compliance.
				local summary = raw:match("<handoff>(.-)</handoff>")
				if summary then
					summary = vim.trim(summary)
				else
					-- No tags: keep everything rather than lose the summary, but say so,
					-- because the result will carry whatever else the model wrote.
					summary = raw
					vim.notify(
						"compact: no <handoff> tags in the reply -- kept the whole response, expect noise",
						vim.log.levels.WARN
					)
				end
				if summary == "" then
					return vim.notify("compact produced nothing; chat left alone", vim.log.levels.WARN)
				end
				local name = "compact-" .. stamp
				local f = io.open(CHAT_HISTORY .. "/" .. name .. ".json", "w")
				if not f then
					return vim.notify("could not write " .. name, vim.log.levels.ERROR)
				end
				f:write(vim.json.encode({
					{
						role = "user",
						content = "Compacted context from the previous conversation:\n\n" .. summary,
					},
				}))
				f:close()
				-- schedule: let the ask unwind before load() calls stop(true) under it
				vim.schedule(function()
					cc.load(name)
					vim.notify(
						("compacted %d messages%s -- original saved as precompact-%s"):format(
							#msgs,
							dropped > 0 and (", %d oldest dropped"):format(dropped) or "",
							stamp
						),
						vim.log.levels.INFO
					)
				end)
			end,
		}
	)
end

-- Autosave the chat on exit. CopilotChat has no autosave and no VimLeave hook of
-- its own (checked: init.lua M.save/M.load are the only writers), and closing the
-- chat window does not clear the messages, so only quitting nvim loses them.
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("CopilotChatAutosave", { clear = true }),
	callback = function()
		local chat = package.loaded["CopilotChat"]
		if not chat then
			return
		end
		-- ponytail: pcall because chat.chat exists only once the window has opened
		pcall(function()
			if #chat.chat:get_messages() > 0 then
				chat.save(vim.fs.basename(repo_root()))
			end
		end)
	end,
})

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
-- Bazel
local function goto_closest_file(filename)
	return function()
		local files = vim.fs.find(filename, {
			upward = true,
			path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
		})

		if #files > 0 then
			vim.cmd("e " .. files[1])
		end
	end
end

local function bazel_override()
	vim.ui.input({}, function(input)
		if not input then
			return
		end
		goto_closest_file("MODULE.bazel")()
		vim.cmd("!bzloverride " .. input)
		vim.fn.feedkeys("G", "n")
	end)
end

local function bzlmod_add()
	vim.ui.input({}, function(input)
		if not input then
			return
		end
		goto_closest_file("MODULE.bazel")()
		vim.cmd("!bzlmod add " .. input)
	end)
end

local function bazel_debug_lldb(callback)
	local bazel = require("bazel")
	bazel.get_target_list(function(targets)
		vim.ui.select(targets, {
			prompt = "Select target to debug",
			format_item = function(target)
				return target.label .. " (" .. target.kind .. ")"
			end,
		}, function(target)
			bazel.target_executable_path("@llvm_toolchain_llvm//:bin/lldb-dap", function(lldb_dap_path)
				--- @type dap.ExecutableAdapter
				local adapter = {
					type = "executable",
					command = lldb_dap_path,
					name = "lldb",
					args = {},
				}

				callback(target, adapter)
			end)
		end)
	end)
end

local function bazel_debug_launch()
	bazel_debug_lldb(function(target, adapter)
		local bazel = require("bazel")
		local dap = require("dap")

		bazel.info({ "execution_root", "workspace" }, function(info)
			bazel.target_executable_path(target.label, function(target_executable_path)
				--- @type dap.Configuration
				local config = {
					name = target.label,
					type = "lldb",
					request = "launch",
					program = info.execution_root .. "/" .. target_executable_path,
					cwd = info.workspace,
					stopOnEntry = false,
					args = {},
					initCommands = {
						"process handle -s false -n false SIGWINCH",
					},
					preRunCommands = {
						"settings set target.language c++20",
						"breakpoint set -E c++ -G true",
						"settings set target.auto-source-map-relative true",
						"settings set target.source-map . " .. info.workspace .. " /proc/self/cwd " .. info.workspace,
					},
				}

				dap.launch(adapter, config, {})
			end)
		end)
	end)
end

local function bazel_debug_attach()
	bazel_debug_lldb(function(target, adapter)
		local bazel = require("bazel")
		local dap = require("dap")

		bazel.info({ "execution_root", "workspace" }, function(info)
			bazel.target_executable_path(target.label, function(target_executable_path)
				--- @type dap.Configuration
				local config = {
					name = target.label,
					type = "lldb",
					request = "attach",
					waitFor = true,
					program = info.execution_root .. "/" .. target_executable_path,
					cwd = info.workspace,
					stopOnEntry = false,
					args = {},
					initCommands = {
						"process handle -s false -n false SIGWINCH",
					},
					preRunCommands = {
						"settings set target.language c++23",
						"breakpoint set -E c++ -G true",
						"settings set target.auto-source-map-relative true",
						"settings set target.source-map . " .. info.workspace .. " /proc/self/cwd " .. info.workspace,
					},
				}

				dap.launch(adapter, config, {})
			end)
		end)
	end)
end

vim.api.nvim_create_user_command("BazelDebug", bazel_debug_launch, {})
vim.api.nvim_create_user_command("BazelDebugAttachWait", bazel_debug_attach, {})

vim.api.nvim_create_user_command("BazelBuildFile", goto_closest_file("BUILD.bazel"), {})
vim.api.nvim_create_user_command("BazelModuleFile", goto_closest_file("MODULE.bazel"), {})
vim.api.nvim_create_user_command("BazelWorkspace", goto_closest_file("WORKSPACE.bazel"), {})
vim.api.nvim_create_user_command("BazelRcFile", goto_closest_file(".bazelrc"), {})
vim.api.nvim_create_user_command("BazelOverride", bazel_override, {})
vim.api.nvim_create_user_command("BazelAddToModule", bzlmod_add, {})
-- Debug
local function get_procs(cb)
	local is_windows = vim.fn.has("win32") == 1
	local separator = is_windows and "," or " \\+"
	local proc = is_windows and "tasklist" or "ps"
	local args = is_windows and { "/nh", "/fo", "csv" } or { "ah", "-U", os.getenv("USER") }
	local stdout = vim.uv.new_pipe()
	-- local stderr = vim.uv.new_pipe()
	local stdout_str = ""

	local get_pid = function(parts)
		if is_windows then
			return vim.fn.trim(parts[2], '"')
		else
			return parts[1]
		end
	end

	local get_process_name = function(parts)
		if is_windows then
			return vim.fn.trim(parts[1], '"')
		else
			local proc_path = table.concat({ unpack(parts, 5) }, " ")
			if vim.startswith(proc_path, "/") then
				return vim.fn.fnamemodify(proc_path, ":t")
			else
				return nil
			end
		end
	end

	vim.uv.spawn(proc, {
		stdio = { nil, stdout, nil },
		args = args,
		hide = true,
	}, function(code, _)
		vim.schedule(function()
			if code == 0 then
				local procs = {}
				for _, line in ipairs(vim.fn.split(stdout_str, "\n")) do
					local parts = vim.fn.split(vim.fn.trim(line), separator)
					local pid, name = get_pid(parts), get_process_name(parts)
					pid = tonumber(pid)
					if name ~= nil then
						table.insert(procs, { name = name, pid = pid })
					end
				end
				cb(procs)
			else
				vim.notify("process find failed", vim.log.levels.ERROR)
			end
		end)
	end)

	vim.uv.read_start(stdout, function(err, data)
		if data ~= nil then
			stdout_str = stdout_str .. data
		end
	end)
end

local function fix_dos_format()
	local dir = "tests/*"
	local cmd = string.format("dos2unix %s", dir)
	vim.cmd("!" .. cmd .. " && exit")
end

vim.api.nvim_create_user_command("FixDosFormat", fix_dos_format, {})

local function debug_attach()
	get_procs(function(procs)
		local largest_name_len = 1
		for _, proc in ipairs(procs) do
			if #proc.name > largest_name_len then
				largest_name_len = #proc.name
			end
		end
		vim.ui.select(procs, {
			prompt = "Attach to process",
			format_item = function(item)
				return item.name
					.. string.rep(" ", largest_name_len - #item.name)
					.. " (pid="
					.. tostring(item.pid)
					.. ")"
			end,
		}, function(choice)
			if choice ~= nil then
				local dap = require("dap")
				---@diagnostic disable-next-line: missing-parameter
				dap.launch({
					type = "executable",
					command = "lldb-dap-19",
					args = {},
					options = {},
				}, {
					name = "Attach to " .. choice.name,
					type = "lldb-dap",
					request = "attach",
					pid = choice.pid,
					stopOnEntry = false,
					-- program = choice.name,
					initCommands = {
						"process handle -s false -n false SIGWINCH",
					},
					postRunCommands = {
						"settings set target.language c++23",
						"breakpoint set -E c++ -G true",
						"settings set target.source-map /proc/self/cwd " .. vim.uv.cwd(),
					},
				})
			end
		end)
	end)
end

vim.api.nvim_create_user_command("LldbDebugAttach", debug_attach, {})
-- ------------------------------------------------------------------
-- 1️⃣  Helper: create a terminal that can be toggled
-- ------------------------------------------------------------------
local Terminal = require("toggleterm.terminal").Terminal
local horizontal_term = Terminal:new({
	direction = "horizontal",
	hidden = true,
	highlights = { border = { "FloatBorder", "Normal" } },
})
vim.api.nvim_create_user_command("ExecInTermHorizontal", function(params)
	local args = type(params) == "table" and params.args or { params }
	vim.notify("[ExecInTermHorizontal] args = " .. vim.inspect(args), vim.log.levels.INFO)
	horizontal_term:toggle().send(horizontal_term, args)
end, {
	nargs = "*",
	desc = "Toggle a horizontal terminal and exec the given command",
	bang = false,
})
local mappings = {
	{ "<leader>R", ":%d+<cr>", desc = "Remove All Text" },
	{ "<leader>a", group = "AI" },

	-- CopilotChat: session and window
	{ "<leader>ac", group = "CopilotChat" },
	{ "<leader>aca", "<cmd>CopilotChatAsk<cr>", desc = "Ask (input prompt)" },
	{ "<leader>acw", cc("CopilotChatToggle"), desc = "Toggle chat window" },
	{ "<leader>acm", cc("CopilotChatModels"), desc = "Pick model" },
	{ "<leader>acp", cc("CopilotChatPrompts"), desc = "Pick prompt" },
	{ "<leader>acx", cc("CopilotChatStop"), desc = "Stop generating" },
	{ "<leader>acR", cc("CopilotChatReset"), desc = "Reset conversation" },
	{ "<leader>acS", chat_save, desc = "Save session (prompts for a name)" },
	{ "<leader>ach", chat_history, desc = "History — <CR> load, <C-x> delete" },
	{ "<leader>acC", chat_compact, desc = "Compact chat (summarise, keep a backup)" },

	-- CopilotChat: on the selection or buffer
	{ "<leader>ace", cc("CopilotChatExplain"), desc = "Explain", mode = { "n", "v" } },
	{ "<leader>acr", cc("CopilotChatReview"), desc = "Review — defects only", mode = { "n", "v" } },
	{ "<leader>acb", cc("CopilotChatBoilerplate"), desc = "Boilerplate", mode = { "n", "v" } },
	{ "<leader>act", cc("CopilotChatTests"), desc = "Tests", mode = { "n", "v" } },
	{ "<leader>acf", cc("CopilotChatFix"), desc = "Fix", mode = { "n", "v" } },
	{ "<leader>aco", cc("CopilotChatOptimize"), desc = "Optimize", mode = { "n", "v" } },
	{ "<leader>acd", cc("CopilotChatDocs"), desc = "Docs", mode = { "n", "v" } },
	{ "<leader>acc", cc("CopilotChatCommit"), desc = "Commit message" },

	-- Codebase questions. Graph and Trace take an argument, so they are
	-- prefilled from the buffer name and the word under the cursor.
	{ "<leader>ag", group = "Codebase (graph)" },

	-- codebase-memory prompts read the index, so AiIndex goes first. It blocks and
	-- errors on failure, which aborts the rest of the sequence -- so a query never
	-- runs against an index that did not build. Once per repo per session.
	{ "<leader>agg", "<cmd>AiIndex<cr><cmd>AiGraph<cr>", desc = "Graph THIS file" },
	{ "<leader>agt", "<cmd>AiIndex<cr><cmd>AiTrace<cr>", desc = "Trace symbol under cursor" },
	{ "<leader>aga", "<cmd>AiIndex<cr><cmd>AiArch<cr>", desc = "Project architecture" },
	{ "<leader>agc", "<cmd>AiCoverage<cr>", desc = "Is the graph current?" },
	{ "<leader>agi", "<cmd>AiIndex!<cr>", desc = "Re-index this repo (force)" },

	-- Verifies the assumption every chained ag* mapping depends on. Expect one
	-- deliberate error message, then a PASS or FAIL notification.
	{ "<leader>at", "<cmd>AiAbortProbe<cr><cmd>AiAbortMark<cr>", desc = "Self-test: <cmd> chain aborts on error?" },
	{ "<leader>aF", "<cmd>AiFreshStatus<cr>", desc = "Why was/wasn't a checkout noticed?" },

	-- serena prompts read real source, not the index, so they are NOT chained
	-- through AiIndex, and activate_project already fits inside their round.
	{ "<leader>ago", "<cmd>AiOutline<cr>", desc = "Outline THIS file (serena)", mode = { "n", "v" } },
	{ "<leader>agw", "<cmd>AiWhere<cr>", desc = "What is this symbol (serena)", mode = { "n", "v" } },
	{ "<leader>agh", "<cmd>AiHow<cr>", desc = "HOW this symbol works (source)", mode = { "n", "v" } },
	{ "<leader>ag7", cc("CopilotChatDocs7"), desc = "Library docs (context7)", mode = { "n", "v" } },

	-- The reasoning model, one question at a time
	{ "<leader>aD", cc("CopilotChatDiagnose"), desc = "Diagnose (reasoning, slow)", mode = { "n", "v" } },

	{ "<leader>ad", "<cmd>ClaudeCode<cr>", desc = "[C]laude [C]ode" },
	{ "<leader>B", group = "Bazel" },
	{ "<leader>Bb", "<cmd>BazelBuildFile<cr>", desc = "Bazel Build File" },
	{ "<leader>Bm", "<cmd>BazelModuleFile<cr>", desc = "Bazel Module File" },
	{ "<leadear>Bw", "<cmd>BazelWorkspaceFile<cr>", desc = "Bazel Workspace File" },
	{ "<leader>Brc", "<cmd>BazelRcFile", desc = "Bazelrc File" },

	{ "<leader>Bo", "<cmd>BazelOverride<cr>", desc = "Bazel Override" },
	{ "<leader>Ba", "<cmd>BazelAddToModule<cr>", desc = "Bazel Add To Module" },

	{ "<leader>Bd", "<cmd>BazelDebug<cr>", desc = "Build and launch bazel target with nvim-dap" },
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
	{ "<leader>cD", ":Neogen<cr>", desc = "generate code docs" },
	{
		"<leader>ce",
		":Trouble diagnostics filter.severity=vim.diagnostic.severity.ERROR<cr>",
		desc = "Show Workspace Errors",
	},
	{ "<leader>cf", "<cmd>lua require('conform').format({async = true})<CR>", desc = "Format Document" },
	{ "<leader>cn", ":Lspsaga diagnostic_jump_next<cr>", desc = "Next Diagnostic" },
	{ "<leader>cb", ":Lspsaga goto_definition<cr>", desc = "GoTo Definition" },
	{ "<leader>co", ":Lspsaga outline<cr>", desc = "Code Outline" },
	{ "<leader>cp", ":Lspsaga diagnostic_jump_prev<cr>", desc = "Prev Diagnostic" },
	{ "<leader>cq", ":Trouble quickfix focus = true<cr>", desc = "Diagnostics Quickfix" },
	{ "<leader>cr", ":Lspsaga rename<cr>", desc = "Rename in current buffer" },
	-- Displays hover information about the symbol under the cursor
	{ "<leader>ch", "<cmd>Lspsaga hover_doc<cr>", desc = "Hover Doc" },

	-- Peek definition
	{ "<leader>cm", "<cmd>Lspsaga peek_definition<cr>", desc = "Peek Definition" },

	-- Lists all the implementations for the symbol under the cursor
	{ "<leader>ci", "<cmd>Lspsaga finder imp<cr>", desc = "Find Implementations" },

	-- Lists all the references
	{ "<leader>c/", "<cmd>Lspsaga finder<cr>", desc = "Find References" },
	-- List all supertypes for the symbol under the cursor
	{ "<leader>cs", "<cmd>Lspsaga supertypes<cr>", desc = "Find Super Types" },
	-- List all subtypes for the symbol under the cursor
	{ "<leader>cd", "<cmd>Lspsaga subtypes<cr>", desc = "Find Sub Types" },
	{ "<leader>cS", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Documents Symbols" },
	{ "<leader>cW", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },
	{ "<leader>cw", ":FixDosFormat<cr>", desc = "Fix Dos Format" },
	{ "<C-p>", ":lua require('ufo.preview'):peekFoldedLinesUnderCursor()<cr>", desc = "Peek inside fold." },
	{ "<leader>cc", "<cmd>Coverage<cr>", desc = "Show Coverage" },
	{ "<leader>ck", "<cmd>CoverageLoad<cr><cmd>CoverageToggle<cr>", desc = "Toggle Coverage" },
	{ "<leader>cu", "<cmd>CoverageSummary<cr>", desc = "Coverage Summary" },
	{
		"<leader>cx",
		":Trouble diagnostics toggle focus = true<cr>",
		desc = "Workspace Diagnostics",
	},
	{ "<leader>cvt", ":lua require('telescope').extensions.vstask.tasks()<CR>", desc = "List vscode tasks" },
	{ "<leader>cvi", ":lua require('telescope').extensions.vstask.inputs()<CR>", desc = "List vscode inputs" },
	{ "<leader>cvh", ":lua require('telescope').extensions.vstask.history()<CR>", desc = "List vscode history" },
	{ "<leader>cvl", ":lua require('telescope').extensions.vstask.launch()<cr>", desc = "Lauch vscode debug conf" },
	{ "<leader>cvj", ":lua require('telescope').extensions.vstask.jobs()<CR>", desc = "List vscode jobs" },
	{ "<leader>cvk", ":lua require('telescope').extensions.vstask.jobhistory()<CR>", desc = "List vscode job history" },
	{
		"<leader>ctr",
		":lua require('neotest').run.run()<cr>",
		desc = "[Test] Run the nearest test",
	},
	{
		"<leader>ctf",
		":lua require('neotest').run.run(vim.fn.expand('%'))<cr>",
		desc = "[Test] Run all tests in the current file",
	},
	{
		"<leader>ctd",
		":lua require('neotest').run.run({ strategy = 'dap' })<cr>",
		desc = "[Test] Debug the nearest test",
	},
	{
		"<leader>cta",
		":lua require('neotest').run.attach()<cr>",
		desc = "[Test] Attach to the nearest test",
	},
	{
		"<leader>ctw",
		":lua require('neotest').watch.toggle(vim.fn.expand('%'))<cr>",
		desc = "[Test] Toggles watching tests in the file, running them when related files change",
	},
	{
		"<leader>cts",
		":lua require('neotest').summary.toggle()<cr>",
		desc = "[Test] Toggles the neotest summary window",
	},
	{
		"<leader>cto",
		":lua require('neotest').output.open()<cr>",
		desc = "[Test] Show the result of the test",
	},
	{ "<BS>", "za", desc = "Toggle fold." },
	{ "<leader>d", group = "Debug" },
	{ "<leader>da", "<cmd>LldbDebugAttach<cr>", desc = "Debug Attach" },
	{ "<leader>db", ":lua require'dap'.toggle_breakpoint()<cr>", desc = "Breakpoint" },
	{ "<leader>dc", ":lua require'dap'.continue()<cr>", desc = "Start/Continue" },
	-- { "<leader>dd", ":lua require'dapui'.toggle()<cr>", desc = "Dap UI" },
	{ "<leader>dd", ":lua require'dap-view'.toggle()<cr>", desc = "Toggle DAP View" },
	{ "<leader>dh", "g?<cr>", desc = "DAP View Help" },
	-- {
	-- 	"<leader>de",
	-- 	":lua require'dapui'.eval(vim.fn.input('eval: '))<cr>",
	-- 	desc = "Evaluate expression",
	-- },
	{
		"<leader>de",
		":lua require'dap-view'.add_expr(vim.fn.input('eval: '))<cr>",
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
	{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
	{ "<leader>fR", "<cmd>Telescope resume<cr>", desc = "Telescope Resume" },
	{ "<leader>fz", "<cmd>Telescope zoxide list<cr>", desc = "zoxide list" },
	{ "<leader>v", group = "Git" },
	{ "<leader>vD", ":DiffviewClose<cr>", desc = "Close Diff" },
	{ "<leader>vP", ":lua require 'gitsigns'.preview_hunk()<cr>", desc = "Preview Hunk" },
	{ "<leader>vR", ":lua require 'gitsigns'.reset_buffer()<cr>", desc = "Reset Buffer" },
	{ "<leader>vb", ":Telescope git_branches<cr>", desc = "Checkout branch" },
	{ "<leader>vc", ":Telescope git_commits<cr>", desc = "Checkout commit" },
	{ "<leader>vd", ":DiffviewOpen<cr>", desc = "Open Diff" },
	{ "<leader>vg", ":LazyGit<cr>", desc = "Lazygit" },
	{ "<leader>vl", ":lua require 'gitsigns'.blame_line()<cr>", desc = "Blame" },
	{ "<leader>vn", ":lua require 'gitsigns'.next_hunk()<cr>", desc = "Next Hunk" },
	{ "<leader>vo", ":Telescope git_status<cr>", desc = "Open changed file" },
	{ "<leader>vp", ":lua require 'gitsigns'.prev_hunk()<cr>", desc = "Prev Hunk" },
	{ "<leader>vr", ":lua require 'gitsigns'.reset_hunk()<cr>", desc = "Reset Hunk" },
	{ "<leader>vs", ":lua require 'gitsigns'.stage_hunk()<cr>", desc = "Stage Hunk" },
	{
		"<leader>vu",
		":lua require 'gitsigns'.undo_stage_hunk()<cr>",
		desc = "Undo Stage Hunk",
	},
	{ "<leader>j", group = "Java" },
	{ "<leader>jC", "<Cmd>JavaBuildBuildWorkspace<CR>", desc = "Build Java" },
	{
		"<leader>jR",
		"<cmd>JavaBuildCleanWorkspace<cr>",
		desc = "Wipe project data and close nvim to Restart server",
	},
	{
		"<leader>jT",
		"<Cmd>JavaTestDebugCurrentClass<CR>",
		desc = "Debug the test class in the active buffer",
	},
	{
		"<leader>ja",
		"<Cmd>JavaRefactorExtractMethod<CR>",
		desc = "Create a method from the value at cursor/selection",
	},
	{
		"<leader>jc",
		"<Cmd>JavaRefactorExtractConstant<CR>",
		desc = "Extract Constant",
	},
	{
		"<leader>jd",
		"<Cmd>JavaDapConfig<cr>",
		desc = "Refresh DAP Debugger",
	},
	{ "<leader>je", "<Cmd>JavaSettingsChangeRuntime<CR>", desc = "Choose Java Runtime" },
	{
		"<leader>jL",
		"<cmd>JavaTestRunCurrentClass<cr>",
		desc = "Run the test class in the active buffer",
	},
	{ "<leader>jl", ":FzfLua lsp_live_workspace_symbols<CR>", desc = "Find Beans" },
	{
		"<leader>jr",
		"<Cmd>JavaTestRunCurrentMethod<cr>",
		desc = "Run the test method on the cursor",
	},
	{
		"<leader>js",
		"<cmd>JavaProfile<CR>",
		desc = "Opens the profiles UI",
	},
	{
		"<leader>ji",
		"<cmd>JavaRefactorExtractVariableAllOccurrence<cr>",
		desc = "Create a variable for all occurrences from value at cursor/selection",
	},
	{
		"<leader>jj",
		"<cmd>JavaRefactorExtractField<cr>",
		desc = "Create a field from the value at cursor/selection",
	},
	{
		"<leader>jn",
		"<Cmd>JavaRunnerRunMain<CR>",
		desc = "Runs the application or selected main class",
	},
	{
		"<leader>jp",
		"<Cmd>JavaRunnerStopMain<CR>",
		desc = "Stops the running application",
	},
	{
		"<leader>jy",
		"<Cmd>JavaRunnerToggleLogs<CR>",
		desc = "Toggle between show & hide runner log window",
	},
	{
		"<leader>jo",
		"<Cmd>JavaTestRunAllTests<CR>",
		desc = "Run all tests in the workspace",
	},
	{
		"<leader>jw",
		"<Cmd>JavaTestDebugAllTests<CR>",
		desc = "Debug all tests in the workspace",
	},
	{
		"<leader>jt",
		"<Cmd>JavaTestDebugCurrentMethod<CR>",
		desc = "Debug the test method on the cursor",
	},
	{
		"<leader>ju",
		"<Cmd>JavaTestViewLastReport<CR>",
		desc = "Open the last test report in a popup window",
	},
	{
		"<leader>jv",
		"<Cmd>JavaRefactorExtractVariable<CR>",
		desc = "Create a variable from value at cursor/selection",
	},
	{
		"<leader>jx",
		"<Cmd>RemoveUnusedImportsFromProject<CR>",
		desc = "Remove unused imports from whole project",
	},
	{
		"<leader>jb",
		"<Cmd>ExecInTermHorizontal rm -f Main.class && javac -cp 'lib/*' Main.java && java -cp '.:lib/*' Main<CR>",
		desc = "Build and Run java file",
	},
	{ "<leader>jz", group = "Java - Class files" },
	{
		"<leader>jzn",
		"<Cmd>JavaNew<CR>",
		desc = "Interactive creation wizard",
	},
	{
		"<leader>jzc",
		"<Cmd>JavaClass<CR>",
		desc = "Create a new class",
	},
	{
		"<leader>jzi",
		"<Cmd>JavaInterface<CR>",
		desc = "Create a new interface",
	},
	{
		"<leader>jze",
		"<Cmd>JavaEnum<CR>",
		desc = "Create a new enum",
	},
	{
		"<leader>jzr",
		"<Cmd>JavaRecord<CR>",
		desc = "Create a new record (Java 16+)",
	},
	{
		"<leader>jzs",
		"<Cmd>JavaAbstractClass<CR>",
		desc = "Create a new abstract class",
	},
	{ "<leader>jm", group = "Java - Maven" },
	{
		"<leader>jmr",
		"<cmd>ExecInTermHorizontal mvn clean -U dependency:resolve<CR>",
		desc = " Refresh dependencies",
	},
	{ "<leader>jmp", "<cmd>ExecInTermHorizontal mvn clean package<CR>", desc = " Package" },
	{ "<leader>jmi", "<cmd>ExecInTermHorizontal mvn clean install<CR>", desc = " Install" },
	{ "<leader>jmd", "<cmd>ExecInTermHorizontal mvn clean deploy<CR>", desc = " Deploy" },
	{ "<leader>jmt", "<cmd>ExecInTermHorizontal mvn clean test<CR>", desc = " Test" },
	{
		"<leader>jme",
		"<cmd>ExecInTermHorizontal mvn dependency:purge-local-repository<CR>",
		desc = " Purge local repository",
	},
	{
		"<leader>jmP",
		"<cmd>ExecInTermHorizontal mvn clean package -DskipTests<CR>",
		desc = " Package (skip tests)",
	},
	{ "<leader>jms", "<cmd>Neotree maven toggle<CR>", desc = " Show project [d]ependencies" },
	{ "<leader>jmc", "<cmd>ExecInTermHorizontal mvn clean compile<CR>", desc = " Compile" },
	{ "<leader>jmC", "<cmd>ExecInTermHorizontal mvn clean<CR>", desc = " Clean" },
	{
		"<leader>jmg",
		"<cmd>ExecInTermHorizontal mvn exec:java -Dexec.args='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005'<CR>",
		desc = "Run with debug",
	},
	{ "<leader>jmv", "<cmd>ExecInTermHorizontal mvn verify<CR>", desc = " Coverage IT tests" },
	{ "<leader>jg", group = "Gradle" },
	{ "<leader>jgt", "ExecInTermHorizontal ./gradlew test<CR>", desc = " Test" },
	{ "<leader>jgb", "ExecInTermHorizontal ./gradlew build<CR>", desc = " Build" },
	{ "<leader>jgc", "<cmd>ExecInTermHorizontal ./gradlew clean<CR>", desc = " Clean" },
	{
		"<leader>jgr",
		"<cmd>ExecInTermHorizontal ./gradlew --refresh-dependencies<CR>",
		desc = " Refresh deps",
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
	{ "<leader>M", group = "Markdown" },
	{ "<leader>Mp", ":MarkdownPreview<CR>", desc = "Preview in browser" },
	{ "<leader>Ms", ":MarkdownPreviewStop<CR>", desc = "Stop Preview" },
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
	{ "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
	{ "<leader>n", "<cmd>NoNeckPain<cr>", desc = "Center buffer no ZenMode" },
	{ "<leader>J", group = "Java Spring Helpers" },
	-- set a vim motion to <Space> + <Shift>J + r to run the spring boot project in a vim terminal
	{ "<leader>Jr", '<cmd>:lua require("springboot-nvim").boot_run()<cr>', desc = "[J]ava [R]un Spring Boot" },
	-- set a vim motion to <Space> + <Shift>J + c to open the generate class ui to create a class
	{ "<leader>Jc", '<cmd>:lua require("springboot-nvim").generate_class()<cr>', desc = "[J]ava Create [C]lass" },
	-- set a vim motion to <Space> + <Shift>J + i to open the generate interface ui to create an interface
	{
		"<leader>Js",
		"<cmd>Springtime<cr>",
		desc = "[J]ava Spring [I]nitializer",
	},
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
