-- JDTLS (Java LSP) configuration
local home = vim.env.HOME -- Get the home directory
local java_home = vim.env.JAVA_HOME -- Get the JAVA home directory

local jdtls = require("jdtls")
local function get_jdtls_cache_dir()
	return vim.fn.stdpath("cache") .. "/nvim-jdtls"
end

local function get_jdtls_workspace_dir()
	return get_jdtls_cache_dir() .. "/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
end
local workspace_dir = get_jdtls_workspace_dir()

local system_os = ""

-- Determine OS
if vim.fn.has("mac") == 1 then
	system_os = "mac"
elseif vim.fn.has("unix") == 1 then
	system_os = "linux"
elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
	system_os = "win"
else
	print("OS not found, defaulting to 'linux'")
	system_os = "linux"
end

local mason_packages_path = home .. "/.local/share/nvim/mason"
-- Nightly Lombok (for completions and annotation processing in DAP/test)
local lombok_nightly = mason_packages_path .. "/share/lombok-nightly/lombok.jar"

-- Gather all relevant bundles, including spring tools and lombok-nightly
local function get_jdtls_bundles()
	local bundles = {}

	-- Java Test bundles
	local java_test_bundles = vim.split(vim.fn.glob(mason_packages_path .. "/share/java-test/*.jar"), "\n")
	if java_test_bundles[1] ~= "" then
		vim.list_extend(bundles, java_test_bundles)
	end

	-- Java Debug Adapter
	local java_debug_bundle = mason_packages_path .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
	if vim.fn.filereadable(java_debug_bundle) == 1 then
		table.insert(bundles, java_debug_bundle)
	end
	-- Java decompiler
	local java_decompiler_bundles =
		vim.split(vim.fn.glob(mason_packages_path .. "/share/vscode-java-decompiler/bundles/*.jar"), "\n")
	if java_test_bundles[1] ~= "" then
		vim.list_extend(bundles, java_decompiler_bundles)
	end
	-- Java jdtls plugins
	local jdtls_bundle_patterns = {
		"org.junit.jupiter.api*.jar",
		"org.junit.jupiter.engine*.jar",
		"org.junit.jupiter.migrationsupport*.jar",
		"org.junit.jupiter.params*.jar",
		"org.junit.vintage.engine*.jar",
		"org.junit.platform.commons*.jar",
		"org.junit.platform.engine*.jar",
		"org.junit.platform.launcher*.jar",
		"org.junit.platform.runner*.jar",
		"org.junit.platform.suite.api*.jar",
	}
	for _, pattern in ipairs(jdtls_bundle_patterns) do
		local matched = vim.split(vim.fn.glob(mason_packages_path .. "/share/java-test/" .. pattern), "\n")
		if
			matched[1] ~= ""
			and not vim.endswith(matched[1], "com.microsoft.java.test.runner-jar-with-dependencies.jar")
			and not vim.endswith(matched[1], "com.microsoft.java.test.runner.jar")
		then
			vim.list_extend(bundles, matched)
		end
	end

	-- Spring Boot Tools (if available)
	local spring_bundle_patterns = {
		"io.projectreactor.reactor-core.jar",
		"org.reactivestreams.reactive-streams.jar",
		"jdt-ls-commons.jar",
	}
	for _, pattern in ipairs(spring_bundle_patterns) do
		local matched =
			vim.split(vim.fn.glob(mason_packages_path .. "/share/vscode-spring-boot-tools/jdtls/" .. pattern), "\n")
		if matched[1] ~= "" then
			vim.list_extend(bundles, matched)
		end
	end

	return bundles
end

-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
	-- The command that starts the language server
	-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-javaagent:" .. lombok_nightly,
		"-Xmx6g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",

		-- Eclipse jdtls location
		"-jar",
		mason_packages_path .. "/share/jdtls/plugins/org.eclipse.equinox.launcher.jar",
		"-configuration",
		mason_packages_path .. "/packages/jdtls/config_" .. system_os,
		"-data",
		workspace_dir,
	},

	-- This is the default if not provided, you can remove it. Or adjust as needed.
	-- One dedicated LSP server & client will be started per unique root_dir
	root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }),

	-- Here you can configure eclipse.jdt.ls specific settings
	-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
	settings = {
		java = {
			-- TODO Replace this with the absolute path to your main java version (JDK 17 or higher)
			home = java_home,
			eclipse = {
				downloadSources = true,
			},
			configuration = {
				updateBuildConfiguration = "interactive",
				-- TODO Update this by adding any runtimes that you need to support your Java projects and removing any that you don't have installed
				-- The runtime name parameters need to match specific Java execution environments.  See https://github.com/tamago324/nlsp-settings.nvim/blob/2a52e793d4f293c0e1d61ee5794e3ff62bfbbb5d/schemas/_generated/jdtls.json#L317-L334
				-- runtimes = {
				-- 	{
				-- 		name = "JavaSE-20",
				-- 		path = "/usr/lib/jvm/java-23-openjdk",
				-- 	},
				-- },
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
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				importOrder = {
					"java",
					"javax",
					"com",
					"org",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
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
				hashCodeEquals = {
					useJava7Objects = true,
				},
			},
		},
	},
	-- Needed for auto-completion with method signatures and placeholders
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
	flags = {
		allow_incremental_sync = true,
	},
	init_options = {
		-- References the bundles defined above to support Debugging and Unit Testing
		bundles = get_jdtls_bundles(),
		extendedClientCapabilities = jdtls.extendedClientCapabilities,
	},
}

-- Needed for debugging
config["on_attach"] = function(client, bufnr)
	jdtls.setup_dap({ hotcodereplace = "auto" })
	require("jdtls.dap").setup_dap_main_class_configs()
	require("jdtls.setup").add_commands()

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

-- This starts a new client & server, or attaches to an existing client & server based on the `root_dir`.
jdtls.start_or_attach(config)
