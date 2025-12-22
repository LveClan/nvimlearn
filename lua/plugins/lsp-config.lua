return {
    {
        "williamboman/mason.nvim",
        config = function()
            -- setup mason with default properties
            require("mason").setup()
        end
    },
    -- mason lsp config utilizes mason to automatically ensure lsp servers you want installed are installed
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            -- ensure that we have lua language server, typescript launguage server, java language server, and java test language server are installed
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "ts_ls", "jdtls" },
            })
        end
    },
    -- mason nvim dap utilizes mason to automatically ensure debug adapters you want installed are installed, mason-lspconfig will not automatically install debug adapters for us
    {
        "jay-babu/mason-nvim-dap.nvim",
        config = function()
            -- ensure the java debug adapter is installed
            require("mason-nvim-dap").setup({
                ensure_installed = { "java-debug-adapter", "java-test" }
            })
        end
    },
    -- utility plugin for configuring the java language server for us
    {
        "mfussenegger/nvim-jdtls",
        dependencies = {
            "mfussenegger/nvim-dap",
        }
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            -- 获取 nvim-cmp capabilities（官方推荐：先基础，再增强）
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            -- 新 API：全局默认配置（name = '*', cfg = table – 合并 capabilities）
            vim.lsp.config('*', {
                capabilities = capabilities,  -- 自动应用到所有服务器
                -- 可添加其他全局默认，如 root_dir 或 handlers
                -- on_attach = function(client, bufnr) ... end,  -- 如果需要全局 on_attach，作为表字段
            })

            -- 新 API：服务器特定配置（name = string, cfg = table – 合并默认 + 自定义）
            -- Lua LS（官方推荐设置，支持 Neovim 集成）
            vim.lsp.config('lua_ls', {
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = { 'vim' } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file('', true),  -- Neovim runtime 库
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
                -- on_attach = function(client, bufnr) ... end,  -- 如果需要服务器特定 on_attach，作为表字段
            })

            -- TypeScript LS（ts_ls 是官方新名；默认配置即可，capabilities 已全局合并）
            vim.lsp.config('ts_ls', {})

            -- 新 API：启用服务器（name = string；自动附加到匹配文件）
            vim.lsp.enable('lua_ls')
            vim.lsp.enable('ts_ls')

            -- 键映射：用 LspAttach autocmd（官方推荐，避免全局）
            -- 这相当于 on_attach 的替代：只在 LSP 附加时生效
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    local buf = args.buf
                    local opts = { buffer = buf, silent = true }  -- 缓冲区本地

                    -- 你的原映射，未变
                    vim.keymap.set('n', '<leader>ch', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = '[C]ode [H]over Documentation' }))
                    vim.keymap.set('n', '<leader>cd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = '[C]ode Goto [D]efinition' }))
                    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = '[C]ode [A]ctions' }))
                    vim.keymap.set('n', '<leader>cr', require('telescope.builtin').lsp_references, vim.tbl_extend('force', opts, { desc = '[C]ode Goto [R]eferences' }))
                    vim.keymap.set('n', '<leader>ci', require('telescope.builtin').lsp_implementations, vim.tbl_extend('force', opts, { desc = '[C]ode Goto [I]mplementations' }))
                    vim.keymap.set('n', '<leader>cR', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = '[C]ode [R]ename' }))
                    vim.keymap.set('n', '<leader>cD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = '[C]ode Goto [D]eclaration' }))
                end,
            })
        end
    }
}
