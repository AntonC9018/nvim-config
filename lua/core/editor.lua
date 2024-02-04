local helper = require('core.helper')

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


