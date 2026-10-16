# Implementation status

## Verified playable scope
Godot 4.6.3 stable, original procedural isometric garden, 16 plots (4 initially open), five plants with three timed growth stages, planting/harvesting, inventory sell-one/all, integer coin wallet, XP/level gates, eight upgrades, stocked flower stand, later harvest helper, eight-hour offline growth/sales cap, local saves/backups/migrations, collection, five permanent quests, contextual onboarding, generated sound/mute, reduced motion, large text, high contrast, local-only telemetry and debug-gated balance control. Version 0.4 adds a three-card repeatable request board (eight recipes), optional crop reservations, batch gardening, plot countdown/progress meters, an XP/unlock hint and richer original plant/garden art.

## Milestone acceptance
| Milestone | Status | Evidence / limit |
| --- | --- | --- |
| M0 | Implemented | Empty repository inspected; bootable Godot scaffold; required docs created; exact engine version recorded. |
| M1 | Implemented, desktop verified | Real pointer planting → 8s growth → harvest → inventory sale → reload; atomic temp/rename saves and previous backup; tested corruption recovery. |
| M2 | Implemented, desktop verified | Eight upgrades; XP; stand/helper; chronological capped offline processing; persisted cursor; 50 bulk-vs-incremental equivalence trials. |
| M3 | Features implemented; mobile acceptance pending | Collection, five quests, tutorial hints, sound and accessibility settings, telemetry adapter. Real Godot renders inspected at 540px/320px. Hardware audio/haptics, touch, safe areas, contrast audit and usability still pending. |
| M4 | Partial | 630 automated checks and 160 rendered interaction checks pass. The 0.3 baseline has 10k synthetic runs; 0.4 adds 1k request-focused runs passing invariants. Android preset and build guide included. Actual export blocked by missing toolchain/templates; no APK, device FPS or battery evidence. |
| M5 | Not started | No independent testers or retention results. No ads/IAP. |

## Material limitations
- Simulation exposes over-fast late progression, rising XP levels without extra content, and convergent profit-optimal plant choices. Initial tuning is not launch-ready. Stand unlock time depends heavily on investment order.
- Offline automation sells existing stock and harvests planted crops only. It intentionally stops producing income when stock/crops run out; no automatic planting.
- Collection records standard variety discovery. Variant breeding and extra businesses are later scope per the supplied specification.
- Services are explicitly injected and UI panels built programmatically, rather than global autoloads and individual panel scenes. No main menu/pause overlay; the game starts directly in the garden, as a vertical slice.
- Save recovery preserves damaged files and pauses writes if neither primary nor backup validates. No cloud sync. Remote analytics, accounts, multiplayer, ads and purchases absent.
- Physical-device accessibility, safe areas, 44dp plot touch targets, Android lifecycle/performance and release export acceptance remain.
- Release and trademark/licensing clearance are not asserted.

## Files and continuation
Core rules: scripts/domain/{config,game_model}.gd. Adapters: scripts/services/{save_service,analytics_service,audio_service}.gd. Rendering/UI: scripts/ui/{garden,garden_board,plot}.gd and scenes/garden/garden.tscn. Tuning: data/*.json. Verification: tests/*.gd and tools/verify.sh. Android: export_presets.cfg and docs/ANDROID.md.

Run tools/verify.sh, then follow CONTINUE.md and ANDROID.md. Keep each next change verifiable and preserve local player saves. All screenshots are actual engine captures; demo images use labelled test fixtures.

## 0.4 update
Existing v3 player saves migrate to v4 without altering earned coins, XP, crops, upgrades, quests or settings. Three unique offer ids and one optional reservation persist with a monotonic delivery cursor. Requests have no expiry or random rewards; reward is current sale value plus an explicit bonus, with XP awarded on delivery. Automatic/manual sales preserve pinned ingredients; another explicit delivery can use shared stock. New recipes appear in replacement offers as level gates permit.

Batch planting honours the last displayed quantity and affordability; batch harvest collects mature plants only. No base plant prices, growth times or XP curve changed. Added local order events; no remote analytics.

Verified 0.4 evidence: 244 core/feature checks; 21 actual GUI pointer checks through planting, real growth, batch harvest, pin, surplus sale, delivery and restart; 1,000 request-focused synthetic players with no failed state/reservation/payout invariants. Captured actual start/demo/request-board/320px screenshots. This does not finish Android or independent usability acceptance.

## 0.5 redesign
Audit/architecture/asset strategy and milestone evidence: UI_REDESIGN.md. Fixed HUD and bottom selector surround an expanding independently interactive garden. Inventory, all upgrades, requests, quests, collection and settings remain in overlays with fixed close controls. Cottage, stand and tools are actual visible controls. Plant artwork and soil both accept accurate pointer input. Three free decor looks persist through schema 5, which migrates schemas 1–4 while preserving every existing player field.

New reusable components live in scripts/ui/components/: palette/theme, selector card, game shell, world building, feedback layer, purchase confirmation. Native SVG source in assets/ui/ is original; no reference image or external asset pack is used.

Current verification: 140 core + 104 request + 383 redesign checks; 25 original rendered workflow checks and 70 redesign pointer checks, including every plot at 320px, plant pixel hits, real quest collection, purchase cancellation/confirmation and whole-scene restart. All pass. Existing economic simulations remain historical 0.3/0.4 evidence; no economy retune was made.

Desktop layout coverage includes 320×568, 320×640, 360×720, 540×960 and 600×1000, normal/large text. Palette text contrast checks pass; this is not a full accessibility certification. Virtual software-renderer frame timings vary and include substantial spikes. The real-device 30fps target, hardware touch, safe areas and battery/thermal acceptance remain unfinished. Do not mark M4 complete.

## 0.6 art milestone
Original textured SVG cottage/market/well/trees/pond and refined botanical crops replace the simpler icon-like world art. Landscape has a curved path, layered grass, pond planting, bench and material detail; beds have stronger depth. Wider mature beds show three blossoms, with alpha-aware hit testing across all three; narrow layouts show a single crop and compact harvest checkmark. Primary harvest styling and seed medallions reinforce action hierarchy.

Autosave checkpoints now persist without rebuilding open panels, preserving button identity/focus during taps. Automated regression checks cover this; income/harvest changes still refresh panels. No economic/service rule or saved field changed, and schema remains 5.

Verification: 630 headless checks and 160 rendered pointer checks pass; actual 540px/320px previews regenerated. See ART_DIRECTION_06.md for scope and limits. Android and independent user acceptance remain outstanding.
