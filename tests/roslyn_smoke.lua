if vim.fn.executable("Microsoft.CodeAnalysis.LanguageServer") ~= 1 then
    print("NOT TESTED: Roslyn requires Microsoft.CodeAnalysis.LanguageServer")
    return
end
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.fn.writefile({ '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>',
    '<TargetFramework>net10.0</TargetFramework>', '</PropertyGroup></Project>' }, root .. "/Smoke.csproj")
vim.fn.writefile({ "class Smoke { public int Value = 1; }" }, root .. "/Smoke.cs")
vim.cmd.edit(vim.fn.fnameescape(root .. "/Smoke.cs"))
local bufnr = vim.api.nvim_get_current_buf()
local initialized = vim.wait(20000, function()
    for _, client in ipairs(vim.lsp.get_clients({ name = "roslyn", bufnr = bufnr })) do
        if client.initialized then return true end
    end
    return false
end, 50)
for _, client in ipairs(vim.lsp.get_clients({ name = "roslyn", bufnr = bufnr })) do
    client:stop(true)
end
vim.api.nvim_buf_delete(bufnr, { force = true })
vim.fn.delete(root, "rf")
assert(initialized, "configured Roslyn server did not initialize and attach to C# fixture")
print("PASS: configured Roslyn C# server initializes and attaches to a project fixture")
