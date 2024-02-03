local helper = {}

helper.isCmderTerminal = function()
    return os.getenv("CMDER_ROOT") ~= nil
end

helper.controlSlash = function()
    -- Some terminals can't send control-slash to apps
    -- (ConEmu can't, at the very least)
    if helper.isCmderTerminal() then
        return "<C-_>"
    else
        return "<C-/>"
    end
end

helper.tab = function()
    if helper.isCmderTerminal() then
        -- Same here
        return "<C-i>"
    else
        return "<Tab>"
    end
end

-- Not actually supported in my terminal
helper.controlSpace = function()
    return "<C-Space>"
end

helper.controlBackspace = function()
    if helper.isCmderTerminal() then
        return "<C-h>"
    else
        return "<C-BS>"
    end
end


helper.lastTextChange = function()
    return '`[v`]'
end

helper.modifyKey = function(modifier, key)
    return "<" .. modifier .. "-" .. key .. ">"
end

--- Define mappings for alt key, command key, and meta key.
--- @param table 
helper.altMacBinding = function(table)
    local key = table.key
    if key == nil then
        error("table.key must not be nil")
    end

    local mode = table.mode
    if mode == nil then
        mode = "n"
    end

    local action = table.action
    if action == nil then
        error("table.action must not be nil")
    end

    local opts = table.opts

    vim.keymap.set(mode, helper.modifyKey('M', key), action, opts)
    vim.keymap.set(mode, helper.modifyKey('D', key), action, opts)
    vim.keymap.set(mode, helper.modifyKey('A', key), action, opts)
end

helper.windowMap = function(key, actionOpen, actionToggle, opts)
    if opts == nil
    then
        opts = {}
    end
    vim.keymap.set("n", "w"..key, actionOpen, opts)
    vim.keymap.set("n", "wt"..key, actionToggle, opts)
end

local function spanEquals(s1, s2, s1Start, s1Length)
    if string.len(s2) < s1Length
    then
        return false
    end
    if string.len(s1) - s1Start < s1Length
    then
        return false
    end

    local idx = 1
    while idx < s1Length
    do
        if s1[idx + s1Start] ~= s2[idx]
        then
            return false
        end
        idx = idx + 1
    end
    return true
end

local function removeRange(s1, start, length)
    if string.len(s1) - start == length
    then
        return string.sub(s1, start, start + length - 1)
    end

    local a = string.sub(s1, 0, start - 1)

    local bStart = start + length
    local b = string.sub(s1, bStart, string.len(s1) - bStart - 1)

    return a .. b
end

local function removePreviewFromCompleteOpt()
    local current = vim.opt.completeopt
    print(vim.inspect(current))
    local delimiter = ','
    local itemToRemove = 'preview'
    local startTokenWithDelimiter = 1
    local startToken = 1
    local idx = 1
    while (idx <= string.len(current))
    do
        local c = current[idx]
        if c == delimiter
        then
            local stringLength = idx - startToken
            if spanEquals(
                current,
                itemToRemove,
                startToken,
                stringLength)
            then
                return removeRange(
                    current,
                    startTokenWithDelimiter,
                    idx - startTokenWithDelimiter)
            else
                startToken = idx + 1
                startTokenWithDelimiter = idx
            end
        end
        idx = idx + 1
    end
end

helper.cmpNormalizeMappings = function(unnormalizedMappings, targetMode)
    -- from sources of cmp
    local keymap = require('cmp.utils.keymap')
    local result = {}
    for k, v in pairs(unnormalizedMappings) do
        if targetMode ~= nil then
            v = { [targetMode] = v }
        end
        -- I have no idea what this does exactly
        result[keymap.normalize(k)] = v
    end
    return result
end

helper.getFontInfo = function()
    local font = vim.o.guifont
    if font == nil
    then
        return helper.getDefaultFontInfo()
    end

    local parts = vim.split(font, ":")
    -- strip away the leading h
    local heightString = string.sub(parts[2], 2)
    local height = tonumber(heightString)
    return
    {
        name = parts[1],
        size = height,
    }
end

helper.setGuiFont = function(fontInfo)
    local result = fontInfo.name .. ":h" .. fontInfo.size
    vim.o.guifont = result
end

helper.getDefaultFontInfo = function()
    return
    {
        name = "SauceCodePro NF",
        size = 16,
    }
end

helper.updateCurrentFontSize = function(amount)
    local currentFont = helper.getFontInfo()
    local newSize = currentFont.size + amount
    if newSize < 1
    then
        newSize = 1
    end
    currentFont.size = newSize
    helper.setGuiFont(currentFont)
end

return helper
