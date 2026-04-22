local home = vim.env.HOME -- Get the home directory
local mason_packages_path = home .. "/.local/share/nvim/mason"
-- Nightly Lombok (for completions and annotation processing in DAP/test)
local lombok_nightly = mason_packages_path .. "/share/lombok-nightly/lombok.jar"
vim.fn.setenv("JDTLS_JVM_ARGS", "-javaagent:" .. lombok_nightly)
local JDTLS_JVM_ARGS = os.getenv("JDTLS_JVM_ARGS")
local jdtls = require("jdtls")

local common = require("lsp.common")
local handlers = common.handlers

local function get_cache_dir()
	return vim.env.XDG_CACHE_HOME and vim.env.XDG_CACHE_HOME or vim.env.HOME .. "/.cache"
end

local function get_jdtls_cache_dir()
	return get_cache_dir() .. "/jdtls"
end

local function get_jdtls_config_dir()
	return mason_packages_path .. "/share/jdtls/config"
end

local function get_jdtls_workspace_dir()
	return get_jdtls_cache_dir() .. "/workspace"
end

local function get_jdtls_jvm_args()
	local args = {}
	for a in string.gmatch((JDTLS_JVM_ARGS or ""), "%S+") do
		local arg = string.format("--jvm-arg=%s", a)
		table.insert(args, arg)
	end
	return unpack(args)
end

-- TextDocument version is reported as 0, override with nil so that
-- the client doesn't think the document is newer and refuses to update
-- See: https://github.com/eclipse/eclipse.jdt.ls/issues/1695
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
		if action.command == "java.apply.workspaceEdit" then -- 'action' is Command in java format
			action.edit = fix_zero_version(action.edit or action.arguments[1])
		elseif type(action.command) == "table" and action.command.command == "java.apply.workspaceEdit" then -- 'action' is CodeAction in java format
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

-- Gather all relevant bundles, including spring tools and lombok-nightly
local function get_jdtls_bundles()
	local bundles = {}
	-- Java Debug Adapter
	local java_debug_bundle = mason_packages_path .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
	if vim.fn.filereadable(java_debug_bundle) == 1 then
		table.insert(bundles, java_debug_bundle)
	end
	-- Java decompiler
	local java_decompiler_bundles =
		vim.split(vim.fn.glob(mason_packages_path .. "/share/vscode-java-decompiler/bundles/*.jar"), "\n")
	vim.list_extend(bundles, java_decompiler_bundles)
	-- Java jdtls plugins
	local jdtls_bundle_patterns = {
		"junit-jupiter-*.jar",
		"junit-platform-*.jar",
		"junit-vintage-engine_*.jar",
		"org.opentest4j*.jar",
		"org.apiguardian.api_*.jar",
		"org.eclipse.jdt.junit*.jar",
		"org.opentest4j_*.jar",
		"org.jacoco.*.jar",
		"org.objectweb.asm*.jar",
	}
	for _, pattern in ipairs(jdtls_bundle_patterns) do
		local matched = vim.split(vim.fn.glob(mason_packages_path .. "/share/java-test/" .. pattern), "\n")
		if
			matched[1] ~= ""
			and not vim.endswith(matched[1], "com.microsoft.java.test.runner-jar-with-dependencies.jar")
			and not vim.endswith(matched[1], "jacocoagent.jar")
		then
			vim.list_extend(bundles, matched)
		end
	end
	-- Spring Boot Integration
	local status, spring_plugin = pcall(require, "spring_boot")
	if status and spring_plugin.java_extensions then
		vim.list_extend(bundles, spring_plugin.java_extensions())
	end
	return bundles
end

local function on_attach(client, bufnr)
	jdtls.setup_dap({ hotcodereplace = "auto" })
	require("jdtls.dap").setup_dap_main_class_configs()
	require("jdtls.setup").add_commands()
	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint.enable(true)
	end
	vim.api.nvim_buf_create_user_command(bufnr, "A", function()
		require("jdtls.tests").goto_subjects()
	end, {})
	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })

	require("lsp_signature").on_attach({
		bind = true,
		padding = "",
		handler_opts = {
			border = "rounded",
		},
		hint_prefix = "󱄑 ",
	}, bufnr)
end

