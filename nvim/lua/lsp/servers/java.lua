-- Load your custom LSP and helpers
local JDTLS_JVM_ARGS = os.getenv("JDTLS_JVM_ARGS")
local common = require("lsp.common")
local util = require("lspconfig.util")
local handlers = require("vim.lsp.handlers")

-- Helper: Robust cache dir pick
local function get_cache_dir()
	return vim.env.XDG_CACHE_HOME and vim.env.XDG_CACHE_HOME or vim.env.HOME .. "/.cache"
end

local function get_jdtls_cache_dir()
	return get_cache_dir() .. "/jdtls"
end

local function get_jdtls_config_dir()
	return get_jdtls_cache_dir() .. "/config"
end

local function get_jdtls_workspace_dir()
	return get_jdtls_cache_dir() .. "/workspace"
end

local function get_jdtls_jvm_args()
	local args = {}
	for a in string.gmatch((JDTLS_JVM_ARGS or ""), "%S+") do
		table.insert(args, string.format("--jvm-arg=%s", a))
	end
	-- Return as unpacked arguments
	return unpack(args)
end

-- Gather additional JARs/bundles robustly
local function get_jdtls_bundles()
	local bundles = {}
	-- Debugger/test support
	local test_bundles = vim.split(vim.fn.glob("$MASON/share/java-test/*.jar"), "\n")
	if test_bundles[1] ~= "" then
		vim.list_extend(bundles, test_bundles)
	end
	local debug_bundle = vim.fn.glob("$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar")
	if debug_bundle and debug_bundle ~= "" then
		table.insert(bundles, debug_bundle)
	end
	-- Spring Boot Tools
	local spring_bundles = vim.split(vim.fn.glob("$MASON/share/vscode-spring-boot-tools/jdtls/*.jar"), "\n")
	if spring_bundles[1] ~= "" then
		vim.list_extend(bundles, spring_bundles)
	end
	return bundles
end

-- Lombok jar path (optional)
local lombok_jar = vim.fn.expand("$MASON/share/lombok-nightly/lombok.jar")
if lombok_jar == "" then
	lombok_jar = nil
end

-- Handler helpers: zero-version fix
local function fix_zero_version(workspace_edit)
	if workspace_edit and workspace_edit.documentChanges then
		for _, change in pairs(workspace_edit.documentChanges) do
			local text_document = change.textDocument
			if text_document and text_document.version and text_document.version == 0 then
				text_document.version = nil
			end
		end
	end
	return workspace_edit
end

local function on_textdocument_codeaction(err, actions, ctx)
	for _, action in ipairs(actions) do
		if action.command == "java.apply.workspaceEdit" then
			action.edit = fix_zero_version(action.edit or action.arguments[1])
		elseif type(action.command) == "table" and action.command.command == "java.apply.workspaceEdit" then
			action.edit = fix_zero_version(action.edit or action.command.arguments[1])
		end
	end
	handlers[ctx.method](err, actions, ctx)
end

local function on_textdocument_rename(err, workspace_edit, ctx)
	handlers[ctx.method](err, fix_zero_version(workspace_edit), ctx)
end

local function on_workspace_applyedit(err, workspace_edit, ctx)
	handlers[ctx.method](err, fix_zero_version(workspace_edit), ctx)
end
-- Combine client capabilities: LSP + cmp_nvim_lsp + jdtls
local capabilities = vim.tbl_deep_extend(
	"force",
	vim.lsp.protocol.make_client_capabilities(),
	common.capabilities or {},
	{ workspace = { configuration = true } }
)

-- nvim-jdtls extended capabilities (see their docs)
local extended_capabilities = require("jdtls").extendedClientCapabilities or {}
capabilities = vim.tbl_deep_extend("force", capabilities, { extendedClientCapabilities = extended_capabilities })

vim.lsp.config.jdtls = {
	cmd = {
		"jdtls",
		"-configuration",
		get_jdtls_config_dir(),
		"-data",
		get_jdtls_workspace_dir(),
		get_jdtls_jvm_args(),
	},
	filetypes = { "java" },
	root_dir = function(fname)
		local root_files = {
			-- Multi-module projects
			{ ".git", "build.gradle", "build.gradle.kts" },
			-- Single-module projects
			{
				"build.xml", -- Ant
				"pom.xml", -- Maven
				"settings.gradle", -- Gradle
				"settings.gradle.kts", -- Gradle
			},
		}
		for _, patterns in ipairs(root_files) do
			local root = util.root_pattern(unpack(patterns))(fname)
			if root then
				return root
			end
		end
	end,
	-- root_markers = {
	-- 	".git",
	-- 	"mvnw",
	-- 	"gradlew",
	-- 	-- "build.gradle",
	-- 	-- "build.gradle.kts",
	-- 	-- "build.xml",
	-- 	-- "pom.xml",
	-- 	-- "settings.gradle",
	-- 	-- "settings.gradle.kts",
	-- },
	init_options = {
		workspace = get_jdtls_workspace_dir(),
		jvm_args = {}, -- extra jvm args can be added here
		-- Lombok as javaagent if available
		vmargs = lombok_jar and { "-javaagent:" .. lombok_jar } or {},
		bundles = get_jdtls_bundles(),
		os_config = nil,
		extendedClientCapabilities = extended_capabilities, -- explicitly in init_options (optional)
	},

	handlers = {
		["textDocument/codeAction"] = on_textdocument_codeaction,
		["textDocument/rename"] = on_textdocument_rename,
		["workspace/applyEdit"] = on_workspace_applyedit,
	},
	capabilities = capabilities,
	on_attach = common.on_attach,
}
-- Load the launch.json configuration
require("dap.ext.vscode").json_decode = require("json5").parse

vim.lsp.enable("jdtls")
