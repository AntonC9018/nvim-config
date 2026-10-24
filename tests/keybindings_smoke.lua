local function fail(message)
    error("keybinding smoke test failed: " .. message, 0)
end

local action_tested_mappings = {}
local mapping_presence = {}
local mapping_labels = {}

local function normalize_lhs(lhs)
    lhs = lhs:gsub("<[lL][eE][aA][dD][eE][rR]>", vim.g.mapleader or " ")
    return vim.api.nvim_replace_termcodes(lhs, true, false, true)
end

local function display_lhs(lhs)
    local leader = vim.g.mapleader or " "
    if lhs:sub(1, #leader) == leader then
        return "<leader>" .. lhs:sub(#leader + 1)
    end
    return lhs
end

local function lookup_mapping(mode, lhs, bufnr)
    lhs = normalize_lhs(lhs)
    local mappings = bufnr and vim.api.nvim_buf_get_keymap(bufnr, mode) or vim.api.nvim_get_keymap(mode)
    for _, mapping in ipairs(mappings) do
        if normalize_lhs(mapping.lhs) == lhs then
            return mapping
        end
    end
end

local function mark_action_tested(mode, lhs)
    local id = mode .. ":" .. normalize_lhs(lhs)
    action_tested_mappings[id] = true
    mapping_presence[id] = true
    mapping_labels[id] = display_lhs(lhs)
end

local function assert_mapping(mode, lhs)
    local mapping = lookup_mapping(mode, lhs)
    if mapping then
        local id = mode .. ":" .. normalize_lhs(lhs)
        mapping_presence[id] = true
        mapping_labels[id] = mapping_labels[id] or display_lhs(mapping.lhs)
        return mapping
    end
    fail(string.format("missing %s-mode mapping %q", mode, lhs))
end

local function assert_buffer_mapping(bufnr, mode, lhs)
    local mapping = lookup_mapping(mode, lhs, bufnr)
    if mapping then
        local id = mode .. ":" .. normalize_lhs(lhs)
        mapping_presence[id] = true
        mapping_labels[id] = mapping_labels[id] or display_lhs(mapping.lhs)
        return mapping
    end
    fail(string.format("missing buffer %d %s-mode mapping %q", bufnr, mode, lhs))
end

local function feed(lhs)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "xt", false)
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
    { "n", "<leader>y" }, { "n", "<leader>p" },
    { "n", "<leader>gb" }, { "n", "<leader>gd" }, { "n", "<leader>go" },
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
mark_action_tested("n", "ww")
vim.api.nvim_feedkeys("ww", "xt", false)
if vim.o.wrap ~= wrap_before then fail("ww did not restore wrap") end

local highlight_before = vim.o.hlsearch
vim.api.nvim_feedkeys(" ht", "xt", false)
if vim.o.hlsearch == highlight_before then fail("<leader>ht did not toggle search highlighting") end
mark_action_tested("n", "<leader>ht")
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
local lsp_fixture_path = fixture_dir .. "/lsp-smoke.lua"
local old_symbol = "fixtureRenameTarget"
local new_symbol = "fixtureRenamedTarget"
vim.fn.writefile({ "local " .. old_symbol .. " = 'hover smoke'", "return " .. old_symbol }, lsp_fixture_path)
local original_cwd = vim.fn.getcwd()
vim.cmd("cd " .. vim.fn.fnameescape(fixture_dir))
vim.cmd.edit(vim.fn.fnameescape(fixture_path))
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd.edit(vim.fn.fnameescape(fixture_path))
vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
vim.api.nvim_feedkeys(" wc", "xt", false)
if vim.fn.getcwd() ~= fixture_dir then fail("<leader>wc did not change directory to the fixture file") end
mark_action_tested("n", "<leader>wc")

-- Exercise the remaining reversible core editing/window actions on the
-- disposable text fixture.
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "windows line\r", "second line" })
vim.api.nvim_feedkeys(" tw", "xt", false)
if vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] ~= "windows line" then
    fail("<leader>tw did not remove the Windows line-ending artifact from the fixture")
end
mark_action_tested("n", "<leader>tw")

vim.api.nvim_buf_set_mark(0, "[", 1, 0, {})
vim.api.nvim_win_set_cursor(0, { 2, 0 })
feed("gb")
if vim.api.nvim_win_get_cursor(0)[1] ~= 1 then fail("gb did not jump to the fixture's last-change mark") end
mark_action_tested("n", "gb")

