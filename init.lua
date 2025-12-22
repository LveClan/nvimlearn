-- 声明 lazy.nvim 克隆插件代码的路径
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- 检查 lazy.nvim 是否已被克隆；若没有则克隆到 lazy.nvim 目录
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- 最新稳定版
		lazypath,
	})
end

-- 将 lazy.nvim 的路径加入运行时路径（rtp）
vim.opt.rtp:prepend(lazypath)

-- 声明一些 lazy.nvim 的选项
local opts = {
	change_detection = {
		-- 配置变更时不弹出通知
		notify = false,
	},
	checker = {
		-- 自动检查插件更新
		enabled = true,
		-- 有更新时不频繁弹通知
		notify = false,
	},
}

require("config.options")
require("config.keymaps")

-- 配置 lazy.nvim（建议放在最后执行）
-- 告诉 lazy：所有插件 specs 都在 plugins 目录中
-- 传入上面定义的选项
require("lazy").setup("plugins", opts)
