require("core.editor")
require("core.mappings")
require("core.terminal")
local helper = require("core.helper")

do
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    ---@diagnostic disable-next-line: undefined-field
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
    ---@diagnostic disable-next-line: undefined-field
    vim.opt.rtp:prepend(lazypath)
end

local plugins =
{
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies =
        {
            -- "andymass/vim-matchup",
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
                -- indent = { enable = true },

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
                -- matchup =
                -- {
                --     enable = true,
                -- },
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
                            ["<C-BS>"] = deleteWordBack,
                            ["<C-h>"] = deleteWordBack,
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
                extensions =
                {
                },
            })

            require("telescope").load_extension('cmdline')

            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>so", function()
                vim.cmd.Telescope()
            end, {})
            vim.keymap.set("n", "<leader>sp", builtin.find_files, {})
            vim.keymap.set("n", "<leader>sf", function()
                builtin.live_grep({
                    grep_open_files = false
                })
            end, {})
            -- TODO: search and replace
            vim.keymap.set("n", "<leader><leader>", builtin.lsp_workspace_symbols, {})
            vim.keymap.set("n", "<leader>ss", builtin.lsp_workspace_symbols, {})
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, {})
            vim.keymap.set("n", "<leader>hm", builtin.command_history, {})
            vim.keymap.set("n", "<leader>hf", builtin.search_history, {})
            vim.keymap.set("n", "<leader>sj", builtin.jumplist, {})
            vim.keymap.set("n", "<leader>sk", builtin.keymaps, {})
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
                    vim.keymap.set('n', binding, action,
                    {
                        buffer = bufnr,
                        desc = desc,
                    })
                end

                -- Need to work around, because explorer.exe can only open 1 directory deep.
                local function getParentPathAndFileName()
                    local lib = require("nvim-tree.lib")
                    local node = lib.get_node_at_cursor()
                    if node == nil then
                        return nil
                    end
                    local absolutePath = node.absolute_path
                    local plenary = require("plenary.path")
                    local path = plenary:new(absolutePath);
                    if path:is_dir() then
                        return vim.fn.shellescape(absolutePath), nil
                    else
                        local directoryPath = path:parent():absolute()
                        -- There's no function for getting the last segment, so working around, again.
                        local name = path:make_relative(directoryPath)
                        return vim.fn.shellescape(directoryPath), vim.fn.shellescape(name)
                    end
                end

                -- action is either "select" or "start"
                local function doExplorer(action)
                    local directoryPath, fileName = getParentPathAndFileName()
                    if fileName == nil then
                        vim.cmd("silent !cd " .. directoryPath .. "; explorer.exe .")
                    else
                        vim.cmd("silent !cd " .. directoryPath .. "; explorer.exe /" .. action .. "," .. fileName)
                    end
                end

                set('<Esc>', api.tree.close, "Close")
                set('q', api.tree.close, "Close")
                set('d', api.tree.change_root_to_node, "Change directory")
                set('<CR>', api.node.open.edit, "Edit")
                set('l', api.node.open.edit, "Open or Edit")
                set('h', api.node.navigate.parent_close, "Fold parent")
                set('<C-i>', api.node.show_info_popup, "Show info")
                set('<F2>', api.fs.rename_basename, "Rename")
                -- set('r', api.fs.rename, "Rename (all)")
                set('<2-LeftMouse>', api.node.open.edit, "Edit")
                set('o', function()
                    doExplorer("select")
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
                set('r', api.fs.copy.relative_path, "Copy relative path")
                set('P', api.fs.copy.absolute_path, "Copy absolute path")
                set('a', api.fs.create, "Create file or directory (append / at end for a directory)")
                -- set('R', api.node.run.system, "Run (system)")
                set('R', function()
                    doExplorer("start")
                end, "Run (system)")
                set('Y', api.fs.copy.filename, "Copy filename")
                set('<C-g>', api.tree.toggle_help, "Help")
                set('e', api.tree.close, "Close")
                set('W', function()
                    local core = require("nvim-tree.core")
                    local explorer = core.get_explorer()
                    if (explorer == nil) then
                        return
                    end
                    local newCwd = explorer.absolute_path
                    local command = string.format(":cd %s", newCwd)
                    vim.cmd(command)
                end, "Change the current working directory to this")

                -- Doesn't work
                local timeoutLenOption = vim.o.timeoutlen
                ---@diagnostic disable-next-line: inject-field
                vim.o.timeoutlen = 1
                vim.api.nvim_create_autocmd("BufEnter",
                {
                    buffer = bufnr,
                    callback = function()
                        ---@diagnostic disable-next-line: inject-field
                        vim.o.timeoutlen = 1
                    end,
                })
                vim.api.nvim_create_autocmd("BufLeave",
                {
                    buffer = bufnr,
                    callback = function()
                        ---@diagnostic disable-next-line: inject-field
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
                        window_picker =
                        {
                            enable = false,
                        },
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
                -- select_prompts = true,
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
            ---@diagnostic disable-next-line: inject-field
            vim.o.foldlevel = 99
            ---@diagnostic disable-next-line: inject-field
            vim.o.foldlevelstart = 99

            local ufo = require('ufo');
            ---@diagnostic disable-next-line: missing-fields
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
            trouble.setup(
            {
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
                    previous = "k",
                    next = "j",
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
                trouble.toggle("workspace_diagnostics")
            end)
            vim.keymap.set("n", "gu", function()
                trouble.toggle("lsp_references")
            end)

            -- vim.keymap.set("n", "ge", function()
            --     trouble.next({ skip_groups = true, jump = true })
            -- end)
            -- vim.keymap.set("n", "gE", function()
            --     trouble.previous({ skip_groups = true, jump = true })
            -- end)
        end
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
            "folke/neodev.nvim",
        },
        config = function(_)
            local lspconfig = require('lspconfig')

            require("neodev").setup({
                -- add any options here, or leave empty to use the default settings
            })

            lspconfig.lua_ls.setup(
            {
            })

            -- https://github.com/LuaLS/lua-language-server/issues/1596#issuecomment-1855087288
            lspconfig.util.on_setup = lspconfig.util.add_hook_after(lspconfig.util.on_setup, function(config)
                if config.name == 'lua_ls' then
                    -- workaround for nvim's incorrect handling of scopes in the workspace/configuration handler
                    -- https://github.com/folke/neodev.nvim/issues/41
                    -- https://github.com/LuaLS/lua-language-server/issues/1089
                    -- https://github.com/LuaLS/lua-language-server/issues/1596
                    config.handlers = vim.tbl_extend('error', {}, config.handlers)
                    config.handlers['workspace/configuration'] = function(...)
                        local _, result, ctx = ...
                        local client_id = ctx.client_id
                        local client = vim.lsp.get_client_by_id(client_id)
                        if client and client.workspace_folders and #client.workspace_folders then
                            if result.items and #result.items > 0 then
                                if not result.items[1].scopeUri then
                                    return vim.tbl_map(function(_) return nil end, result.items)
                                end
                            end
                        end

                        return vim.lsp.handlers['workspace/configuration'](...)
                    end
                end
            end)

            lspconfig.zls.setup(
            {
                on_init = function(_)
                    vim.g.zig_fmt_autosave = false
                end,
            })

            lspconfig.clangd.setup(
            {
                on_init = function(_)
                    do
                        -- https://clang.llvm.org/docs/ClangFormatStyleOptions.html
                        local filePath = vim.fn.expand("~/.clang-format")
                        if not vim.loop.fs_stat(filePath) then
                            vim.fn.writefile(
                                {
                                    "BasedOnStyle: Microsoft",
                                    "IndentWidth: 4",
                                    "SortIncludes: SI_Never",
                                },
                                filePath)
                        end
                    end

                    do
                        -- https://clangd.llvm.org/config#files
                        local filePath
                        if vim.fn.has("win32") == 1 then
                            filePath = vim.fn.expand("$LocalAppData") .. "\\clangd\\config.yaml"
                        else if vim.fn.has("mac") == 1 then
                            filePath = vim.fn.expand("~/Library/Preferences/clangd/config.yaml")
                        else
                            filePath = vim.fn.expand("$XDG_CONFIG_HOME") .. "/clangd/config.yaml"
                        end

                        local dirPath = vim.fn.fnamemodify(filePath, ":h")
                        if not vim.loop.fs_stat(dirPath) then
                            vim.fn.mkdir(dirPath, "p")
                        end

                        if not vim.loop.fs_stat(filePath) then
                            vim.fn.writefile(
                                {
                                    [[CompileFlags:]],
                                    [[If:]],
                                    [[Path-Match: ".*\.cpp"]],
                                    [[Add: [ "-std=c++20", "-Wall" ] ]],
                                },
                                filePath)
                            end
                        end
                    end
                end,
                capabilities =
                {
                    offsetEncoding = "utf-8",
                },
            })

            lspconfig.tsserver.setup({})

            vim.api.nvim_create_autocmd('LspAttach',
            {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    ---@diagnostic disable-next-line: inject-field
                    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                    local opts = { buffer = ev.buf }

                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                    vim.keymap.set("n", "U", vim.lsp.buf.hover, opts)
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

            vim.keymap.set("n", "ge", function()
                vim.diagnostic.goto_next()
            end);
            vim.keymap.set("n", "gE", function()
                vim.diagnostic.goto_prev()
            end);
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
            local cmp = require('cmp')
            require("copilot_cmp").setup()

            local defaultSources = cmp.config.sources(
            {
                -- { name = 'copilot' },
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

            local defaultMapping =
            {
                ['<C-Space>'] = function(_)
                    if cmp.visible() then
                        cmp.abort()
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

                    cmp.config.compare.offset,
                    -- cmp.config.compare.scopes,
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
                enabled = function()
                    local bufType = vim.api.nvim_buf_get_option(0, "buftype")
                    if (bufType ~= "prompt") then
                        return true
                    end
                    local cmpDap = require("cmp_dap")
                    if cmpDap.is_dap_buffer() then
                        return true
                    end
                    return false
                end,
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
                            if cmp.visible() then
                                cmp.abort()
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
                    ghost_text = true,
                },
                matching =
                {
                    disallow_fuzzy_matching = false,
                    disallow_partial_fuzzy_matching = false,
                    disallow_fullfuzzy_matching = false,
                    disallow_partial_matching = false,
                    disallow_prefix_unmatching = false,
                },
            })

            ---@diagnostic disable-next-line: undefined-field
            cmp.setup.filetype('gitcommit',
            {
                sources = cmp.config.sources(
                {
                    { name = 'git' },
                    { name = 'copilot' },
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

            ---@diagnostic disable-next-line: undefined-field
            cmp.setup.filetype(
            {
                'dap-repl',
                'dapui-watches',
                'dapui-hover',
            },
            {
                sources =
                {
                    { name = 'dap' },
                },
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
    ---@diagnostic disable-next-line: inject-field
    vim.o.langmap = completeLangmap
    -- vim.o.langremap = false
end

registerLangmaps()

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

local function doNothing()
    -- it's set up in the cmp setup
end

table.insert(plugins,
{
    "zbirenbaum/copilot-cmp",
    dependencies =
    {
        "zbirenbaum/copilot.lua",
    },
    config = doNothing,
})

table.insert(plugins,
{
    "rcarriga/cmp-dap",
    dependencies =
    {
        "mfussenegger/nvim-dap",
    },
    config = doNothing,
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
                section_separators = { left = '', right = ''},
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
                    'filetype',
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
    end,
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
    enabled = false,
    init = function()
        vim.keymap.set("n", "<leader>hd", ":UndotreeToggle<CR>")
    end,
})

vim.api.nvim_create_autocmd("ColorScheme",
{
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

table.insert(plugins,
{
    "danielfalk/smart-open.nvim",
    enabled = false,
    branch = "0.2.x",
    dependencies =
    {
        "kkharji/sqlite.lua",
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        if vim.fn.has("win32") then
            -- The slashes must be /
            vim.g.sqlite_clib_path = "D:/bin/sqlite3.dll"
        end

        local telescope = require("telescope")
        telescope.load_extension("smart_open")
    end,
    init = function()
        local telescope = require("telescope")
        vim.keymap.set({ "n", "c", "i" }, "<C-e>", function()
            telescope.extensions.smart_open.smart_open()
        end)
    end,
});

table.insert(plugins,
{
    "AntonC9018/telescope-recent-files",
    -- dev = true,
    branch = "return-picker",
    dependencies =
    {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("telescope").load_extension("recent_files")
    end,
    init = function()
        -- local recent_files = require('recent_files')
        vim.keymap.set({ "n", "i", "c" }, "<C-e>", function()
            ---@diagnostic disable-next-line: unused-local
            local picker = require("telescope").extensions.recent_files.pick()
        end)
    end,
})

table.insert(plugins,
{
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")

        -- REQUIRED
        ---@diagnostic disable-next-line: missing-parameter
        harpoon:setup()
        -- REQUIRED

        vim.keymap.set("n", "<M-a>", function() harpoon:list():append() end)
        vim.keymap.set("n", "<M-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        for i = 1, 6 do
            local str = tostring(i)
            helper.altMacBinding({
                key = str,
                action = function()
                    harpoon:list():select(i)
                end,
                mode = "n",
            })
        end

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "<M-p>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<M-S-p>", function() harpoon:list():next() end)
    end,
});

table.insert(plugins,
{
    "rcarriga/nvim-dap-ui",
    dependencies =
    {
        "mfussenegger/nvim-dap",
    },
})

require("lazy").setup(plugins);
