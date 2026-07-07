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

local function replace_word(line, start_col, end_col, new_text)
    return {
        range = {
            start = { line = line, character = start_col },
            ["end"] = { line = line, character = end_col },
        },
        newText = new_text,
    }
end

local function buffer_lines(bufnr)
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function run()
    configure_runtime()

    local renameUndo = require("core.lsp_rename_undo")
    local root = vim.fn.tempname()
    vim.fn.mkdir(root, "p")

    local first = root .. "/first.lua"
    local second = root .. "/second.lua"
    vim.fn.writefile({ "local alpha = 1", "return alpha" }, first)
    vim.fn.writefile({ "local alpha = 2", "return alpha" }, second)

    vim.cmd.edit(vim.fn.fnameescape(first))
    local firstBufnr = vim.api.nvim_get_current_buf()
    local secondBufnr = vim.uri_to_bufnr(vim.uri_from_fname(second))

    renameUndo.applyWorkspaceEdit(
        {
            changes =
            {
                [vim.uri_from_fname(first)] =
                {
                    replace_word(0, 6, 11, "beta"),
                    replace_word(1, 7, 12, "beta"),
                },
                [vim.uri_from_fname(second)] =
                {
                    replace_word(0, 6, 11, "beta"),
                    replace_word(1, 7, 12, "beta"),
                },
            },
        },
        "utf-16")

    assert_equal(
        buffer_lines(firstBufnr),
        { "local beta = 1", "return beta" },
        "rename should edit the current buffer")
    assert_equal(
        buffer_lines(secondBufnr),
        { "local beta = 2", "return beta" },
        "rename should edit another affected file")

    vim.cmd("normal u")

    assert_equal(
        buffer_lines(firstBufnr),
        { "local alpha = 1", "return alpha" },
        "u should undo the rename in the current buffer")
    assert_equal(
        buffer_lines(secondBufnr),
        { "local alpha = 2", "return alpha" },
        "u should undo the rename in every affected buffer")

    vim.fn.delete(root, "rf")
    vim.cmd("qa!")
end

run()
