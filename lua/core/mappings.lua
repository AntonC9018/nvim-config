local helper = require("core.helper")

vim.g.mapleader = " "

helper.altMacBinding("h", "<C-o>")
helper.altMacBinding("l", "<C-i>")

-- Toggle line comment
vim.keymap.set("v", "<C-/>", "<Plug>Commentary")
vim.keymap.set("n", "<C-/>", "<Plug>CommentaryLine")

do
    local function mapSystemRegisterPaste(from, action)
        vim.keymap.set("n", from, '"*' .. action .. 'gv=')
        vim.keymap.set("v", from, '"*' .. action .. 'gv=')
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

vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", "=", "=gv")

-- Toggle highlight
vim.keymap.set("n", "<leader>ht",
    function()
        if (vim.v.hlsearch == 1)
        then
            vim.cmd.nohl()
        else
            vim.o.hls = 1
        end
    end)

vim.keymap.set("n", "ww",
    function()
        vim.o.wrap = not vim.o.wrap
    end)

vim.keymap.set("n", "<C-h>", "<C-W><C-h>")
vim.keymap.set("n", "<C-l>", "<C-W><C-l>")
vim.keymap.set("n", "<C-j>", "<C-W><C-j>")
vim.keymap.set("n", "<C-k>", "<C-W><C-k>")

vim.keymap.set('n', 'wtw', [[:%s/\s\+$//e<cr>]])
vim.keymap.set('n',
    'wg',
    '<C-W>o',
    {
        desc = "Closes the goddamn floats, for Christ sake!"
    })
vim.g.bufferize_focus_output = true
