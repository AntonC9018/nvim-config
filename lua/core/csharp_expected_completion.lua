local M = {}

local COMPLETION_KIND = {
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Property = 10,
    EnumMember = 20,
    Constant = 21,
}

local SYMBOL_KIND = {
    Class = 5,
    Enum = 10,
    Interface = 11,
}

local INVOKED_TRIGGER = 1
local SIGNATURE_HELP_INVOKED = 1
local TIMEOUT_MS = 5000
local INSERT_TEXT_FORMAT_SNIPPET = 2
local SYNTHETIC_COMPLETION_ITEM = "__roslyn_expected_arg_synthetic"
local ORIGINAL_COMPLETION_ITEM = "__roslyn_expected_arg_original"

local typeAliases = {
    Boolean = "bool",
    Byte = "byte",
    Char = "char",
    Decimal = "decimal",
    Double = "double",
    Int16 = "short",
    Int32 = "int",
    Int64 = "long",
    Object = "object",
    SByte = "sbyte",
    Single = "float",
    String = "string",
    UInt16 = "ushort",
    UInt32 = "uint",
    UInt64 = "ulong",
}

local builtinTypeNames = {
    ["bool"] = true,
    ["byte"] = true,
    ["char"] = true,
    ["decimal"] = true,
    ["double"] = true,
    ["dynamic"] = true,
    ["float"] = true,
    ["int"] = true,
    ["long"] = true,
    ["nint"] = true,
    ["nuint"] = true,
    ["object"] = true,
    ["sbyte"] = true,
    ["short"] = true,
    ["string"] = true,
    ["uint"] = true,
    ["ulong"] = true,
    ["ushort"] = true,
    ["void"] = true,
}

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
    typeName = typeName:gsub("^System%.([_%a][_%w]*)$", function(systemType)
        return typeAliases[systemType] or ("System." .. systemType)
    end)
    typeName = typeAliases[typeName] or typeName
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
    line = line:gsub("^%s*const%s+", "")

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

local parameterTypesBeforeCursor

