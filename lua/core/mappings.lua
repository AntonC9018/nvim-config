vim.g.mapleader = " "

-- Explorer
vim.keymap.set("n", "we", vim.cmd.Ex)

-- Toggle line comment
vim.keymap.set("v", "<C-/>", "<Plug>Commentary")
vim.keymap.set("n", "<C-/>", "<Plug>CommentaryLine")

function mapSystemRegisterCopy(from, action)
    vim.keymap.set("n", from, 'V"*' .. action .. 'gv=')
    vim.keymap.set("v", from, '"*' .. action .. 'gv=')
end
function mapSystemRegisterPaste(from, action)
    vim.keymap.set("n", from, '"*' .. action)
    vim.keymap.set("v", from, '"*' .. action)
end
mapSystemRegisterCopy("<leader>c", "y")
mapSystemRegisterCopy("<leader>y", "y")
mapSystemRegisterCopy("<leader>d", "d")
mapSystemRegisterPaste("<leader>p", "p")
mapSystemRegisterPaste("<leader>P", "P")
mapSystemRegisterPaste("<leader>v", "p")

vim.keymap.set("n", "&", "v$")

-- Folding
vim.keymap.set("n", "L", "zo")
vim.keymap.set("n", "H", "zc")

vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", "=", "=gv")

-- Clear highlight
vim.keymap.set("n", "<leader>hc",
    function()
        if (vim.v.hlsearch == 1)
        then
            vim.cmd.nohl()
        else
            vim.o.hls = 1
        end
    end)
