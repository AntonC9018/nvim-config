require("core.editor")
require("core.mappings")
require("core.terminal")
local helper = require("core.helper")

-- Default commands conflict with other stuff
do
    local lsp_defaults = { "gri", "grr", "gre", "gra", "grt", "grT", "grf", "grF" }
    for _, key in ipairs(lsp_defaults) do
        pcall(vim.keymap.del, "n", key)
    end
end

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
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        dependencies =
        {
            "nvim-telescope/telescope-fzf-native.nvim",
        },
        config = function()
            local parsers = {
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
                "typescript",
                "html",
                "go",
                "latex",
                "markdown",
                "markdown_inline",
                "templ",
                "vim",
                "vimdoc",
                "bash",
            }
            require('nvim-treesitter').setup()
            require('nvim-treesitter').install(parsers)

            vim.api.nvim_create_autocmd('FileType',
            {
                pattern = parsers,
                callback = function()
                    local buf = vim.api.nvim_get_current_buf()
                    local max_filesize = 100 * 1024 -- 100 KB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))

                    if ok and stats and stats.size <= max_filesize then
                        local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
                        if lang and pcall(vim.treesitter.language.inspect, lang) then
                            vim.treesitter.start()
                        end
                    end
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "javascript", "typescript", "typescriptreact", "javascriptreact" },
                callback = function(args)
                    if vim.treesitter.highlighter.active[args.buf] ~= nil then
                        vim.keymap.set("n", "=", vim.lsp.buf.format, { buffer = args.buf })
                    end
                end,
            })

            vim.api.nvim_create_autocmd("BufEnter",
            {
                pattern = "*.templ",
                callback = function()
                    vim.cmd("TSBufEnable highlight")
                end
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        -- Completely breaks some things
        enabled = false,
        config = function()
            local configs = require('nvim-treesitter.configs')
            local select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    -- ["af"] = "@function.outer",
                    -- ["if"] = "@function.inner",
                    -- ["at"] = "@class.outer",
                    -- ["it"] = "@class.inner",
                    -- ii to select the condition of an in (the condition node inside an if_statement node).
                    ["ii"] = "@conditional.inner",
                    ["ai"] = "@conditional.outer",
                },
            }
            configs.setup({
                textobjects =
                {
                    select = select,
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
        branch = "master",
        dependencies =
        {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
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

            local telescope = require("telescope")
            ---@diagnostic disable-next-line: missing-parameter
            telescope.setup({
                defaults =
                {
                    mappings = (function()
                        insert = {}
                        normal = {}

                        -- Remove defaults
                        insert["<C-x>"] = false
                        insert["<C-v>"] = false
                        insert["<C-t>"] = false
                        insert["<C-f>"] = false
                        insert["<PageUp>"] = false
                        insert["<PageDown>"] = false
                        insert["<M-f>"] = false
                        insert["<C-q>"] = false
                        insert["<M-q>"] = false
                        insert["<C-r><C-w>"] = false
                        insert["<C-u>"] = false
                        insert["<C-d>"] = false
                        insert[helper.controlSlash()] = false
                        normal["<C-x>"] = false
                        normal["<C-v>"] = false
                        normal["<C-t>"] = false
                        normal["<C-q>"] = false
                        normal["<M-q>"] = false
                        normal["H"] = false
                        normal["L"] = false
                        normal["<C-u>"] = false
                        normal["<C-d>"] = false
                        normal["<C-k>"] = false
                        normal["<C-j>"] = false
                        normal["<C-f>"] = false
                        normal["<PageUp>"] = false
                        normal["<PageDown>"] = false
                        normal["<M-f>"] = false
                        normal["<M-k>"] = false

                        local function setBothInsertAndNormal(key, action)
                            insert[key] = action
                            normal[key] = action
                        end
                        local function setall(obj, keys, action)
                            for _, key in ipairs(keys) do
                                obj[key] = action
                            end
                        end
                        local function setAllInsert(keys, action)
                            setall(insert, keys, action)
                        end
                        local function setAllNormal(keys, action)
                            setall(normal, keys, action)
                        end

                        insert["<C-Y>"] = copyAllEntries
                        insert["<C-y>"] = copySelectedEntry

                        setBothInsertAndNormal(helpKey, actions.which_key)
                        setBothInsertAndNormal("<C-i>", function(prompt_bufnr)
                            -- CHAT GPT CODE!!
                            -- Probably doesn't work properly
                            local action_state = require("telescope.actions.state")
                            local builtin = require("telescope.builtin")
                            local picker = action_state.get_current_picker(prompt_bufnr)

                            -- 1. Get the prompt and the original options
                            local current_input = action_state.get_current_line()
                            local title = picker.prompt_title

                            -- This table contains the options the picker was started with
                            -- We make a shallow copy so we don't modify the original state accidentally
                            local opts = vim.tbl_extend("force", {}, picker.original_opts or {})

                            -- 2. Define our toggle state
                            local is_hidden = title:find("Hidden") ~= nil
                            local is_file_search = title:find("Find Files") ~= nil
                            local is_text_search = title:find("Live Grep") ~= nil

                            -- 3. Update the options for the new search
                            opts.default_text = current_input

                            if is_file_search then
                                opts.hidden = not is_hidden
                                opts.prompt_title = not is_hidden and "Find Files (Hidden)" or "Find Files"

                                require("telescope.actions").close(prompt_bufnr)
                                builtin.find_files(opts)

                            elseif is_text_search then
                                opts.prompt_title = not is_hidden and "Live Grep (Hidden)" or "Live Grep"

                                -- Handle ripgrep arguments for hidden files
                                local args = opts.additional_args
                                if type(args) == "function" then args = args() end
                                args = args or {}

                                if not is_hidden then
                                    table.insert(args, "--hidden")
                                else
                                    -- Remove --hidden if it exists
                                    for i, v in ipairs(args) do
                                        if v == "--hidden" then table.remove(args, i) end
                                    end
                                end

                                opts.additional_args = function() return args end

                                require("telescope.actions").close(prompt_bufnr)
                                builtin.live_grep(opts)

                            else
                                vim.notify("Hidden toggle not supported for: " .. title, vim.log.levels.WARN)
                            end
                        end)

                        setAllInsert({ "<C-w>", "<C-BS>", "<C-h>" }, deleteWordBack)
                        setAllInsert({ "<C-j>", "<C-DOWN>" }, actions.move_selection_next)
                        setAllInsert({ "<C-j>", "<DOWN>" }, actions.move_selection_next)
                        setAllInsert({ "<C-k>", "<UP>" }, actions.move_selection_previous)
                        setAllNormal({ "j", "<DOWN>" }, actions.move_selection_next)
                        setAllNormal({ "k", "<UP>" }, actions.move_selection_previous)
                        insert["<C-c>"] = actions.close
                        insert["<CR>"] = actions.select_default

                        local actions = require('telescope.actions')
                        setBothInsertAndNormal("<M-j>", actions.cycle_history_next)
                        setBothInsertAndNormal("<M-k>", actions.cycle_history_prev)

                        normal["<C-Y>"] = copyAllEntries
                        normal["<C-y>"] = copySelectedEntry
                        normal["<esc>"] = actions.close
                        normal["<CR>"] = actions.select_default
                        normal["M"] = actions.move_to_middle
                        normal["gg"] = actions.move_to_top
                        normal["G"] = actions.move_to_bottom
                        return {
                            i = insert,
                            n = normal,
                        }
                    end)(),
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
                    history =
                    {
                        path = vim.fn.stdpath('data') .. '/telescope_history',
                        limit = 1000,
                    },
                },
                extensions =
                {
                    fzf =
                    {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                    },
                },
            })

            telescope.load_extension('cmdline')
            telescope.load_extension('fzf')

            local builtin = require("telescope.builtin")
            local utils = require("telescope.utils")

            local function searchMaybeSelection(picker, opts)
                local mode = vim.fn.mode()
                if mode ~= 'v' and mode ~= 'V' then
                    picker(opts)
                    return
                end

                helper.cancelSelectionAndExecuteWithSelection(
                {
                    func = function(lines)
                        local text = table.concat(lines, '\n')
                        opts.default_text = text
                        picker(opts)
                    end
                })
            end


            -- vim.keymap.set("n", "wF", function()
            --     vim.cmd.Telescope()
            -- end, {
            --     desc = "Open the window of windows",
            -- })
            vim.keymap.set({ "n", "v" }, "wp", function()
                searchMaybeSelection(builtin.find_files, {
                    hidden = true,
                    no_ignore = true,
                    no_ignore_parent = true,
                })
            end, {
                desc = "Find files by name",
            })

            vim.keymap.set({ "n", "v" }, "wF", function()
                searchMaybeSelection(builtin.live_grep, {
                    grep_open_files = false,
                    cwd = utils.buffer_dir(),
                })
            end, {
                desc = "Search in directory of the current buffer",
            })

            vim.keymap.set({ "n", "v" }, "wf", function()
                searchMaybeSelection(builtin.live_grep, {
                    grep_open_files = false,
                })
            end, {
                desc = "Search files",
            })

            vim.keymap.set({ "n" }, "w*", function()
                local cword = vim.fn.expand("<cword>")
                builtin.live_grep({
                    grep_open_files = false,
                    default_text = cword,
                })
            end, {
                desc = "Search under cursor",
            })

            do
                local t = { desc = "Show workspace symbols" }
                vim.keymap.set("n", "<leader><leader>", builtin.lsp_dynamic_workspace_symbols, t)
                vim.keymap.set("n", "ws", builtin.lsp_dynamic_workspace_symbols, t)
            end

            vim.keymap.set("n", "wh", builtin.help_tags, {
                desc = "Search help",
            })
            vim.keymap.set("n", "<leader>hm", builtin.command_history, {})
            vim.keymap.set("n", "<leader>hf", builtin.search_history, {})
            vim.keymap.set("n", "wj", builtin.jumplist, {
                desc = "Search jumplist",
            })
            vim.keymap.set("n", "wk", builtin.keymaps, {
                desc = "Search keymaps",
            })
            vim.keymap.set("n", "gu", builtin.lsp_references, {})
            vim.keymap.set("n", "gi", builtin.lsp_implementations, {})
            vim.keymap.set("n", "gt", builtin.lsp_type_definitions, {})
            vim.keymap.set('n', 'gd', builtin.lsp_definitions, {})
            vim.keymap.set("n", "gs", builtin.lsp_document_symbols, {})
            vim.keymap.set("n", "wy", function()
                vim.cmd("Telescope resume")
            end, {
                desc = "Restore the previous telescope search",
            })
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        tag = "v1.17.0",
        config = function(_)
            local api = require("nvim-tree.api")

            vim.keymap.set("n", "wl", function()
                local logPath = vim.fn.stdpath("log")
                vim.cmd("NvimTreeOpen " .. logPath)
            end, {
                desc = "Open the logs folder",
            })

            local function onAttach(bufnr)
                local function set(binding, action, desc)
                    vim.keymap.set('n', binding, action, {
                        buffer = bufnr,
                        desc = desc,
                    })
                end

                local function doExplorer(action)
                    local node = api.tree.get_node_under_cursor()
                    if node == nil then return end

                    local Path = require("plenary.path")
                    local path = Path:new(node.absolute_path)

                    local dir, args
                    if path:is_dir() then
                        dir = node.absolute_path
                        args = { "explorer.exe", "." }
                    else
                        local parentDir = path:parent():absolute()
                        local name = path:make_relative(parentDir)
                        dir = parentDir
                        args = { "explorer.exe", "/" .. action .. "," .. name }
                    end

                    vim.fn.jobstart(args, { cwd = dir, detach = true })
                end

                set('<Esc>', api.tree.close, "Close")
                set('q', api.tree.close, "Close")
                set('d', api.tree.change_root_to_node, "Change directory")
                set('<CR>', api.node.open.edit, "Edit")
                set('l', api.node.open.edit, "Open or Edit")
                set('h', api.node.navigate.parent_close, "Fold parent")
                set('<C-i>', api.node.show_info_popup, "Show info")
                set('<F2>', api.fs.rename_basename, "Rename")
                set('s', api.fs.rename, "Rename (including extension)")
                set('<2-LeftMouse>', api.node.open.edit, "Edit")
                set('o', function() doExplorer("select") end, "Open in Explorer")
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
                set('R', function() doExplorer("start") end, "Run (system)")
                set('Y', api.fs.copy.filename, "Copy filename")
                set('<C-g>', api.tree.toggle_help, "Help")
                set('e', api.tree.close, "Close")
                set('W', function()
                    local node = api.tree.get_nodes()
                    if node == nil then return end
                    local newCwd = node.absolute_path
                    vim.cmd(string.format(":cd %s", newCwd))
                    print("Changed CWD to " .. newCwd)
                end, "Change the current working directory to this")

                local timeoutLenOption = vim.o.timeoutlen
                vim.o.timeoutlen = 1
                vim.api.nvim_create_autocmd("BufEnter", {
                    buffer = bufnr,
                    callback = function()
                        vim.o.timeoutlen = 1
                    end,
                })
                vim.api.nvim_create_autocmd("BufLeave", {
                    buffer = bufnr,
                    callback = function()
                        vim.o.timeoutlen = timeoutLenOption
                    end,
                })
            end

            require("nvim-tree").setup({
                actions = {
                    open_file = {
                        quit_on_open = true,
                        window_picker = {
                            enable = false,
                        },
                    },
                },
                on_attach = onAttach,
                filters = {
                    dotfiles = true,
                },
                renderer = {
                    add_trailing = true,
                    indent_width = 4,
                    highlight_diagnostics = "name",
                    highlight_clipboard = "name",
                    highlight_bookmarks = "name",
                    icons = {
                        glyphs = {
                            git = {
                                unstaged = "×",
                                staged = "✓",
                                unmerged = "",
                                renamed = "R",
                                untracked = "N",
                                deleted = "D",
                                ignored = "◌",
                            },
                        },
                    },
                },
                git = {
                    cygwin_support = true,
                },
                diagnostics = {
                    enable = false,
                },
                hijack_cursor = true,
                ui = {
                    confirm = {
                        default_yes = true,
                    },
                },
                view = {
                    relativenumber = true,
                    width = "100%",
                },
            })

            local tree = require('nvim-tree.api').tree

            vim.keymap.set('n', 'we', function()
                if tree.is_tree_buf(0) then
                    tree.close()
                else
                    tree.open()
                end
            end, {
                desc = "Open file explorer",
            })

            vim.keymap.set('n', 'wE', function()
                tree.open({
                    find_file = true,
                    update_root = true,
                })
            end, {
                desc = "Select current file in the file explorer",
            })
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
        'smoka7/hop.nvim',
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

            vim.keymap.set({ 'n', 'v' }, '<C-;>',
                function()
                    hop.hint_char2(hopOpts)
                end,
                opts)
        end,
    },
    {
        -- "ys" is the bind
        'kylechui/nvim-surround',
        config = function(_)
            vim.g.nvim_surround_no_insert_mappings = true

            require("nvim-surround").setup(
            {
            })
        end
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function(_)
            local trouble = require("trouble");
            require("trouble").setup(
                {
                    auto_close = false,
                    auto_preview = true,
                    auto_jump = false,
                    focus = false,
                    follow = true,
                    restore = true,
                    multiline = true,
                    indent_guides = true,
                    win =
                    {
                        position = "bottom",
                        border = "single",
                        padding = false,
                        wo =
                        {
                            winhighlight = "Normal:TroubleNormal,NormalNC:TroubleNormalNC",
                            winhl = "Normal:TroubleNormal",
                        },
                    },
                    preview =
                    {
                        type = "main",
                        scratch = true,
                    },
                    keys =
                    {
                        ["<esc>"]               = "cancel",
                        ["<C-r>"]               = "refresh",
                        ["<cr>"]                = "jump",
                        ["<2-leftmouse>"]       = "jump",
                        o                       = "jump_close",
                        gd                      = "jump_close",
                        P                       = "toggle_preview",
                        p                       = "preview",
                        L                       = "fold_toggle",
                        k                       = "prev",
                        j                       = "next",
                        [helper.controlSlash()] = "help",
                    },
                    modes =
                    {
                        diagnostics =
                        {
                            filter = { 
                                severity = { 
                                    vim.diagnostic.severity.WARN, 
                                    vim.diagnostic.severity.ERROR,
                                    vim.diagnostic.severity.HINT,
                                },
                            },
                            group = true,
                            cycle_results = false,
                            auto_jump = false,
                            win = { position = "bottom", border = "single" },
                        },
                    },
                })

            vim.keymap.set("n", "wd", function()
                trouble.toggle("diagnostics")
            end)
            vim.keymap.set("n", "gu", function()
                trouble.toggle("lsp_references")
            end)
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
            "williamboman/mason-lspconfig.nvim",
            "mrjones2014/codesettings.nvim",
            "hrsh7th/cmp-nvim-lsp",
            -- "folke/neodev.nvim",
        },
        config = function(_)
            local defaultCapabilities = vim.tbl_deep_extend(
                "force",
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities())

            local function filterList(list, shouldKeepFunc)
                for i = #list, 1, -1 do
                    local d = list[i]
                    if not shouldKeepFunc(d) then
                        table.remove(list, i)
                    end
                end
                return list
            end

            local function withFilteredDiagnostics(c)
                return function(err, result, context, config)
                    local function pass()
                        return vim.lsp.diagnostic.on_publish_diagnostics(err, result, context)
                    end

                    if result == nil then
                        return pass()
                    end

                    if c.shouldFilter ~= nil then
                        if not c.shouldFilter(result) then
                            return pass()
                        end
                    end

                    if c.keep ~= nil then
                        local diagnostics = result.diagnostics
                        result.diagnostics = filterList(diagnostics, c.keep)
                    end
                    return pass()
                end
            end

            local allConfigOptions = {}
            local allConfigNames = {}
            local function config(name, opts)
                opts = opts or {}
                opts.capabilities = vim.tbl_deep_extend(
                    "force",
                    {},
                    defaultCapabilities,
                    opts.capabilities or {})
                table.insert(allConfigOptions, opts)
                table.insert(allConfigNames, name)
            end

            config("pyright", {})

            config("gopls",
            {
                settings = (function()
                    local s = {}
                    s.semanticTokens = true
                    s.analyses = {
                        unusedparams = true,
                    }
                    s.staticcheck = true
                    s.hints = {
                        assignVariableTypes = true,
                        compositeLiteralFields = true,
                        compositeLiteralTypes = true,
                        constantValues = true,
                        functionTypeParameters = true,
                        parameterNames = true,
                        rangeVariableTypes = true,
                    }
                    return { gopls = s }
                end)(),
                on_attach = function(client)
                    local semantic = client.config.capabilities.textDocument.semanticTokens
                    client.server_capabilities.semanticTokensProvider =
                    {
                        full = true,
                        legend =
                        {
                            tokenModifiers = semantic.tokenModifiers,
                            tokenTypes = semantic.tokenTypes,
                        },
                        range = true,
                    }
                end,
                handlers =
                {
                    ["textDocument/publishDiagnostics"] = withFilteredDiagnostics(
                        {
                            shouldFilter = function(result)
                                if string.match(result.uri, "_templ%.go$") then
                                    return true
                                end
                                return false
                            end,
                            keep = function(d)
                                return d.severity == vim.diagnostic.severity.ERROR
                            end
                        }),
                },
            })

            config("lua_ls",
            {
            })

            config("zls",
            {
                on_init = function(_)
                    vim.g.zig_fmt_autosave = false
                end,
            })

            config("clangd",
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
                        if helper.isWindows() then
                            filePath = vim.fn.expand("$LocalAppData") .. "\\clangd\\config.yaml"
                        elseif vim.fn.has("mac") == 1 then
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
                                    [[Add: [ "-std=c++20", "-Wall", "-Wconversion", "-Werror" ] ]],
                                },
                                filePath)
                        end
                    end
                end,
                capabilities =
                {
                    offsetEncoding = "utf-8",
                },
            })

            vim.lsp.config('vtsls', 
            {
                before_init = function(_, config)
                    local codesettings = require('codesettings')
                    codesettings.with_local_settings(config.name, config)
                end,
            })

            config("vtsls", {})

            config("templ", {})

            for _, lsp in ipairs({ "html", "htmx" }) do
                config(lsp,
                {
                    filetypes = { "html", "templ" },
                })
            end

            -- config("tailwindcss",
            -- {
            --     filetypes =
            --     {
            --         "templ",
            --         "astro",
            --         "javascript",
            --         "typescript",
            --         "react",
            --     },
            --     init_options =
            --     {
            --         userLanguages =
            --         {
            --             templ = "html"
            --         }
            --     },
            -- })

            config("eslint", {})

            local function noCompletionOnSpaceForTailwind()
                for _, client in pairs((vim.lsp.get_clients {})) do
                    if client.name == "tailwindcss" then
                        local ch = { '"', "'", "`", ".", "(", "[", "!", "/", ":" }
                        client.server_capabilities.completionProvider.triggerCharacters = ch
                    end
                end
            end

            local function appendCompletionTriggerCharacters(client, characters)
                local completionProvider = client.server_capabilities.completionProvider
                if not completionProvider then
                    return
                end

                completionProvider.triggerCharacters = completionProvider.triggerCharacters or {}
                local existing = {}
                for _, character in ipairs(completionProvider.triggerCharacters) do
                    existing[character] = true
                end

                for _, character in ipairs(characters) do
                    if not existing[character] then
                        table.insert(completionProvider.triggerCharacters, character)
                        existing[character] = true
                    end
                end
            end

            vim.api.nvim_create_autocmd('LspAttach',
            {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    noCompletionOnSpaceForTailwind()
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client and client.name == "roslyn" then
                        appendCompletionTriggerCharacters(client, { "." })
                    end
                    ---
                    ---@diagnostic disable-next-line: inject-field
                    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                    local opts = { buffer = ev.buf }
                    local function setKey(mode, key, action, desc)
                        opts.desc = desc
                        vim.keymap.set(mode, key, action, opts)
                    end

                    setKey('n', 'gD', vim.lsp.buf.declaration, "Go to declaration")
                    -- setKey("n", "U", vim.lsp.buf.hover, "Show info about symbol")

                    opts.desc = "Show info about symbol"
                    helper.altMacBinding(
                    {
                        mode = 'n',
                        key = 'i',
                        action = vim.lsp.buf.hover,
                        opts = opts,
                    })

                    opts.desc = "Show function signature"
                    helper.altMacBinding(
                    {
                        mode = { 'n', 'i' },
                        key = 'u',
                        action = vim.lsp.buf.signature_help,
                        opts = opts,
                    })
                    helper.altMacBinding(
                    {
                        mode = 'i',
                        key = 'i',
                        action = vim.lsp.buf.signature_help,
                        opts = opts,
                    })

                    setKey('n', '<F2>', vim.lsp.buf.rename, "Rename symbol")
                    setKey({ 'n', 'v' }, '<C-.>', vim.lsp.buf.code_action, "LSP code action")
                    setKey({ 'n', 'v' }, '<leader>r', function()
                        vim.lsp.buf.format({
                            async = true,
                        })
                    end, "Reformat selection (visual) or the whole buffer (normal)")
                end,
            })

            -- vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufWritePost" }, {
            --     callback = function()
            --         vim.diagnostic.setqflist({ open = false })
            --     end,
            -- })
            -- local function cnext_wrap()
            --     local ok = pcall(vim.cmd.cnext)
            --     if not ok then
            --         vim.cmd.cfirst()
            --     end
            -- end

            -- local function cprev_wrap()
            --     local ok = pcall(vim.cmd.cprev)
            --     if not ok then
            --         vim.cmd.clast()
            --     end
            -- end

            -- vim.keymap.set("n", "ge", cnext_wrap, {
            --     desc = "Next workspace diagnostic",
            -- })
            -- vim.keymap.set("n", "gE", cprev_wrap, {
            --     desc = "Previous workspace diagnostic",
            -- })
            -- end
            local diagnosticNavigationSeverity =
            {
                vim.diagnostic.severity.ERROR,
                vim.diagnostic.severity.WARN,
            }
            local diagnosticNavigationSeverityLookup = {}
            for _, severity in ipairs(diagnosticNavigationSeverity) do
                diagnosticNavigationSeverityLookup[severity] = true
            end
            local diagnosticNavigationCache = {}
            local function isDiagnosticNavigationSeverity(diagnostic)
                return diagnosticNavigationSeverityLookup[diagnostic.severity] == true
            end
            local function diagnosticBufferKey(bufnr)
                local name = vim.api.nvim_buf_get_name(bufnr)
                if name ~= "" then
                    return vim.fn.fnamemodify(name, ":p")
                end
                return string.format("\255%d", bufnr)
            end
            local function setDiagnosticNavigationCache(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) then
                    diagnosticNavigationCache[bufnr] = nil
                    return
                end

                local diagnostics = vim.diagnostic.get(bufnr, {
                    severity = diagnosticNavigationSeverity,
                })
                if #diagnostics > 0 or bufnr == vim.api.nvim_get_current_buf() then
                    diagnosticNavigationCache[bufnr] = diagnostics
                end
            end
            local function refreshDiagnosticNavigationCache()
                for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(bufnr) then
                        local diagnostics = vim.diagnostic.get(bufnr, {
                            severity = diagnosticNavigationSeverity,
                        })
                        if #diagnostics > 0 then
                            diagnosticNavigationCache[bufnr] = diagnostics
                        end
                    else
                        diagnosticNavigationCache[bufnr] = nil
                    end
                end
                setDiagnosticNavigationCache(vim.api.nvim_get_current_buf())
            end
            local function compareDiagnosticPosition(a, b)
                if a.path ~= b.path then
                    return a.path < b.path and -1 or 1
                end
                if a.lnum ~= b.lnum then
                    return a.lnum < b.lnum and -1 or 1
                end
                if a.col ~= b.col then
                    return a.col < b.col and -1 or 1
                end
                if a.bufnr ~= b.bufnr then
                    return a.bufnr < b.bufnr and -1 or 1
                end
                return 0
            end
            local function sortedWorkspaceDiagnostics()
                refreshDiagnosticNavigationCache()

                local result = {}
                for bufnr, diagnostics in pairs(diagnosticNavigationCache) do
                    if vim.api.nvim_buf_is_valid(bufnr) then
                        for _, diagnostic in ipairs(diagnostics) do
                            table.insert(result, {
                                bufnr = bufnr,
                                col = diagnostic.col or 0,
                                diagnostic = diagnostic,
                                lnum = diagnostic.lnum or 0,
                                path = diagnosticBufferKey(bufnr),
                            })
                        end
                    else
                        diagnosticNavigationCache[bufnr] = nil
                    end
                end

                table.sort(result, function(a, b)
                    local positionComparison = compareDiagnosticPosition(a, b)
                    if positionComparison ~= 0 then
                        return positionComparison < 0
                    end
                    if a.diagnostic.severity ~= b.diagnostic.severity then
                        return a.diagnostic.severity < b.diagnostic.severity
                    end
                    return (a.diagnostic.message or "") < (b.diagnostic.message or "")
                end)
                return result
            end
            local diagnosticNavigationGroup =
                vim.api.nvim_create_augroup("DiagnosticNavigation", { clear = true })
            vim.api.nvim_create_autocmd("DiagnosticChanged", {
                group = diagnosticNavigationGroup,
                callback = function(args)
                    local bufnr = args.buf
                    local diagnostics = {}
                    for _, diagnostic in ipairs((args.data or {}).diagnostics or {}) do
                        if isDiagnosticNavigationSeverity(diagnostic) then
                            table.insert(diagnostics, diagnostic)
                        end
                    end
                    if #diagnostics > 0 then
                        diagnosticNavigationCache[bufnr] = diagnostics
                        return
                    end

                    vim.schedule(function()
                        setDiagnosticNavigationCache(bufnr)
                    end)
                end,
            })
            local function jumpToWorkspaceDiagnostic(direction)
                local diagnostics = sortedWorkspaceDiagnostics()
                if #diagnostics == 0 then
                    vim.api.nvim_echo({
                        { "No error or warning diagnostics to move to", "WarningMsg" },
                    }, true, {})
                    return
                end

                local cursor = vim.api.nvim_win_get_cursor(0)
                local currentBufnr = vim.api.nvim_get_current_buf()
                local currentPosition = {
                    bufnr = currentBufnr,
                    col = cursor[2],
                    lnum = cursor[1] - 1,
                    path = diagnosticBufferKey(currentBufnr),
                }
                local target
                if direction > 0 then
                    for _, diagnostic in ipairs(diagnostics) do
                        if compareDiagnosticPosition(diagnostic, currentPosition) > 0 then
                            target = diagnostic
                            break
                        end
                    end
                    target = target or diagnostics[1]
                else
                    for i = #diagnostics, 1, -1 do
                        local diagnostic = diagnostics[i]
                        if compareDiagnosticPosition(diagnostic, currentPosition) < 0 then
                            target = diagnostic
                            break
                        end
                    end
                    target = target or diagnostics[#diagnostics]
                end

                vim.cmd("normal! m'")
                vim.api.nvim_win_set_buf(0, target.bufnr)

                local lineCount = vim.api.nvim_buf_line_count(target.bufnr)
                local lnum = math.min(target.lnum, math.max(lineCount - 1, 0))
                vim.api.nvim_win_set_cursor(0, { lnum + 1, target.col })
                vim.cmd("normal! zv")
                vim.schedule(function()
                    vim.diagnostic.open_float({
                        bufnr = target.bufnr,
                        scope = "cursor",
                        focus = false,
                    })
                end)
            end

            vim.keymap.set("n", "ge", function()
                jumpToWorkspaceDiagnostic(1)
            end, {
                desc = "Go to next diagnostic",
            })
            vim.keymap.set("n", "gE", function()
                jumpToWorkspaceDiagnostic(-1)
            end, {
                desc = "Go to previous diagnostic",
            })

            require("mason").setup({
                registries =
                {
                    "github:mason-org/mason-registry",
                    "github:Crashdummyy/mason-registry",
                },
            })
            require("mason-lspconfig").setup({
                --ensure_installed = allConfigNames,
            })

            for i, _ in ipairs(allConfigOptions) do
                opts = allConfigOptions[i]
                name = allConfigNames[i]
                vim.lsp.config(name, opts)
            end
            vim.lsp.enable(allConfigNames)

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

            vim.keymap.set("n", "gr", substitute.operator, { noremap = true })
            vim.keymap.set("n", "grr", substitute.line, { noremap = true, nowait = true })
            vim.keymap.set("x", "gr", substitute.visual, { noremap = true, nowait = true })

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
        },
        config = function(_)
            local cmp = require('cmp')
            local cmpCompare = cmp.config.compare
            local lspCompletionItemKind = cmp.lsp.CompletionItemKind

            local defaultSources = cmp.config.sources(
            {
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

            local csharpSources = cmp.config.sources(
            {
                {
                    name = "nvim_lsp",
                    keyword_length = 1,
                    entry_filter = function(entry)
                        return entry:get_kind() ~= lspCompletionItemKind.Snippet
                    end,
                },
            },
            {
                {
                    name = "buffer",
                    keyword_length = 2,
                },
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
                    cmpCompare.offset,
                    cmpCompare.exact,
                    cmpCompare.score,
                    -- cmpCompare.scopes,
                    cmpCompare.kind,
                    cmpCompare.sort_text,
                    cmpCompare.length,
                    cmpCompare.order,
                    cmpCompare.locality,
                    cmpCompare.recently_used,
                },
            }

            local csharpSorting =
            {
                priority_weight = 2,
                comparators =
                {
                    cmpCompare.offset,
                    cmpCompare.exact,
                    cmpCompare.sort_text,
                    cmpCompare.score,
                    cmpCompare.locality,
                    cmpCompare.recently_used,
                    cmpCompare.kind,
                    cmpCompare.length,
                    cmpCompare.order,
                },
            }

            ---@diagnostic disable-next-line: missing-parameter
            cmp.setup(
            {
                enabled = function()
                    -- Disable in operator-pending mode
                    local mode = vim.api.nvim_get_mode().mode
                    if mode == 'no' or mode == 'nov' or mode == 'noV' then
                        return false
                    end

                    local bufType = vim.api.nvim_get_option_value("buftype", { buf = 0 })
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
                completion = {
                    -- It suggests lots of garbage without this.
                    keyword_length = 2,
                },
                mapping = vim.tbl_deep_extend(
                    'error',
                    defaultMapping,
                    {
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
                    -- ghost_text = true,
                },
                matching =
                {
                    disallow_fuzzy_matching = false,
                    disallow_partial_fuzzy_matching = false,
                    disallow_fullfuzzy_matching = false,
                    disallow_partial_matching = false,
                    disallow_prefix_unmatching = false,
                    disallow_symbol_nonprefix_matching = false,
                },
            })

            cmp.setup.filetype('cs',
            {
                sources = csharpSources,
                sorting = csharpSorting,
            })

            ---@diagnostic disable-next-line: undefined-field
            cmp.setup.filetype('gitcommit',
            {
                sources = cmp.config.sources(
                {
                    { name = 'git' },
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
            vim.keymap.set('n', '<leader>a', 'vae', {
                remap = true,
                desc = "Select whole buffer",
            })
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
                local lineOrSelection = mode == "n" and "line" or "selection"

                helper.altMacBinding(
                {
                    mode = mode,
                    key = 'k',
                    action = '<Plug>Go' .. modeCapital .. 'SMUp',
                    desc = "Move " .. lineOrSelection .. " up",
                })
                helper.altMacBinding(
                {
                    mode = mode,
                    key = 'j',
                    action = '<Plug>Go' .. modeCapital .. 'SMDown',
                    desc = "Move " .. lineOrSelection .. " down",
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
        end, {
            desc = "Show console messages in a temporary buffer",
        })
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
})

table.insert(plugins,
{
    "folke/tokyonight.nvim",
    opts =
    {
        styles = {
            comments = { italic = false },
            keywords = { italic = false },
        },
    },
    init = function(_)
        vim.cmd("colorscheme tokyonight-moon")
    end
})

-- vim.g.copilot_enabled = false
table.insert(plugins,
{
    "zbirenbaum/copilot.lua",
    -- cmd = "Copilot",
    -- event = "InsertEnter",
    enabled = false,
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
            filetypes =
            {
                yaml = true,
                markdown = true,
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
    config = function()
        local spectre = require("spectre")
        local opts = {
            desc = "Search and Replace",
        }
        vim.keymap.set('n', 'wr', function()
            spectre.toggle()
        end, opts)
        vim.keymap.set('v', 'wr', function()
            spectre.open_visual()
        end, opts)
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
                globalstatus = true,
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
        vim.keymap.set({ 'n', 'v' }, '<leader>go', ':GBrowse<CR>', {
            desc = "Open selection (visual) or file (normal) on GitHub",
        })
        vim.keymap.set('n', '<leader>gb', ':Git blame<CR>')
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

-- Buggy with <C-w><C-o>
table.insert(plugins,
{
    "nvim-treesitter/nvim-treesitter-context",
    dependencies =
    {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        local context = require("treesitter-context");
        context.setup({
            max_lines = 5,
            on_attach = function()
                if vim.bo.filetype == "go" then
                    return false
                end
                return true
            end,
        })
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
        if helper.isWindows() then
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

        vim.keymap.set("n", "<M-a>", function() harpoon:list():add() end)
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
    "kwkarlwang/bufjump.nvim",
    config = function()
        local opts = {
            silent = true,
            noremap = true,
        };
        local t = {
            mode = { "i", "n" },
            opts = opts,
        };
        local bufjump = require("bufjump");
        local configs = {
            { "H", bufjump.backward_same_buf },
            { "L", bufjump.forward_same_buf },
            { "J", bufjump.forward },
            { "K", bufjump.backward },
        };
        for _, config in ipairs(configs) do
            t.key = config[1]
            t.action = config[2]
            helper.altMacBinding(t);
        end
    end,
});

table.insert(plugins,
{
    "rcarriga/nvim-dap-ui",
    dependencies =
    {
        "mfussenegger/nvim-dap",
        "nvim-neotest/nvim-nio",
    },
    config = function(_)
        require("dapui").setup()
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end
    end,
})

table.insert(plugins,
{
    "stevearc/overseer.nvim",
    config = function()
        require('overseer').setup()
    end,
})

table.insert(plugins,
{
    "mfussenegger/nvim-dap",
    dependencies =
    {
        "leoluz/nvim-dap-go",
        "stevearc/overseer.nvim",
        "Joakker/lua-json5",
        "theHamsta/nvim-dap-virtual-text",
    },
    config = function(_)
        local dap = require("dap")

        ---@diagnostic disable-next-line: undefined-field
        dap.adapters.lldb =
        {
            type = "executable",
            command = "lldb-vscode-14",
            name = "lldb",
        }

        ---@diagnostic disable-next-line: undefined-field
        dap.adapters.cppvsdbg =
        {
            type = "executable",
            command = "vsdbg",
            name = "cppvsdbg",
        }

        local path = require("utils.path")

        local function cConfigs(compiler)
            local program = function()
                local currentFile = vim.api.nvim_buf_get_name(0)
                local currentFileFolder = vim.fn.fnamemodify(currentFile, ":h")

                -- do current file but remove the extension.
                -- on windows, add .exe
                local extension = helper.isWindows() and ".exe" or nil
                local outputFile = path.withExtension(currentFile, extension)

                -- compile
                vim.fn.system(
                    "cd " .. vim.fn.shellescape(currentFileFolder)
                    .. "; " .. compiler .. " -Wall -Werror -Wconversion -o "
                    .. vim.fn.shellescape(outputFile)
                    .. " " .. vim.fn.shellescape(currentFile))

                -- execute
                return outputFile
            end

            local result =
            {
                name = "Launch current file (Default)",
                type = "lldb",
                request = "launch",
                program = program,
            }
            return { result }
        end

        dap.configurations.cpp = cConfigs("g++")
        dap.configurations.c = cConfigs("gcc")
        dap.configurations.zig =
        {{
            name = "Zig run",
            type = "lldb",
            request = "launch",
            preLauchTask = "zig build install",
            stopOnEntry = false,
            program = function()
                -- find the first executable file in zig-out/bin
                local workspaceDir = vim.fn.getcwd()
                local outputPath = path.join(workspaceDir, "zig-out", "bin")
                local dir = vim.loop.fs_scandir(outputPath)
                if not dir then
                    error("Failed to read from the default directory '" ..  outputPath .. "'")
                end

                local firstFile = nil
                while true do
                    local name, type = vim.loop.fs_scandir_next(dir)
                    if name == nil then
                        error("No default output for the build command")
                    end

                    if type == 'file' then
                        if helper.isWindows() and name:match("%.exe$") then
                            firstFile = name
                            break
                        elseif not name:match("%.") then
                            firstFile = name
                            break
                        end
                    end
                end
                return path.join(outputPath, firstFile)
            end,
        }}

        dap.adapters.go = {
            type = "executable",
            command = "node",
            args = { vim.fn.stdpath("data") .. "/mason/bin/go-debug-adapter" },
        }
        require("dap-go").setup()

        do
            local vscode = require("dap.ext.vscode")
            vscode.json_decode = require("json5").parse
        end

        local function setSign(signName, symbol)
            vim.fn.sign_define(signName,
            {
                text = symbol,
                texthl = '',
                linehl = '',
                numhl = '',
            })
        end
        setSign("DapBreakpoint", "🔴")
        setSign("DapBreakpointConditional", "🟢")
        setSign("DapBreakpointRejected", "🚫")
        setSign("DapStopped", "👉")
        setSign("DapLogPoint", "📜")

        vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
        vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
        vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
        vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
        vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)

        -- vim.keymap.set("n", "wdl", ":ed " .. vim.fn.stdpath('cache') .. "/dap.log<CR>")
    end,
})

table.insert(plugins,
{
    'Joakker/lua-json5',
    build = helper.isWindows() and 'powershell ./install.ps1' or './install.sh'
})

table.insert(plugins,
{
    -- C-k  --  add link
    -- C-b  --  toggle bold
    -- C-i  --  toggle italic
    -- C-e  --  toggle code block
    "antonk52/markdowny.nvim",
    config = function()
        require('markdowny').setup()
    end,
})

table.insert(plugins,
{
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
    },
})

table.insert(plugins,
{
    "seblyng/roslyn.nvim",
    ft = "cs",
    dependencies =
    {
        "mason.nvim",
        "neovim/nvim-lspconfig",
        "hrsh7th/cmp-nvim-lsp",
    },
    init = function()
        local capabilities = vim.tbl_deep_extend(
            "force",
            vim.lsp.protocol.make_client_capabilities(),
            require("cmp_nvim_lsp").default_capabilities())

        vim.lsp.config("roslyn",
        {
            capabilities = capabilities,
            settings = {
                ["csharp|completion"] = {
                    dotnet_show_completion_items_from_unimported_namespaces = true,
                    dotnet_show_name_completion_suggestions = true,
                },
                ["csharp|symbol_search"] = {
                    dotnet_search_reference_assemblies = true,
                },
                ["csharp|background_analysis"] = {
                    dotnet_compiler_diagnostics_scope = "fullSolution",
                    dotnet_analyzer_diagnostics_scope = "fullSolution",
                },
            },
        })
    end,
    config = function()
        require("roslyn").setup()
    end,
})

table.insert(plugins,
{
    'mrjones2014/codesettings.nvim',
    lazy = false,
    opts = 
    {
        config_file_paths = { 
            '.vscode/settings.json',
            'codesettings.json',
            'lspsettings.json',
        },
        jsonc_filetype = true,
        jsonls_integration = true,
        live_reload = true,
        loader_extensions = { 'codesettings.extensions.vscode' },
        lua_ls_integration = true,
        merge_lists = 'append',
        nls = true,
    },
})

table.insert(plugins, 
{
    "stevearc/dressing.nvim",
    opts = {},
});
table.insert(plugins,
{
    "folke/noice.nvim",
    opts = {
        lsp = {
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },
        },
        presets = {
            bottom_search = true,
            command_palette = false,
            long_message_to_split = true,
            inc_rename = false,
            lsp_doc_border = false,
        },
    },
});

require("lazy").setup(plugins);
