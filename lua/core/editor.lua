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
