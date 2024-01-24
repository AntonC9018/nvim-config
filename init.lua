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
        },
        init = function(plugin)
            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>so", function()
                vim.cmd.Telescope()
                -- vim.
            end, {})
            vim.keymap.set("n", "<leader>sp", builtin.find_files, {})
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
            require('ufo').setup({
                provider_selector = function(bufnr, filetype, buftype)
                    return {
                        'treesitter',
                        'indent'
                    }
                end
            })
        end,
    },
});

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

