local helper = require("core.helper")

vim.g.mapleader = " "

helper.altMacBinding({ key = "h", action = "<C-o>" })
helper.altMacBinding({ key = "l", action = "<C-i>" })

do
    local function mapSystemRegisterPaste(from, action)
        local mapping =  '"*' .. action .. helper.lastTextChange() .. '='
        vim.keymap.set("n", from, mapping)
        vim.keymap.set("v", from, mapping)
    end
    local function mapSystemRegisterCopy(from, action)
        vim.keymap.set("n", from, 'V"*' .. action)
        vim.keymap.set("v", from, '"*' .. action)
    end
    mapSystemRegisterCopy("<leader>c", "y")
    mapSystemRegisterCopy("<leader>y", "y")
    mapSystemRegisterCopy("<leader>d", "d")
    mapSystemRegisterPaste("<leader>p", "p")
    mapSystemRegisterPaste("<leader>P", "P")
    mapSystemRegisterPaste("<leader>v", "p")
end

vim.keymap.set("n", "&", "v$")

-- Folding
vim.keymap.set("n", "L", "zo")
vim.keymap.set("n", "H", "zc")

vim.keymap.set("v", ">", ">" .. helper.lastTextChange())
vim.keymap.set("v", "<", "<gv" .. helper.lastTextChange())
vim.keymap.set("v", "=", "=gv" .. helper.lastTextChange())

-- Toggle highlight
vim.keymap.set("n", "<leader>ht", function()
    if (vim.v.hlsearch == 1)
    then
        vim.cmd.nohl()
    else
        vim.o.hls = 1
    end
end)

-- Word wrap
vim.keymap.set("n", "ww", function()
    vim.o.wrap = not vim.o.wrap
end)

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-W><C-h>")
vim.keymap.set("n", "<C-l>", "<C-W><C-l>")
vim.keymap.set("n", "<C-j>", "<C-W><C-j>")
vim.keymap.set("n", "<C-k>", "<C-W><C-k>")

vim.keymap.set('n', '<leader>tw', [[:%s/\s\+$//e<cr>]],
{
    desc = 'Trim whitespace',
})

vim.keymap.set('n', 'wo', '<C-W>o',
{
    desc = "Closes the goddamn floats, for Christ sake!",
})
vim.keymap.set('n', '<leader>*', helper.lastTextChange())