vim.lsp.config("jdtls", {
	cmd = {
		"jdtls",
		"-configuration",
		get_jdtls_config_dir(),
		"-data",
		get_jdtls_workspace_dir(),
		get_jdtls_jvm_args(),
	},
	single_file_support = true,
	filetypes = { "java" },
	root_markers = {
		".git",
		"build.gradle",
		"build.gradle.kts",
		"build.xml", -- Ant
		"pom.xml", -- Maven
		"settings.gradle", -- Gradle
		"settings.gradle.kts", -- Gradle
	},
	capabilities = common.capabilities,
	on_attach = on_attach,

	init_options = {

		workspace = get_jdtls_workspace_dir(),
		jvm_args = {},
		os_config = nil,
		extendedClientCapabilities = {
			actionableRuntimeNotificationSupport = true,
			advancedExtractRefactoringSupport = true,
			advancedGenerateAccessorsSupport = true,
			advancedIntroduceParameterRefactoringSupport = true,
			advancedOrganizeImportsSupport = true,
			advancedUpgradeGradleSupport = true,
			classFileContentsSupport = true,
			clientDocumentSymbolProvider = false,
			clientHoverProvider = false,
			executeClientCommandSupport = true,
			extractInterfaceSupport = true,
			generateConstructorsPromptSupport = true,
			generateDelegateMethodsPromptSupport = true,
			generateToStringPromptSupport = true,
			gradleChecksumWrapperPromptSupport = true,
			hashCodeEqualsPromptSupport = true,
			inferSelectionSupport = {
				"extractConstant",
				"extractField",
				"extractInterface",
				"extractMethod",
				"extractVariableAllOccurrence",
				"extractVariable",
			},
			moveRefactoringSupport = true,
			onCompletionItemSelectedCommand = "editor.action.triggerParameterHints",
			overrideMethodsPromptSupport = true,
		},
	},

	handlers = {
		-- Due to an invalid protocol implementation in the jdtls we have to conform these to be spec compliant.
		-- https://github.com/eclipse/eclipse.jdt.ls/issues/376
		["textDocument/codeAction"] = on_textdocument_codeaction,
		["textDocument/rename"] = on_textdocument_rename,
		["workspace/applyEdit"] = on_workspace_applyedit,
	},
	before_init = function(params)
		---@diagnostic disable-next-line: inject-field
		params.initializationOptions.bundles = get_jdtls_bundles()
	end,
	-- Here you can configure eclipse.jdt.ls specific settings
	-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
	settings = {
		java = {
			eclipse = {
				downloadSources = true,
			},
			maxConcurrentBuilds = 8,
			configuration = {
				updateBuildConfiguration = "interactive",
				-- TODO Update this by adding any runtimes that you need to support your Java projects and removing any that you don't have installed
				-- The runtime name parameters need to match specific Java execution environments.  See https://github.com/tamago324/nlsp-settings.nvim/blob/2a52e793d4f293c0e1d61ee5794e3ff62bfbbb5d/schemas/_generated/jdtls.json#L317-L334
				runtimes = {
					{
						name = "Java-25.01",
						path = "~/.sdkman/candidates/java/25.0.1-amzn/",
					},
				},
			},
			maven = {
				downloadSources = true,
			},
			implementationsCodeLens = {
				enabled = true,
			},
			referencesCodeLens = {
				enabled = true,
			},
			references = {
				includeDecompiledSources = true,
			},
			signatureHelp = { enabled = true },
			format = {
				enabled = true,
				-- Formatting works by default, but you can refer to a specific file/URL if you choose
				-- settings = {
				--   url = "https://github.com/google/styleguide/blob/gh-pages/intellij-java-google-style.xml",
				--   profile = "GoogleStyle",
				-- },
			},
			completion = {
				favoriteStaticMembers = {
					"com.github.tomakehurst.wiremock.client.WireMock.*",
					"com.github.tomakehurst.wiremock.matching.MatchResult.*",
					"java.lang.*",
					"java.lang.Integer.*",
					"java.lang.String.*",
					"java.lang.System.*",
					"java.nio.charset.Charset.*",
					"java.nio.charset.StandardCharsets.*",
					"java.nio.file.Files.*",
					"java.util.*",
					"java.util.Calendar.*",
					"java.util.Collections.*",
					"java.util.EnumSet.*",
					"java.util.List.*",
					"java.util.Map.*",
					"java.util.Objects.*",
					"java.util.Optional.*",
					"java.util.function.Function.*",
					"java.util.stream.*",
					"java.util.stream.Collectors.*",
					"java.util.stream.Stream.*",
					"org.apache.commons.lang3.StringUtils.*",
					"org.assertj.core.api.Assertions.*",
					"org.hibernate.jpa.HibernateHints.*",
					"org.junit.jupiter.api.Assertions.*",
					"org.junit.jupiter.api.DynamicTest.*",
					"org.junit.jupiter.api.TestInstance.Lifecycle.*",
					"org.junit.jupiter.params.ParameterizedTest.*",
					"org.junit.jupiter.params.provider.Arguments.*",
					"org.mapstruct.MappingConstants.ComponentModel.*",
					"org.mapstruct.ReportingPolicy.*",
					"org.mockito.AdditionalMatchers.*",
					"org.mockito.Answers.*",
					"org.mockito.ArgumentMatchers.*",
					"org.mockito.Mockito.*",
					"org.mockito.MockitoAnnotations.*",
					"org.mockito.internal.verification.VerificationModeFactory.*",
					"org.springframework.beans.factory.config.ConfigurableBeanFactory.*",
					"org.springframework.boot.test.context.SpringBootTest.WebEnvironment.*",
					"org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions.*",
					"org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions.*",
					"org.springframework.context.annotation.FilterType.*",
					"org.springframework.core.annotation.AnnotatedElementUtils.*",
					"org.springframework.http.HttpHeaders.*",
					"org.springframework.http.HttpMethod.*",
					"org.springframework.http.MediaType.*",
					"org.springframework.http.ResponseEntity.*",
					"org.springframework.security.config.Customizer.*",
					"org.springframework.security.config.http.SessionCreationPolicy.*",
					"org.springframework.security.oauth2.core.oidc.StandardClaimNames.*",
					"org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*",
					"org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher.*",
					"org.springframework.test.annotation.DirtiesContext.ClassMode.*",
					"org.springframework.test.web.servlet.client.MockMvcWebTestClient.*",
					"org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
					"org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
					"org.springframework.web.bind.annotation.RequestMethod.*",
					"org.springframework.web.context.request.RequestAttributes.*",
					"org.springframework.web.servlet.function.RequestPredicates.*",
					"org.springframework.web.servlet.function.RouterFunctions.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
				importOrder = {
					"java",
					"javax",
					"org.apache",
					"org.springframework",
					"org",
					"com",
					"",
					"#",
				},
			},
			saveActions = {
				organizeImports = true,
			},
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				useBlocks = true,
				addFinalForNewDeclaration = "fields",
				hashCodeEquals = {
					useJava7Objects = true,
				},
			},
		},
	},
})
vim.lsp.enable("jdtls")
