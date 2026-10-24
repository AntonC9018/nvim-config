#!/bin/sh
set -eu

test_source_data=$(nvim --headless --clean -u NONE -c 'lua print(vim.fn.stdpath("data"))' -c 'qa!' 2>/dev/null | tail -n 1)
test_root=$(mktemp -d)
test_cleanup() {
    if [ "$test_history_existed" -eq 1 ]; then
        cp -a "$test_root/telescope_history.backup" "$test_history"
    else
        rm -f "$test_history"
    fi
    rm -rf "$test_root"
}
trap test_cleanup EXIT HUP INT TERM
test_history="$test_source_data/telescope_history"
test_history_existed=0
if [ -e "$test_history" ]; then
    cp -a "$test_history" "$test_root/telescope_history.backup"
    test_history_existed=1
fi
mkdir -p "$test_root/config" "$test_root/bin"
ln -s "$PWD" "$test_root/config/nvim"
cat > "$test_root/bin/xdg-open" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$KEYBINDING_EXTERNAL_CAPTURE"
EOF
chmod +x "$test_root/bin/xdg-open"
cat > "$test_root/bin/explorer.exe" <<'EOF'
#!/bin/sh
printf 'explorer:%s:%s\n' "$PWD" "$*" >> "$KEYBINDING_EXTERNAL_CAPTURE"
EOF
chmod +x "$test_root/bin/explorer.exe"
PATH="$test_root/bin:$PATH"
export PATH

go_fixture=${KEYBINDING_GO_FIXTURE:-}
dotnet_fixture=${KEYBINDING_DOTNET_FIXTURE:-}
if [ -z "$go_fixture" ] && command -v go >/dev/null 2>&1 && command -v dlv >/dev/null 2>&1; then
    go_fixture="$test_root/go-fixture"
    go build -p=1 -gcflags=all='-N -l' -o "$go_fixture" tests/fixtures/dap-go/main.go
fi
if [ -z "$dotnet_fixture" ] && command -v dotnet >/dev/null 2>&1 && command -v netcoredbg >/dev/null 2>&1; then
    dotnet build tests/fixtures/dap-dotnet/KeybindingSmoke.csproj \
        --output "$test_root/dotnet-out" --verbosity quiet --nologo \
        --ignore-failed-sources -maxcpucount:1 \
        -p:BaseIntermediateOutputPath="$test_root/dotnet-obj/" \
        -p:MSBuildProjectExtensionsPath="$test_root/dotnet-obj/"
    dotnet_fixture="$test_root/dotnet-out/KeybindingSmoke.dll"
fi

XDG_CONFIG_HOME="$test_root/config" \
XDG_STATE_HOME="$test_root/state" \
XDG_CACHE_HOME="$test_root/cache" \
KEYBINDING_EXTERNAL_CAPTURE="$test_root/external-calls.txt" \
KEYBINDING_GO_FIXTURE="$go_fixture" \
KEYBINDING_DOTNET_FIXTURE="$dotnet_fixture" \
nvim --headless -u "$PWD/init.lua" -c 'luafile tests/keybindings_smoke.lua' -c 'qa!'
