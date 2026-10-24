-- Exercise the actual DAP program callbacks without compiling during this test.
local dap = require("dap")
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/zig-out/bin", "p")
vim.fn.writefile({ "int main(void) { return 0; }" }, root .. "/fixture.c")
vim.cmd.edit(vim.fn.fnameescape(root .. "/fixture.c"))
local fixture_bufnr = vim.api.nvim_get_current_buf()
local original_system = vim.system
local original_shell = vim.fn.system
local original_cwd = vim.fn.getcwd()
local calls, exit_code = {}, 0
-- Keep old implementations harmless so the regression fails on its assertion.
vim.fn.system = function() return "" end
vim.system = function(argv, options)
    table.insert(calls, { argv = argv, options = options })
    return { wait = function() return { code = exit_code, stdout = "", stderr = "fixture build failed" } end }
end
local ok, err = xpcall(function()
    local output = dap.configurations.c[1].program()
    assert(#calls == 1, "C debug callback did not invoke a checked process")
    assert(vim.tbl_contains(calls[1].argv, "-g"), "C debug build has no debug symbols")
    assert(vim.tbl_contains(calls[1].argv, "-O0"), "C debug build is optimized")
    assert(calls[1].options.cwd == root, "C build ran outside the source directory")
    assert(output == root .. "/fixture", "C debug callback selected the wrong executable")
    exit_code = 42
    assert(not pcall(dap.configurations.c[1].program), "failed C build returned a stale executable")
    exit_code, calls = 0, {}
    vim.cmd.cd(vim.fn.fnameescape(root))
    vim.fn.writefile({ "fixture executable" }, root .. "/zig-out/bin/fixture")
    local zig = dap.configurations.zig[1].program()
    assert(#calls == 1 and vim.deep_equal(calls[1].argv, { "zig", "build", "install" }),
        "Zig debug callback skipped zig build install")
    assert(zig == root .. "/zig-out/bin/fixture", "Zig selected the wrong executable")
    exit_code = 42
    assert(not pcall(dap.configurations.zig[1].program), "failed Zig build returned a stale executable")
end, debug.traceback)
vim.system, vim.fn.system = original_system, original_shell
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.api.nvim_buf_delete(fixture_bufnr, { force = true })
vim.fn.delete(root, "rf")
assert(ok, err)
print("PASS: C debug symbols, checked C/Zig builds, and failed-build rejection")
