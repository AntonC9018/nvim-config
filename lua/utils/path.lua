local M = {}

---The file system path separator for the current platform.
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1
if M.is_windows == true then
    M.path_separator = "\\"
    M.inactive_path_separator = "/"
else
    M.path_separator = "/"
    M.inactive_path_separator = "\\"
end
M.any_path_separator_regex = "[\\/]"
M.not_any_path_separator_regex = "[^\\/]"

---Split string into a table of strings using a separator.
---@param inputString string The string to split.
---@param sep string The separator to use.
---@return table table A table of strings.
function M.split(inputString, sep)
  local fields = {}

  local pattern = string.format("([^%s]+)", sep)
  local _ = string.gsub(inputString, pattern, function(c)
    fields[#fields + 1] = c
  end)

  return fields
end

---Joins arbitrary number of paths together.
---@param ... string The paths to join.
---@return string
function M.join(...)
  local args = {...}
  if #args == 0 then
    return ""
  end

  local all_parts = {}
  if type(args[1]) == "string" and args[1]:sub(1, 1) == M.path_separator then
    all_parts[1] = ""
  end

  for _, arg in ipairs(args) do
    local arg_parts = M.split(arg, M.path_separator)
    vim.list_extend(all_parts, arg_parts)
  end
  return table.concat(all_parts, M.path_separator)
end

--- @param path string
--- @return string
function M.getDirectoryPath(path)
    local result = vim.fn.fnamemodify(path, ":h")
    if result == nil then
        error("Couldn't call vim function for path?")
    end
    return result
end

--- @param path string
--- @return string
function M.getFileNameWithoutExtension(path)
    local result vim.fn.fnamemodify(path, ":t:r")
    if result == nil then
        error("Couldn't call vim function for path?")
    end
    return result
end

--- @param path string
--- @param newExtension ?string
--- @return string
function M.withExtension(path, newExtension)
    local filePathWithoutExtension = vim.fn.fnamemodify(path, ":r")
    if filePathWithoutExtension == nil then
        error("Couldn't call vim function for path?")
    end
    if newExtension == "" or newExtension == nil then
        return filePathWithoutExtension
    else
        return filePathWithoutExtension .. "." .. newExtension
    end
end

function M.normalize(path)
    local result = path:gsub(M.inactive_path_separator, M.path_separator)
    return result
end

function M.isAbsolute(path)
    local result = string.find(path, "^[A-Z]:")
    return result ~= nil
end

function M.unparse(parsedPath)
    local pathPart = table.concat(parsedPath.segments, M.path_separator)
    if parsedPath.drive ~= nil then
        return parsedPath.drive .. M.path_separator .. pathPart
    else
        return pathPart
    end
end

function M.parsedCwd()
    -- TODO: event on cwd change
    return M.parse(vim.fn.getcwd())
end

local pathSegmentRegex = M.any_path_separator_regex .. "(" .. M.not_any_path_separator_regex .. "*)"
local driveRegex = "^[A-Za-z]:"

function M.isRooted(path)
    local hasDrive = string.find(path, driveRegex)
    return hasDrive ~= nil
end

function M.parse(path)
    local drive = string.match(path, driveRegex)

    local result = {}
    result.drive = drive
    result.segments = {}
    result.is_rooted = drive ~= nil
        -- Hack for unix?
        or #path > 0 and path[1] == '/'

    if drive ~= nil then
        if string.len(path) == string.len(drive) then
            return result
        end

        path = string.sub(path, string.len(drive) + 1, string.len(path))
    else
        local firstSep = string.find(path, M.any_path_separator_regex)
        if firstSep == nil then
            if string.len(path) > 0 then
                table.insert(result.segments, path)
            end
            return result
        end

        if firstSep ~= 1 then
            local firstSegment = path:sub(1, firstSep - 1)
            table.insert(result.segments, firstSegment)
        end
    end

    for segment in string.gmatch(path, pathSegmentRegex) do
        if string.len(segment) > 0 then
            table.insert(result.segments, segment)
        end
    end

    return result
end

function M.absolutePath(basePath, relativePath)
    local relativeParts = M.parse(relativePath)
    if relativeParts.drive ~= nil then
        return relativePath
    end

    if #relativeParts.segments == 0 then
        return basePath
    end

    local newSegments = {}
    local function appendParts(parts)
        for _, part in ipairs(parts) do
            if part == ".." and #newSegments ~= 0 then
                table.remove(newSegments, #newSegments)
            elseif part ~= "." then
                table.insert(newSegments, part)
            end
        end
    end

    local baseParts = M.parse(basePath)
    appendParts(baseParts.segments)
    appendParts(relativeParts.segments)

    local resultParts =
    {
        drive = baseParts.drive,
        segments = newSegments,
    }

    return M.unparse(resultParts)
end

function M.currentFilePath()
    return vim.fn.expand("%:p")
end

function M.currentFileDirectoryPath()
    return vim.fn.expand("%:p:h")
end

return M
