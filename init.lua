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

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("core.mappings")

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
            vim.cmd("TSUpdate");
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
        },
        init = function(plugin)
            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>so", function()
                vim.cmd.Telescope()
                -- vim.
            end, {})
            vim.keymap.set("n", "<leader>sp", builtin.find_files, {})
            vim.keymap.set("n", "<leader>sP", builtin.find_files, {})
            vim.keymap.set("n", "<leader>ss", builtin.lsp_workspace_symbols, {})
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, {})
            vim.keymap.set("n", "<leader><leader>", builtin.commands, {})
            vim.keymap.set("n", "<leader>h<leader>", builtin.command_history, {})
            vim.keymap.set("n", "<leader>hf", builtin.search_history, {})
            vim.keymap.set("n", "<C-e>", builtin.buffers, {})
            vim.keymap.set("n", "<leader>sj", builtin.jumplist, {})
            -- vim.keymap.set("n", "gs", builtin.treesitter, {})
        end,
        config = function()
            local actions = require("telescope.actions")
            local helpKey = "<C-/>"

            require("telescope").setup({
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
                provider_selector = function(bufnr, filetype, buftype)
                    return {
                        'treesitter',
                        'indent'
                    }
                end,
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
        opts = 
        {
            position = "bottom",
            icons = true,
            mode = "workspace_diagnostics",
            severity = vim.diagnostic.severity.ERROR,
            group = true,
            padding = false,
            cycle_results = false,
            action_keys =
            {
                close = "q", -- close the list
                cancel = "<esc>",
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
                error = "",
                warning = "",
                hint = "",
                information = "",
                other = "",
            },
            use_diagnostic_signs = false,
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        config = function(plugin)
            local api = require("nvim-tree.api")
            local function onAttach(bufnr)
                local function set(binding, action)
                    vim.keymap.set('n', binding, action, { buffer = bufnr })
                end
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
            end
            require("nvim-tree").setup(
            {
                on_attach = onAttach,
                filters = {
                    dotfiles = true,
                },
            })
        end
    },
    {
        "j-hui/fidget.nvim",
        dependencies =
        {
            "nvim-tree/nvim-tree.lua"
        },
        opts =
        {
            -- Options related to LSP progress subsystem
            progress =
            {
                -- Options related to how LSP progress messages are displayed as notifications
                display =
                {
                    render_limit = 10,
                    done_ttl = 2,
                },
            },
            notification =
            {
                history_size = 128,
                override_vim_notify = true,
                view = {
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
});

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

