local helper = require('core.helper')

-- vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local defaultFontInfo = helper.defaultFontInfo()
vim.opt.guifont = helper.setGuiFont(defaultFontInfo)

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.opt.completeopt:remove("preview")

vim.o.mouse = 'a'

vim.o.scrolloff = 5
vim.o.relativenumber = true
vim.o.number = true

vim.o.timeoutlen = 8000

-- https://stackoverflow.com/questions/36500099/vim-gf-should-open-file-and-jump-to-line
vim.cmd("set isfname-=:")

vim.cmd("set whichwrap+=h,l")

vim.o.autoindent = true
vim.o.cmdheight = 2

vim.o.undofile = true

vim.opt.formatoptions:remove("o")
vim.api.nvim_create_autocmd("FileType",
{
    group = vim.api.nvim_create_augroup("no_comment_continuation", { clear = true }),
    callback = function(args)
        vim.bo[args.buf].formatoptions = vim.bo[args.buf].formatoptions:gsub("o", "")
    end,
})

-- https://github.com/nguynkhn/dotfiles/blob/3b4c9b908d760d942c0ad29b68551604fe2a28ff/nvim/lua/autocmds.lua#L13-L22
vim.api.nvim_create_autocmd("BufWritePre",
{
    group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
    callback = function(event)
        if event.match:match("^%w%w+://") then
            return
        end
        ---@diagnostic disable-next-line: undefined-field
        local file = vim.loop.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

vim.filetype.add(
{
    pattern =
    {
        ['.*/MSVC/[^/]*/include/.*'] = 'cpp',
    },
})

vim.api.nvim_create_autocmd("BufWritePost",
{
    pattern = { ".tmux.conf" },
    callback = function()
        vim.system({"tmux", "source-file", vim.fn.expand("%")})
        print("Reloaded tmux")
    end,
})

vim.g.tex_fold_enabled = true

vim.filetype.add(
{
    extension =
    {
        templ = "templ"
    }
})
vim.api.nvim_create_autocmd("FileType", {
    pattern = "templ",
    command = "setlocal commentstring=//\\ %s"
})

vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'},
{
    group = vim.api.nvim_create_augroup('ReadOnlyTemplFiles', { clear = true }),
    pattern = '*_templ.go',
    callback = function()
        vim.cmd('set readonly')
    end,
})

vim.api.nvim_create_autocmd("ColorScheme",
{
    callback = function()
        --- @param name string Highlight group name, e.g. "ErrorMsg"
        --- @param val vim.api.keyset.highlight Highlight definition map, accepts the following keys:
        local function highlight(name, val)
            local globalHighlight = 0
            vim.api.nvim_set_hl(globalHighlight, name, val)
        end
        highlight("MatchParen", { bg = "#555599", sp = "Blue" })
        highlight("TreesitterContext", { bg = "#202020" })
        highlight("SpellBad", { fg = "#EE5555" })
        highlight("DiagnosticUnderlineError", { underline = true, sp = "#EE5555" })
        highlight("DiagnosticError", { fg = "#EE5555" })

        for _, type in ipairs({ "@lsp.type.delegate.cs", "@lsp.type.generic.cs", "@lsp.type.record.cs" }) do
            highlight(type, { fg = "#1f8730" });
        end
        for _, type in ipairs({ "@lsp.type.recordStruct.cs", "@lsp.type.struct.cs" }) do
            highlight(type, { fg = "#AABB30" });
        end
        for _, type in ipairs({ "@lsp.typemod.field.static.cs" }) do
            highlight(type, { fg = "#3399FF" });
        end
        for _, type in ipairs({ "@lsp.type.extensionMethod.cs" }) do
            highlight(type, { fg = "#44BC44" });
        end
    end
})