vim.wo.foldmethod = "manual"
vim.wo.foldenable = true
vim.cmd("1,2fold")
if vim.fn.foldclosed(1) ~= 1 then fail("fixture fold could not be created") end
feed("L")
if vim.fn.foldclosed(1) ~= -1 then fail("L did not open the fixture fold") end
mark_action_tested("n", "L")
feed("H")
if vim.fn.foldclosed(1) ~= 1 then fail("H did not close the fixture fold") end
mark_action_tested("n", "H")
vim.cmd("normal! zE")
vim.wo.foldmethod = "manual"

vim.cmd("vsplit")
local left_win = vim.api.nvim_get_current_win()
vim.cmd.wincmd("l")
local right_win = vim.api.nvim_get_current_win()
feed("<C-h>")
if vim.api.nvim_get_current_win() ~= left_win then fail("<C-h> did not focus the left fixture window") end
mark_action_tested("n", "<C-h>")
feed("<C-l>")
if vim.api.nvim_get_current_win() ~= right_win then fail("<C-l> did not focus the right fixture window") end
mark_action_tested("n", "<C-l>")
vim.cmd("split")
vim.cmd.wincmd("k")
local upper_win = vim.api.nvim_get_current_win()
feed("<C-j>")
if vim.api.nvim_get_current_win() == upper_win then fail("<C-j> did not leave the upper fixture window") end
mark_action_tested("n", "<C-j>")
feed("<C-k>")
if vim.api.nvim_get_current_win() ~= upper_win then fail("<C-k> did not focus the upper fixture window") end
mark_action_tested("n", "<C-k>")
feed("wo")
if #vim.api.nvim_list_wins() ~= 1 then fail("wo did not close other fixture windows") end
mark_action_tested("n", "wo")

-- Start the configured Lua language server on a temporary source file, then
-- exercise its real initialize, hover and rename requests through the bound
-- buffer actions. The resulting edits and undo are confined to the fixture.
vim.cmd.edit(vim.fn.fnameescape(lsp_fixture_path))
local lsp_bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_win_set_cursor(0, { 1, 6 })
local lsp_started = vim.wait(15000, function()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = lsp_bufnr })) do
        if client.name == "lua_ls" and client.initialized then return true end
    end
    return false
end, 50)
if not lsp_started then fail("lua_ls did not initialize on the temporary Lua file") end

local hover_mapping = assert_buffer_mapping(lsp_bufnr, "n", "<M-i>")
local hover_win_count = #vim.api.nvim_list_wins()
if hover_mapping.callback then
    hover_mapping.callback()
else
    feed("<M-i>")
end
local hover_open = vim.wait(5000, function()
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(winid)
        if config.relative ~= "" then return true end
    end
    return #vim.api.nvim_list_wins() > hover_win_count
end, 20)
if not hover_open then fail("<M-i> did not show Lua LSP hover information") end
mark_action_tested("n", "<M-i>")
for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(winid).relative ~= "" then
        pcall(vim.api.nvim_win_close, winid, true)
    end
end

local original_ui_input = vim.ui.input
local original_notify = vim.notify
local rename_notices = {}
local original_lsp_rename = vim.lsp.buf.rename
vim.notify = function(message, ...)
    table.insert(rename_notices, tostring(message))
    return original_notify(message, ...)
end
vim.ui.input = function(_, callback) callback(new_symbol) end
-- Inject the interactive answer at vim.lsp.buf.rename's boundary. This keeps
-- the configured mapping and real server request under test without relying
-- on headless UI input behavior in Neovim 0.12.
vim.lsp.buf.rename = function(name, opts) return original_lsp_rename(name or new_symbol, opts) end
local rename_mapping = assert_buffer_mapping(lsp_bufnr, "n", "<F2>")
if rename_mapping.callback then rename_mapping.callback() else feed("<F2>") end
vim.lsp.buf.rename = original_lsp_rename
vim.ui.input = original_ui_input
vim.notify = original_notify
local rename_complete = vim.wait(10000, function()
    local text = table.concat(vim.api.nvim_buf_get_lines(lsp_bufnr, 0, -1, false), "\n")
    return text:find(new_symbol, 1, true) ~= nil and text:find(old_symbol, 1, true) == nil
end, 50)
if not rename_complete then
    fail("<F2> did not apply Lua LSP rename to the temporary file; cursor=" .. vim.inspect(vim.api.nvim_win_get_cursor(0))
        .. "; text=" .. vim.inspect(vim.api.nvim_buf_get_lines(lsp_bufnr, 0, -1, false))
        .. "; notices=" .. vim.inspect(rename_notices)
        .. "; mode=" .. vim.api.nvim_get_mode().mode .. "; mapping=" .. vim.inspect(rename_mapping))
