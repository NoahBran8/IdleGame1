# Garden Empire

A playable, offline-first portrait gardening prototype built with **Godot 4.6.3 stable**. No external runtime dependencies, login, ads or purchases.

![Godot gameplay preview — seeded demo fixture](docs/screenshots/garden-demo.png)

## Play
Open project.godot in Godot 4.6.3 and press **F5**, or run:
```sh
godot --path .
```

1. Choose Carrot, then tap a + plot. Seeds cost coins; starter carrots grow in 8 seconds.
2. Tap a ready plant to harvest; open Inventory to sell one or all.
3. Claim permanent goals in Journal, discover five species, earn XP and expand in Shop.
4. The flower stand sells your harvested inventory. A later helper harvests ready plants; neither creates free crops or replants.
5. Growth and stocked stand sales advance while away, capped at eight hours. Settings and progress save locally.

Original procedural art and sounds. Keyboard focus and mouse input work through Godot controls; touch uses Godot mouse emulation. Android touch, haptics, physical safe areas and device performance remain unverified.

## Verification
From this repository:
```sh
tools/verify.sh
```
This imports scripts, runs **141 automated checks**, then launches a headless runtime smoke test. It isolates test data in a temporary directory.

Additional checks:
```sh
# Requires a working display (real-time 8-second growth + actual GUI pointer events).
godot --path . --audio-driver Dummy --script tests/smoke_interaction.gd

# Four deterministic strategies, 10,000 synthetic players; ~3 minutes here.
# Rewrites docs/SIMULATION_RESULTS.json. For a quick run append: -- --runs=100
godot --headless --path . --script tests/simulation.gd

# Actual engine screenshots, including a labelled seeded demo and 320px large text.
godot --path . --audio-driver Dummy --script tests/capture_preview.gd
```
Tests use their own save filenames. In a restricted environment with an unwritable home, prefix commands with:
```sh
XDG_DATA_HOME=/tmp/garden-data XDG_CONFIG_HOME=/tmp/garden-config XDG_CACHE_HOME=/tmp/garden-cache
```
For a headless Linux host with an existing virtual X server, also set DISPLAY appropriately (this session used :99 and Mesa llvmpipe). Preview fixtures are illustrative game states, not evidence of real player progress.

Developer coin control: `godot --path . -- --debug-garden` then Settings; only available in debug builds.

## Status and continuation
M0–M2 are implemented and tested on desktop. M3 features are present; mobile accessibility and usability acceptance remain. M4 automated tests, simulation, Android preset and guide are present; **Android export fails here because SDK components and export templates are missing**. No APK or device performance is claimed. Economy is provisional: simulations expose fast progression and convergent optimal plant choices, requiring further tuning and human tests.

- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Testing evidence](docs/TEST_PLAN.md)
- [Simulation results](docs/SIMULATION_RESULTS.json)
- [Economy and limitations](docs/ECONOMY.md)
- [Android setup and QA](docs/ANDROID.md)
- [Exact continuation steps](docs/CONTINUE.md)
- [Supplied master specification](docs/CODEX_MASTER_SPEC.md)
