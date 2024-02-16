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
M.not_any_path_separator_regex = "[^\\^/]"


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

function M.joinParts(parsedPath)
    local pathPart = table.concat(parsedPath.parts, M.path_separator)
    if parsedPath.drive ~= nil then
        return parsedPath.drive .. M.path_separator .. pathPart
    else
        return pathPart
    end
end

function M.parse(path)
    local drive = string.match(path, "^[A-Z]:")

    local result = {}
    result.drive = drive

    if drive ~= nil then
        if string.len(path) == string.len(drive) then
            return result
        end

        path = string.sub(path, string.len(path) + 1)
    end

    -- (^[A-Z]:)|

    local partsIterator = string.gmatch(path,
        M.any_path_separator_regex .. M.not_any_path_separator_regex .. "*")

    local parts = {}
    for part in partsIterator do
        if string.len(part) > 0 then
            table.insert(parts, part)
        end
    end

    result.parts = parts
    return result
end

function M.absolutePath(basePath, relativePath)
    local relativeParts = M.parse(relativePath)
    if relativeParts.drive ~= nil then
        return relativePath
    end

    if #relativeParts.parts == 0 then
        return basePath
    end

    local newParts = {}
    local function appendParts(parts)
        for _, part in ipairs(parts) do
            if part == ".." and #newParts ~= 0 then
                table.remove(newParts, #newParts)
            elseif part ~= "." then
                table.insert(newParts, part)
            end
        end
    end

    local baseParts = M.parse(basePath)
    appendParts(baseParts.parts)
    appendParts(relativeParts.parts)

    local resultParts =
    {
        drive = baseParts.drive,
        parts = newParts,
    }

    return M.joinParts(resultParts)
end

function M.currentFilePath()
    return vim.fn.expand("%:p")
end

function M.currentFileDirectoryPath()
    return vim.fn.expand("%:p:h")
end

return M
