# Garden Empire
Offline-first portrait gardening game, Godot **4.6.3 stable**. No dependencies, accounts, ads or purchases.

## Run
Open project.godot in Godot 4.6.3 and press F5, or:
```sh
godot --path .
```
Select a seed, tap a + plot, wait (starter carrots: 8 seconds), tap its mature plant, then sell from Inventory. Level rises with harvest XP.

## Verify
```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_runner.gd
godot --headless --path . --quit-after 120
```
In restricted environments prefix each command with:
```sh
XDG_DATA_HOME=/tmp/garden-data XDG_CONFIG_HOME=/tmp/garden-config XDG_CACHE_HOME=/tmp/garden-cache
```
For tests, use a separate XDG_DATA_HOME=/tmp/garden-test-data; the runner deletes only its test saves and its isolated garden save. Do not run tests against real player saves.

See docs/IMPLEMENTATION_STATUS.md for verified scope and docs/CODEX_MASTER_SPEC.md for the full contract.
