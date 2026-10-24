# Keybinding smoke coverage

Run `make test` from the repository root. `tests/run_keybindings_smoke.sh` launches the full user configuration with isolated Neovim state, fixture files, a temporary Git repository, and fake external opener commands. It uses the inherited `PATH`; prebuilt debug fixtures can be supplied through `KEYBINDING_GO_FIXTURE` and `KEYBINDING_DOTNET_FIXTURE`. If those are unset and the relevant tools are available, fixture builds write outputs and intermediate files under a temporary directory.

The passing run on 2026-10-24 reported **300 distinct mode/key mappings: 33 action-tested and 267 presence-only**. The smoke test prints the complete case-sensitive inventory and its current counts on every run, so platform-specific mappings remain visible.

## Actions exercised

- Core editor actions: wrap and search toggles, file-directory change, Windows line-ending cleanup, last-change jump, fold open/close, horizontal and vertical window navigation, and close-other-windows.
- Telescope: `wf`, `wF`, `w*`, and `wp` return matches from a temporary search fixture. `wf` is checked against the compiled `telescope-fzf-native` sorter.
- NvimTree: `we` and `wE` open the tree; `<F2>` renames and `D` deletes only a temporary file; `o` passes the fixture directory to an isolated file-manager shim. All explicitly configured NvimTree bindings are inventoried for presence.
- Undotree: `<leader>hd` opens and closes the panel.
- Fugitive: `<leader>gb` opens blame, `<leader>gd` opens a fixture diff, and `<leader>go` produces the expected GitHub URL.
- LSP: Lua language server initialization, `<M-i>` hover, `<F2>` rename, and undo of the fixture rename.
- Clipboard: `<leader>y` and `<leader>p` round-trip through an in-memory provider without touching the desktop clipboard.
- DAP: `<leader>b` creates a temporary breakpoint. The `<F5>`, `<F10>`, `<F11>`, and `<F12>` callbacks are checked against their nvim-dap API methods. LLDB and netcoredbg initialization are checked, and Delve/Go and netcoredbg/.NET launch temporary programs to completion.

## Presence-only and contextual checks

The report marks a mapping presence-only when its mapping is installed but its behavior is not invoked in this suite. This includes insert/command-line editing variants, many modifier aliases, visual/operator variants, interactive quit/write actions, and language-server actions outside the Lua fixture. The printed inventory is the detailed list for the tested environment.

Physical modifier delivery and GUI font changes require the interactive desktop and are covered by the parent’s Kitty checks. The configured C# language server executable `Microsoft.CodeAnalysis.LanguageServer` was absent from the supplied test `PATH`; .NET debugging itself passed. C/C++ and Zig debugger stepping are not covered here.
