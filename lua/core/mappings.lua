local helper = require("core.helper")

vim.g.mapleader = " "

helper.altMacBinding({ mode = { 'i', 'n' }, key = "h", action = "<C-o>" })
helper.altMacBinding({ mode = { 'i', 'n' }, key = "l", action = "<C-i>" })

do
    local function mapSystemRegisterPaste(from, action)
        local mapping = '"*' .. action
        vim.keymap.set("n", from, mapping)
        vim.keymap.set("v", from, mapping .. 'gv')
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
    vim.o.hls = not vim.o.hls
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

-- Changing font size (this won't work in the terminal I think)
vim.keymap.set("", "<C-->", function()
    helper.updateCurrentFontSize(-1)
end)
vim.keymap.set("", "<C-=>", function()
    helper.updateCurrentFontSize(1)
end)

-- Regular text editing commands
vim.keymap.set({ "i", "c" }, helper.controlBackspace(), "<C-w>")
vim.keymap.set({ "i", "c" }, "<C-del>", "<C-o>de")
vim.keymap.set({ "i" }, "<C-z>", "<C-o>u")
vim.keymap.set({ "i" }, "<C-y>", "<C-o><C-r>")

vim.keymap.set("n", "<leader>wd", vim.cmd("let @*=getcwd()"))

local function registerRomanianKeys()
    -- Register binings to romanian letters
    local keys = { '[', ']', '\\', ';', '\'' }
    local letters = { 'ă', 'î', 'â', 'ș', 'ț' }
    -- I wanted to derive these automatically from the lowercase letters.
    -- For that we need to be able to uppercase UTF-8 characters.
    -- For that we need either to implement it manually,
    -- which I don't want to do, or use a library.
    -- I've tried to include a few libraries using lazy, but that didn't work,
    -- because they're regular libraries and not plugins and are structured
    -- in a different way from what lazy expects.
    -- So I need to include the packages in a regular way.
    -- That means either a git submodule, which won't 
    -- work for packages that compile C btw, or a luarocks package.
    -- There's no plugin that helps with luarocks packages that works on Windows,
    -- and writing one manually is a challenge for me right now.
    local capitalKeys = { '{', '}', '|', ':', '"' }
    local capitalLetters = { 'Ă', 'Î', 'Â', 'Ș', 'Ț' }
    local t = { mode = { 'i', 'c' } }

    for i, key in ipairs(keys) do
        t.key = key
        t.action = letters[i]
        helper.altMacBinding(t)
    end

    for i, key in ipairs(capitalKeys) do
        t.key = key
        t.action = capitalLetters[i]
        helper.altMacBinding(t)
    end
end

registerRomanianKeys()
