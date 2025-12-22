-- 这是 lazy.nvim 的“插件声明（plugin spec）”文件：
-- - lazy.nvim 会加载 lua/plugins/*.lua
-- - 每个文件需要 return 一个 Lua table（表），描述要安装/如何配置插件
return {
	-- 插件仓库地址：owner/repo（lazy.nvim 会用它来下载插件）
	"nvim-tree/nvim-tree.lua",

	-- config：插件加载完成后会执行这个函数，用于初始化/设置
	config = function()
		-- 绑定快捷键：
		-- - 'n' 表示普通模式（Normal mode）
		-- - <leader> 是你的“前缀键”（通常是空格或反斜杠，可在配置里改）
		-- - <cmd>...<CR> 等价于在命令行执行 :NvimTreeToggle
		-- - desc 会显示在 which-key 等提示里（如果你装了的话）
		vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })

		-- 插件初始化：这里传入一张 table 作为配置选项
		require("nvim-tree").setup({
			-- 接管内置的 netrw 文件浏览器，避免和 nvim-tree 冲突
			hijack_netrw = true,

			-- 当你保存文件时，自动刷新树形目录的显示
			auto_reload_on_write = true,
		})
	end,
}
