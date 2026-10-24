local function fail(message)
    error("keybinding smoke test failed: " .. message, 0)
end

local function assert_mapping(mode, lhs)
    lhs = lhs:gsub("<leader>", " "):lower()
    local mappings = vim.api.nvim_get_keymap(mode)
    for _, mapping in ipairs(mappings) do
        if mapping.lhs:lower() == lhs then
            return mapping
        end
    end
    fail(string.format("missing %s-mode mapping %q", mode, lhs))
end

if vim.v.errmsg ~= "" then
    fail("full startup recorded an error: " .. vim.v.errmsg)
end

-- These mappings are defined directly by core.mappings.lua and are expected
-- to exist whenever the user's full configuration starts.
for _, item in ipairs({
    { "n", "ww" }, { "n", "W" }, { "n", "Q" },
    { "n", "<C-h>" }, { "n", "<C-j>" }, { "n", "<C-k>" }, { "n", "<C-l>" },
    { "n", "<leader>tw" }, { "n", "wo" }, { "n", "<leader>wd" },
    { "n", "<leader>wc" }, { "n", "wf" }, { "n", "wF" }, { "n", "w*" }, { "n", "wp" },
    { "n", "we" }, { "n", "wE" }, { "n", "<leader>hd" },
    { "n", "<F5>" }, { "n", "<F10>" }, { "n", "<F11>" }, { "n", "<F12>" },
    { "n", "<leader>b" },
}) do
    assert_mapping(item[1], item[2])
end

for _, command in ipairs({
    "Telescope", "Trouble", "NvimTreeOpen", "GBrowse", "Git", "UndotreeToggle", "Inspect", "Bufferize",
}) do
    if vim.fn.exists(":" .. command) ~= 2 then
        fail("mapping command dependency is unavailable: " .. command)
    end
end

-- Exercise the reversible, non-destructive core toggles and restore their
-- original values so the test does not leave state behind.
local wrap_before = vim.o.wrap
vim.api.nvim_feedkeys("ww", "xt", false)
if vim.o.wrap == wrap_before then fail("ww did not toggle wrap") end
vim.api.nvim_feedkeys("ww", "xt", false)
if vim.o.wrap ~= wrap_before then fail("ww did not restore wrap") end

local highlight_before = vim.o.hlsearch
vim.api.nvim_feedkeys(" ht", "xt", false)
if vim.o.hlsearch == highlight_before then fail("<leader>ht did not toggle search highlighting") end
vim.api.nvim_feedkeys(" ht", "xt", false)
if vim.o.hlsearch ~= highlight_before then fail("<leader>ht did not restore search highlighting") end

if vim.fn.executable("rg") ~= 1 then
    fail("ripgrep executable 'rg' is unavailable (required by wf and wF)")
end

local fixture_dir = vim.fn.tempname()
vim.fn.mkdir(fixture_dir, "p")
local fixture_path = fixture_dir .. "/keybinding-fixture.txt"
local needle = "nvim_keybinding_smoke_fixture_7d31"
vim.fn.writefile({ "fixture line", needle .. " searchable text" }, fixture_path)
vim.cmd("cd " .. vim.fn.fnameescape(fixture_dir))
vim.cmd.edit(vim.fn.fnameescape(fixture_path))
vim.api.nvim_win_set_cursor(0, { 1, 0 })

-- Exercise both file-tree entry points against the temporary fixture, then
-- close the tree so no window or buffer state leaks from the test.
assert_mapping("n", "we").callback()
local tree_open = vim.wait(3000, function()
    return vim.bo.filetype == "NvimTree"
end, 20)
if not tree_open then fail("we did not open nvim-tree") end
require("nvim-tree.api").tree.close()
vim.cmd.buffer(vim.fn.bufnr(fixture_path))

-- Undotree used to be disabled while its mapping was declared inside the
-- disabled plugin spec. Toggle it open and closed without modifying a file.
local function has_window_filetype(filetype)
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        local bufnr = vim.api.nvim_win_get_buf(winid)
        if vim.bo[bufnr].filetype == filetype then return true end
    end
    return false
end

vim.api.nvim_feedkeys(" hd", "xt", false)
local undotree_open = vim.wait(3000, function()
    return has_window_filetype("undotree")
end, 20)
if not undotree_open then fail("<leader>hd did not open Undotree") end
vim.api.nvim_feedkeys(" hd", "xt", false)
local undotree_closed = vim.wait(1000, function() return not has_window_filetype("undotree") end, 20)
if not undotree_closed then fail("<leader>hd did not close Undotree") end
vim.cmd.buffer(vim.fn.bufnr(fixture_path))