local function localVariableTypesBeforeCursor(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
    if #lines == 0 then
        return {}
    end

    lines[#lines] = lines[#lines]:sub(1, cursor[2])

    local result = parameterTypesBeforeCursor and parameterTypesBeforeCursor(bufnr) or {}
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

local function parameterNameAndType(parameter)
    parameter = stripLeadingAttributes(trim(parameter:gsub("%s*=.*$", "")))
    parameter = parameter:gsub("^this%s+", "")
    parameter = parameter:gsub("^ref%s+", "")
    parameter = parameter:gsub("^out%s+", "")
    parameter = parameter:gsub("^in%s+", "")
    parameter = parameter:gsub("^params%s+", "")
    parameter = parameter:gsub("^scoped%s+", "")

    local typeName, name = parameter:match("^(.-)%s+([_%a][_%w]*)$")
    if not typeName or typeName == "" then
        return nil, nil
    end

    return name, normalizeTypeName(typeName)
end

local function expectedTypeFromTypeName(typeName)
    typeName = normalizeTypeName(typeName)
    return {
        name = typeName,
        shortName = shortTypeName(typeName),
    }
end

local declarationParameterListKeywords = {
    ["catch"] = true,
    ["checked"] = true,
    ["fixed"] = true,
    ["for"] = true,
    ["foreach"] = true,
    ["if"] = true,
    ["lock"] = true,
    ["switch"] = true,
    ["unchecked"] = true,
    ["using"] = true,
    ["while"] = true,
}

local function addParameterTypesFromDeclaration(result, declaration)
    declaration = declaration:gsub("//.*$", "")

    local name, parameterList = declaration:match("([_%a][_%w]*)%s*%((.*)%)%s*[{=>]")
    if not name or declarationParameterListKeywords[name] then
        return
    end

    for _, parameter in ipairs(splitTopLevelParameters(parameterList)) do
        local parameterName, typeName = parameterNameAndType(parameter)
        if parameterName and typeName then
            result[parameterName] = typeName
        end
    end
end

parameterTypesBeforeCursor = function(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
    if #lines == 0 then
        return {}
    end

    lines[#lines] = lines[#lines]:sub(1, cursor[2])

    local result = {}
    local pending = nil
    for _, line in ipairs(lines) do
        local current = trim(line)
        if pending then
            pending = pending .. " " .. current
            if current:find("[{=>]") then
                addParameterTypesFromDeclaration(result, pending)
                pending = nil
            end
        elseif current:find("%(") and not current:find(";") then
            pending = current
            if current:find("[{=>]") then
                addParameterTypesFromDeclaration(result, pending)
                pending = nil
            end
        end
    end

    return result
end

local function signatureContext(signatureHelp)
    if not signatureHelp or not signatureHelp.signatures then
        return nil
    end

    local signature = signatureHelp.signatures[(signatureHelp.activeSignature or 0) + 1]
    if not signature or not signature.label then
        return nil
    end

    local parameters = {}
    for index, parameter in ipairs(splitTopLevelParameters(signatureParameterList(signature.label) or "")) do
        local parameterName, typeName = parameterNameAndType(parameter)
        local expectedType = typeName and expectedTypeFromTypeName(typeName) or expectedTypeFromParameter(parameter)
        table.insert(parameters, {
            index = index,
            name = parameterName,
            typeName = typeName,
            expectedType = expectedType,
        })
    end

    local activeParameterIndex = (signatureHelp.activeParameter or 0) + 1
    if not parameters[activeParameterIndex] then
        return nil
    end

    return {
        activeParameterIndex = activeParameterIndex,
        activeParameter = parameters[activeParameterIndex],
        parameters = parameters,
    }
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

local function implementationSymbolQueries(expectedType)
    local queries = { expectedType.shortName }
    local interfaceQuery = expectedType.shortName:match("^I(%u.*)$")
    if interfaceQuery then
        table.insert(queries, interfaceQuery)
    end

    return queries
end

local function workspaceSymbols(client, bufnr, queries, callback)
    local result = {}
    local index = 1

    local function nextQuery()
        local query = queries[index]
        if not query then
            callback(result)
            return
        end

        request(client, "workspace/symbol", { query = query }, bufnr, function(symbols)
            vim.list_extend(result, symbols or {})
            index = index + 1
            nextQuery()
        end)
    end

    nextQuery()
end

local function implementationInfo(self, client, bufnr, expectedType, callback)
    local cacheKey = table.concat({ client.id, expectedType.name }, ":")
    local cached = self.implementationCache[cacheKey]
    if cached then
        callback(cached)
        return
    end

    workspaceSymbols(client, bufnr, implementationSymbolQueries(expectedType), function(symbols)
        local info = {
            expectedSymbolKind = nil,
            implementations = {},
        }

        for _, item in ipairs(symbols or {}) do
            if item.name ~= expectedType.shortName and item.kind == SYMBOL_KIND.Class then
                info.implementations[item.name] = true
            end
        end

        local symbol = vim.iter(symbols or {}):find(function(item)
            return item.name == expectedType.shortName
                and (item.kind == SYMBOL_KIND.Interface
                    or item.kind == SYMBOL_KIND.Class
                    or item.kind == SYMBOL_KIND.Enum)
        end)

        info.expectedSymbolKind = symbol and symbol.kind or nil
        if next(info.implementations) or not symbol or symbol.kind == SYMBOL_KIND.Enum or not symbol.location then
            self.implementationCache[cacheKey] = info
            callback(info)
            return
        end

        request(client, "textDocument/implementation", {
            textDocument = { uri = symbol.location.uri },
            position = symbol.location.range.start,
        }, bufnr, function(locations)
            for _, location in ipairs(locations or {}) do
                local name = implementationName(location)
                if name then
                    info.implementations[name] = true
                end
            end

            self.implementationCache[cacheKey] = info
            callback(info)
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

local function stripDetailModifiers(detail)
    local changed = true
    while changed do
        changed = false
        detail = detail:gsub("^%s*const%s+", function()
            changed = true
            return ""
        end)
        detail = detail:gsub("^%s*static%s+", function()
            changed = true
            return ""
        end)
        detail = detail:gsub("^%s*readonly%s+", function()
            changed = true
            return ""
        end)
    end

    return trim(detail)
end

local function detailTypeName(detail)
    detail = stripDetailModifiers(trim(detail or ""))
    if detail == "" then
        return nil
    end

    local typeName = detail:match("^([_%a][_%w%.<>%[%]%?]*)%s+[_%a][_%w%.]*")
    if typeName then
        return normalizeTypeName(typeName)
    end

    return nil
end

local function itemDetailMatchesExpectedType(item, expectedType)
    local detailType = detailTypeName(item.detail)
    return isExactType(detailType, expectedType)
end

local function isTypedItemKind(kind)
    return kind == COMPLETION_KIND.Constant
        or kind == COMPLETION_KIND.Method
        or kind == COMPLETION_KIND.Function
        or kind == COMPLETION_KIND.Field
        or kind == COMPLETION_KIND.Property
        or kind == COMPLETION_KIND.Variable
end

local function isTypedStaticOrConstantItem(item, expectedType)
    local kind = item.kind
    if not isTypedItemKind(kind) then
        return false
    end

    return itemDetailMatchesExpectedType(item, expectedType)
end

local function isExpectedTypeStaticMember(item, expectedType)
    if not isTypedItemKind(item.kind) or type(item.label) ~= "string" then
        return false
    end

    return vim.startswith(item.label, expectedType.shortName .. ".")
end

local function isCompatibleItem(item, expectedType, implementations, localVariables)
    if isExpectedEnumMember(item, expectedType) then
        return true
    end

    if isExpectedTypeStaticMember(item, expectedType) then
        return true
    end

    if isTypedStaticOrConstantItem(item, expectedType) then
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

local function markExpectedItem(item, rank)
    local originalItem = item[SYNTHETIC_COMPLETION_ITEM] ~= true and vim.deepcopy(item) or nil

    item = vim.deepcopy(item)
    item.sortText = string.format("0000_expected_%02d_%s", rank or 0, item.sortText or item.label)
    item.dup = 0
    if originalItem then
        item[ORIGINAL_COMPLETION_ITEM] = originalItem
    end

    return item
end

local function addExpectedItem(result, seen, item, rank)
    if not item.label or seen[item.label] then
        return
    end

    table.insert(result, markExpectedItem(item, rank))
    seen[item.label] = true
end

local function markSyntheticCompletionItem(item)
    item[SYNTHETIC_COMPLETION_ITEM] = true
    return item
end

local function isSyntheticCompletionItem(item)
    return item and item[SYNTHETIC_COMPLETION_ITEM] == true
end

local function roslynCompletionItem(item)
    return item and (item[ORIGINAL_COMPLETION_ITEM] or item) or nil
end

local function shouldResolveWithRoslyn(item)
    local lspItem = roslynCompletionItem(item)
    return lspItem and not isSyntheticCompletionItem(item) and lspItem.data ~= nil
end

local function looksLikeInterfaceName(typeName)
    return shortTypeName(typeName):match("^I%u") ~= nil
end

local function isConstructibleTypeName(typeName, info)
    local shortName = shortTypeName(typeName)
    if builtinTypeNames[shortName] then
        return false
    end

    if info.expectedSymbolKind == SYMBOL_KIND.Interface
        or info.expectedSymbolKind == SYMBOL_KIND.Enum
        or (not info.expectedSymbolKind and looksLikeInterfaceName(typeName))
    then
        return false
    end

    return shortName:match("^[_%u]") ~= nil
end

local function newExpressionItem(typeName)
    typeName = normalizeTypeName(typeName)
    local label = "new " .. typeName .. "()"
    return markSyntheticCompletionItem({
        label = label,
        kind = COMPLETION_KIND.Constructor,
        sortText = "0001_new_" .. typeName,
        filterText = "new " .. typeName,
        insertText = "new " .. typeName .. "($0)",
        insertTextFormat = INSERT_TEXT_FORMAT_SNIPPET,
        detail = "Create " .. typeName,
    })
end

local function addNewExpressionItems(result, seen, expectedType, info)
    if isConstructibleTypeName(expectedType.name, info) then
        addExpectedItem(result, seen, newExpressionItem(expectedType.name), 2)
    end

    local implementationNames = vim.tbl_keys(info.implementations)
    table.sort(implementationNames)
    for _, implementationName in ipairs(implementationNames) do
        addExpectedItem(result, seen, newExpressionItem(implementationName), 2)
    end
end

local function textBeforeCursor(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor[1], false)
    if #lines == 0 then
        return ""
    end

    lines[#lines] = lines[#lines]:sub(1, cursor[2])
    return table.concat(lines, "\n")
end

local function currentArgumentTextBeforeCursor(bufnr)
    local text = textBeforeCursor(bufnr)
    local depth = 0

    for index = #text, 1, -1 do
        local character = text:sub(index, index)
        if character == ")" then
            depth = depth + 1
        elseif character == "(" then
            if depth == 0 then
                return text:sub(index + 1)
            end

            depth = depth - 1
        end
    end

    return text
end

local function namedArgumentsBeforeCursor(bufnr)
    local result = {}
    for name in currentArgumentTextBeforeCursor(bufnr):gmatch("([_%a][_%w]*)%s*:") do
        result[name] = true
    end

    return result
end

local function namedArgumentItem(parameter, signature)
    local sortIndex = parameter.index == signature.activeParameterIndex
        and 0
        or (100 + parameter.index)
    local label = parameter.name .. ":"

    return markSyntheticCompletionItem({
        label = label,
        kind = COMPLETION_KIND.Property,
        sortText = string.format("%03d_%s", sortIndex, parameter.name),
        filterText = parameter.name,
        insertText = parameter.name .. ": $0",
        insertTextFormat = INSERT_TEXT_FORMAT_SNIPPET,
        detail = parameter.typeName and ("Named argument: " .. parameter.typeName) or "Named argument",
    })
end

local function addNamedArgumentItems(result, seen, signature, usedNamedArguments)
    if not signature then
        return
    end

    for _, parameter in ipairs(signature.parameters) do
        if parameter.name
            and parameter.index >= signature.activeParameterIndex
            and not usedNamedArguments[parameter.name]
        then
            addExpectedItem(result, seen, namedArgumentItem(parameter, signature), 1)
        end
    end
end

local function hasNamedArgumentItems(signature)
    if not signature then
        return false
    end

    for _, parameter in ipairs(signature.parameters) do
        if parameter.name and parameter.index >= signature.activeParameterIndex then
            return true
        end
    end

    return false
end

local function hasArgumentCompletionItems(signature)
    return signature
        and (signature.activeParameter.expectedType ~= nil or hasNamedArgumentItems(signature))
        or false
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
    if params.completion_context.triggerKind ~= INVOKED_TRIGGER then
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
        local signature = signatureContext(help)
        if not signature then
            finish({})
            return
        end

        local expectedType = signature.activeParameter.expectedType
        local usedNamedArguments = namedArgumentsBeforeCursor(bufnr)
        if not expectedType then
            local result = {}
            local seen = {}
            addNamedArgumentItems(result, seen, signature, usedNamedArguments)
            finish(result)
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
                        addExpectedItem(enumMembers, seen, item)
                    end
                end
                addNamedArgumentItems(enumMembers, seen, signature, usedNamedArguments)
                finish(enumMembers)
                return
            end

            implementationInfo(self, client, bufnr, expectedType, function(info)
                local result = {}
                local seen = {}
                for _, item in ipairs(items) do
                    if not seen[item.label]
                        and isCompatibleItem(item, expectedType, info.implementations, localVariables)
                    then
                        addExpectedItem(result, seen, item)
                    end
                end

                addNamedArgumentItems(result, seen, signature, usedNamedArguments)
                addNewExpressionItems(result, seen, expectedType, info)
                finish(result)
            end)
        end)
    end)
end

function source:resolve(completionItem, callback)
    if not shouldResolveWithRoslyn(completionItem) then
        callback(completionItem)
        return
    end

    local client = findRoslynClient(vim.api.nvim_get_current_buf(), "textDocument/completion")
    if not client then
        callback(completionItem)
        return
    end

    request(client, "completionItem/resolve", roslynCompletionItem(completionItem), vim.api.nvim_get_current_buf(), function(resolved)
        callback(resolved or completionItem)
    end)
end

function source:execute(completionItem, callback)
    if isSyntheticCompletionItem(completionItem) then
        callback(completionItem)
        return
    end

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

function M.complete_argument_or_fallback(cmp, fallback)
    if vim.bo.filetype ~= "cs" then
        return false
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local client = findRoslynClient(bufnr, "textDocument/completion")
    if not client then
        return false
    end

    signatureHelp(client, bufnr, function(help)
        if not vim.api.nvim_win_is_valid(win)
            or vim.api.nvim_win_get_buf(win) ~= bufnr
            or vim.api.nvim_get_mode().mode ~= "i"
        then
            return
        end

        local currentCursor = vim.api.nvim_win_get_cursor(win)
        if currentCursor[1] ~= cursor[1] or currentCursor[2] ~= cursor[2] then
            return
        end

        if hasArgumentCompletionItems(signatureContext(help)) then
            cmp.complete({
                config = {
                    sources = cmp.config.sources({
                        {
                            name = "roslyn_expected_arg",
                            keyword_length = 0,
                        },
                    }),
                },
            })
            return
        end

        fallback()
    end)

    return true
end

return M
