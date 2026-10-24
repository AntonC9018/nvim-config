# Keybinding smoke coverage

Run `make test` from the repository root. `tests/run_keybindings_smoke.sh` launches the full user configuration with isolated Neovim state, fixture files, a temporary Git repository, and fake external opener commands. It uses the inherited `PATH`; prebuilt debug fixtures can be supplied through `KEYBINDING_GO_FIXTURE` and `KEYBINDING_DOTNET_FIXTURE`. If those are unset and the relevant tools are available, fixture builds write outputs and intermediate files under a temporary directory.

The passing run on 2026-10-24 reported **302 distinct mode/key mappings: 90 action-tested and 212 presence-only**. The smoke test prints the complete case-sensitive inventory and its current counts on every run, so platform-specific mappings remain visible.

## Actions exercised

- Core editor actions: wrap and search toggles, file-directory change, Windows line-ending cleanup, last-change jump, fold open/close, horizontal and vertical window navigation, close-other-windows, Trouble diagnostics toggle, next/previous diagnostic navigation on fixture diagnostics, and the `W`/`Q` mappings writing a temporary fixture and closing a disposable split.
- Insert and command-line editing: `<C-h>` and `<C-BS>` remove the preceding word, `<C-Del>` removes the next word, and `<C-z>`/`<C-y>` undo and redo fixture edits. Command-line behavior is observed through `CmdlineChanged` while the prompt is canceled without executing the command.
- Visual editing: `>`, `<`, and `=` change disposable selected lines; visual `<leader>tw` trims only selected lines; visual `<leader>x` executes selected fixture Lua lines; the equal-indent fixture starts with inconsistent leading whitespace.
- Clipboard: normal and visual copy/cut/paste, visual common-indent copy, and normal/visual replace use an in-memory provider without touching the desktop clipboard.
- Operator actions: `gr`/`grr` substitute fixture text, `cx`/`cxx` exchange words and lines, visual `X` exchanges selected words, and `Xs` cancels a pending exchange.
- Telescope: `wf`, `wF`, `w*`, `wp`, and `wy` return or resume matches from a temporary search fixture. `wf` is checked against the compiled `telescope-fzf-native` sorter.
- Bufferize: `wm` displays a test-generated message in a temporary buffer, which the test then closes.
- NvimTree: `we` and `wE` open the tree; `q` closes it, `<CR>` opens the fixture file, `h`/`l` collapse and expand a nested fixture directory, `<F2>` renames and `D` deletes only a temporary file, and `o` passes the fixture directory to an isolated file-manager shim. Remaining NvimTree defaults are inventoried for presence.
- Undotree: `<leader>hd` opens and closes the panel.
- Fugitive: `<leader>gb` opens blame, `<leader>gd` opens a fixture diff, and `<leader>go` produces the expected GitHub URL.
- LSP: Lua language server initialization, `<M-i>` hover, `<F2>` rename, and undo of the fixture rename.
- Clipboard: `<leader>y` and `<leader>p` round-trip through an in-memory provider without touching the desktop clipboard.
- DAP: `<leader>b` creates a temporary breakpoint. The `<F5>`, `<F10>`, `<F11>`, and `<F12>` callbacks are checked against their nvim-dap API methods. LLDB and netcoredbg initialization are checked, and Delve/Go and netcoredbg/.NET launch temporary programs to completion.

## Presence-only and contextual checks

The report marks a mapping presence-only when its behavior is not invoked in this suite. Other command-line editing aliases, operator-mode font-size shortcuts, platform modifier aliases, and GUI font changes remain presence-only. The `wc` command-history window and physical modifier delivery require an interactive terminal or desktop. `Q` is checked only when closing a disposable split; prompts for modified buffers and quitting the final window are not covered. `W` is exercised against temporary files. Visual mappings outside the tested clipboard, trimming, indentation, execution, exchange and substitution actions, including selection-based Telescope searches, remain presence-only, as do language-server actions outside the Lua fixture. The printed inventory is the detailed list for the tested environment.

Physical modifier delivery and GUI font changes require the interactive desktop and are covered by the parent’s Kitty checks. With the Nix-provided `Microsoft.CodeAnalysis.LanguageServer`, the configured Roslyn server initializes and attaches to a temporary C# project. C/C++ build callbacks are checked for debug symbols, disabled optimization and failed-build rejection; Zig is checked for actually running `zig build install` and rejecting failed builds. C/C++ and Zig debugger stepping are not covered here.

The smoke runner exits nonzero on any Lua assertion failure, restores its working directory before removing fixtures, and never treats an error printed by Neovim followed by `qa!` as a passing test.
