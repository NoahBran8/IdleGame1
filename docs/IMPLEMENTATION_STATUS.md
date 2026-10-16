# Implementation status
## M0
Scaffold committed; Godot 4.6.3 imports project. Initial attempt could not write default user directories; use writable XDG paths in this sandbox. Editor debugger sockets are blocked by sandbox; headless runtime works.
## M1
Plant → three growth stages → harvest → inventory → sell-one/all; five configured species with level gates; 4/16 plots open; original isometric procedural art; mouse/touch button input; local atomic saves with previous-save backup, corruption recovery notice and blocked overwrite if both files invalid. Monotonic session clock. Settings persisted.
Verification: 37 automated checks passed, including mounted garden scene. Headless smoke passed after redirecting writable user-data paths. Visual rendering/device checks pending.
## Remaining
M2 upgrades, stand, capped offline progression; M3 collection, quests, sound, accessibility polish; M4 simulations, performance and Android QA; M5 user testing. No claim of device or product validation.

## M2
Implemented eight upgrades, expansion to 16 plots, XP levels, stand, harvest helper, chronological offline processing capped to 8 hours, persisted reconciliation cursor, and v1→v2 save migration. Expensive upgrades use purchase confirmation and all show effect/cost/level. 64 automated checks pass, including repeated resume/reload, backward clocks, 8h cap, upgrade prerequisites/caps and inventory-backed offline sales.

## M3
Implemented collection book, five permanent claimable quests, contextual onboarding, procedural sound/mute, reduced-motion action feedback, high contrast, larger text, local telemetry adapter and debug-only balance button. 87 checks pass (quest idempotency, migrations, privacy parameter allowlist, generated sound, mute and UI settings included). Actual desktop rendering captured with a virtual Xorg display and software OpenGL. Narrow-screen preview exposed navigation wrapping; fixed with a two-row grid. Still needs real-device safe-area, 44dp touch, sound, haptics, contrast audit and usability review before M3 acceptance.
