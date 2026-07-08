local function assert_equal(actual, expected, context)
    if vim.deep_equal(actual, expected) then
        return
    end

    error(
        string.format(
            "%s\nexpected:\n%s\nactual:\n%s",
            context,
            vim.inspect(expected),
            vim.inspect(actual)
        )
    )
end

local function configure_runtime()
    local config_dir = vim.fn.getcwd()

    vim.opt.runtimepath:prepend(config_dir)
end

local function completion_labels(items)
    local result = {}
    for _, item in ipairs(items) do
        table.insert(result, item.label)
    end

    return result
end

local function first_labels(items, count)
    local result = {}
    for index = 1, math.min(count, #items) do
        table.insert(result, items[index].label)
    end

    return result
end

local function with_fake_roslyn(configOrSignatureHelp, completionItemsOrCallback, maybeCallback)
    local config
    local callback
    if type(maybeCallback) == "function" then
        config = {
            signatureHelp = configOrSignatureHelp,
            completionItems = completionItemsOrCallback,
        }
        callback = maybeCallback
    else
        config = configOrSignatureHelp or {}
        callback = completionItemsOrCallback
    end

    local originalGetClients = vim.lsp.get_clients
    local requests = {}
    local fakeClient = {
        id = 10,
        name = "roslyn",
        offset_encoding = "utf-16",
    }

    function fakeClient:request(method, params, handler, bufnr)
        table.insert(requests, {
            method = method,
            params = params,
        })

        local handlerFn = config.handlers and config.handlers[method] or nil
        if handlerFn then
            handlerFn(params, handler, requests)
        elseif method == "textDocument/signatureHelp" then
            handler(nil, config.signatureHelp)
        elseif method == "textDocument/completion" then
            handler(nil, { items = config.completionItems or {} })
        elseif method == "workspace/symbol" then
            handler(nil, config.workspaceSymbols or {})
        elseif method == "textDocument/documentSymbol" then
            handler(nil, config.documentSymbols or {})
        else
            handler(nil, nil)
        end
    end

    vim.lsp.get_clients = function(opts)
        if opts and opts.method then
            return { fakeClient }
        end

        return {}
    end

    local ok, err = pcall(callback, requests)
    vim.lsp.get_clients = originalGetClients
    if not ok then
        error(err)
    end
end

local function complete_argument(source)
    local response
    source:complete({
        completion_context = {
            triggerKind = 1,
        },
    }, function(result)
        response = result
    end)

    return response
end

local function prepare_cs_buffer(lines)
    vim.cmd("enew!")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.filetype = "cs"

    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

    local lastLine = lines[#lines]
    vim.api.nvim_win_set_cursor(0, { #lines, #lastLine })
end

local function run()
    configure_runtime()

    local csharpExpectedCompletion = require("core.csharp_expected_completion")

    prepare_cs_buffer({
        "class Example",
        "{",
        "    void Build()",
        "    {",
        "        Thing localThing = new Thing();",
        "        SomeType value = new(",
    })

    with_fake_roslyn(
        {
            activeSignature = 0,
            activeParameter = 0,
            signatures = {
                {
                    label = "SomeType.SomeType(Thing dependency, string name)",
                },
            },
        },
        {
            {
                label = "wrongName",
                kind = 6,
                detail = "string wrongName",
            },
            {
                label = "localThing",
                kind = 6,
            },
            {
                label = "ThingProvider.Default",
                kind = 5,
                detail = "static Thing ThingProvider.Default",
            },
        },
        function(requests)
            local source = csharpExpectedCompletion.new()
            local response = complete_argument(source)

            assert_equal(
                completion_labels(response.items),
                {
                    "localThing",
                    "ThingProvider.Default",
                    "dependency:",
                    "name:",
                    "new Thing()",
                },
                "C# argument completion should prefer type-compatible values before named arguments"
            )

            assert_equal(
                {
                    response.items[3].insertText,
                    response.items[4].insertText,
                },
                {
                    "dependency: $0",
                    "name: $0",
                },
                "C# named argument completions should insert named argument snippets"
            )

            local requestCount = #requests
            source:resolve(response.items[3], function(resolved)
                assert_equal(
                    resolved,
                    response.items[3],
                    "C# synthetic named argument completion should resolve locally"
                )
            end)

            response.items[3].command = {
                command = "synthetic.command",
            }
            source:execute(response.items[3], function(executed)
                assert_equal(
                    executed,
                    response.items[3],
                    "C# synthetic named argument completion should execute locally"
                )
            end)

            assert_equal(
                #requests,
                requestCount,
                "C# synthetic named argument completion should not call Roslyn on confirm"
            )
        end
    )

    prepare_cs_buffer({
        "class Example",
        "{",
        "    void Build()",
        "    {",
        "        _importer.ImportAll(context, [",
        "            DocumentType.ScannedPdf,",
        "            DocumentType.ThesisPdf,",
        "            Do",
    })

    with_fake_roslyn({
        signatureHelp = {
            activeSignature = 0,
            activeParameter = 1,
            signatures = {
                {
                    label = "Importer.ImportAll(Context context, IReadOnlyCollection<DocumentType> documentTypes)",
                },
            },
        },
        completionItems = {
            {
                label = "DocumentType",
                kind = 7,
            },
        },
        workspaceSymbols = {
            {
                name = "DocumentType",
                kind = 10,
                location = {
                    uri = "file:///tmp/DocumentType.cs",
                    range = {
                        start = { line = 0, character = 5 },
                        ["end"] = { line = 4, character = 1 },
                    },
                },
            },
        },
        documentSymbols = {
            {
                name = "DocumentType",
                kind = 10,
                range = {
                    start = { line = 0, character = 5 },
                    ["end"] = { line = 4, character = 1 },
                },
                selectionRange = {
                    start = { line = 0, character = 5 },
                    ["end"] = { line = 0, character = 17 },
                },
                children = {
                    {
                        name = "ScannedPdf",
                        kind = 22,
                    },
                    {
                        name = "ThesisPdf",
                        kind = 22,
                    },
                    {
                        name = "BankStatementPdf",
                        kind = 22,
                    },
                },
            },
        },
    }, function(requests)
        local source = csharpExpectedCompletion.new()
        local response = complete_argument(source)

        assert_equal(
            first_labels(response.items, 3),
            {
                "DocumentType.ScannedPdf",
                "DocumentType.ThesisPdf",
                "DocumentType.BankStatementPdf",
            },
            "C# collection argument completion should suggest all enum members using the Roslyn element type"
        )

        assert_equal(
            vim.tbl_contains(vim.tbl_map(function(request)
                return request.method
            end, requests), "textDocument/documentSymbol"),
            true,
            "C# enum member completion should backfill missing members from Roslyn symbols"
        )
    end)

    prepare_cs_buffer({
        "class Example",
        "{",
        "    void Build()",
        "    {",
        "        _importer.ImportAll(context, [",
        "            DocumentType.ScannedPdf,",
        "            Do",
    })

    with_fake_roslyn({
        signatureHelp = {
            activeSignature = 0,
            activeParameter = 1,
            signatures = {
                {
                    label = "Importer.ImportAll(Context context, IReadOnlyCollection<DocumentType> documentTypes)",
                },
            },
        },
        completionItems = {
            {
                label = "DocumentType.ScannedPdf",
                kind = 20,
            },
        },
        handlers = {
            ["workspace/symbol"] = function(params, handler)
                handler({ code = -32603, message = "workspace symbol failed" }, nil)
            end,
        },
    }, function()
        local source = csharpExpectedCompletion.new()
        local response = complete_argument(source)

        assert_equal(
            first_labels(response.items, 1),
            {
                "DocumentType.ScannedPdf",
            },
            "C# enum member completion should keep working when Roslyn symbol lookup fails"
        )
    end)

    vim.cmd("qa!")
end

run()
