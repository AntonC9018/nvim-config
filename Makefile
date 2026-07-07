.PHONY: test

test:
	nvim --headless --clean -u NONE -l tests/cs_indent_spec.lua
