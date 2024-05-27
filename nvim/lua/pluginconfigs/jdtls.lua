local java_cmds = vim.api.nvim_create_augroup('java_cmds', { clear = true })
local cache_vars = {}

local root_files = {
  '.git',
  'mvnw',
  'gradlew',
  'pom.xml',
  'build.gradle',
}

local features = {
  -- change this to `true` to enable codelens
  codelens = true,

  -- change this to `true` if you have `nvim-dap`,
  -- `java-test` and `java-debug-adapter` installed
  debugger = true,
}

local function get_jdtls_paths()
  if cache_vars.paths then
    return cache_vars.paths
  end

  local path = {}

  path.data_dir = vim.fn.stdpath('cache') .. '/nvim-jdtls'

  local jdtls_install = require('mason-registry')
      .get_package('jdtls')
      :get_install_path()

  path.lombok = jdtls_install .. '/lombok.jar'
  path.launcher_jar = vim.fn.glob(jdtls_install .. '/plugins/org.eclipse.equinox.launcher_*.jar')

  if vim.fn.has('mac') == 1 then
    path.platform_config = jdtls_install .. '/config_mac'
  elseif vim.fn.has('unix') == 1 then
    path.platform_config = jdtls_install .. '/config_linux'
  elseif vim.fn.has('win32') == 1 then
    path.platform_config = jdtls_install .. '/config_win'
  end

  path.bundles = {}

  ---
  -- Include java-test bundle if present
  ---
  local java_test_path = require('mason-registry')
      .get_package('java-test')
      :get_install_path()

  local java_test_bundle = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n")

  if java_test_bundle[1] ~= "" then
    for _, bundle in ipairs(java_test_bundle) do
      --These two jars are not bundles, therefore don't put them in the table
      if
          not vim.endswith(bundle, "com.microsoft.java.test.runner-jar-with-dependencies.jar")
          and not vim.endswith(bundle, "com.microsoft.java.test.runner.jar")
      then
        if java_test_bundle[1] ~= '' then
          table.insert(path.bundles, bundle)
        end
      end
    end
    vim.list_extend(path.bundles, java_test_bundle)
  end

  ---
  -- Include java-debug-adapter bundle if present
  ---
  local java_debug_path = require('mason-registry')
      .get_package('java-debug-adapter')
      :get_install_path()

  local java_debug_bundle = vim.split(
    vim.fn.glob(java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar'),
    '\n'
  )

  if java_debug_bundle[1] ~= '' then
    vim.list_extend(path.bundles, java_debug_bundle)
  end

  ---
  -- Useful if you're starting jdtls with a Java version that's
  -- different from the one the project uses.
  ---
  path.runtimes = {
    -- Note: the field `name` must be a valid `ExecutionEnvironment`,
    -- you can find the list here:
    -- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    --
    -- This example assume you are using sdkman: https://sdkman.io
    -- {
    --   name = 'JavaSE-17',
    --   path = vim.fn.expand('~/.sdkman/candidates/java/17.0.6-tem'),
    -- },
    -- {
    --   name = 'JavaSE-18',
    --   path = vim.fn.expand('~/.sdkman/candidates/java/18.0.2-amzn'),
    -- },
  }

  cache_vars.paths = path

  return path
end

local function enable_codelens(bufnr)
  pcall(vim.lsp.codelens.refresh)

  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = bufnr,
    group = java_cmds,
    desc = 'refresh codelens',
    callback = function()
      pcall(vim.lsp.codelens.refresh)
    end,
  })
end

local function enable_debugger(bufnr)
  require('jdtls').setup_dap({ hotcodereplace = 'auto' })
  require('jdtls.dap').setup_dap_main_class_configs()
end

local function jdtls_on_attach(client, bufnr)
  require("lsp_signature").on_attach({
    bind = true,
    use_lspsaga = false,
    floating_window = true,
    fix_pos = true,
    hint_enable = false,
    hi_parameter = "Search",
    handler_opts = {
      border = "rounded",
    },
    bufnr
  })

  if features.codelens then
    enable_codelens(bufnr)
  end

  if features.debugger then
    enable_debugger(bufnr)
  end
end

local function jdtls_setup(event)
  local jdtls = require('jdtls')

  local path = get_jdtls_paths()
  local data_dir = path.data_dir .. '/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

  if cache_vars.capabilities == nil then
    jdtls.extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
  end

  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  local cmd = {
    -- 💀
    'java',

    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-javaagent:' .. path.lombok,
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',

    -- 💀
    '-jar',
    path.launcher_jar,

    -- 💀
    '-configuration',
    path.platform_config,

    -- 💀
    '-data',
    data_dir,
  }

  local lsp_settings = {
    java = {
      -- jdt = {
      --   ls = {
      --     vmargs = "-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx4G -Xms256m"
      --   }
      -- },
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = 'interactive',
        runtimes = path.runtimes,
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
      -- inlayHints = {
      --   parameterNames = {
      --     enabled = 'all' -- literals, all, none
      --   }
      -- },
      format = {
        enabled = true,
        -- settings = {
        --   profile = 'asdf'
        -- },
      }
    },
    signatureHelp = {
      enabled = true,
    },
    completion = {
      favoriteStaticMembers = {
        'org.hamcrest.MatcherAssert.assertThat',
        'org.hamcrest.Matchers.*',
        'org.hamcrest.CoreMatchers.*',
        'org.junit.jupiter.api.Assertions.*',
        'java.util.Objects.requireNonNull',
        'java.util.Objects.requireNonNullElse',
        'org.mockito.Mockito.*',
      },
    },
    contentProvider = {
      preferred = 'fernflower',
    },
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      }
    },
  }

  -- This starts a new client & server,
  -- or attaches to an existing client & server depending on the `root_dir`.
  jdtls.start_or_attach({
    cmd = cmd,
    settings = lsp_settings,
    on_attach = jdtls_on_attach,
    capabilities = cache_vars.capabilities,
    root_dir = jdtls.setup.find_root(root_files),
    flags = {
      allow_incremental_sync = true,
    },
    init_options = {
      bundles = path.bundles,
    },
  })
end

vim.api.nvim_create_autocmd('FileType', {
  group = java_cmds,
  pattern = { 'java' },
  desc = 'Setup jdtls',
  callback = jdtls_setup,
})
