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

--- @class FontInfo
--- @field name string
--- @field size number

--- @return FontInfo
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

--- @param fontInfo FontInfo
function helper.setGuiFont(fontInfo)
    local result = fontInfo.name .. ":h" .. fontInfo.size
    vim.o.guifont = result
end

--- @return FontInfo
function helper.defaultFontInfo()
    return
    {
        name = "SauceCodePro NF",
        size = 14,
    }
end

--- @param amount number
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

--- @param filePath string
--- @return string
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

--- NOTE: Must be used inside a vim.schedule if executing inside bindings in order to cancel the visual mode.
--- @param lineMode boolean Whether to trim the first and last lines to selection
local function getVisualSelectionLines(lineMode)
    local bufnr = vim.api.nvim_get_current_buf()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line = start_pos[2] - 1
    local end_line = end_pos[2] - 1
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
    if lineMode then
        return lines
    end

    if #lines == 0 then
        return lines
    end

    -- Handle selection within the same line
    if start_line == end_line then
        local start_col = start_pos[3] - 1
        local end_col = end_pos[3]
        lines[1] = string.sub(lines[1], start_col + 1, end_col)
        return lines
    end

    -- Handle selection spanning multiple lines
    local start_col = start_pos[3] - 1
    local end_col = end_pos[3]
    lines[1] = string.sub(lines[1], start_col + 1)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
    return lines
end

--- @class CancelSelectionAndExecuteWithSelectionOptions
--- @field lineMode boolean|nil If true, selects entire lines, otherwise looks at the current mode to guess
--- @field func fun(lines: string[]): nil The function to execute with the selection

--- @param opts CancelSelectionAndExecuteWithSelectionOptions
--- @return nil
function helper.cancelSelectionAndExecuteWithSelection(opts)
    local mode = vim.fn.mode()
    if mode ~= 'v' and mode ~= 'V' then
        error("Must be called in visual mode")
    end

    local lineMode
    if opts.lineMode ~= nil then
        lineMode = opts.lineMode
    elseif mode == 'v' then
        lineMode = false
    else
        lineMode = true
    end

    -- Exit visual mode
    vim.api.nvim_input("<Esc>")
    -- This is required so that the exiting gets processed.
    vim.schedule(function()
        -- LuaDoc can't even determite it can't be nil here.
        ---@diagnostic disable-next-line: param-type-mismatch
        local selection = getVisualSelectionLines(lineMode)
        opts.func(selection)
    end)
end

return helper
