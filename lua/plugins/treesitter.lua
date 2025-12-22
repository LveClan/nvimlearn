-- 这是 lazy.nvim 的“插件声明（plugin spec）”文件：
-- - lazy.nvim 会加载 lua/plugins/*.lua
-- - 每个文件需要 return 一个 Lua table（表），描述要安装/如何配置插件
return {
	-- nvim-treesitter：基于 Tree-sitter 的语法解析与高亮（更准确的语法结构）
	"nvim-treesitter/nvim-treesitter",

	dependencies = {
		-- nvim-ts-autotag：利用 Tree-sitter 理解代码结构，自动补全/闭合 HTML/JSX/TSX 标签
		"windwp/nvim-ts-autotag",
	},

	-- build：安装/更新该插件后执行的命令
	-- :TSUpdate 会下载/更新各语言的 Tree-sitter 解析器（parsers），让高亮与结构分析生效
	build = ":TSUpdate",

	config = function()
		-- 引入 treesitter 的配置模块（插件提供的 Lua 模块）
		local ts_config = require("nvim-treesitter.configs")

		-- setup：传入一个 table 作为配置选项
		ts_config.setup({
			-- ensure_installed：自动安装/确保已安装的解析器列表
			-- 这些名字对应各语言的 parser（不是 LSP “服务器”）
			ensure_installed = {
				"vim",
				"vimdoc",
				"lua",
				"java",
				"javascript",
				"typescript",
				"html",
				"css",
				"json",
				"tsx",
				"markdown",
				"markdown_inline",
				"gitignore",
			},

			-- highlight：开启基于 Tree-sitter 的语法高亮
			highlight = { enable = true },

			-- autotag：启用自动补全/闭合标签（由 nvim-ts-autotag 提供）
			autotag = { enable = true },
		})
	end,
}
