-- lua/y/plugins/java.lua  (or directly in your main plugins list)
return {
  "mfussenegger/nvim-jdtls",
  ft = { "java" },
  dependencies = {
    "williamboman/mason.nvim",
    "mfussenegger/nvim-dap",           -- optional but recommended
  },
  config = function()
    local function setup_jdtls()
      local jdtls = require("jdtls")

      -- Mason paths
      local mason = vim.fn.stdpath("data") .. "/mason"
      local jdtls_path = mason .. "/packages/jdtls"
      local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar", true, true)[1]

      if not launcher_jar then
        vim.notify("jdtls launcher not found! Run :MasonInstall jdtls", vim.log.levels.ERROR)
        return
      end

      -- OS-specific config directory
      local os_config = "linux"
      local sysname = vim.loop.os_uname().sysname
      if sysname == "Darwin" then os_config = "mac"
      elseif sysname:find("Windows") then os_config = "win" end

      local config_dir = jdtls_path .. "/config_" .. os_config

      -- Workspace
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
      local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

      -- Bundles (debugger + test)
      local bundles = {}
      local java_test_jars = mason .. "/packages/java-test/extension/server/*.jar"
      local java_debug_jar = mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"

      vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_jars, true), "\n"))
      local debug_jar = vim.fn.glob(java_debug_jar, true, true)[1]
      if debug_jar then table.insert(bundles, debug_jar) end

      local config = {
        cmd = {
          "java",
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.level=ALL",
          "-Xmx2g",
          "--add-modules=ALL-SYSTEM",
          "--add-opens", "java.base/java.util=ALL-UNNAMED",
          "--add-opens", "java.base/java.lang=ALL-UNNAMED",
          "-jar", launcher_jar,
          "-configuration", config_dir,
          "-data", workspace_dir,
        },

        root_dir = require("jdtls.setup").find_root({ ".git", "pom.xml", "build.gradle", "mvnw", "gradlew" }),

        settings = {
          java = {
            format = { settings = { url = vim.fn.stdpath("config") .. "/java/google_java_format.xml" } },
            eclipse = { downloadSources = true },
            maven = { downloadSources = true },
            implementationsCodeLens = { enabled = true },
            referencesCodeLens = { enabled = true },
            signatureHelp = { enabled = true },
            contentProvider = { preferred = "fernflower" },
          },
        },

        init_options = { bundles = bundles },

        capabilities = vim.lsp.protocol.make_client_capabilities(),
        on_attach = function(client, bufnr)
          -- Your custom Java keymaps (on top of global LspAttach)
          local opts = { buffer = bufnr, silent = true }
          vim.keymap.set("n", "<leader>lo", jdtls.organize_imports, opts)
          vim.keymap.set("n", "<leader>lv", jdtls.extract_variable, opts)
          vim.keymap.set("n", "<leader>lc", jdtls.extract_constant, opts)
          vim.keymap.set("v", "<leader>lm", function() jdtls.extract_method(true) end, opts)

          vim.keymap.set("n", "<leader>df", jdtls.test_class, opts)
          vim.keymap.set("n", "<leader>dn", jdtls.test_nearest_method, opts)
        end,
      }

      -- Enhance capabilities for nvim-cmp
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        config.capabilities = vim.tbl_deep_extend("force", config.capabilities, cmp_lsp.default_capabilities())
      end

      jdtls.start_or_attach(config)
    end

    -- Run setup only once per session
    if not vim.g.jdtls_setup_done then
      setup_jdtls()
      vim.g.jdtls_setup_done = true
    end
  end,
}
