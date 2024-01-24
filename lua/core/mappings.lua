vim.g.mapleader = " "
vim.keymap.set("n", "we", vim.cmd.Ex)

vim.keymap.set("v", "<C-/>", "<Plug>Commentary")
vim.keymap.set("n", "<C-/>", "<Plug>CommentaryLine")

function mapSystemRegisterMotion(from, action)
    vim.keymap.set("n", from, 'V"*' .. action .. 'gv=')
    vim.keymap.set("v", from, '"*' .. action .. 'gv=')
end
mapSystemRegisterMotion("<leader>c", "y")
mapSystemRegisterMotion("<leader>y", "y")
mapSystemRegisterMotion("<leader>d", "d")
mapSystemRegisterMotion("<leader>p", "p")
mapSystemRegisterMotion("<leader>P", "P")
mapSystemRegisterMotion("<leader>v", "p")

vim.keymap.set("n", "&", "v$")
