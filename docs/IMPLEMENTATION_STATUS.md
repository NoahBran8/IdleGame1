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
