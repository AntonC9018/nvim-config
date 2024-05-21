local helper = require("core.helper")

vim.g.mapleader = " "

helper.altMacBinding({ mode = { 'i', 'n' }, key = "h", action = "<C-o>" })
helper.altMacBinding({ mode = { 'i', 'n' }, key = "l", action = "<C-i>" })

do
    local systemClipboardRegisterReference = '"' .. helper.systemClipboardRegister

    local function mapSystemRegisterPaste(from, action)
        local mapping = systemClipboardRegisterReference .. action
        vim.keymap.set("n", from, mapping)
        vim.keymap.set("v", from, mapping .. 'gv')
    end
    local function mapSystemRegisterCopy(from, action)
        vim.keymap.set("n", from, 'V' .. systemClipboardRegisterReference .. action)
        vim.keymap.set("v", from, systemClipboardRegisterReference .. action)
    end

    mapSystemRegisterCopy("<leader>y", "y")
    mapSystemRegisterCopy("<leader>d", "d")
    mapSystemRegisterPaste("<leader>p", "p")
    mapSystemRegisterPaste("<leader>P", "P")

    -- Map <leader>c to copying to the system register without indentation
    vim.keymap.set("n", "<leader>c", '0v$' .. systemClipboardRegisterReference .. 'y')
    vim.keymap.set("v", "<leader>c", function()

        -- This function won't work unless you've exited visual mode.
        -- The markers are only updated then.
        local function get_visual_selection()
            local bufnr = vim.api.nvim_get_current_buf()
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")
            local start_line = start_pos[2] - 1
            local end_line = end_pos[2] - 1
            local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
            return lines
        end

        -- Exit visual mode
        vim.api.nvim_input("<Esc>")
        -- This is required so that the exiting gets processed.
        vim.schedule(function()
            local lines = get_visual_selection()
            if #lines == 0 then
                return
            end

            local minIndentation = nil
            for _, line in ipairs(lines) do
                local indentation = line:match("^%s*")
                if minIndentation == nil then
                    minIndentation = #indentation
                elseif #indentation < minIndentation then
                    minIndentation = #indentation
                end
            end

            if minIndentation ~= 0 then
                for i, line in ipairs(lines) do
                    lines[i] = line:sub(minIndentation + 1)
                end
            end

            local linesAsString = table.concat(lines, "\n")
            vim.fn.setreg(helper.systemClipboardRegister, linesAsString, "l")
        end)
    end)
end

-- Folding
vim.keymap.set("n", "L", "zo")
vim.keymap.set("n", "H", "zc")

vim.keymap.set("v", ">", ">" .. helper.lastTextChange())
vim.keymap.set("v", "<", "<" .. helper.lastTextChange())
vim.keymap.set("v", "=", "=" .. helper.lastTextChange())

vim.keymap.set("n", "<leader>ht", function()
    vim.o.hls = not vim.o.hls
end, {
    desc = "Toggle highlight",
})

vim.keymap.set("n", "ww", function()
    vim.o.wrap = not vim.o.wrap
end, {
    desc = "Toggle word wrap",
})

vim.keymap.set("n", "W", ":w<CR>")

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
    desc = "Closes the floats",
})
vim.keymap.set('n', '<leader>*', helper.lastTextChange())

-- Changing font size (this won't work in the terminal)
vim.keymap.set("", "<C-->", function()
    helper.updateCurrentFontSize(-1)
end)
vim.keymap.set("", "<C-=>", function()
    helper.updateCurrentFontSize(1)
end)


-- Regular text editing commands
vim.keymap.set({ "i", "c" }, "<C-h>", "<C-w>")
vim.keymap.set({ "i", "c" }, "<C-BS>", "<C-w>")
vim.keymap.set({ "i", "c" }, "<C-del>", "<C-o>de")
vim.keymap.set({ "i" }, "<C-z>", "<C-o>u")
vim.keymap.set({ "i" }, "<C-y>", "<C-o><C-r>")

vim.keymap.set("n", "<leader>wd", function()
    vim.cmd("let @" .. helper.systemClipboardRegister .. "=getcwd()")
end, {
    desc = "Copy the current working directory to clipboard",
})
vim.keymap.set("n", "<leader>wc", function()
    vim.cmd("cd %:h")
end, {
    desc = "Change the current working directory to the directory of the current file",
})

local function registerRomanianKeys()
    -- Register bindings to romanian letters
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
    local t = {
        mode = { 'i', 'c' },
    }

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

vim.keymap.set("n", "gb", "`[")
vim.keymap.set("n", "<M-v>", "<C-v>")
vim.keymap.set("c", "<Esc>", "<C-c>")

vim.keymap.set("n", "<leader>xx", function()
    vim.cmd(".lua")
    print("Reloaded")
end, {
    desc = "Execute the current line",
})
-- A similar binding for insert mode that executes the selected lines
vim.keymap.set("v", "<leader>x", function()
    vim.api.nvim_input("<Esc>")
    vim.schedule(function()
        vim.cmd(helper.visualRange() .. "lua")
        print("Reloaded")
    end)
end, {
    desc = "Execute selected lines",
})

do
    local trimCommand = [[s/\r$//g]]
    local opts = {
        desc = "Trim windows line ending artifacts carriage-returns",
        silent = true,
    }
    local function bind(mode, range)
        vim.keymap.set(mode, "<leader>tw", ":" .. range .. trimCommand .. "<CR>", opts)
    end
    bind("n", "%")
    bind("v", "")
end
