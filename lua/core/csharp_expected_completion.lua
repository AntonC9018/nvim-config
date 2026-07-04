local M = {}

local COMPLETION_KIND = {
    EnumMember = 20,
}

local SYMBOL_KIND = {
    Class = 5,
    Enum = 10,
    Interface = 11,
}

local MANUAL_TRIGGER = 1
local SIGNATURE_HELP_INVOKED = 1
local TIMEOUT_MS = 5000

local function trim(value)
    local result = (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return result
end

local function findRoslynClient(bufnr, method)
    return vim.iter(vim.lsp.get_clients({
        bufnr = bufnr,
        method = method,
    })):find(function(client)
        return client.name == "roslyn"
    end)
end

local function request(client, method, params, bufnr, callback)
    client:request(method, params, function(err, result)
        if err then
            callback(nil)
            return
        end

        callback(result)
    end, bufnr)
end

local function completionItems(response)
    if not response then
        return {}
    end

    if vim.islist(response) then
        return response
    end

    return response.items or {}
end

local function normalizeTypeName(typeName)
    typeName = trim(typeName)
    typeName = typeName:gsub("^global::", "")
    typeName = typeName:gsub("%?$", "")
    typeName = typeName:gsub("%s+", " ")
    return typeName
end

local function removeGenericArguments(typeName)
    local result = {}
    local depth = 0

    for i = 1, #typeName do
        local character = typeName:sub(i, i)
        if character == "<" then
            depth = depth + 1
        elseif character == ">" then
            depth = math.max(depth - 1, 0)
        elseif depth == 0 then
            table.insert(result, character)
        end
    end

    return table.concat(result)
end

local function shortTypeName(typeName)
    typeName = normalizeTypeName(removeGenericArguments(typeName))
    typeName = typeName:gsub("%[%]$", "")
    return typeName:match("([_%a][_%w]*)$") or typeName
end

local ignoredDeclarationTypes = {
    ["await"] = true,
    ["case"] = true,
    ["catch"] = true,
    ["else"] = true,
    ["fixed"] = true,
    ["for"] = true,
    ["foreach"] = true,
    ["if"] = true,
    ["lock"] = true,
    ["return"] = true,
    ["switch"] = true,
    ["using"] = true,
    ["while"] = true,
}

local function inferredVarType(initializer)
    return initializer and initializer:match("^new%s+([_%a][_%w%.<>]*)")
end

local function parseVariableDeclaration(line)
    line = line:gsub("//.*$", "")

    local typeName, name, initializer = line:match(
        "^%s*([_%a][_%w%.<>%[%]%?]*)%s+([_%a][_%w]*)%s*=%s*(.-)%s*;?%s*$")
    if not typeName then
        typeName, name = line:match("^%s*([_%a][_%w%.<>%[%]%?]*)%s+([_%a][_%w]*)%s*;%s*$")
    end

    if not typeName or ignoredDeclarationTypes[typeName] then
        return nil, nil
    end

    if typeName == "var" then
        typeName = inferredVarType(initializer)
    end

    if not typeName then
        return nil, nil
    end

    return name, normalizeTypeName(typeName)
end

local function localVariableTypesBeforeCursor(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
    if #lines == 0 then
        return {}
    end

    lines[#lines] = lines[#lines]:sub(1, cursor[2])

    local result = {}
    for _, line in ipairs(lines) do
        local name, typeName = parseVariableDeclaration(line)
        if name and typeName then
            result[name] = typeName
        end
    end

    return result
end

local function splitTopLevelParameters(parameterList)
    local result = {}
    local start = 1
    local depth = 0
    local openers = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
        ["<"] = ">",
    }
    local closing = {
        [")"] = true,
        ["]"] = true,
        ["}"] = true,
        [">"] = true,
    }

    for i = 1, #parameterList do
        local character = parameterList:sub(i, i)
        if openers[character] then
            depth = depth + 1
        elseif closing[character] then
            depth = math.max(depth - 1, 0)
        elseif character == "," and depth == 0 then
            table.insert(result, trim(parameterList:sub(start, i - 1)))
            start = i + 1
        end
    end

    table.insert(result, trim(parameterList:sub(start)))
    return result
end

local function signatureParameterList(label)
    local firstParen = label:find("%(")
    if not firstParen then
        return nil
    end

    local depth = 0
    for i = firstParen, #label do
        local character = label:sub(i, i)
        if character == "(" then
            depth = depth + 1
        elseif character == ")" then
            depth = depth - 1
            if depth == 0 then
                return label:sub(firstParen + 1, i - 1)
            end
        end
    end
end

local function stripLeadingAttributes(parameter)
    while parameter:sub(1, 1) == "[" do
        local depth = 0
        local closeIndex = nil

        for i = 1, #parameter do
            local character = parameter:sub(i, i)
            if character == "[" then
                depth = depth + 1
            elseif character == "]" then
                depth = depth - 1
                if depth == 0 then
                    closeIndex = i
                    break
                end
            end
        end

        if not closeIndex then
            break
        end

        parameter = trim(parameter:sub(closeIndex + 1))
    end

    return parameter
end

local function expectedTypeFromParameter(parameter)
    parameter = stripLeadingAttributes(trim(parameter:gsub("%s*=.*$", "")))
    parameter = parameter:gsub("^this%s+", "")
    parameter = parameter:gsub("^ref%s+", "")
    parameter = parameter:gsub("^out%s+", "")
    parameter = parameter:gsub("^in%s+", "")
    parameter = parameter:gsub("^params%s+", "")
    parameter = parameter:gsub("^scoped%s+", "")

    local typeName = parameter:match("^(.-)%s+[_%a][_%w]*$")
    if not typeName or typeName == "" then
        return nil
    end

    typeName = normalizeTypeName(typeName)
    return {
        name = typeName,
        shortName = shortTypeName(typeName),
    }
end

local function expectedTypeFromSignature(signatureHelp)
    if not signatureHelp or not signatureHelp.signatures then
        return nil
    end

    local signature = signatureHelp.signatures[(signatureHelp.activeSignature or 0) + 1]
    if not signature or not signature.label then
        return nil
    end

    local parameters = splitTopLevelParameters(signatureParameterList(signature.label) or "")
    local parameter = parameters[(signatureHelp.activeParameter or 0) + 1]
    if not parameter then
        return nil
    end

    return expectedTypeFromParameter(parameter)
end

local function signatureHelp(client, bufnr, callback)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = {
        triggerKind = SIGNATURE_HELP_INVOKED,
        isRetrigger = false,
    }

    request(client, "textDocument/signatureHelp", params, bufnr, callback)
end

local function roslynCompletion(client, bufnr, triggerContext, callback)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = {
        triggerKind = triggerContext.triggerKind,
        triggerCharacter = triggerContext.triggerCharacter,
    }

    request(client, "textDocument/completion", params, bufnr, function(response)
        callback(completionItems(response))
    end)
end

local function uriLines(uri)
    local filename = vim.uri_to_fname(uri)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) == filename then
            return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        end
    end

    local ok, lines = pcall(vim.fn.readfile, filename)
    if ok then
        return lines
    end

    return {}
end

local function implementationName(location)
    local uri = location.uri or location.targetUri
    local range = location.targetSelectionRange or location.range
    if not uri or not range or not range.start then
        return nil
    end

    local lines = uriLines(uri)
    local line = lines[range.start.line + 1] or ""
    local afterCursor = line:sub(range.start.character + 1)
    return afterCursor:match("^%s*([_%a][_%w]*)")
end

local function implementationNames(self, client, bufnr, expectedType, callback)
    local cacheKey = table.concat({ client.id, expectedType.name }, ":")
    local cached = self.implementationCache[cacheKey]
    if cached then
        callback(cached)
        return
    end

    request(client, "workspace/symbol", { query = expectedType.shortName }, bufnr, function(symbols)
        local names = {}
        for _, item in ipairs(symbols or {}) do
            if item.name ~= expectedType.shortName and item.kind == SYMBOL_KIND.Class then
                names[item.name] = true
            end
        end

        local symbol = vim.iter(symbols or {}):find(function(item)
            return item.name == expectedType.shortName
                and (item.kind == SYMBOL_KIND.Interface
                    or item.kind == SYMBOL_KIND.Class
                    or item.kind == SYMBOL_KIND.Enum)
                and item.location
        end)

        if next(names) or not symbol then
            self.implementationCache[cacheKey] = names
            callback(names)
            return
        end

        request(client, "textDocument/implementation", {
            textDocument = { uri = symbol.location.uri },
            position = symbol.location.range.start,
        }, bufnr, function(locations)
            for _, location in ipairs(locations or {}) do
                local name = implementationName(location)
                if name then
                    names[name] = true
                end
            end

            self.implementationCache[cacheKey] = names
            callback(names)
        end)
    end)
end

local function isExactType(typeName, expectedType)
    if not typeName then
        return false
    end

    local normalized = normalizeTypeName(typeName)
    return normalized == expectedType.name
        or shortTypeName(normalized) == expectedType.shortName
end

local function isExpectedEnumMember(item, expectedType)
    return item.kind == COMPLETION_KIND.EnumMember
        and type(item.label) == "string"
        and vim.startswith(item.label, expectedType.shortName .. ".")
end

local function isCompatibleItem(item, expectedType, implementations, localVariables)
    if isExpectedEnumMember(item, expectedType) then
        return true
    end

    local itemType = type(item.label) == "string" and localVariables[item.label] or nil
    if isExactType(itemType, expectedType) then
        return true
    end

    if itemType and implementations[shortTypeName(itemType)] then
        return true
    end

    return false
end

local function markExpectedItem(item)
    item = vim.deepcopy(item)
    item.sortText = "0000_expected_" .. (item.sortText or item.label)
    item.dup = 0
    return item
end

local function expectedEnumMembers(items, expectedType)
    local result = {}
    local seen = {}

    for _, item in ipairs(items) do
        if not seen[item.label] and isExpectedEnumMember(item, expectedType) then
            table.insert(result, markExpectedItem(item))
            seen[item.label] = true
        end
    end

    return result
end

local source = {}
source.__index = source

function source:get_debug_name()
    return "roslyn_expected_arg"
end

function source:is_available()
    return vim.bo.filetype == "cs"
        and findRoslynClient(vim.api.nvim_get_current_buf(), "textDocument/completion") ~= nil
end

function source:get_position_encoding_kind()
    local client = findRoslynClient(vim.api.nvim_get_current_buf(), "textDocument/completion")
    return client and (client.offset_encoding or "utf-16") or "utf-16"
end

function source:complete(params, callback)
    if params.completion_context.triggerKind ~= MANUAL_TRIGGER then
        callback({})
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local client = findRoslynClient(bufnr, "textDocument/completion")
    if not client then
        callback({})
        return
    end

    local done = false
    local function finish(items)
        if done then
            return
        end

        done = true
        callback({
            items = items or {},
            isIncomplete = false,
        })
    end

    vim.defer_fn(function()
        finish({})
    end, TIMEOUT_MS)

    signatureHelp(client, bufnr, function(help)
        local expectedType = expectedTypeFromSignature(help)
        if not expectedType then
            finish({})
            return
        end

        roslynCompletion(client, bufnr, params.completion_context, function(items)
            local localVariables = localVariableTypesBeforeCursor(bufnr)
            local enumMembers = expectedEnumMembers(items, expectedType)
            if #enumMembers > 0 then
                local seen = {}
                for _, item in ipairs(enumMembers) do
                    seen[item.label] = true
                end
                for _, item in ipairs(items) do
                    if not seen[item.label]
                        and isCompatibleItem(item, expectedType, {}, localVariables)
                    then
                        table.insert(enumMembers, markExpectedItem(item))
                        seen[item.label] = true
                    end
                end
                finish(enumMembers)
                return
            end

            implementationNames(self, client, bufnr, expectedType, function(implementations)
                local result = {}
                local seen = {}
                for _, item in ipairs(items) do
                    if not seen[item.label] and isCompatibleItem(item, expectedType, implementations, localVariables) then
                        table.insert(result, markExpectedItem(item))
                        seen[item.label] = true
                    end
                end

                finish(result)
            end)
        end)
    end)
end

function source:resolve(completionItem, callback)
    local client = findRoslynClient(vim.api.nvim_get_current_buf(), "textDocument/completion")
    if not client then
        callback(completionItem)
        return
    end

    request(client, "completionItem/resolve", completionItem, vim.api.nvim_get_current_buf(), function(resolved)
        callback(resolved or completionItem)
    end)
end

function source:execute(completionItem, callback)
    if not completionItem.command then
        callback(completionItem)
        return
    end

    local client = findRoslynClient(vim.api.nvim_get_current_buf(), "textDocument/completion")
    if not client then
        callback(completionItem)
        return
    end

    request(client, "workspace/executeCommand", completionItem.command, vim.api.nvim_get_current_buf(), function()
        callback(completionItem)
    end)
end

function M.new()
    return setmetatable({
        implementationCache = {},
    }, source)
end

return M
