local helper = {}

helper.controlSlash = function()
    return "<C-_>"
end

helper.modifyKey = function(modifier, key)
    return "<" .. modifier .. "-" .. key .. ">"
end

helper.altMacBinding = function(key, action)
    vim.keymap.set("n", helper.modifyKey('M', key), action)
    vim.keymap.set("n", helper.modifyKey('D', key), action)
    vim.keymap.set("n", helper.modifyKey('A', key), action)
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

return helper
