-- JDTLS（Java Language Server）配置入口。
--
-- 依赖关系（建议先理解“谁负责什么”）：
-- - mason.nvim：负责下载安装到本机的外部工具（jdtls / java-debug-adapter / java-test）
-- - nvim-jdtls：负责把“jdtls 语言服务器 + 调试/测试能力”接入到 Neovim
-- - nvim-cmp + cmp-nvim-lsp：负责补全 UI，并把补全能力（capabilities）告知 LSP
--
-- 这个文件做的事情：
-- 1) 从 mason 的安装目录里找到 jdtls 的启动 jar、配置目录、lombok.jar
-- 2) 组装调试/测试所需的 jar（bundles），交给 nvim-jdtls
-- 3) 计算 Java 项目的 root_dir 和 workspace_dir
-- 4) 通过 require("jdtls").start_or_attach(...) 启动或复用 jdtls
--
-- 小白用法（通常在 FileType java 时调用）：
--   require("config.jdtls").setup_jdtls()

local function get_jdtls()
	-- mason-registry：mason 的“已安装包注册表”，可以用它查询某个包装到了哪里
	local mason_registry = require("mason-registry")

	-- jdtls：mason 包名（确保你在 mason 里装过它，否则会报错）
	local jdtls = mason_registry.get_package("jdtls")

	-- jdtls 的实际安装路径（形如 ~/.local/share/nvim/mason/packages/jdtls）
	local jdtls_path = jdtls:get_install_path()

	-- 启动语言服务器的 jar：org.eclipse.equinox.launcher_*.jar（版本号会变，所以用 glob 匹配）
	-- 小白提示：
	-- - vim.fn.glob(...) 返回的是“字符串”，若匹配到多个文件，可能会用换行拼在一起
	-- - 这里通常只会匹配到 1 个 launcher；如果你遇到启动报错，可以检查这里是否拿到了正确路径
	local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

	-- 操作系统标识：jdtls 的配置目录按系统区分
	-- - Linux：config_linux
	-- - macOS：config_mac
	-- - Windows：config_win
	-- 这里写死为 linux：如果你不是 Linux，需要改这个值
	-- 小白提示：更通用的做法是“自动识别系统”，例如根据 vim.loop.os_uname() / vim.fn.has("win32") 等判断
	local SYSTEM = "linux"

	-- jdtls 的系统配置目录（里面包含 launcher 需要的各种 ini/配置）
	local config = jdtls_path .. "/config_" .. SYSTEM

	-- lombok.jar：让语言服务器理解 Lombok 相关注解（例如 @Data / @Builder）
	local lombok = jdtls_path .. "/lombok.jar"

	return launcher, config, lombok
end

