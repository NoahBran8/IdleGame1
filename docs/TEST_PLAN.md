# Test plan and actual evidence

Engine: Godot 4.6.3.stable.official.7d41c59c4. Desktop Linux sandbox. Local game state and domain arithmetic; no network dependencies.

## Executed
- tools/verify.sh: import, **627 checks / 0 failures** (140 core + 104 requests + 383 redesign checks), headless game launch for 120 frames. Test data isolated under /tmp.
- tests/smoke_interaction.gd: **25 checks / 0 failures** using Mesa llvmpipe via Xorg dummy display. Actual GUI pointer clicks, duplicate tap, two real 8.1-second growth waits, single and batch gardening, pin reservation, surplus sale, request delivery, reload overlay open/close and 320px large-text nav dimensions.
- Historical 0.3 baseline, tests/simulation.gd: **10,000 players / 0 failed invariants**, four seeded strategies (2,500 each), snapshots at 1h/1d/7d. 175.221 seconds. Full output in SIMULATION_RESULTS.json; synthetic behavior only.
- tests/request_simulation.gd: **1,000 request-focused players / 0 failed invariants**, seed 20261016, real recipe costs and stock, 1h play plus 1d/7d offline returns and JSON persistence. 45.446 seconds. Full output in REQUEST_SIMULATION_RESULTS.json.
- tests/capture_preview.gd: actual Godot OpenGL start/demo/request-board/320px screenshots; inspected narrow-screen layout and fixed tab wrapping. Demo fixtures explicitly labelled.
- Android debug export attempted. Export preset was parsed; build failed due to missing Android templates, Java SDK setting and Android SDK/platform/build tools. No APK generated.
- git diff --check for whitespace errors.

## Automated coverage
- Exact coin debit/credit, no negative wallet, affordability/level/plot gates, duplicate planting/harvest/sale, growth stage boundaries, backward/huge clocks, inventory capacity, wallet cap with goods preserved.
- Eight upgrade categories, plot cost ladder, scaling/prerequisites/caps, seed-reserve dead-end prevention.
- Stand needs stock; helper harvests only mature plants; simultaneous ticks ordered helper before stand; 8h cap; repeated resume and reload cannot repay; **50 randomized trials** compare one bulk advance with many incremental advances.
- Save roundtrip and previous backup, corrupt primary recovery with notice, both corrupt blocked without overwriting; v1/v2/v3/v4→v5 migrations; future saves preserved. Missing/malformed configs fail visibly.
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

## Redesign verification
- tests/test_redesign.gd: 383 checks / 0 failures. Every original v4 field compared through direct migration and real JSON loading; decor validation/save/reload; all three decor controls; text contrast; bounded/static feedback; ordinary notice expiry and persistent save notices.
- Five viewport sizes × normal/large text: HUD, all primary controls, all plots/buildings and modal close controls inside the viewport; primary targets at least 44 logical px. This is a geometry test, not physical dp certification.
- tests/smoke_redesign.gd: 70 checks / 0 failures. Real pointer events to every one of 16 soil plots and every visible crop image at 320px, harvest/sale, cottage quest reward, built/unbuilt stand, tools, all building-selector entries, real in-app purchase cancel/confirm, decor, complete scene restart, settings/high contrast and reduced motion.
- Original rendered workflow passes 25 checks, including two actual 8.1-second waits. Dedicated redesign smoke injects elapsed time for its sixteen-plot fixture; it does not claim those waits are physical.
- Reusable sprites use a cached alpha mask for crop hit testing; visible blossom pixels are clickable above the soil while transparent sprite margins do not intercept neighbouring plots.
- Actual engine screenshots: fresh garden, dense demo garden, requests, decor, purchase confirmation, 320px large text and narrow inventory.
- Desktop-only frame sample: UI_RENDER_METRICS.json. Software-renderer timings vary considerably; large p95 spikes remain. Not evidence of 30fps on a midrange Android.
- The former exact-8-second UI countdown assertion was changed to a valid positive countdown bounded by growth duration. A real UI pass can cross a wall-clock second; maturity boundary arithmetic remains tested deterministically in core tests.
- Purchase confirmation is an in-app component so the same mobile viewport, theme, keyboard/cancel and input path apply. Cancel and confirm are both exercised by real pointer events.

