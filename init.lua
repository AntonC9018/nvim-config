require("core.editor")
require("core.mappings")
local helper = require("core.helper")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        config = function()
            require("nvim-treesitter").setup(
            {
                ensure_installed =
                {
                    "c",
                    "cpp",
                    "c_sharp",
                    "lua",
                    "vim",
                    "vimdoc",
                    "query",
                    "zig",
                    "python",
                    "javascript",
                    "html",
                    "go",
                },
                sync_install = false,
                auto_install = true,

                highlight =
                {
                    enable = true,
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(
                        vim.loop.fs_stat,
                        vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                        return false
                    end,
                    additional_vim_regex_highlighting = false,
                },
            })
            vim.cmd(":silent TSUpdate");
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
        opts =
        {
            default = true,
        },
    },
    {
        -- NOTE: Requires `brew install ripgrep`
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies =
        {
            "nvim-treesitter/nvim-treesitter",
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            -- 'MunifTanjim/nui.nvim',
            'jonarrien/telescope-cmdline.nvim',
        },
        config = function()
            local actions = require("telescope.actions")
            local helpKey = "<C-/>"

            require("telescope").setup({
                actions =
                {
                    quit_on_open = true,
                },
                defaults =
                {
                    mappings =
                    {
                        i =
                        {
                            ["<C-n>"] = false,
                            ["<C-p>"] = false,
                            ["<C-x>"] = false,
                            ["<C-v>"] = false,
                            ["<C-t>"] = false,
                            ["<C-f>"] = false,
                            ["<PageUp>"] = false,
                            ["<PageDown>"] = false,
                            ["<M-f>"] = false,
                            ["<M-k>"] = false,
                            ["<C-q>"] = false,
                            ["<M-q>"] = false,
                            ["<C-_>"] = false,
                            ["<C-w>"] = false,
                            ["<C-r><C-w>"] = false,
                            ["<C-u>"] = false,
                            ["<C-d>"] = false,

                            [helpKey] = actions.which_key,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-c>"] = actions.close,
                            ["<Down>"] = actions.move_selection_next,
                            ["<Up>"] = actions.move_selection_previous,
                            ["<CR>"] = actions.select_default,
                        },
                        n =
                        {
                            ["<esc>"] = actions.close,
                            ["<CR>"] = actions.select_default,
                            ["<C-x>"] = false,
                            ["<C-v>"] = false,
                            ["<C-t>"] = false,
                            ["<C-q>"] = false,
                            ["<M-q>"] = false,

                            ["j"] = actions.move_selection_next,
                            ["k"] = actions.move_selection_previous,
                            ["H"] = false,
                            ["M"] = actions.move_to_middle,
                            ["L"] = false,

                            ["<Down>"] = actions.move_selection_next,
                            ["<Up>"] = actions.move_selection_previous,
                            ["gg"] = actions.move_to_top,
                            ["G"] = actions.move_to_bottom,

                            -- ["p"] = function(bufnr)
                            -- local escapeSpecialKeys = true
                            -- vim.api.nvim_feedkeys('i^R"^[', 'm', escapeSpecialKeys)
                            -- end,
                            -- ["<leader>p"] = function(bufnr)
                            --  local escapeSpecialKeys = true
                            -- vim.api.nvim_feedkeys('i^R*^[', 'm', escapeSpecialKeys)
                            -- end,

                            ["<C-u>"] = false,
                            ["<C-d>"] = false,
                            ["<C-k>"] = false,
                            ["<C-j>"] = false,
                            ["<C-f>"] = false,

                            ["<PageUp>"] = false,
                            ["<PageDown>"] = false,
                            ["<M-f>"] = false,
                            ["<M-k>"] = false,

                            [helpKey] = actions.which_key,
                        },
                    },
                },
            })

            require("telescope").load_extension('cmdline')

            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>so", function()
                vim.cmd.Telescope()
            end, {})
            vim.keymap.set("n", "<leader>sp", builtin.find_files, {})
            vim.keymap.set("n", "<leader>sP", builtin.oldfiles, {})
            vim.keymap.set("n", "<leader>sf",
                function()
                    builtin.live_grep({
                        grep_open_files = false
                    })
                end, {})
            -- TODO: search and replace
            vim.keymap.set("n", "<leader>ss", builtin.lsp_workspace_symbols, {})
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, {})
            vim.keymap.set("n",
                "<leader><leader>",
                function()
                    vim.cmd("Telescope cmdline")
                end, {})
            vim.keymap.set("n", "<leader>h<leader>", builtin.command_history, {})
            vim.keymap.set("n", "<leader>hf", builtin.search_history, {})
            vim.keymap.set("n", "<C-e>", builtin.buffers, {})
            vim.keymap.set("n", "<leader>sj", builtin.jumplist, {})
            -- vim.keymap.set("n", "gs", builtin.treesitter, {})
        end,
    },
    {
        "tpope/vim-commentary"
    },
    {
        'kevinhwang91/nvim-ufo',
        dependencies =
        {
            'kevinhwang91/promise-async',
            'nvim-treesitter/nvim-treesitter',
        },
        url = "git@github.com:AntonC9018/nvim-ufo.git",
        branch = "ts-refactor",
        config = function()
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99

            require('ufo').setup({
            })
        end,
    },
    {
        'phaazon/hop.nvim',
        config = function(plugin)
            local hop = require("hop")
            hop.setup();

            local directions = require("hop.hint").HintDirection
            vim.keymap.set(
                { 'n', 'v' },
                ';',
                function()
                    hop.hint_char1({
                        direction = directions.AFTER_CURSOR,
                        current_line_only = false,
                    })
                end,
                { remap = true })
        end,
    },
    {
        'kylechui/nvim-surround',
        config = function(plugin)
            -- I'm fine with the defaults here.
            require("nvim-surround").setup({})
        end
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function(plugin)
            require("trouble").setup({
                position = "bottom",
                icons = true,
                mode = "workspace_diagnostics",
                severity = vim.diagnostic.severity.ERROR,
                group = true,
                padding = false,
                cycle_results = false,
                action_keys =
                {
                    close = "<esc>", -- close the list
                    refresh = "r",
                    jump = { "<cr>", "<tab>", "<2-leftmouse>" },
                    -- open_tab = { "<c-t>" }, -- open buffer in new tab
                    jump_close = "gd",
                    toggle_mode = "m", -- workspace / document
                    switch_severity = "s",
                    toggle_preview = "P",
                    hover = "<C-i>",
                    preview = "p",
                    open_code_href = "gi",
                    toggle_fold = "L",
                    previous = "k",
                    next = "j",
                    help = "<C-/>",
                },
                multiline = true,
                indent_lines = true,
                win_config = { border = "single" },
                auto_close = false,
                auto_preview = true,
                auto_fold = false,
                auto_jump = { "lsp_definitions" },
                include_declaration =
                {
                    "lsp_references",
                    "lsp_implementations",
                    "lsp_definitions",
                },
                signs =
                {
                    error = "!",
                    warning = "?",
                    hint = "$",
                    information = "i",
                    other = "*",
                },
                use_diagnostic_signs = false,
            })

            vim.keymap.set("n", "wd", vim.cmd.Trouble)
        end
    },
    {
        "nvim-tree/nvim-tree.lua",
        config = function(plugin)
            local api = require("nvim-tree.api")

            local function onAttach(bufnr)
                local function set(binding, action)
                    vim.keymap.set('n', binding, action, { buffer = bufnr })
                end
                set('q', api.tree.close)
                set('cd', api.tree.change_root_to_node)
                set('<CR>', api.node.open.edit)
                set('l', api.node.open.edit)
                set('h', api.node.navigate.parent_close)
                set('<C-i>', api.node.show_info_popup)
                set('<F2>', api.fs.rename_basename)
                set('r', api.fs.rename)
                set('.', api.node.run.cmd)
                set('-', api.tree.change_root_to_parent)
                set('ti', api.tree.toggle_gitignore_filter)
                set('d', api.fs.remove)
                set('E', api.tree.expand_all)
                set('<C-r>', api.tree.reload)
                set('e', api.tree.collapse_all)
                set('pr', api.fs.copy.relative_path)
                set('pa', api.fs.copy.absolute_path)
                set('a', api.fs.create)
                set('R', api.node.run.system)
                set('yn', api.fs.copy.filename)
                set('g?', api.tree.toggle_help)
                set('<2-LeftMouse>', api.node.open.edit)
            end

            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            require("nvim-tree").setup(
            {
                on_attach = onAttach,
                filters = {
                    dotfiles = true,
                },
            })

            -- Explorer
            helper.windowMap(
                "e",
                vim.cmd.NvimTreeOpen,
                vim.cmd.NvimTreeToggle)
        end
    },
    {
        "j-hui/fidget.nvim",
        enabled = false,
        dependencies =
        {
            "nvim-tree/nvim-tree.lua"
        },
        opts =
        {
            progress =
            {
                display =
                {
                    render_limit = 10,
                    done_ttl = 5,
                },
            },
            notification =
            {
                history_size = 128,
                override_vim_notify = true,
                view =
                {
                    stack_upwards = false,
                },
            },
            integration =
            {
                ["nvim-tree"] =
                {
                    enable = true,
                },
            },
        },
    },
    {
        "williamboman/mason.nvim",
        opts =
        {
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies =
        {
            "williamboman/mason.nvim"
        },
        config = function(plugin)
            local lspconfig = require('lspconfig')

            lspconfig.lua_ls.setup(
            {
                on_init = function(client)
                    local path = client.workspace_folders[1].name

                    if
                        not vim.loop.fs_stat(path .. '/.luarc.json')
                        and not vim.loop.fs_stat(path .. '/.luarc.jsonc')
                    then
                        local settings = vim.tbl_deep_extend(
                            'force',
                            client.config.settings,
                            {
                                Lua =
                                {
                                    runtime =
                                    {
                                        version = 'LuaJIT',
                                    },
                                    workspace =
                                    {
                                        checkThirdParty = false,
                                        library =
                                        {
                                            vim.env.VIMRUNTIME,
                                        },
                                    },
                                },
                            })
                        client.config.settings = settings

                        client.notify(
                            "workspace/didChangeConfiguration",
                            {
                                settings = settings,
                            })
                    end
                    return true
                end
            })

            vim.keymap.set('n', 'gE', vim.diagnostic.goto_prev)
            vim.keymap.set('n', 'ge', vim.diagnostic.goto_next)

            vim.api.nvim_create_autocmd('LspAttach',
            {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                    local opts = { buffer = ev.buf }

                    -- helper.windowMap(
                    --     'd',
                    --     vim.diagnostic.open_float,
                    --     vim.diagnostic.hide,
                    --     opts)
                    vim.keymap.set({'i', "n"}, '<C-Space>', vim.lsp.omnifunc, opts)

                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set({ 'n', 'i' }, '<C-i>', vim.lsp.buf.hover, opts)
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                    vim.keymap.set({ 'n', 'i' }, '<M-i>', vim.lsp.buf.signature_help, opts)
                    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
                    vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
                    vim.keymap.set({ 'n', 'v' }, '<C-.>', vim.lsp.buf.code_action, opts)
                    vim.keymap.set('n', 'gu', vim.lsp.buf.references, opts)
                    vim.keymap.set({ 'n', 'v' }, '<space>ref', function()
                        vim.lsp.buf.format { async = true }
                    end, opts)
                end,
            })
        end
    },
    {
        "gbprod/substitute.nvim",
        config = function(_)
            local substitute = require("substitute")
            substitute.setup(
            {
                on_substitute = nil,
                yank_substituted_text = false,
                preserve_cursor_position = false,
                modifiers = nil,
                highlight_substituted_text =
                {
                    enabled = true,
                    timer = 500,
                },
                range =
                {
                    prefix = nil,
                    prompt_current_text = false,
                    confirm = false,
                    complete_word = false,
                    subject = nil,
                    range = nil,
                    suffix = "",
                    auto_apply = false,
                    cursor_position = "end",
                },
                exchange =
                {
                    motion = false,
                    use_esc_to_cancel = false,
                    preserve_cursor_position = false,
                },
            });

            vim.keymap.set("n", "gr", substitute.operator)
            vim.keymap.set("n", "grr", substitute.line)
            vim.keymap.set("x", "gr", substitute.visual)

            local exchange = require("substitute.exchange")

            vim.keymap.set("n", "X", exchange.operator)
            vim.keymap.set("n", "XX", exchange.line)
            vim.keymap.set("x", "X", exchange.visual)
            vim.keymap.set("n", "Xs", exchange.cancel)
        end,
    },

    {
        'hrsh7th/nvim-cmp',
        dependencies =
        {
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            -- 'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            "petertriho/cmp-git",
        },
        config = function(_)
            -- Set up nvim-cmp.
            local cmp = require('cmp')

            cmp.setup(
            {
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                preselect_mode = cmp.PreselectMode.None,
                autocomplete = true,
                mapping = cmp.mapping.preset.insert(
                {
                    ['<C-j>'] = cmp.mapping.select_next_item(),
                    ['<C-k>'] = cmp.mapping.select_prev_item(),
                    ['<Tab>'] = function(fallback)
                        -- NOTE: 
                        -- get_active_entry can return non-null even if the thing is not open
                        if cmp.visible() and cmp.get_active_entry() ~= nil then
                            cmp.confirm({ select = true })
                        else
                            cmp.abort()
                            fallback()
                        end
                    end,
                    ['<Esc>'] = function(fallback)
                        if not cmp.visible() then
                            fallback()
                            return
                        end

                        cmp.abort()

                        -- Only exit to normal mode if nothing was selected prior
                        if cmp.get_active_entry() == nil then
                            fallback()
                        end
                    end,
                }),
                sources = cmp.config.sources(
                {
                    { name = 'nvim_lsp' },
                },
                {
                    { name = 'buffer' },
                }),
                experimental =
                {
                    ghost_test = true,
                },
            })

            cmp.setup.filetype('gitcommit',
            {
                sources = cmp.config.sources(
                {
                    { name = 'git' },
                },
                {
                    { name = 'buffer' },
                })
            })

            cmp.setup.cmdline({ '/', '?' },
            {
                mapping = cmp.mapping.preset.cmdline(),
                sources =
                {
                    { name = 'buffer' },
                },
            })

            cmp.setup.cmdline(':',
            {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources(
                {
                    { name = 'path' },
                },
                {
                    { name = 'cmdline' },
                })
            })
        end,
    },
    {
        'kana/vim-textobj-entire',
        dependencies =
        {
            'kana/vim-textobj-user',
        },
    },
    {
        'wellle/targets.vim',
    },
    {
        'AndrewRadev/bufferize.vim',
        init = function(_)
            vim.keymap.set('n',
                'wm',
                function()
                    vim.cmd("Bufferize messages")
                end)
        end,
    },
});
