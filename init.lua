require("core.editor")
require("core.mappings")
local helper = require("core.helper")

do
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
end

local plugins =
{
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies =
        {
            "andymass/vim-matchup",
        },
        config = function()
            require('nvim-treesitter.configs').setup(
            ---@diagnostic disable-next-line: missing-fields
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
                    "latex",
                    "markdown",
                    "markdown_inline",
                },
                sync_install = false,
                auto_install = true,

                highlight =
                {
                    enabled = true,
                    disable = function(_, buf)
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
                matchup =
                {
                    enable = true,
                },
            })
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

            local helpKey = "<F1>"

            local function deleteWordBack()
                vim.api.nvim_input("<C-S-w>")
            end

            local action_state = require("telescope.actions.state")
            local entry_display = require("telescope.pickers.entry_display")

            local function copyAllEntries(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local manager = picker.manager

                local entries = {}
                for entry in manager:iter() do
                    local display, _ = entry_display.resolve(picker, entry)
                    table.insert(entries, display)
                end

                local text = table.concat(entries, "\n")

                vim.fn.setreg("+", text)
            end

            local function copySelectedEntry(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local entry = picker:get_selection()
                local display, _ = entry_display.resolve(picker, entry)
                vim.fn.setreg("+", display)
            end

            ---@diagnostic disable-next-line: missing-parameter
            require("telescope").setup({
                defaults =
                {
                    mappings =
                    {
                        i =
                        {
                            ["<C-Y>"] = copyAllEntries,
                            ["<C-y>"] = copySelectedEntry,
                            -- ["<C-n>"] = false,
                            -- ["<C-p>"] = false,
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
                            [helper.controlSlash()] = false,
                            ["<C-w>"] = deleteWordBack,
                            [helper.controlBackspace()] = deleteWordBack,
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
                            ["<C-p>"] = require('telescope.actions').cycle_history_next,
                            ["<C-n>"] = require('telescope.actions').cycle_history_prev,
                            ["<C-h>"] = function()
                                vim.api.nvim_input("<Left>")
                            end,
                            ["<C-l>"] = function()
                                vim.api.nvim_input("<Right>")
                            end,
                        },
                        n =
                        {
                            ["<C-Y>"] = copyAllEntries,
                            ["<C-y>"] = copySelectedEntry,
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
                    selection_caret = '',
                    prompt_prefix = '',
                    entry_prefix = '',
                    layout_strategy = 'horizontal',
                    layout_config =
                    {
                        horizontal =
                        {
                            height = 0.999,
                            preview_width = 0.6,
                            preview_cutoff = 0,
                            width = 0.999,
                        },
                    },
                    results_title = false,
                    prompt_title = false,
                    path_display = function(_, path)
                        return helper.formatPath(path)
                    end,
                    dynamic_preview_title = true,
                },
            })

            require("telescope").load_extension('cmdline')

            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>so", function()
                vim.cmd.Telescope()
            end, {})
            vim.keymap.set("n", "<leader>sp", builtin.find_files, {})
            vim.keymap.set("n", "<leader>sP", builtin.oldfiles, {})
            vim.keymap.set("n", "<leader>sf", function()
                builtin.live_grep({
                    grep_open_files = false
                })
            end, {})
            -- TODO: search and replace
            vim.keymap.set("n", "<leader>ss", builtin.lsp_workspace_symbols, {})
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, {})
            vim.keymap.set("n", "<leader><leader>", function()
                vim.cmd("Telescope cmdline")
            end, {})
            -- vim.keymap.set("n", "<leader>h<leader>", builtin.command_history, {})
            -- vim.keymap.set("n", "<leader>hf", builtin.search_history, {})
            vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
                builtin.buffers({
                    sort_lastused = true,
                    bufnr_width = 0,
                })
            end, {})
            vim.keymap.set("n", "<leader>sj", builtin.jumplist, {})
            vim.keymap.set("n", "<leader>sk", builtin.keymaps, {})
            vim.keymap.set("n", "<leader>sd", builtin.diagnostics, {})
            vim.keymap.set("n", "gu", builtin.lsp_references, {})
            vim.keymap.set("n", "gi", builtin.lsp_implementations, {})
            vim.keymap.set("n", "gt", builtin.lsp_type_definitions, {})
            vim.keymap.set('n', 'gd', builtin.lsp_definitions, {})
            vim.keymap.set("n", "gs", builtin.lsp_document_symbols, {})
            vim.keymap.set("n", "<leader>sy", function()
                vim.cmd("Telescope resume")
            end)
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        config = function(_)
            local api = require("nvim-tree.api")

            local function onAttach(bufnr)
                local function set(binding, action, desc)
                    vim.keymap.set('n', binding, action, {
                        buffer = bufnr,
                        desc = desc,
                    })
                end

                set('<Esc>', api.tree.close, "Close")
                set('q', api.tree.close, "Close")
                set('d', api.tree.change_root_to_node, "Change directory")
                set('<CR>', api.node.open.edit, "Edit")
                set('l', api.node.open.edit, "Open or Edit")
                set('h', api.node.navigate.parent_close, "Fold parent")
                set('<C-i>', api.node.show_info_popup, "Show info")
                set('<F2>', api.fs.rename_basename, "Rename")
                set('r', api.fs.rename, "Rename (all)")
                set('<2-LeftMouse>', api.node.open.edit, "Edit")
                set('o', function()
                    local lib = require("nvim-tree.lib")
                    local node = lib.get_node_at_cursor()
                    if node == nil then
                        return
                    end
                    vim.cmd("silent !start explorer.exe /select," .. vim.fn.shellescape(node.absolute_path))
                end, "Open in Explorer")
                set("y", api.fs.copy.node, "Copy")
                set("x", api.fs.cut, "Cut")
                set("p", api.fs.paste, "Paste")
                set("t", api.fs.clear_clipboard, "Clear clipboard")
                set('-', api.tree.change_root_to_parent, "Go up")
                set('i', api.tree.toggle_gitignore_filter, "Toggle gitignore")
                set('I', api.tree.toggle_hidden_filter, "Toggle hidden")
                set('D', api.fs.remove, "Delete")
                set('L', api.tree.expand_all, "Expand all")
                set('H', api.tree.collapse_all, "Collapse all")
                set('<C-r>', api.tree.reload, "Reload")
                set('R', api.fs.copy.relative_path, "Copy relative path")
                set('P', api.fs.copy.absolute_path, "Copy absolute path")
                set('a', api.fs.create, "Create file or directory (append / at end for a directory)")
                set('R', api.node.run.system, "Run (system)")
                set('Y', api.fs.copy.filename, "Copy filename")
                set('<C-g>', api.tree.toggle_help, "Help")
                set('e', api.tree.close, "Close")

                -- Doesn't work
                local timeoutLenOption = vim.o.timeoutlen
                vim.o.timeoutlen = 1
                vim.api.nvim_create_autocmd("BufEnter",
                {
                    buffer = bufnr,
                    callback = function()
                        vim.o.timeoutlen = 1
                    end,
                })
                vim.api.nvim_create_autocmd("BufLeave",
                {
                    buffer = bufnr,
                    callback = function()
                        vim.o.timeoutlen = timeoutLenOption
                    end,
                })
            end

            require("nvim-tree").setup(
            {
                actions =
                {
                    open_file =
                    {
                        quit_on_open = true,
                    },
                },
                on_attach = onAttach,
                filters =
                {
                    dotfiles = true,
                },
                -- sync_root_with_cwd = true,
                renderer =
                {
                    add_trailing = true,
                    indent_width = 4,
                    highlight_diagnostics = "name",
                    highlight_clipboard = "name",
                    highlight_bookmarks = "name",
                    icons =
                    {
                        glyphs =
                        {
                            git =
                            {
                                unstaged = "x",
                                staged = "✓",
                                unmerged = "",
                                renamed = "R",
                                untracked = "N", -- new
                                deleted = "D",
                                ignored = "◌",
                            },
                        },
                    },
                },
                git =
                {
                    cygwin_support = true,
                },
                diagnostics =
                {
                    enable = true,
                },
                hijack_cursor = true,
                ui =
                {
                    confirm =
                    {
                        default_yes = true,
                    },
                },
                view =
                {
                    relativenumber = true,
                    width = "100%",
                },
            })

            local tree = require('nvim-tree.api').tree

            -- Explorer
            vim.keymap.set('n', 'we', function()
                if tree.is_tree_buf(0) then
                    tree.close()
                else
                    tree.open()
                end
            end)

            vim.keymap.set('n', 'wE', function()
                tree.open(
                {
                    find_file = true,
                    update_root = true,
                })
            end)
        end
    },
    {
        "tpope/vim-commentary",
        init = function(_)
            vim.keymap.set("v", helper.controlSlash(), "<Plug>Commentary")
            vim.keymap.set("n", helper.controlSlash(), "<Plug>CommentaryLine")
        end,
    },
    {
        'kevinhwang91/nvim-ufo',
        dependencies =
        {
            'kevinhwang91/promise-async',
            'nvim-treesitter/nvim-treesitter',
        },
        url = "https://github.com/AntonC9018/nvim-ufo",
        branch = "ts-refactor",
        config = function()
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99

            local ufo = require('ufo');
            ufo.setup({
            })
        end,
    },
    {
        'phaazon/hop.nvim',
        config = function(_)
            local hop = require("hop")
            hop.setup(
            {
            });

            local hopOpts =
            {
                direction = nil,
                current_line_only = false,
                case_insensitive = false,
            }
            local opts = { remap = true }

            vim.keymap.set({ 'n', 'v' }, ';',
                function()
                    hop.hint_char1(hopOpts)
                end,
                opts)

            vim.keymap.set({ 'n', 'v' }, '<C-;>',
                function()
                    hop.hint_char2(hopOpts)
                end,
                opts)
        end,
    },
    {
        'kylechui/nvim-surround',
        config = function(_)
            require("nvim-surround").setup(
            ---@diagnostic disable-next-line: missing-fields
            {
                keymaps =
                {
                    insert = false,
                    insert_line = false,
                },
            })
        end
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function(_)
            local trouble = require("trouble");
            trouble.setup({
                position = "bottom",
                icons = true,
                mode = "workspace_diagnostics",
                severity = { vim.diagnostic.severity.WARN, vim.diagnostic.severity.ERROR },
                group = true,
                padding = false,
                cycle_results = false,
                action_keys =
                {
                    close = "<esc>", -- close the list
                    refresh = "<C-r>",
                    jump = { "<cr>", "<tab>", "<2-leftmouse>" },
                    -- open_tab = { "<c-t>" }, -- open buffer in new tab
                    jump_close = "gd",
                    toggle_mode = "m", -- workspace / document
                    switch_severity = "s",
                    toggle_preview = "P",
                    hover = "<C-i>",
                    preview = "p",
                    open_code_href = "x",
                    toggle_fold = "L",
                    previous = "<C-k>",
                    next = "<C-j>",
                    help = helper.controlSlash(),
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
            })

            vim.keymap.set("n", "wd", function()
                trouble.toggle()
            end)
            vim.keymap.set("n", "gu", function()
                trouble.toggle("lsp_references")
            end)
            vim.keymap.set("n", "ge", function()
                trouble.next({ skip_groups = true, jump = true })
            end)
            vim.keymap.set("n", "gE", function()
                trouble.previous({ skip_groups = true, jump = true })
            end)
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
            "williamboman/mason.nvim",
        },
        config = function(_)
            local lspconfig = require('lspconfig')

            lspconfig.lua_ls.setup(
            {
                on_init = function(client)
                    local path = client.workspace_folders[1].name

                    if
                        not vim.loop.fs_stat(path .. '/.luarc.json')
                        and not vim.loop.fs_stat(path .. '/.luarc.jsonc')
                    then
                        local lazyConfig = require("lazy.core.config")
                        local lazyPath = lazyConfig.options.root;

                        local libraries =
                        {
                            vim.env.VIMRUNTIME,
                            lazyPath,
                        }

                        local lazy = require("lazy")
                        local plugins = lazy.plugins()
                        for _, plugin in ipairs(plugins) do
                            table.insert(libraries, plugin.dir)
                        end

                        -- TODO: figure out autocommands to modify this list dynamically.

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
                                        library = libraries,
                                    },
                                },
                            })
                        client.config.settings = settings

                        -- wtach the lazy directory with plugins

                        client.notify("workspace/didChangeConfiguration",
                        {
                            settings = settings,
                        })
                    end
                    return true
                end
            })

            lspconfig.zls.setup(
            {
                on_init = function(_)
                    vim.g.zig_fmt_autosave = false
                end
            })

            lspconfig.clangd.setup(
            {
                -- TODO: Create a config file if it doesn't exist:
                --
                -- https://clangd.llvm.org/config#files
                --
                -- CompileFlags:
                --   Add: [ "-std=c++20", "-Wall" ]
                --
                -- TODO: Automatically create a formatter config if it doesn't exist:
                --
                -- https://clang.llvm.org/docs/ClangFormatStyleOptions.html
                --
                -- BasedOnStyle: Microsoft
                -- IndentWidth: 4
                -- SortIncludes: SI_Never
                --
                capabilities =
                {
                    offsetEncoding = "utf-8",
                },
            })

            vim.api.nvim_create_autocmd('LspAttach',
            {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                    local opts = { buffer = ev.buf }

                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                    helper.altMacBinding(
                    {
                        mode = { 'n', 'i' },
                        key = 'i',
                        action = vim.lsp.buf.hover,
                        opts = opts,
                    })
                    helper.altMacBinding(
                    {
                        mode = { 'n', 'i' },
                        key = 'u',
                        action = vim.lsp.buf.signature_help,
                        opts = opts,
                    })
                    vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
                    vim.keymap.set({ 'n', 'v' }, '<C-.>', vim.lsp.buf.code_action, opts)
                    vim.keymap.set({ 'n', 'v' }, '<space>ref', function()
                        vim.lsp.buf.format({
                            async = true,
                        })
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

            vim.keymap.set("n", "cx", exchange.operator)
            vim.keymap.set("n", "cxx", exchange.line)
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
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            "petertriho/cmp-git",
            "zbirenbaum/copilot-cmp",
        },
        config = function(_)
            -- Set up nvim-cmp.
            local cmp = require('cmp')
            require("copilot_cmp").setup()

            local defaultSources = cmp.config.sources(
            {
                { name = 'copilot' },
                {
                    name = "nvim_lsp",

                    -- Disable snippets
                    entry_filter = function(entry)
                        local snippetKind = cmp.lsp.CompletionItemKind.Snippet
                        local entryKind = entry:get_kind()
                        return entryKind ~= snippetKind
                    end,
                },
                { name = 'buffer' },
            })

            local globalCompletionTarget
            local function tryResetCompletionTarget(completionTarget)
                if not cmp.visible() then
                    globalCompletionTarget = completionTarget
                    return true
                end

                if globalCompletionTarget == completionTarget then
                    return false
                end
                globalCompletionTarget = completionTarget
                return true
            end


            local defaultMapping =
            {
                ['<C-Space>'] = function(_)
                    local isRegular = tryResetCompletionTarget('regular')
                    cmp.abort()
                    if not isRegular then
                        return
                    end
                    cmp.complete()
                end,
                ['<C-j>'] = cmp.mapping.select_next_item(),
                ['<C-k>'] = cmp.mapping.select_prev_item(),
                [helper.tab()] = function(fallback)
                    if not cmp.visible() then
                        fallback()
                        return
                    end

                    cmp.confirm({ select = true })
                    cmp.close()
                end,
                ["<CR>"] = function(fallback)
                    if not cmp.visible() then
                        fallback()
                        return
                    end

                    if cmp.get_active_entry() == nil then
                        fallback()
                        return
                    end

                    cmp.confirm({ select = true })
                    cmp.close()
                end,
            }

            local defaultSorting =
            {
                priority_weight = 2,
                comparators =
                {
                    require("copilot_cmp.comparators").prioritize,

                    -- Below is the default comparitor list and order for nvim-cmp
                    cmp.config.compare.offset,
                    -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    cmp.config.compare.recently_used,
                    cmp.config.compare.locality,
                    cmp.config.compare.kind,
                    cmp.config.compare.sort_text,
                    cmp.config.compare.length,
                    cmp.config.compare.order,
                },
            }

            ---@diagnostic disable-next-line: missing-parameter
            cmp.setup(
            {
                snippet =
                {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                window =
                {
                    documentation =
                    {
                        max_width = 1000,
                    },
                },
                preselect_mode = cmp.PreselectMode.None,
                autocomplete = true,
                mapping = vim.tbl_deep_extend(
                    'error',
                    defaultMapping,
                    {
                        ["<C-\\>"] = function(_)
                            local isCopilot = tryResetCompletionTarget('copilot')
                            cmp.abort()
                            if not isCopilot then
                                return
                            end
                            cmp.complete(
                            {
                                config =
                                {
                                    sources =
                                    {
                                        {
                                            name = 'copilot',
                                        },
                                    },
                                },
                            })
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
                sources = defaultSources,
                sorting = defaultSorting,
                experimental =
                {
                    ghost_test = true,
                },
            })

            ---@diagnostic disable-next-line: undefined-field
            cmp.setup.filetype('gitcommit',
            {
                sources = cmp.config.sources(
                {
                    { name = 'git' },
                    { name = 'copilot' },
                },
                {
                    { name = 'buffer' },
                })
            })

            -- Required hack to fix the issue
            -- https://github.com/hrsh7th/nvim-cmp/issues/1814
            local escKey = vim.api.nvim_replace_termcodes('<C-c>', true, false, true)

            local defaultMappingsC = vim.tbl_deep_extend(
                "error",
                defaultMapping,
                {
                    ['<Esc>'] = function()
                        local function sendEsc()
                            vim.api.nvim_feedkeys(escKey, 'n', false)
                        end

                        if not cmp.visible() then
                            sendEsc()
                            return
                        end

                        cmp.abort()

                        -- Only exit to normal mode if nothing was selected prior
                        if cmp.get_active_entry() == nil then
                            sendEsc()
                        end
                    end,
                })
            local cmdlineMappings = helper.cmpNormalizeMappings(defaultMappingsC, 'c')

            ---@diagnostic disable-next-line: undefined-field
            cmp.setup.cmdline({ '/', '?' },
            {
                mapping = cmdlineMappings,
                sources =
                {
                    { name = 'buffer' },
                },
            })

            ---@diagnostic disable-next-line: undefined-field
            cmp.setup.cmdline(':',
            {
                mapping = cmdlineMappings,
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
        init = function(_)
            vim.keymap.set('n', '<leader>a', 'vae', { remap = true })
        end,
    },
    {
        'wellle/targets.vim',
    },
    {
        "booperlv/nvim-gomove",
        opts =
        {
            map_defaults = false,
            reindent = true,
            undojoin = true,
            move_past_end_col = true,
        },
        init = function(_)
            for _, mode in ipairs({ 'n', 'v' }) do
                local modeCapital = string.upper(mode)
                helper.altMacBinding(
                {
                    mode = mode,
                    key = 'k',
                    action = '<Plug>Go' .. modeCapital .. 'SMUp',
                })
                helper.altMacBinding(
                {
                    mode = mode,
                    key = 'j',
                    action = '<Plug>Go' .. modeCapital .. 'SMDown',
                })
            end
        end,
    },
}

vim.g.bufferize_focus_output = true
table.insert(plugins,
{
    'AndrewRadev/bufferize.vim',
    init = function()
        vim.keymap.set('n', 'wm', function()
            vim.cmd("Bufferize messages")
        end)
    end,
})

-- This thing is just not going to work.
-- It works only for builtin commands, not for regular mappings.
---@diagnostic disable-next-line: unused-function, unused-local
local function registerLangmaps()
    local langmaps =
    {
        { "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯЖХЪЭЮ", 'ABCDEFGHIJKLMNOPQRSTUVWXYZ:{}">' },
        { "фисвуапршолдьтщзйкыегмцчняжхъэю", "abcdefghijklmnopqrstuvwxyz;[]'." },
        { "ĂÎÂȘȚ", ";{}|:" },
        { "ăîâșț", ",[];'" },
    };

    local temp = {}
    for _, langmap in pairs(langmaps) do
        if #langmap ~= 2 then
            error("The langmap arrays must have 2 elements.")
        end

        local patternToEscape = '[,;"|]'

        local a = langmap[1]
        do
            -- I'm guessing this is a list?
            -- The documentation doesn't specify this.
            local _, _, characterFound = string.find(a, patternToEscape)
            if characterFound ~= nil then
                error("Disallowed character " .. characterFound .. " in from mapping.")
            end
        end

        local b = langmap[2]
        local escapedB = string.gsub(b, patternToEscape, [[\%0]])
        local joinedLangmap = a .. ';' .. escapedB
        table.insert(temp, joinedLangmap)
    end

    local completeLangmap = table.concat(temp, ",")
    vim.o.langmap = completeLangmap
    -- vim.o.langremap = false
end

table.insert(plugins,
{
    'uga-rosa/utf8.nvim',
    config = function(_)
        -- registerLangmaps()
    end
})

table.insert(plugins,
{
    "loctvl842/monokai-pro.nvim",
    dependencies =
    {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function(_)
        require("monokai-pro").setup(
        {
        })
        vim.cmd("colorscheme monokai-pro")
    end
})

-- vim.g.copilot_enabled = false
table.insert(plugins,
{
    "zbirenbaum/copilot.lua",
    -- cmd = "Copilot",
    -- event = "InsertEnter",
    config = function()
        require("copilot").setup(
        {
            panel =
            {
                enabled = false,
            },
            suggestion =
            {
                enabled = false,
            },
        })
    end,
})

table.insert(plugins,
{
    "zbirenbaum/copilot-cmp",
    dependencies =
    {
        "zbirenbaum/copilot.lua",
    },
    config = function()
        -- set up in the cmp setup
    end,
})

table.insert(plugins,
{
    "nvim-pack/nvim-spectre",
    dependencies =
    {
        "nvim-lua/plenary.nvim"
    },
    init = function()
        local spectre = require("spectre")
        vim.keymap.set('n', 'wr', function()
            spectre.toggle()
        end)
        vim.keymap.set('v', 'wr', function()
            spectre.open_visual()
        end)
        vim.keymap.set('n', '<leader>sr', function()
            spectre.open_file_search()
        end)
    end
})

table.insert(plugins,
{
    "yamatsum/nvim-nonicons",
    dependencies =
    {
        "kyazdani42/nvim-web-devicons",
    },
})

table.insert(plugins,
{
    "jonahgoldwastaken/copilot-status.nvim",
    dependencies =
    {
        "zbirenbaum/copilot.lua",
        "yamatsum/nvim-nonicons",
    },
})

table.insert(plugins,
{
    "nvim-lualine/lualine.nvim",
    dependencies =
    {
        "jonahgoldwastaken/copilot-status.nvim",
        "arkav/lualine-lsp-progress",
    },
    config = function()
        local copilotStatus = require("copilot_status")

        require('lualine').setup({
            options =
            {
                component_separators = {'', ''},
            },
            sections =
            {
                lualine_a =
                {
                    'mode'
                },
                lualine_b =
                {
                    'branch',
                },
                lualine_c =
                {
                    'lsp_progress'
                },
                lualine_x =
                {
                    'filename',
                    'encoding',
                    function()
                        return copilotStatus.status_string()
                    end,
                },
            },
        })
    end,
})

table.insert(plugins,
{
    "tpope/vim-fugitive",
    init = function(_)
        vim.keymap.set({ 'n', 'v' }, '<leader>go', ':GBrowse<CR>')
        vim.keymap.set('n', '<leader>gbl', ':Git blame<CR>')
        vim.keymap.set('n', '<leader>gd', ':Gvdiffsplit<CR>')
    end
})

for _, name in ipairs({
    "cedarbaum/fugitive-azure-devops.vim",
    "tpope/vim-rhubarb",
}) do

    table.insert(plugins,
    {
        name,
        dependencies =
        {
            "tpope/vim-fugitive",
        },
    })
end

table.insert(plugins,
{
    "mbbill/undotree",
    init = function()
        vim.keymap.set("n", "<leader>h", ":UndotreeToggle<CR>")


    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        vim.cmd.highlight("MatchParen guibg=#555599 guisp=Blue")
    end
})

-- Buggy with <C-w><C-o>
table.insert(plugins,
{
    "nvim-treesitter/nvim-treesitter-context",
    dependencies =
    {
        "nvim-treesitter/nvim-treesitter",
    },
    init = function()
        local context = require("treesitter-context");
        vim.keymap.set("n", "[c", function()
            context.go_to_context(vim.v.count1)
        end, { silent = true })
    end,
})

require("lazy").setup(plugins);