assert_mapping("n", "wE").callback()
tree_open = vim.wait(3000, function()
    return vim.bo.filetype == "NvimTree"
end, 20)
if not tree_open then fail("wE did not open nvim-tree") end
require("nvim-tree.api").tree.close()
vim.cmd.buffer(vim.fn.bufnr(fixture_path))

local telescope_state = require("telescope.state")
local function run_picker_mapping(lhs, query, expected)
    local mapping = assert_mapping("n", lhs)
    if not mapping.callback then fail(lhs .. " is not an executable callback") end
    vim.api.nvim_feedkeys(lhs, "xt", false)

    local prompt_bufnr
    local picker_ready = vim.wait(5000, function()
        for _, bufnr in ipairs(telescope_state.get_existing_prompt_bufnrs()) do
            if telescope_state.get_status(bufnr).picker then
                prompt_bufnr = bufnr
                return true
            end
        end
        return false
    end, 20)
    if not picker_ready then fail(lhs .. " did not open a Telescope picker") end

    local picker = telescope_state.get_status(prompt_bufnr).picker
    if lhs == "wf" then
        local native_sorter = require("telescope.config").values.generic_sorter
        local sorter_source = debug.getinfo(native_sorter, "S").source
        if not sorter_source:find("telescope%-fzf%-native") then
            fail("wf was not configured with the compiled telescope-fzf-native sorter: " .. sorter_source)
        end
    end
    if query then picker:set_prompt(query) end
    local result_found = vim.wait(5000, function()
        if not picker.manager then return false end
        for entry in picker.manager:iter() do
            local text = table.concat({ tostring(entry.ordinal or ""), tostring(entry.display or "") }, " ")
            if text:find(expected, 1, true) then return true end
        end
        return false
    end, 20)
    if not result_found then fail(lhs .. " did not return fixture match " .. expected) end
    require("telescope.actions").close(prompt_bufnr)
end

-- Exercise Telescope mappings against the real temporary fixture. wf and wF
-- use live_grep, w* seeds search from the cursor word, and wp finds the file.
run_picker_mapping("wf", needle, needle)
run_picker_mapping("wF", needle, needle)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
run_picker_mapping("w*", nil, needle)
run_picker_mapping("wp", "keybinding-fixture", "keybinding-fixture.txt")

-- Confirm the selected LLVM adapter exists and responds to DAP initialize.
local lldb_adapter = vim.fn.exepath("lldb-dap")
if lldb_adapter == "" then lldb_adapter = vim.fn.exepath("lldb-vscode") end
if lldb_adapter ~= "" then
    local dap = require("dap")
    if dap.adapters.lldb.command ~= lldb_adapter then
        fail("nvim-dap did not select the installed LLDB adapter")
    end
    local help = vim.system({ lldb_adapter, "--help" }, { text = true }):wait(5000)
    if not help or help.code ~= 0 then fail("LLDB adapter --help failed") end

    local request = vim.json.encode({
        seq = 1,
        type = "request",
        command = "initialize",
        arguments = {
            clientID = "nvim-config-smoke",
            adapterID = "lldb",
            locale = "en-US",
            linesStartAt1 = true,
            columnsStartAt1 = true,
            pathFormat = "path",
        },
    })
    local response = vim.system({ lldb_adapter }, {
        stdin = "Content-Length: " .. #request .. "\r\n\r\n" .. request,
        text = true,
    }):wait(5000)
    if not response then fail("LLDB adapter did not finish DAP initialize") end
    local response_json = response.stdout:match("\r\n\r\n(.*)") or response.stdout:match("\n\n(.*)")
    local decoded = response_json and vim.json.decode(response_json) or nil
    if not decoded or decoded.type ~= "response" or decoded.command ~= "initialize" or decoded.success ~= true then
        fail("LLDB adapter did not return a successful DAP initialize response: " .. vim.inspect(response))
    end
    print("PASS: LLDB adapter --help and DAP initialize")
else
    print("NOT TESTED: lldb-dap/lldb-vscode is not installed")
end

vim.fn.delete(fixture_dir, "rf")
print("PASS: startup, command dependencies, reversible core toggles, NvimTree and Undotree fixture actions, Telescope wf/wF/w*/wp fixture searches, and LLDB DAP initialization.")
print("NOT TESTED: LSP actions need an attached server; debugger launch/step actions need a real debuggee; Git/browser actions need repository context; destructive filesystem actions, clipboard writes, GUI font changes, and physical Alt/Command keyboard sequences were not invoked.")
