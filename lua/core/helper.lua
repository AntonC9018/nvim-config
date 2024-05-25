local helper = {}

-- Won't work with * in tmux for some reason.
helper.systemClipboardRegister = "+"

function helper.isCmderTerminal()
    return os.getenv("CMDER_ROOT") ~= nil
end

function helper.controlSlash()
    return "<C-/>"
end

function helper.tab()
    return "<Tab>"
end

-- Not actually supported in my terminal
function helper.controlSpace()
    return "<C-Space>"
end


function helper.lastTextChange()
    return '`[v`]'
end

function helper.visualRange()
    return "'<,'>"
end

function helper.modifyKey(modifier, key)
    return "<" .. modifier .. "-" .. key .. ">"
end

local altKeys = { "M", "D", "A" }

--- Define mappings for alt key, command key, and meta key.
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

    for _, altKey in ipairs(altKeys) do
        local modifiedKey = helper.modifyKey(altKey, key)
        vim.keymap.set(mode, modifiedKey, action, opts)
    end
end

function helper.cmpNormalizeMappings(unnormalizedMappings, targetMode)
    local result = {}
    for k, v in pairs(unnormalizedMappings) do
        if targetMode ~= nil then
            v = { [targetMode] = v }
        end
        result[k] = v
    end
    return result
end

function helper.fontInfo()
    local font = vim.o.guifont
    if font == nil
    then
        return helper.defaultFontInfo()
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

function helper.setGuiFont(fontInfo)
    local result = fontInfo.name .. ":h" .. fontInfo.size
    vim.o.guifont = result
end

function helper.defaultFontInfo()
    return
    {
        name = "SauceCodePro NF",
        size = 14,
    }
end

function helper.updateCurrentFontSize(amount)
    local currentFont = helper.fontInfo()
    local newSize = currentFont.size + amount
    if newSize < 1
    then
        newSize = 1
    end
    currentFont.size = newSize
    helper.setGuiFont(currentFont)
end

local path = require("utils.path")

function helper.formatPath(filePath)
    local parsedFilePath = path.parse(filePath);
    if parsedFilePath.is_rooted then
        return filePath
    end

    local fileName = parsedFilePath.segments[#parsedFilePath.segments];
    return fileName
end

function helper.isWindows()
    return vim.fn.has("win32") == 1
end

return helper
