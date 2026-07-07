local M = {}

local pendingRename = nil
local nextRenameId = 0

local function getBufferKeymap(bufnr, lhs)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return nil
    end

    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
        if mapping.lhs == lhs then
            return mapping
        end
    end

    return nil
end

local function restoreBufferKeymap(bufnr, mapping)
    if mapping == nil or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    local action = mapping.callback or mapping.rhs
    if action == nil then
        return
    end

    local opts =
    {
        buffer = bufnr,
        expr = mapping.expr == 1,
        nowait = mapping.nowait == 1,
        silent = mapping.silent == 1,
        script = mapping.script == 1,
    }

    if mapping.desc ~= nil then
        opts.desc = mapping.desc
    end

    if mapping.replace_keycodes ~= nil then
        opts.replace_keycodes = mapping.replace_keycodes == 1
    end

    if mapping.noremap == 0 then
        opts.remap = true
    end

    vim.keymap.set("n", mapping.lhs, action, opts)
end

local function clearPendingRename()
    local pending = pendingRename
    pendingRename = nil

    if pending == nil then
        return
    end

    for bufnr, undoMapping in pairs(pending.undoMappings) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            local currentMapping = getBufferKeymap(bufnr, "u")
            if currentMapping ~= nil and currentMapping.callback == undoMapping.callback then
                pcall(vim.api.nvim_buf_del_keymap, bufnr, "n", "u")
                restoreBufferKeymap(bufnr, undoMapping.previous)
            end
        end
    end
end

local function normalUndo()
    local count = vim.v.count
    local command = "normal! "
    if count > 0 then
        command = command .. tostring(count)
    end
    vim.cmd(command .. "u")
end

local function validLoadedBuffer(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

local function pendingRenameIsCurrent(pending)
    for _, bufnr in ipairs(pending.buffers) do
        if not validLoadedBuffer(bufnr) then
            return false
        end

        if vim.api.nvim_buf_get_changedtick(bufnr) ~= pending.changedticks[bufnr] then
            return false
        end
    end

    return true
end

local function sortedBufferList(bufferSet)
    local buffers = vim.tbl_keys(bufferSet)
    table.sort(buffers)
    return buffers
end

local function workspaceEditInfo(workspaceEdit)
    local bufferSet = {}
    local hasResourceOperations = false

    if workspaceEdit.documentChanges ~= nil then
        for _, change in ipairs(workspaceEdit.documentChanges) do
            if change.kind ~= nil then
                hasResourceOperations = true
            elseif change.edits ~= nil and next(change.edits) ~= nil then
                bufferSet[vim.uri_to_bufnr(change.textDocument.uri)] = true
            end
        end
    end

    if workspaceEdit.changes ~= nil then
        for uri, changes in pairs(workspaceEdit.changes) do
            if changes ~= nil and next(changes) ~= nil then
                bufferSet[vim.uri_to_bufnr(uri)] = true
            end
        end
    end

    return
    {
        buffers = sortedBufferList(bufferSet),
        hasResourceOperations = hasResourceOperations,
    }
end

local function bufferChangedTicks(buffers)
    local changedticks = {}

    for _, bufnr in ipairs(buffers) do
        if validLoadedBuffer(bufnr) then
            changedticks[bufnr] = vim.api.nvim_buf_get_changedtick(bufnr)
        end
    end

    return changedticks
end

local function loadBuffers(buffers)
    for _, bufnr in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) and not vim.api.nvim_buf_is_loaded(bufnr) then
            vim.fn.bufload(bufnr)
        end
    end
end

local function bufferUndoSequences(buffers)
    local sequences = {}

    for _, bufnr in ipairs(buffers) do
        if validLoadedBuffer(bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
                sequences[bufnr] = vim.fn.undotree().seq_cur
            end)
        end
    end

    return sequences
end

