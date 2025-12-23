-- 打开 Java 文件时启动/附加 JDTLS
local group = vim.api.nvim_create_augroup("jdtls_lsp", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = "java",
	desc = "为 Java buffer 启动/附加 jdtls",
	callback = function()
		require("config.jdtls").setup_jdtls()
	end,
})
