#!/bin/sh
set -eu

test_source_data=$(nvim --headless --clean -u NONE -c 'lua print(vim.fn.stdpath("data"))' -c 'qa!' 2>/dev/null | tail -n 1)
test_root=$(mktemp -d)
test_history="$test_source_data/telescope_history"
test_history_existed=0
if [ -e "$test_history" ]; then
    cp -a "$test_history" "$test_root/telescope_history.backup"
    test_history_existed=1
fi
mkdir -p "$test_root/config"
ln -s "$PWD" "$test_root/config/nvim"

test_cleanup() {
    if [ "$test_history_existed" -eq 1 ]; then
        cp -a "$test_root/telescope_history.backup" "$test_history"
    else
        rm -f "$test_history"
    fi
    rm -rf "$test_root"
}
trap test_cleanup EXIT HUP INT TERM

XDG_CONFIG_HOME="$test_root/config" \
XDG_STATE_HOME="$test_root/state" \
XDG_CACHE_HOME="$test_root/cache" \
nvim --headless -u "$PWD/init.lua" -c 'luafile tests/keybindings_smoke.lua' -c 'qa!'