## 0.6 art verification
- tools/verify.sh passes 630 checks: 140 core, 104 requests and 386 redesign/layout/save checks, plus the headless game smoke.
- New checkpoint regressions prove that a 30-second autosave keeps the same inventory Button, preserves keyboard focus and still writes a reloadable checkpoint. This fixes the stale-control failure discovered during rendered interaction testing.
- Rendered workflow: 25 checks / 0 failures, including both real growth waits, sale, reservation, delivery and persistence.
- Expanded rendered redesign: 135 checks / 0 failures. In addition to the existing 320px flows, a dense 540px garden exercises both added side-blossom targets on all 16 beds and proves one inventory crop per bed. These checks inject mature fixture timestamps; they are not extra real-time growth tests.
- All seven actual preview images regenerated and normal/narrow garden images visually inspected. SVG import and runtime logs checked for script errors. Source diff whitespace checks pass.
- Art assets are shared textures; scenery stays static between resize/look/building changes. Three-blossom beds are used only at plot widths >=75 logical pixels. Reduced-motion behavior remains static.
- No Android hardware, battery/thermal or full accessibility claim. Latest software-renderer timing sample remains explicitly desktop-only.


## 0.7 verification
- 679 automated checks: 140 core, 104 requests, 386 redesign/layout/save, 49 presentation. Existing suites plus the new final presentation suite pass with zero failures; tools/verify.sh includes all four and the runtime smoke.
- tests/test_presentation.gd exercises empty/built/reserved/surplus stand states, counter species, badge clearing after delivery/claim, 99+ bounds, upgrade-state binding, read-only refreshes, schema-5 persistence, narrow caption fit and imported texture dimensions. Initial fixture failures were corrected by allowing layout frames, accounting for the existing sale goal on delivery, and requiring the real signage/stand dependency in the fixture. No production rule was loosened.
- 176 rendered checks: 25 workflow (including two actual growth waits) and 151 redesign checks. Mixed planted beds cover all five generated crop heads at 320px and both side blossoms at 540px; each still awards one crop per bed.
- Eight actual previews captured, including developed-garden installation/stock details. Normal, narrow large-text and developed scenes inspected visually. Fixture scenes do not represent player/user-research evidence.
- Shared/mipmapped imports cap world textures at 256px and crop textures at 128px. Source PNGs retain original detail for future work. No continuous ambient animation was added; existing reduced-motion checks pass.
- Latest desktop timing sample is UI_RENDER_METRICS.json; software-renderer timing is not Android acceptance.


## 0.8 verification
- tools/verify.sh passes 1,194 checks: 140 core + 104 requests + 428 redesign + 49 presentation + 473 area tests; headless runtime smoke passes.
- tests/test_areas.gd covers real 16-bed v5 JSON migration, every-field preservation, four appended empties, source immutability, repeated reload, locked/unknown visit rejection, all expansion prices, unlock boundaries 8/9 and 15/16, cap 20, 20-bed batch gardening, offline helper/stand including bed 19, idempotent reconciliation and persisted area choice.
- All areas at 320x568, 320x640 and 540x960: road/bed bounds do not intersect; all 20 bed controls are unique and in bounds at >=44 logical px width. The existing normal/large-text geometry matrix also passes. This is not physical dp certification.
- 267 rendered pointer checks: 25 workflow (two real growth waits), 151 redesign/mixed crop checks and 91 new progression/area checks. Actual upgrade controls/confirmations purchase all 16 expansions; area cards visit every area; each of 20 crop targets is harvested in each arrangement, with exact inventory and reload assertions.
- Updated 20-grown-plant desktop frame fixture records UI_RENDER_METRICS.json. Device FPS remains unverified.
- 100 baseline-strategy and 100 request-strategy synthetic trials have zero invariant failures; versioned reports preserve historical files. Use --output=res://docs/SIMULATION_08.json or --output=res://docs/REQUEST_SIMULATION_08.json to reproduce separately.
- Actual preview capture adds Market, Lakeside, starter locked-area cards and narrow area selection. Planted/established screenshots use labelled seeded fixtures.