end
mark_action_tested("n", "<F2>")
feed("u")
local rename_undo_complete = vim.wait(3000, function()
    local text = table.concat(vim.api.nvim_buf_get_lines(lsp_bufnr, 0, -1, false), "\n")
    return text:find(old_symbol, 1, true) ~= nil and text:find(new_symbol, 1, true) == nil
end, 20)
if not rename_undo_complete then fail("undo did not reverse the fixture LSP rename") end

-- Exercise both file-tree entry points against the temporary fixture, then
-- close the tree so no window or buffer state leaks from the test.
assert_mapping("n", "we").callback()
local tree_open = vim.wait(3000, function()
    return vim.bo.filetype == "NvimTree"
end, 20)
if not tree_open then fail("we did not open nvim-tree") end
mark_action_tested("n", "we")
local tree_buf_for_inventory = vim.api.nvim_get_current_buf()
for _, lhs in ipairs({
    "<Esc>", "q", "d", "<CR>", "l", "h", "<C-i>", "<F2>", "s", "<2-LeftMouse>",
    "o", "y", "x", "p", "t", "-", "i", "I", "D", "L", "H", "<C-r>", "r", "P", "a", "R", "Y", "<C-g>", "e", "W",
}) do
    assert_buffer_mapping(tree_buf_for_inventory, "n", lhs)
end
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
mark_action_tested("n", "<leader>hd")
vim.api.nvim_feedkeys(" hd", "xt", false)
local undotree_closed = vim.wait(1000, function() return not has_window_filetype("undotree") end, 20)
if not undotree_closed then fail("<leader>hd did not close Undotree") end
vim.cmd.buffer(vim.fn.bufnr(fixture_path))

assert_mapping("n", "wE").callback()
tree_open = vim.wait(3000, function()
    return vim.bo.filetype == "NvimTree"
end, 20)
if not tree_open then fail("wE did not open nvim-tree") end
mark_action_tested("n", "wE")
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
    mark_action_tested("n", lhs)
end

-- Exercise Telescope mappings against the real temporary fixture. wf and wF
-- use live_grep, w* seeds search from the cursor word, and wp finds the file.
vim.api.nvim_buf_set_lines(vim.fn.bufnr(fixture_path), 0, -1, false, { "fixture line", needle .. " searchable text" })
vim.cmd.buffer(vim.fn.bufnr(fixture_path))
run_picker_mapping("wf", needle, needle)
run_picker_mapping("wF", needle, needle)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
run_picker_mapping("w*", nil, needle)
run_picker_mapping("wp", "keybinding-fixture", "keybinding-fixture.txt")

-- Run the system clipboard mappings through an in-memory provider so the
-- actual mappings and register path are exercised without touching the OS.
local clipboard_payload = {}
local old_clipboard = vim.g.clipboard
vim.g.clipboard = {
    name = "keybinding-smoke-memory",
    copy = { ["+"] = function(lines) clipboard_payload = vim.deepcopy(lines) end },
    paste = { ["+"] = function() return vim.deepcopy(clipboard_payload), "V" end },
}
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "clipboard round-trip fixture" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed(" y")
if clipboard_payload[1] ~= "clipboard round-trip fixture" then
    fail("<leader>y did not copy through the isolated clipboard provider")
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed(" p")
if vim.api.nvim_get_current_line() ~= "clipboard round-trip fixture" then
    fail("<leader>p did not paste through the isolated clipboard provider")
end
vim.g.clipboard = old_clipboard
mark_action_tested("n", "<leader>y")
mark_action_tested("n", "<leader>p")

