require("lsp.servers.clangd")
require("lsp.servers.java")
require("lsp.servers.lua")
require("lsp.servers.marksman")
require("lsp.servers.tailwindcss")
require("lsp.servers.json")
-- require("lsp.servers.typescript")
require("lsp.servers.prisma")
require("lsp.servers.rust")
require("lsp.servers.kotlin")
require("lsp.servers.other")
local api = vim.api
local lspgroup = api.nvim_create_augroup("lsp", {})
local completion_convert = {}
local setk = vim.keymap.set
local lsp_auto_complete_enabled = false

completion_convert.zls = function(item)
	if item.filterText then
		return { word = item.filterText }
	end
	return {}
end
---@param client vim.lsp.Client
local function extendtriggers(client)
	local triggers = vim.tbl_get(client.server_capabilities, "completionProvider", "triggerCharacters")
	if not triggers then
		return
	end
	for _, char in ipairs({ "a", "e", "i", "o", "u" }) do
		if not vim.tbl_contains(triggers, char) then
			table.insert(triggers, char)
		end
	end
	for i, t in ipairs(triggers) do
		if t == "," then
			triggers[i] = nil
		end
	end
	client.server_capabilities.completionProvider.triggerCharacters = vim.iter(triggers):totable()
end
api.nvim_create_autocmd("LspAttach", {
	group = lspgroup,
	---@param args vim.api.keyset.create_autocmd.callback_args
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

		if client.server_capabilities.completionProvider and lsp_auto_complete_enabled then
			extendtriggers(client)
			vim.lsp.completion.enable(true, client.id, args.buf, {
				autotrigger = true,
				convert = completion_convert[client.name],
			})
		end
		if client.server_capabilities.implementationProvider then
			setk("n", "gD", vim.lsp.buf.implementation, { buffer = args.buf })
		end
		if client.server_capabilities.documentHighlightProvider then
			local group = api.nvim_create_augroup(string.format("lsp-%s-%s", args.buf, args.data.client_id), {})
			api.nvim_create_autocmd("CursorHold", {
				group = group,
				buffer = args.buf,
				callback = function(cb_args)
					local buf = cb_args.buf
					local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
					local function on_highlight(_, result)
						if result then
							vim.lsp.util.buf_highlight_references(buf, result, client.offset_encoding)
						end
					end
					---@diagnostic disable-next-line: param-type-mismatch
					client:request("textDocument/documentHighlight", params, on_highlight, buf)
				end,
			})
			api.nvim_create_autocmd("CursorMoved", {
				group = group,
				buffer = args.buf,
				callback = function()
					pcall(vim.lsp.util.buf_clear_references, args.buf)
				end,
			})
		end
	end,
})
api.nvim_create_autocmd("LspDetach", {
	group = lspgroup,
	callback = function(args)
		local group = api.nvim_create_augroup(string.format("lsp-%s-%s", args.buf, args.data.client_id), {})
		pcall(api.nvim_del_augroup_by_name, group)
	end,
})

local timer = vim.loop.new_timer()
api.nvim_create_autocmd("LspProgress", {
	group = lspgroup,
	callback = function()
		if api.nvim_get_mode().mode == "n" then
			vim.cmd.redrawstatus()
		end
		if timer then
			timer:stop()
			timer:start(
				500,
				0,
				vim.schedule_wrap(function()
					timer:stop()
					vim.cmd.redrawstatus()
				end)
			)
		end
	end,
})
