local function assert_equal(actual, expected, context)
    if vim.deep_equal(actual, expected) then
        return
    end

    error(
        string.format(
            "%s\nexpected:\n%s\nactual:\n%s",
            context,
            table.concat(expected, "\n"),
            table.concat(actual, "\n")
        )
    )
end

local function configure_runtime()
    local config_dir = vim.fn.getcwd()

    vim.opt.runtimepath:prepend(config_dir)
    vim.opt.runtimepath:append(config_dir .. "/after")
    vim.cmd("filetype plugin indent on")
end

local function reindent_cs(lines)
    vim.cmd("enew!")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.filetype = "cs"

    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd("silent normal! gg=G")

    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function assert_reindents(lines, expected, context)
    assert_equal(reindent_cs(lines), expected, context)
end

local function run()
    configure_runtime()

    assert_reindents(
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new",
            "{",
            "}",
        },
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new",
            "    {",
            "    }",
        },
        "C# lambda object initializer braces should align with the call chain"
    )

    assert_reindents(
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new",
            "{",
            "Value = 1,",
            "}",
        },
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new",
            "    {",
            "        Value = 1,",
            "    }",
        },
        "C# lambda object initializer contents should stay one shiftwidth inside"
    )

    assert_reindents(
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new",
            "{",
            "}",
            ");",
        },
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new",
            "    {",
            "    }",
            "    );",
        },
        "C# lambda object initializer should keep following call terminator aligned"
    )

    assert_reindents(
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new // keep this comment",
            "{",
            "Value = 1,",
            "});",
        },
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x => new // keep this comment",
            "    {",
            "        Value = 1,",
            "    });",
        },
        "C# lambda object initializer should allow a trailing comment after new"
    )

    assert_reindents(
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x =>",
            "{",
            "return x.ThesisPdfData;",
            "});",
        },
        {
            "f.DependsOn(x => x.ThesisPdfData)",
            "    .RecreateWhenAnyOfTheseChange(x =>",
            "    {",
            "        return x.ThesisPdfData;",
            "    });",
        },
        "C# lambda block braces should still align with the call chain"
    )

    assert_reindents(
        {
            "items.Select(x =>",
            "{",
            "return x;",
            "});",
        },
        {
            "items.Select(x =>",
            "{",
            "    return x;",
            "});",
        },
        "C# top-level lambda block braces should stay aligned with the lambda line"
    )

    vim.cmd("qa!")
end

run()
