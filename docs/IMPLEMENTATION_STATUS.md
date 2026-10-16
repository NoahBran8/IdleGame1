# Implementation status

## Verified playable scope
Godot 4.6.3 stable, original procedural isometric garden, 16 plots (4 initially open), five plants with three timed growth stages, planting/harvesting, inventory sell-one/all, integer coin wallet, XP/level gates, eight upgrades, stocked flower stand, later harvest helper, eight-hour offline growth/sales cap, local saves/backups/migrations, collection, five permanent quests, contextual onboarding, generated sound/mute, reduced motion, large text, high contrast, local-only telemetry and debug-gated balance control.

## Milestone acceptance
| Milestone | Status | Evidence / limit |
| --- | --- | --- |
| M0 | Implemented | Empty repository inspected; bootable Godot scaffold; required docs created; exact engine version recorded. |
| M1 | Implemented, desktop verified | Real pointer planting → 8s growth → harvest → inventory sale → reload; atomic temp/rename saves and previous backup; tested corruption recovery. |
| M2 | Implemented, desktop verified | Eight upgrades; XP; stand/helper; chronological capped offline processing; persisted cursor; 50 bulk-vs-incremental equivalence trials. |
| M3 | Features implemented; mobile acceptance pending | Collection, five quests, tutorial hints, sound and accessibility settings, telemetry adapter. Real Godot renders inspected at 540px/320px. Hardware audio/haptics, touch, safe areas, contrast audit and usability still pending. |
| M4 | Partial | 141 automated checks and 11 rendered interaction checks pass. 10k synthetic players pass invariants. Android preset and build guide included. Actual export blocked by missing toolchain/templates; no APK, device FPS or battery evidence. |
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
