-- 这是 lazy.nvim 的“插件声明（plugin spec）”文件：
-- 小白提示：这里 return 的是“插件列表”（一个 table，里面放了多个插件 spec），用于配置 LSP/调试相关能力。
return {
	{
		-- mason.nvim：LSP/DAP/formatter 等外部工具的安装管理器（统一下载与更新）
		"williamboman/mason.nvim",
		config = function()
			-- 使用默认配置初始化 mason
			require("mason").setup()
		end,
	},

	-- mason-lspconfig.nvim：把 mason 和 LSP 服务器对接起来，确保你指定的 LSP 服务器会被安装
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				-- ensure_installed：mason 的包名（不是文件类型名）
				-- lua_ls：Lua Language Server
				-- ts_ls：TypeScript Language Server（Neovim 0.11 推荐的新名，旧名常见为 tsserver）
				-- jdtls：Java Language Server（注意：本文件后面目前没有启用/配置 jdtls，需要额外配置才会真正生效）
				ensure_installed = { "lua_ls", "ts_ls", "jdtls" },
			})
		end,
	},

	-- mason-nvim-dap.nvim：用于安装/管理调试适配器（DAP）
	-- 小白提示：mason-lspconfig 只管 LSP，不会帮你装调试器，所以 DAP 需要单独配置
	{
		"jay-babu/mason-nvim-dap.nvim",
		config = function()
			require("mason-nvim-dap").setup({
				-- Java 调试相关组件
				ensure_installed = { "java-debug-adapter", "java-test" },
			})
		end,
	},

	-- nvim-jdtls：专门用于配置/增强 Java 的 jdtls（通常需要 workspace、root_dir 等额外信息）
	{
		"mfussenegger/nvim-jdtls",
		dependencies = {
			-- nvim-dap：调试框架（Java 调试会用到）
			"mfussenegger/nvim-dap",
		},
	},

	-- nvim-lspconfig：Neovim 官方维护的 LSP 配置入口
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- nvim-cmp + cmp-nvim-lsp：用于补全，并把补全能力（capabilities）注入到 LSP 客户端
			"hrsh7th/nvim-cmp",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- 获取 nvim-cmp capabilities（官方推荐：先基础，再增强）
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

			-- 新 API：全局默认配置（name='*', cfg=table；会合并进所有服务器）
			-- 相关帮助：:h vim.lsp.config  :h vim.lsp.enable
			-- 小白提示：这套写法需要 Neovim 0.11+；旧版本通常使用 require("lspconfig").xxx.setup(...)
			vim.lsp.config("*", {
				capabilities = capabilities, -- 自动应用到所有服务器
			})

			-- 新 API：服务器特定配置（name=string, cfg=table）
			-- Lua LS（官方推荐设置，支持 Neovim 集成）
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true), -- Neovim runtime 库
							checkThirdParty = false,
						},
						telemetry = { enable = false },
					},
				},
			})

			-- TypeScript LS（ts_ls 是官方新名；默认配置即可，capabilities 已全局合并）
			vim.lsp.config("ts_ls", {})

			-- 启用服务器：会按文件类型自动附加到对应 buffer
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("ts_ls")

			-- 键映射：用 LspAttach autocmd（官方推荐，避免全局）
			-- 这相当于 on_attach 的替代：只在 LSP 附加到当前 buffer 时生效
				vim.api.nvim_create_autocmd("LspAttach", {
					callback = function(args)
					local buf = args.buf
					local opts = { buffer = buf, silent = true } -- 缓冲区本地

					-- 小白提示：这里用 telescope 的 LSP 相关 picker，会在按键触发时才 require，不会影响启动速度
					vim.keymap.set(
						"n",
						"<leader>ch",
						vim.lsp.buf.hover,
						vim.tbl_extend("force", opts, { desc = "[C]ode [H]over Documentation" })
					)
					vim.keymap.set(
						"n",
						"<leader>cd",
						vim.lsp.buf.definition,
						vim.tbl_extend("force", opts, { desc = "[C]ode Goto [D]efinition" })
					)
					vim.keymap.set(
						{ "n", "v" },
						"<leader>ca",
						vim.lsp.buf.code_action,
						vim.tbl_extend("force", opts, { desc = "[C]ode [A]ctions" })
					)
					vim.keymap.set(
						"n",
						"<leader>cr",
						require("telescope.builtin").lsp_references,
						vim.tbl_extend("force", opts, { desc = "[C]ode Goto [R]eferences" })
					)
					vim.keymap.set(
						"n",
						"<leader>ci",
						require("telescope.builtin").lsp_implementations,
						vim.tbl_extend("force", opts, { desc = "[C]ode Goto [I]mplementations" })
					)
					vim.keymap.set(
						"n",
						"<leader>cR",
						vim.lsp.buf.rename,
						vim.tbl_extend("force", opts, { desc = "[C]ode [R]ename" })
					)
					vim.keymap.set(
						"n",
						"<leader>cD",
						vim.lsp.buf.declaration,
						vim.tbl_extend("force", opts, { desc = "[C]ode Goto [D]eclaration" })
					)
				end,
			})
			end,
		},
	}