local function get_bundles()
	-- bundles：nvim-jdtls 用来“扩展 jdtls”的 jar 列表
	-- 这里主要用于：
	-- - Java Debug Adapter（调试）
	-- - Java Test（测试）
	local mason_registry = require("mason-registry")

	-- java-debug-adapter：mason 包名
	-- 小白提示：如果你还没装这些包，会在这里报错；可用 :Mason 打开界面安装/更新
	local java_debug = mason_registry.get_package("java-debug-adapter")
	local java_debug_path = java_debug:get_install_path()

	-- com.microsoft.java.debug.plugin-*.jar：调试适配器的核心 jar
	-- 小白提示：vim.fn.glob 默认返回字符串（可能包含换行），这里作为单个元素放进列表即可
	local bundles = {
		vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1),
	}

	-- java-test：mason 包名（用于 JUnit/TestNG 等测试集成）
	local java_test = mason_registry.get_package("java-test")
	local java_test_path = java_test:get_install_path()

	-- 把 java-test 的所有 server/*.jar 都加入 bundles
	-- vim.fn.glob(...) 返回用 \n 分隔的字符串，所以这里用 vim.split 拆开，再 list_extend 合并
	vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", 1), "\n"))

	return bundles
end

local function get_workspace()
	-- workspace_dir：jdtls 会把“项目的缓存/索引/元信息”放在这里（不是你的源码目录）
	-- 小白提示：不同项目必须用不同 workspace_dir，否则会串项目导致奇怪问题
	local home = os.getenv("HOME")

	-- 你希望存放 workspace 的根目录
	-- 注意：这个目录需要存在；如果不存在，jdtls 可能启动失败
	-- 小白提示：如果你想自动创建目录，可以用 vim.fn.mkdir(workspace_path, "p")（p 表示递归创建）
	local workspace_path = home .. "/code/workspace/"

	-- 取当前工作目录（cwd）的项目名作为子目录名
	-- 这里用 ":p:h:t" 是为了“稳定取到当前目录名”：
	-- - :p 会把目录规范化成绝对路径，并可能带上结尾的 "/"（例如 /a/b/c/）
	-- - 如果直接 :p:t，遇到结尾 "/" 时 :t 可能会变成空字符串
	-- - 先 :h 去掉结尾 "/"（回到 /a/b/c），再 :t 才能得到目录名 c
	-- 也不要写成 :h:t：因为那会先取父目录 /a/b，再取目录名 b（会变成“父目录名”）
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
	local workspace_dir = workspace_path .. project_name

	return workspace_dir
end

local function java_keymaps()
	-- 这些命令/按键只在 jdtls 真正 attach 到当前 buffer 后才创建（见 on_attach）
	-- -buffer：创建“缓冲区本地命令”，只对当前 Java buffer 生效，避免污染全局命令空间

	-- 定义 :JdtCompile（可选参数，带自动补全）
	vim.cmd(
		"command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)"
	)
	-- 定义 :JdtUpdateConfig（更新项目配置，例如依赖变更后刷新）
	vim.cmd("command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()")
	-- 定义 :JdtBytecode（javap：反编译/查看字节码）
	vim.cmd("command! -buffer JdtBytecode lua require('jdtls').javap()")
	-- 定义 :JdtJshell（打开 jshell）
	vim.cmd("command! -buffer JdtJshell lua require('jdtls').jshell()")

	-- 约定：用 <leader>J* 作为 Java 专属前缀（避免和通用 LSP 快捷键冲突）
	vim.keymap.set("n", "<leader>Jo", "<Cmd> lua require('jdtls').organize_imports()<CR>", { desc = "[J]ava [O]rganize Imports" })

	-- 抽取重构：变量/常量（支持普通模式/可视模式）
	vim.keymap.set("n", "<leader>Jv", "<Cmd> lua require('jdtls').extract_variable()<CR>", { desc = "[J]ava Extract [V]ariable" })
	vim.keymap.set(
		"v",
		"<leader>Jv",
		"<Esc><Cmd> lua require('jdtls').extract_variable(true)<CR>",
		{ desc = "[J]ava Extract [V]ariable" }
	)
	vim.keymap.set("n", "<leader>JC", "<Cmd> lua require('jdtls').extract_constant()<CR>", { desc = "[J]ava Extract [C]onstant" })
	vim.keymap.set(
		"v",
		"<leader>JC",
		"<Esc><Cmd> lua require('jdtls').extract_constant(true)<CR>",
		{ desc = "[J]ava Extract [C]onstant" }
	)

	-- 测试：最近方法 / 当前测试类
	vim.keymap.set("n", "<leader>Jt", "<Cmd> lua require('jdtls').test_nearest_method()<CR>", { desc = "[J]ava [T]est Method" })
	vim.keymap.set(
		"v",
		"<leader>Jt",
		"<Esc><Cmd> lua require('jdtls').test_nearest_method(true)<CR>",
		{ desc = "[J]ava [T]est Method" }
	)
	vim.keymap.set("n", "<leader>JT", "<Cmd> lua require('jdtls').test_class()<CR>", { desc = "[J]ava [T]est Class" })

	-- 更新项目配置（例如依赖/构建文件改动后）
	vim.keymap.set("n", "<leader>Ju", "<Cmd> JdtUpdateConfig<CR>", { desc = "[J]ava [U]pdate Config" })
end

local function setup_jdtls()
	-- jdtls：nvim-jdtls 插件导出的 Lua 模块
	local jdtls = require("jdtls")

	-- 获取 jdtls 的 launcher jar、系统配置目录、lombok.jar
	local launcher, os_config, lombok = get_jdtls()

	-- 计算 workspace_dir（用于存放 jdtls 的缓存/索引）
	local workspace_dir = get_workspace()

	-- 获取 bundles（调试/测试相关 jar）
	local bundles = get_bundles()

	-- root_dir：jdtls 用它判断“这个 Java 项目在哪里”，并据此启动/复用语言服务器
	-- 一般会根据 .git/mvnw/gradlew/pom.xml/build.gradle 等标记来判断项目根
	-- 小白提示：如果找不到这些标记，root_dir 可能为 nil；这会导致 jdtls 启动/复用行为不稳定
	local root_dir = jdtls.setup.find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })

	-- capabilities：告诉语言服务器客户端支持哪些特性
	-- 小白提示：LSP 的 capabilities 是“客户端能力声明”，对补全/代码操作等行为有影响
	local capabilities = {
		workspace = {
			configuration = true,
		},
		textDocument = {
			completion = {
				snippetSupport = false,
			},
		},
	}

	-- 把 nvim-cmp 的补全能力合并进去（否则部分补全能力不会被 LSP 充分利用）
	-- 小白提示：这里是“浅合并”（只合并第一层 key）；一般够用，但如果你深度自定义 capabilities，可能需要更细的合并策略
	local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

	for k, v in pairs(lsp_capabilities) do
		capabilities[k] = v
	end

	-- extendedClientCapabilities：jdtls 扩展能力（非标准 LSP 的补充能力）
	local extendedClientCapabilities = jdtls.extendedClientCapabilities

	-- resolveAdditionalTextEditsSupport：允许服务器在某些操作中返回“额外文本编辑”
	extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

	-- cmd：启动 jdtls 的命令行参数
	-- 小白提示：这里的 cmd 是一个“字符串数组”，Neovim 会按数组逐项传给系统执行
	-- 额外提示（常见踩坑）：
	-- - 需要系统里能找到 java（PATH 里有 Java 可执行文件）；否则 jdtls 无法启动
	-- - 如果启动报 UnsupportedClassVersionError，通常是你的 JDK 版本太旧，需要升级
	-- - -Xmx1g 是最大堆内存，项目很大时可以适当调大
	local cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		-- -javaagent：把 lombok 注入到 jdtls 的 JVM 进程中
		"-javaagent:" .. lombok,
		"-jar",
		launcher,
		"-configuration",
		os_config,
		"-data",
		workspace_dir,
	}

	-- settings：传给 jdtls 的服务端配置（大多是 Java 相关的行为偏好）
	local settings = {
		java = {
			-- 代码格式化
			format = {
				enabled = true,
				-- 这里使用 Google 风格（XML 文件需存在）
				settings = {
					url = vim.fn.stdpath("config") .. "/lang_servers/intellij-java-google-style.xml",
					profile = "GoogleStyle",
				},
			},

			-- 自动下载源码包（便于跳转到源码/查看文档）
			eclipse = {
				downloadSources = true,
			},
			maven = {
				downloadSources = true,
			},

			-- 签名帮助（函数参数提示）
			signatureHelp = {
				enabled = true,
			},

			-- javap 反编译器选择：fernflower 输出更接近 Java 源码
			contentProvider = {
				preferred = "fernflower",
			},

			-- 保存时自动整理 import
			saveActions = {
				organizeImports = true,
			},

			-- 补全相关偏好
			completion = {
				-- 静态成员 import 的优先候选（更符合测试/断言习惯）
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				-- 尽量不要从这些包里建议导入（避免污染）
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
				-- import 排序顺序
				importOrder = {
					"java",
					"jakarta",
					"javax",
					"com",
					"org",
				},
			},

			-- import 合并阈值：设为很大，避免自动变成 .*（更符合多数团队规范）
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},

			-- 代码生成偏好（toString / equals&hashCode 等）
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = {
					useJava7Objects = true,
				},
				useBlocks = true,
			},

			-- 当项目结构变更需要重新导入/刷新构建配置时，交互式提示你是否更新
			configuration = {
				updateBuildConfiguration = "interactive",
			},

			-- CodeLens：显示引用数量/实现数量等小提示
			referencesCodeLens = {
				enabled = true,
			},

			-- Inlay Hints：参数名提示
			inlayHints = {
				parameterNames = {
					enabled = "all",
				},
			},
		},
	}

	-- init_options：nvim-jdtls 的扩展启动参数
	-- - bundles：调试/测试 jar
	-- - extendedClientCapabilities：jdtls 扩展能力
	local init_options = {
		bundles = bundles,
		extendedClientCapabilities = extendedClientCapabilities,
	}

	-- on_attach：当 jdtls 成功附加到当前 buffer 后执行（这里最适合放 buffer 本地映射/命令）
	local on_attach = function(_, bufnr)
		-- Java 专属按键/命令
		-- 小白提示：当前 java_keymaps() 里设置的 keymap 没有传 { buffer = bufnr }，所以是“全局映射”
		-- 如果你只想让这些映射在 Java 文件中生效，可以在 vim.keymap.set 里加上 { buffer = bufnr }
		java_keymaps()

		-- 启用 jdtls 的 DAP 支持（调试）
		require("jdtls.dap").setup_dap()

		-- 扫描 main 方法，生成可调试的 main class 配置
		-- 小白提示：如果项目太大/启动慢，偶尔会因为 jdtls 尚未准备好而失败；
		-- 这时可以：
		-- 1) 打开包含 main 的类再运行调试
		-- 2) 或重启 Neovim 再试
		require("jdtls.dap").setup_dap_main_class_configs()

		-- 注册 jdtls 的额外命令（例如 :JdtCompile 等）
		require("jdtls.setup").add_commands()

		-- 刷新 CodeLens（引用数/实现数等）
		vim.lsp.codelens.refresh()

		-- 保存 Java 文件后自动刷新 CodeLens（用 pcall 防止偶发报错中断）
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = { "*.java" },
			callback = function()
				local _, _ = pcall(vim.lsp.codelens.refresh)
			end,
		})
	end

	-- start_or_attach 所需的配置表
	local config = {
		cmd = cmd,
		root_dir = root_dir,
		settings = settings,
		capabilities = capabilities,
		init_options = init_options,
		on_attach = on_attach,
	}

	-- start_or_attach：如果同一个 root_dir 已经有 jdtls 在跑，就复用；否则启动新的
	require("jdtls").start_or_attach(config)
end

return {
	-- 对外暴露的入口函数
	setup_jdtls = setup_jdtls,
}
