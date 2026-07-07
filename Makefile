.PHONY: test

test:
	nvim --headless --clean -u NONE -l tests/cs_indent_spec.lua
	nvim --headless --clean -u NONE -l tests/csharp_expected_completion_spec.lua
	nvim --headless --clean -u NONE -l tests/lsp_rename_undo_spec.lua
