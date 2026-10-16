# Garden Empire interface redesign
## A — audit and architecture proposal
Baseline: commit 24b989f, Godot 4.6.3, app 0.4.0, schema 4.
- GardenModel owns deterministic planting/growth/harvest/sales, upgrades, XP, quests, request rotation/reservations and offline reconciliation. Config JSON supplies all tuning.
- GardenSave validates/migrates JSON, flushes a temporary file and renames it, retaining a previous backup. Bad primary recovers backup; two invalid files block writes. Future schemas are preserved.
- Garden controller handles monotonic clock, resume, persistence, telemetry and audio. UI is one full-page ScrollContainer with HUD, garden and all panels stacked.
- Each of 16 plots is already an independent Button with deterministic visual state. Buildings currently are decorative drawings without their own controls.
- All core features must stay reachable: five seeds, single/batch plant and harvest, inventory sell-one/surplus, eight upgrades and confirmations, stand/helper, XP, five quests, collection, requests/reservations, settings and debug gate.
- Existing evidence: 244 headless checks, 21 rendered interaction checks and separate synthetic economy reports. Android SDK/device acceptance remains outstanding.

## Proposed UI boundary
- Keep GameModel economic/time/request behavior intact.
- GardenShell builds fixed safe-area HUD, expanding world, side rail, bottom selector and modal sheet. It uses controller callbacks, never writes currency.
- GardenTheme supplies palette, reusable panel/button/card typography and spacing.
- SelectorCard and WorldBuilding are visible controls with their own artwork and hit regions.
- GardenBoard arranges independently clickable plots and world buildings over illustrated scenery. Decorative trees, path/pond/fence remain noninteractive scenery.
- FeedbackLayer provides bounded event-only floating gains and planting/harvest bursts; reduced motion uses static feedback.
- Existing panel builders remain in the controller for inventory/requests/shop/journal/settings, presented in a scrollable overlay with a fixed close control.
- Bottom seed/building/decor rail scrolls horizontally; primary navigation/HUD/batch controls never scroll off screen.
- Decor selector offers three free cosmetic garden treatments. A schema migration adds only decor selection; existing balances, XP, plants, inventory, goals, requests and timestamps survive unchanged.

## Asset strategy
Original SVG icon illustrations and vector-drawn garden objects, authored in this repository. No downloaded assets, competitor material, flattened reference background or invisible image hotspots. Same plant palette across selector and world. Built-in Godot font; no new font/dependency license. Track provenance in ASSET_LICENSES.md.

## Milestones / acceptance
A: audit/proposal documented, baseline checks recorded.
B: reusable components and fixed game shell; independently rendered illustrated world and clickable buildings; existing feature tests and responsive shell tests.
C: integrate all panels, saved decor and reduced-motion feedback; migration must preserve all prior fields.
D: real pointer workflow, every plot/feature access, 320/360/540/600 layouts, large text/high contrast, restart/offline/corruption checks and screenshots. Record actual timings/node counts as desktop evidence, not Android FPS.

## Performance / accessibility constraints
No continuously animated world or per-frame simulation. Static vector scenery redraws on resize/decor change; plot state updates once per second. Bounded transient effects, no shader/post-processing dependencies. Essential controls at least 44 logical px; test narrow-screen layout and viewport containment. Physical dp, touch, device safe areas, battery/thermals and Android FPS require hardware.

## Results
Milestone A recorded the proposal before implementation. Verified B/C/D results follow below; physical-device acceptance remains open.

## B/C — functional shell and compatibility verification
Implemented fixed HUD, expanding clipped world, side rail, horizontally scrolling seed/building/decor cards and dismissible feature overlays. All 16 plot controls and three illustrated buildings are independent controls with visible hit targets. Original SVG icons and native vector scenery replace the old stacked presentation. All eight upgrades, inventory actions, requests/reservations, five quests, collection and settings remain available.

Schema 5 adds only decor. Tests compare every v4 gameplay/settings field through direct migration and real JSON loading; decor saves/reloads. Coin/XP/upgrades produce bounded transient labels; reduced motion uses static labels. Palette text contrast tests pass. No prices or progression rules were retuned.

Evidence at this checkpoint:
- Original 140 core + 104 request checks pass.
- 378 redesign checks pass across 320×568, 320×640, 360×720, 540×960 and 600×1000, normal and large text; primary controls/buildings/plot bounds and modal close controls stay in view.
- Updated original rendered smoke: 25 checks pass, including real growth waits, overlay closing, sales and delivery.
- Dedicated rendered redesign smoke: 50 checks pass, including every plot at 320px, building routing, quest reward, decor and complete scene restart.
- Actual screenshots inspected. Scenery initially painted above the world; clipped the world to keep HUD/selector unobscured. High-contrast empty/locked symbols corrected for dark soil.

D remains in progress: isolated rendering timing, final screenshots/documentation and publication. Physical Android touch/dp, safe areas, hardware performance and formal accessibility audit remain pending.

## D — final desktop verification and outstanding acceptance
Functional redesign verified on desktop:
- 627 automated checks pass (140 core, 104 requests, 383 redesign).
- 95 real-pointer checks pass (25 existing workflow and 70 redesign), including all plot soil and visible crop targets, buildings, journal reward, inventory/surplus sales, request reservation/delivery, in-app purchase cancel/confirm, decor and complete scene restart.
- Each of three cosmetic looks is tested. No gameplay data field or economic rule was removed. Schema 5 adds only decor; schemas 1–4 migrate in sequence.
- Actual 540px and 320px renders inspected, including large text, request/inventory overlays and confirmation. Short viewports use a smaller selector dock; essential controls stay in view. Ordinary notices expire after 5 seconds; save warnings persist and remain available in Settings.
- A real pointer pass exposed native-popup input/styling fragility; confirmation is now an in-app component with tested cancel, cost display and single debit.
- Plant drawing uses original shared SVG sprites and alpha-aware visible-pixel hits. This replaces many per-flower primitives while retaining each plant's independent stages and controls.

Performance evidence and limits:
UI_RENDER_BEFORE_SPRITES.json records an intermediate 180-frame software-renderer sample (median 57.14ms, p95 103.94ms). Subsequent sprite samples ranged from 27.78ms/p95 66.09ms to 50.37ms/p95 84.56ms; the last expanded interaction/confirmation run recorded median 33.25ms, p95 522.84ms, 86 nodes at 320×640. These virtual Xorg/Mesa llvmpipe wall timings vary substantially and contain large spikes. They do not establish a reliable speedup or meet a real-device 30fps acceptance gate. Latest raw sample is UI_RENDER_METRICS.json.

Outstanding:
- Midrange Android GPU/frame profiling and hitch investigation, battery/thermal/memory tests.
- Physical touch targets in dp, hardware safe areas, audio/haptics and release export.
- Formal contrast and screen-reader audit; geometry/palette tests are partial accessibility evidence.
- Independent usability testing of the new layout and long-term economy tuning.
No Android APK, stable device FPS, accessibility certification, user retention or App Market/store readiness is claimed.