-- Exercise Fugitive actions in a disposable local repository. The fake
-- xdg-open executable captures GBrowse so no external application is opened.
local git_dir = fixture_dir .. "/git-repo"
vim.fn.mkdir(git_dir, "p")
local function git(args)
    local result = vim.system(vim.list_extend({ "git", "-C", git_dir }, args), { text = true }):wait(10000)
    if not result or result.code ~= 0 then fail("git fixture command failed: " .. table.concat(args, " ") .. " " .. (result and result.stderr or "")) end
    return result.stdout
end
git({ "init", "-q" })
git({ "config", "commit.gpgsign", "false" })
vim.fn.writefile({ "git fixture base" }, git_dir .. "/tracked.txt")
git({ "add", "tracked.txt" })
git({ "commit", "-qm", "fixture base" })
git({ "remote", "add", "origin", "https://github.com/example/keybinding-smoke.git" })
vim.cmd.edit(vim.fn.fnameescape(git_dir .. "/tracked.txt"))
vim.api.nvim_feedkeys(" gb", "xt", false)
if not vim.wait(3000, function() return vim.bo.filetype == "fugitiveblame" end, 20) then
    fail("<leader>gb did not open Fugitive blame in the fixture repository")
end
mark_action_tested("n", "<leader>gb")
vim.cmd("quit")
vim.cmd.edit(vim.fn.fnameescape(git_dir .. "/tracked.txt"))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "git fixture changed" })
vim.cmd.write()
vim.api.nvim_feedkeys(" gd", "xt", false)
if not vim.wait(3000, function() return #vim.api.nvim_list_wins() >= 2 end, 20) then
    fail("<leader>gd did not open a Fugitive vertical diff")
end
mark_action_tested("n", "<leader>gd")
vim.cmd("only")
vim.api.nvim_feedkeys(" go", "xt", false)
local browse_result = vim.api.nvim_exec2("GBrowse", { output = true }).output
if not browse_result:find("https://github.com/example/keybinding-smoke", 1, true) then
    fail("<leader>go did not pass the fixture GitHub URL to xdg-open")
end
mark_action_tested("n", "<leader>go")

-- Rename and delete a file only inside the temporary tree fixture.
vim.cmd.edit(vim.fn.fnameescape(fixture_path))
vim.api.nvim_feedkeys(" wE", "xt", false)
tree_open = vim.wait(3000, function() return vim.bo.filetype == "NvimTree" end, 20)
if not tree_open then fail("wE did not open the tree for filesystem action tests") end
local tree_api = require("nvim-tree.api")
local tree_buf = vim.api.nvim_get_current_buf()
local tree_rename = assert_buffer_mapping(tree_buf, "n", "<F2>")
vim.ui.input = function(_, callback) callback("renamed-smoke") end
if tree_rename.callback then tree_rename.callback() else feed("<F2>") end
vim.ui.input = original_ui_input
local renamed_path = fixture_dir .. "/renamed-smoke.txt"
if vim.fn.filereadable(renamed_path) ~= 1 then fail("nvim-tree F2 did not rename the fixture file") end
mark_action_tested("n", "<F2>")
local tree_delete = assert_buffer_mapping(tree_buf, "n", "D")
vim.ui.input = function(_, callback) callback("") end
if tree_delete.callback then tree_delete.callback() else feed("D") end
vim.ui.input = original_ui_input
if vim.fn.filereadable(renamed_path) == 1 then fail("nvim-tree D did not delete the renamed fixture file") end
mark_action_tested("n", "D")
tree_api.tree.close()

-- The tree's file-manager action is exercised safely with the xdg-open shim.
vim.cmd.edit(vim.fn.fnameescape(fixture_path))
vim.api.nvim_feedkeys(" wE", "xt", false)
if not vim.wait(3000, function() return vim.bo.filetype == "NvimTree" end, 20) then fail("wE did not reopen tree") end
tree_buf = vim.api.nvim_get_current_buf()
local open_mapping = assert_buffer_mapping(tree_buf, "n", "o")
if open_mapping.callback then open_mapping.callback() else feed("o") end
local capture_file = vim.env.KEYBINDING_EXTERNAL_CAPTURE
local captured_open = vim.wait(2000, function()
    local lines = vim.fn.filereadable(capture_file) == 1 and vim.fn.readfile(capture_file) or {}
    return table.concat(lines, "\n"):find(fixture_dir, 1, true) ~= nil
end, 20)
if not captured_open then fail("nvim-tree o did not send fixture directory to the isolated file-manager shim") end
mark_action_tested("n", "o")
tree_api.tree.close()

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
    local content_length, response_json = response.stdout:match("^Content%-Length:%s*(%d+)\r?\n\r?\n(.*)$")
    local decoded = content_length and vim.json.decode(response_json:sub(1, tonumber(content_length))) or nil
    if not decoded or decoded.type ~= "response" or decoded.command ~= "initialize" or decoded.success ~= true then
        fail("LLDB adapter did not return a successful DAP initialize response: " .. vim.inspect(response))
    end
    print("PASS: LLDB adapter --help and DAP initialize")
else
    print("NOT TESTED: lldb-dap/lldb-vscode is not installed")
end

local dap = require("dap")
local netcoredbg = vim.fn.exepath("netcoredbg")
if netcoredbg ~= "" then
    if dap.adapters.coreclr.command ~= netcoredbg or dap.adapters.coreclr.args[1] ~= "--interpreter=vscode" then
        fail("coreclr adapter did not select netcoredbg --interpreter=vscode")
    end
    local help = vim.system({ netcoredbg, "--help" }, { text = true }):wait(5000)
    if not help or help.code ~= 0 then fail("netcoredbg --help failed") end
    local request = vim.json.encode({
        seq = 1, type = "request", command = "initialize",
        arguments = {
            clientID = "nvim-config-smoke", adapterID = "coreclr", locale = "en-US",
            linesStartAt1 = true, columnsStartAt1 = true, pathFormat = "path",
        },
    })
    local response = vim.system({ netcoredbg, "--interpreter=vscode" }, {
        stdin = "Content-Length: " .. #request .. "\r\n\r\n" .. request,
        text = true,
    }):wait(5000)
    if not response then fail("netcoredbg did not finish DAP initialize") end
    local content_length, response_json = response.stdout:match("^Content%-Length:%s*(%d+)\r?\n\r?\n(.*)$")
    local decoded = content_length and vim.json.decode(response_json:sub(1, tonumber(content_length))) or nil
    local initialized = decoded and ((decoded.type == "response" and decoded.command == "initialize" and decoded.success == true)
        or (decoded.type == "event" and decoded.event == "capabilities" and decoded.body and decoded.body.capabilities))
    if not initialized then
        fail("netcoredbg did not return successful DAP initialize: " .. vim.inspect(response))
    end
    print("PASS: netcoredbg --help and DAP initialize/capabilities handshake")
else
    print("NOT TESTED: netcoredbg is not installed")
end

local function run_debug_fixture(config, fixture_name)
    local terminated = false
    local exited = false
    dap.listeners.after.event_terminated["keybinding-smoke"] = function() terminated = true end
    dap.listeners.after.event_exited["keybinding-smoke"] = function() exited = true end
    local ok, err = pcall(dap.run, config)
    if not ok then fail(fixture_name .. " dap.run failed: " .. tostring(err)) end
    if not vim.wait(30000, function() return terminated or exited or not dap.session() end, 50) then
        pcall(dap.terminate)
        fail(fixture_name .. " adapter did not complete the temporary debuggee")
    end
    dap.listeners.after.event_terminated["keybinding-smoke"] = nil
    dap.listeners.after.event_exited["keybinding-smoke"] = nil
end

-- Verify each DAP key invokes its intended nvim-dap API action. Adapter
-- launch is tested separately below against real Delve and netcoredbg fixtures.
for lhs, method in pairs({ ["<F5>"] = "continue", ["<F10>"] = "step_over", ["<F11>"] = "step_into", ["<F12>"] = "step_out" }) do
    local original = dap[method]
    local called = false
    dap[method] = function() called = true end
    assert_mapping("n", lhs).callback()
    dap[method] = original
    if not called then fail(lhs .. " did not call dap." .. method) end
    mark_action_tested("n", lhs)
end

local go_fixture = vim.env.KEYBINDING_GO_FIXTURE
if go_fixture and go_fixture ~= "" and vim.fn.executable(go_fixture) == 1 and vim.fn.executable(vim.fn.exepath("dlv")) == 1 then
    local go_config = {
        type = "go", name = "keybinding smoke Go launch", request = "launch",
        mode = "exec", program = go_fixture,
    }
    local bp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bp_buf, 0, -1, false, { "temporary breakpoint fixture" })
    vim.api.nvim_set_current_buf(bp_buf)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    assert_mapping("n", "<leader>b").callback()
    local placed = vim.fn.sign_getplaced(bp_buf, { group = "dap_breakpoints" })
    if not placed[1] or #placed[1].signs == 0 then fail("<leader>b did not add a fixture breakpoint sign") end
    dap.clear_breakpoints()
    vim.api.nvim_buf_delete(bp_buf, { force = true })
    mark_action_tested("n", "<leader>b")
    run_debug_fixture(go_config, "Go")
    print("PASS: Delve Go launch and fixture exit; breakpoint action tested")
