local M = {}

---The file system path separator for the current platform.
M.path_separator = "/"
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1
if M.is_windows == true then
  M.path_separator = "\\"
end

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
  if type(args[1]) =="string" and args[1]:sub(1, 1) == M.path_separator then
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
    return vim.fn.fnamemodify(path, ":h")
end

--- @param path string
--- @return string
function M.getFileNameWithoutExtension(path)
    return vim.fn.fnamemodify(path, ":t:r")
end

--- @param path string
--- @param newExtension ?string
--- @return string
function M.withExtension(path, newExtension)
    local filePathWithoutExtension = vim.fn.fnamemodify(path, ":r")
    if newExtension == "" or newExtension == nil then
        return filePathWithoutExtension
    else
        return filePathWithoutExtension .. "." .. newExtension
    end
end

return M