local function changedBuffersAfterEdit(buffers, beforeChangedticks)
    local changedBuffers = {}

    for _, bufnr in ipairs(buffers) do
        if validLoadedBuffer(bufnr) then
            local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
            if beforeChangedticks[bufnr] ~= changedtick then
                changedBuffers[#changedBuffers + 1] = bufnr
            end
        end
    end

    return changedBuffers
end

local function undoBuffer(bufnr, sequence)
    if not validLoadedBuffer(bufnr) then
        return false
    end

    local ok = pcall(vim.api.nvim_buf_call, bufnr, function()
        vim.cmd("silent undo " .. tostring(sequence))
    end)

    return ok
end

local function buffersWithCurrentLast(buffers)
    local current = vim.api.nvim_get_current_buf()
    local result = {}
    local hasCurrent = false

    for _, bufnr in ipairs(buffers) do
        if bufnr == current then
            hasCurrent = true
        else
            result[#result + 1] = bufnr
        end
    end

    if hasCurrent then
        result[#result + 1] = current
    end

    return result
end

function M.undoPendingRename(expectedRenameId)
    local pending = pendingRename
    if pending == nil or pending.id ~= expectedRenameId then
        normalUndo()
        return
    end

    local current = vim.api.nvim_get_current_buf()
    if pending.bufferSet[current] ~= true or not pendingRenameIsCurrent(pending) then
        clearPendingRename()
        normalUndo()
        return
    end

    clearPendingRename()

    local failedBuffers = {}
    for _, bufnr in ipairs(buffersWithCurrentLast(pending.buffers)) do
        if not undoBuffer(bufnr, pending.undoSequences[bufnr]) then
            failedBuffers[#failedBuffers + 1] = vim.api.nvim_buf_get_name(bufnr)
        end
    end

    if #failedBuffers > 0 then
        vim.notify(
            "Failed to undo rename in: " .. table.concat(failedBuffers, ", "),
            vim.log.levels.WARN)
    end
end

local function installUndoMaps(buffers, undoSequences)
    nextRenameId = nextRenameId + 1
    local renameId = nextRenameId
    local bufferSet = {}
    local undoMappings = {}

    for _, bufnr in ipairs(buffers) do
        bufferSet[bufnr] = true
    end

    pendingRename =
    {
        id = renameId,
        buffers = buffers,
        bufferSet = bufferSet,
        changedticks = bufferChangedTicks(buffers),
        undoSequences = undoSequences,
        undoMappings = undoMappings,
    }

    for _, bufnr in ipairs(buffers) do
        local undoCallback = function()
            M.undoPendingRename(renameId)
        end

        undoMappings[bufnr] =
        {
            callback = undoCallback,
            previous = getBufferKeymap(bufnr, "u"),
        }

        vim.keymap.set("n", "u", undoCallback,
        {
            buffer = bufnr,
            desc = "Undo LSP rename across files",
            nowait = true,
        })
    end
end

function M.applyWorkspaceEdit(workspaceEdit, positionEncoding)
    local editInfo = workspaceEditInfo(workspaceEdit)
    local buffers = editInfo.buffers
    loadBuffers(buffers)
    local beforeChangedticks = bufferChangedTicks(buffers)
    local beforeUndoSequences = bufferUndoSequences(buffers)

    clearPendingRename()
    vim.lsp.util.apply_workspace_edit(workspaceEdit, positionEncoding)

    local changedBuffers = changedBuffersAfterEdit(buffers, beforeChangedticks)
    if #changedBuffers > 0 and not editInfo.hasResourceOperations then
        installUndoMaps(changedBuffers, beforeUndoSequences)
    end
end

local function lspErrorMessage(err)
    if type(err) == "table" then
        return err.message or vim.inspect(err)
    end

    return tostring(err)
end

function M.renameHandler(err, result, ctx)
    if err ~= nil then
        vim.notify("LSP rename failed: " .. lspErrorMessage(err), vim.log.levels.ERROR)
        return
    end

    if result == nil then
        vim.notify("Language server couldn't provide rename result", vim.log.levels.INFO)
        return
    end

    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client == nil then
        vim.notify("LSP rename failed: client is no longer available", vim.log.levels.ERROR)
        return
    end

    local ok, applyError = pcall(M.applyWorkspaceEdit, result, client.offset_encoding)
    if not ok then
        vim.notify("LSP rename failed: " .. tostring(applyError), vim.log.levels.ERROR)
    end
end

function M.rename(newName, opts)
    vim.lsp.buf.rename(newName, opts)
end

function M.setup()
    vim.lsp.handlers["textDocument/rename"] = M.renameHandler
end

return M
