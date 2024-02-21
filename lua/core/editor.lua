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

-- https://github.com/nguynkhn/dotfiles/blob/57e6ebdc5d9f76fcbfd49543cf198bb90b2a5f2d/.config/nvim/lua/autocmds.lua#L13-L22
vim.api.nvim_create_autocmd("BufWritePre",
{
    group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
    callback = function(event)
        if event.match:match("^%w%w+://") then
            return
        end
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
