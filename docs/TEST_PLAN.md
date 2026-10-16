# Test plan and actual evidence

Engine: Godot 4.6.3.stable.official.7d41c59c4. Desktop Linux sandbox. Local game state and domain arithmetic; no network dependencies.

## Executed
- tools/verify.sh: import, **244 checks / 0 failures** (140 core + 104 feature checks), headless game launch for 120 frames. Test data isolated under /tmp.
- tests/smoke_interaction.gd: **21 checks / 0 failures** using Mesa llvmpipe via Xorg dummy display. Actual GUI pointer clicks, duplicate tap, two real 8.1-second growth waits, single and batch gardening, pin reservation, surplus sale, request delivery, reload and 320px large-text nav dimensions.
- Historical 0.3 baseline, tests/simulation.gd: **10,000 players / 0 failed invariants**, four seeded strategies (2,500 each), snapshots at 1h/1d/7d. 175.221 seconds. Full output in SIMULATION_RESULTS.json; synthetic behavior only.
- tests/request_simulation.gd: **1,000 request-focused players / 0 failed invariants**, seed 20261016, real recipe costs and stock, 1h play plus 1d/7d offline returns and JSON persistence. 45.446 seconds. Full output in REQUEST_SIMULATION_RESULTS.json.
- tests/capture_preview.gd: actual Godot OpenGL start/demo/request-board/320px screenshots; inspected narrow-screen layout and fixed tab wrapping. Demo fixtures explicitly labelled.
- Android debug export attempted. Export preset was parsed; build failed due to missing Android templates, Java SDK setting and Android SDK/platform/build tools. No APK generated.
- git diff --check for whitespace errors.

## Automated coverage
- Exact coin debit/credit, no negative wallet, affordability/level/plot gates, duplicate planting/harvest/sale, growth stage boundaries, backward/huge clocks, inventory capacity, wallet cap with goods preserved.
- Eight upgrade categories, plot cost ladder, scaling/prerequisites/caps, seed-reserve dead-end prevention.
- Stand needs stock; helper harvests only mature plants; simultaneous ticks ordered helper before stand; 8h cap; repeated resume and reload cannot repay; **50 randomized trials** compare one bulk advance with many incremental advances.
- Save roundtrip and previous backup, corrupt primary recovery with notice, both corrupt blocked without overwriting; v1/v2/v3→v4 migrations; future saves preserved. Missing/malformed configs fail visibly.
- Discovery/quest rewards with duplicate claims rejected; onboarding; local event allowlist and no persistent identifier; generated audio/mute; mounted UI and idempotent large-text scaling.
- Request recipes require known, unlocked species and positive quantities; three deterministic offers; unique ids and monotonic replacement cursor; partial ingredients never consumed on failure; cap preserves stock; duplicate/stale delivery rejected.
- Pin reservations survive sell-one/all, automatic stand ticks, helper harvest, offline return and save reload; unpin restores sales.
- Batch quotes respect affordability, level gates and the displayed quantity if income arrives during the click; no duplicate harvest/debit.
- Forty seeded reservation-aware bulk/incremental equivalence trials supplement the original 50 automation trials.
- Test and preview scene saves use separate filenames from the real garden save.

## Remaining acceptance
See ANDROID.md for physical touch, hit sizes in dp, safe areas, orientation/lifecycle, performance and release checks.
App-killed-during-file-write needs device-level interruption testing; current coverage proves corrupt-file recovery, not filesystem durability under every power-loss scenario.
Audio output quality and actual haptic feedback need hardware. High-contrast colors need a formal contrast/accessibility audit; screen-reader support is not claimed.
M5 requires real independent participants, not simulations. No retention, revenue, usability or market-fit result is claimed.

## Reproduce
Use README commands. In this session actual rendered commands used DISPLAY=:99, XDG_DATA_HOME under /tmp, writable XDG_CONFIG_HOME/XDG_CACHE_HOME and a Godot --rendering-method gl_compatibility --audio-driver Dummy launch. Extra supported network permission was needed for local X11 sockets. The headless editor's debugger socket warnings under the strict sandbox were environmental; runtime checks now also inspect output for script/runtime errors, since Godot can exit with status 0 after a script error. Silent headless transaction tests verify generated audio and mute; active AudioStreamPlayer playback is tested with the rendered scene to avoid the headless dummy mixer retaining playback resources at shutdown; rendered pointer tests exercise the full flow.
