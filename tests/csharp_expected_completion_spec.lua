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

local function with_fake_roslyn(signatureHelp, completionItems, callback)
    local originalGetClients = vim.lsp.get_clients
    local fakeClient = {
        id = 10,
        name = "roslyn",
        offset_encoding = "utf-16",
    }

    function fakeClient:request(method, params, handler, bufnr)
        if method == "textDocument/signatureHelp" then
            handler(nil, signatureHelp)
        elseif method == "textDocument/completion" then
            handler(nil, { items = completionItems })
        elseif method == "workspace/symbol" then
            handler(nil, {})
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

    local ok, err = pcall(callback)
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
        function()
            local response = complete_argument(csharpExpectedCompletion.new())

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
        end
    )

    vim.cmd("qa!")
end

run()
