-- 这是 lazy.nvim 的“插件声明（plugin spec）”文件。
-- 因为 init.lua 里调用了：require("lazy").setup("plugins", opts)
-- 所以 lazy.nvim 会自动加载 lua/plugins/*.lua，并读取每个文件 return 的 table。
--
-- 小白提示：
-- - Lua 的 table（表）类似“字典/对象 + 数组”的组合：既可以用 key=value，也可以按顺序放值。
-- - 这里的写法同时用了两种形式：第 1 个元素是字符串，其余是 key=value 选项。
--
-- 相关帮助（在 Neovim 里输入查看）：
-- - :h lazy.nvim
-- - :h lua-vim
-- - :h vim.cmd
-- - :h :colorscheme
return {
    -- 简写的 GitHub 仓库地址
    -- 这是这个插件的来源：lazy.nvim 会从这里下载并安装它
    "Mofiqul/dracula.nvim",

    -- lazy=false：表示不要按需加载，而是在启动时尽早加载（配色一般希望尽早生效）
    lazy = false,

    -- priority：当多个插件都可能在启动阶段加载时，数值越大越优先加载
    priority = 1000,

    -- config：插件加载完成后会执行这个函数，用来做插件的初始化/设置
    config = function()
        -- 确保在 Neovim 加载并配置 dracula 插件时设置配色方案
        -- vim.cmd.colorscheme "dracula" 等价于在命令行执行：:colorscheme dracula
        -- “dracula” 这个名字由插件提供（它在运行时路径里注册了对应的 colorscheme）
        vim.cmd.colorscheme "dracula"
    end,
}
