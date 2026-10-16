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
Pending implementation. No redesign completion claimed at milestone A.