else
    print("NOT TESTED: Go launch needs dlv and KEYBINDING_GO_FIXTURE")
end

local dotnet_fixture = vim.env.KEYBINDING_DOTNET_FIXTURE
if netcoredbg ~= "" and dotnet_fixture and vim.fn.filereadable(dotnet_fixture) == 1 then
    local dotnet_config = {
        type = "coreclr", name = "keybinding smoke .NET launch", request = "launch",
        program = dotnet_fixture, cwd = vim.fn.fnamemodify(dotnet_fixture, ":h"),
    }
    run_debug_fixture(dotnet_config, ".NET")
    print("PASS: netcoredbg .NET launch and fixture exit")
else
    print("NOT TESTED: .NET launch needs netcoredbg and KEYBINDING_DOTNET_FIXTURE")
end

-- Inventory global mappings from the config sources and the explicit
-- buffer-local mappings checked above, separating actions from presence.
local source_by_sid = {}
for _, script in ipairs(vim.fn.getscriptinfo()) do source_by_sid[script.sid] = script.name end
local covered = {}
local tested_count, presence_count = 0, 0
local modes = { "n", "v", "x", "s", "o", "i", "c", "t" }
for _, mode in ipairs(modes) do
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
        local source = source_by_sid[mapping.sid]
        if source and (source:match("/init%.lua$") or source:match("/lua/core/mappings%.lua$")) then
            local id = mode .. ":" .. normalize_lhs(mapping.lhs)
            mapping_labels[id] = mapping_labels[id] or display_lhs(mapping.lhs)
            if not covered[id] then
                covered[id] = true
                if action_tested_mappings[id] then tested_count = tested_count + 1 else presence_count = presence_count + 1 end
            end
        end
    end
