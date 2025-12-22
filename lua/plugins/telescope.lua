-- 这是 lazy.nvim 的“插件声明（plugin spec）”文件。
-- 小白提示：这里 return 的是“插件列表”（一个 table，里面放了多个插件 spec）。
return {
	{
		-- Telescope：模糊搜索/选择器框架（查文件、grep、诊断、buffers 等）
		"nvim-telescope/telescope.nvim",
		tag = "v0.1.9",
		dependencies = {
			-- plenary.nvim：许多 Neovim 插件都会依赖的通用 Lua 工具库
			"nvim-lua/plenary.nvim",
		},
		config = function()
			-- telescope.builtin：telescope 内置的一组常用搜索函数（find_files / live_grep 等）
			local builtin = require("telescope.builtin")

			-- 下面这些是“全局快捷键”（普通模式 n）
			-- <leader> 是你的“前缀键”（通常是空格，可在配置中修改）
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
			vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]inder [R]esume" })
			vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = [[Find Recent Files ("." for repeat)]] })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind Existing [B]uffers" })
		end,
	},
	{
		-- telescope-ui-select：把某些选择界面改成 Telescope 的下拉 UI（例如 LSP 的一些选择）
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			-- actions：telescope 里用于“选择列表操作”的动作函数（移动、切换历史等）
			local actions = require("telescope.actions")

			require("telescope").setup({
				-- extensions：配置 telescope 的扩展
				extensions = {
					-- 使用 dropdown 风格作为 ui-select 的界面
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},

				-- mappings：telescope 面板内部的按键映射
				-- i 表示插入模式（也就是你在 Telescope 输入框里输入时）
				mappings = {
					i = {
						-- 使用 Ctrl+n / Ctrl+p 在历史记录中前后切换
						["<C-n>"] = actions.cycle_history_next,
						["<C-p>"] = actions.cycle_history_prev,

						-- 使用 Ctrl+j / Ctrl+k 在候选项中上下移动
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
					},
				},
			})

			-- 启用 ui-select 扩展：放在 setup 之后更直观（也符合多数插件文档的写法）
			require("telescope").load_extension("ui-select")
		end,
	},
}
