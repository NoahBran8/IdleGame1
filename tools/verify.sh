#!/usr/bin/env bash
set -eu
garden_repo="$(cd "$(dirname "$0")/.." && pwd)"
garden_check_root="$(mktemp -d /tmp/garden-check.XXXXXX)"
trap 'rm -rf "$garden_check_root"' EXIT
export XDG_DATA_HOME="$garden_check_root/data"
export XDG_CONFIG_HOME="$garden_check_root/config"
export XDG_CACHE_HOME="$garden_check_root/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path "$garden_repo" --editor --quit > "$garden_check_root/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script' "$garden_check_root/import.log"; then
    cat "$garden_check_root/import.log"
    exit 1
fi
godot --headless --path "$garden_repo" --script tests/test_runner.gd
godot --headless --path "$garden_repo" --quit-after 120
printf 'Garden verification passed. Test data was isolated.\n'