end
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    for _, mode in ipairs({ "n", "v", "x", "i" }) do
        for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
            local source = source_by_sid[mapping.sid]
            if source and source:match("/init%.lua$") then
                local id = mode .. ":" .. normalize_lhs(mapping.lhs)
                mapping_labels[id] = mapping_labels[id] or display_lhs(mapping.lhs)
                if not covered[id] then
                    covered[id] = true
                    if action_tested_mappings[id] then tested_count = tested_count + 1 else presence_count = presence_count + 1 end
                end
            end
        end
    end
end
for id in pairs(mapping_presence) do
    if not covered[id] then
        covered[id] = true
        if action_tested_mappings[id] then tested_count = tested_count + 1 else presence_count = presence_count + 1 end
    end
end
print(string.format("MAPPING COVERAGE: %d action-tested, %d presence-only configured mappings", tested_count, presence_count))
local tested_names, presence_names = {}, {}
for id in pairs(covered) do
    local mode = id:match("^(.-):")
    local name = mode .. ":" .. (mapping_labels[id] or "<termcode>")
    if action_tested_mappings[id] then table.insert(tested_names, name) else table.insert(presence_names, name) end
end
table.sort(tested_names)
table.sort(presence_names)
print("ACTION-TESTED MAPPINGS: " .. table.concat(tested_names, ", "))
print("PRESENCE-ONLY MAPPINGS: " .. table.concat(presence_names, ", "))

vim.fn.delete(fixture_dir, "rf")
print("PASS: full-user startup and all fixture-backed smoke actions above.")
print("CONTEXTUAL MANUAL CHECKS: GUI font selection, terminal physical modifier delivery, interactive Quit/Write mappings, and environment-specific Roslyn/C#/TypeScript servers are not emulated by this headless fixture suite.")
