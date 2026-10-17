# Decisions
- Godot 4.6.3 stable official (7d41c59c4), typed GDScript, no external dependencies.
- Empty checkout on branch work; origin is NoahBran8/IdleGame1. Remote inspection failed because session proxy was unavailable. No existing tracked source to preserve.
- Portrait 540 × 960 logical canvas, scalable controls. Original procedural art.
- Deterministic domain model with injected integer clock; UI/service adapters handle persistence and monotonic time.
- Uploaded specification retained verbatim. No purchases, ads, accounts or network gameplay.
- Implementation proceeds in local milestone commits; remote publishing is not assumed.
- M2 uses eight data-driven upgrades: expansion, compost, irrigation, baskets, stand, helper, signage, learning garden. Prices use spec scaling except expansion's exact ladder. Growth reductions apply only to new plantings.
- Save schema v2 migrates v1 preserving progress. Offline reconciliation processes helper then stand when simultaneous, clamps to 8 hours, shifts deadlines beyond cap, and persists its cursor.
- Stand sells one item per tick, in plant-config order. Helper harvests every 5 seconds and never replants.
- Upgrade purchases preserve a 5-coin seed reserve if no growing plants or inventory remain, preventing an empty-garden dead end.
- Domain/services use explicit dependency injection rather than global autoloads. One programmatic garden UI replaces separate panel scenes for the initial slice; module boundaries remain independent of rendering.
- M3 save schema v3 migrates v1/v2; permanent quest rewards and tutorial step persist. Future-version saves are preserved and writes paused.
- Journal combines collection and five non-expiring quests. MVP collection records discovery of the standard variety; breeding and variants are deferred as in the spec.
- Audio consists of original synthesized 150ms tones. Sound, reduced motion, large text, high contrast and local telemetry settings persist.
- Event adapter writes a bounded local JSONL journal (256 KiB rotation), no persistent install identifier, no external endpoint. Event/parameter allowlists reject unknown fields. Local logs can be disabled.
- Developer coin button exists only in debug builds with explicit --debug-garden user argument. Release builds cannot enable it.
- Initial network failure was sandbox socket access. Supported additional network permission allows proxy access; git ls-remote now confirms origin has no refs.
- M4 preparation: optimization skips empty automation ticks while preserving tick phase; 50 seeded bulk/incremental equivalence trials guard behavior.
- Tests/preview inject separate save and event paths. tools/verify.sh also isolates XDG data to avoid changing player saves.
- Added Android ARM64 preset with internet permission off; actual export attempt confirmed missing templates and Android SDK settings/tools. No external SDK downloads or device claims.
- Retained provisional economy after simulation, with defects documented in ECONOMY.md rather than declaring final balance. The full 10k report is checked in.

- User played the initial Godot build and asked to continue. 0.4 adds the spec's secondary order loop plus gardening feedback and batch controls, while preserving the tested base economy.
- New pure request rules use deterministic replacement from eight data-driven templates; three offers, no expiry, no random or paid refresh. Pinning one request reserves its required quantities from normal and stand sales; explicit deliveries may use shared ingredients.
- Request reward equals upgraded sale value plus declared bonus; XP is declared. Fulfilment consumes a unique id atomically. Wallet cap or missing stock leaves the offer/stock intact. Save v4 migrates all previous versions, preserving player progress.
- Batch planting caps spending to the displayed quantity, even if an automatic sale arrives during the handler.
- Original plant drawing now differentiates sunflower/rose/lavender/orchid/carrot, with fence/edging, countdowns, growth meters, XP meter and next unlock. No external artwork or dependencies.
- Runtime verification now fails on script/runtime error output as well as exit status; Godot may otherwise return 0 on a script exception.
- 0.4 request simulation is recorded separately from the historical 10k baseline so the methods are not conflated. No base economy retuning or retention claim.

- 0.5 audit and architecture were committed before implementation (UI_REDESIGN.md). The redesign changes rendering/navigation, retaining the model's economic/time/request rules.
- UI is fixed safe-area HUD/world/dock; feature panels use overlays. Side rail and world buildings are separate visible controls. No flattened reference-image hotspots.
- Schema 5 adds only a free decor selection and chains prior migrations. App name/save directory unchanged. Full v4 field preservation tested through real JSON loading.
- Plant SVGs are cached textured quads shared with selector cards; an alpha mask cached per species extends input to visible blossom pixels. Static scenery redraws on resize/look change, not a continuous animation loop.
- Small viewports use compact dock cards; large text applies to UI and plot/building captions. Main text palette contrast tested; hardware/screen-reader audit still open.
- Expensive upgrades retain cost/effect display, cancel and captured-price validation in a reusable in-app confirmation instead of a native popup.
- Six transient labels maximum; reduced motion never starts label tweens. Ordinary notices expire, save warnings persist and are repeated in Settings.
- Software renderer timing samples vary substantially (roughly 28–57ms medians across development runs, with large p95 spikes); do not claim a stable speedup or mobile performance acceptance.

## 0.6 storybook rendering
Keep domain rules and save schema 5 stable during the art pass. Use original editable SVG building/plant/scenery textures, native static landscaping and existing reusable Controls. This supports independent world interaction and modest texture sizes without adding a large opaque backdrop, shader stack or external runtime dependency. Mature clusters use shared art and alpha-aware hits; use one silhouette at narrow widths to protect legibility. Autosave-only checkpoints must not rebuild interactive panels or discard focus; refresh content on actual inventory/income changes instead.


## 0.7 readable miniature simulation
Use broad simulation-design qualities—readable cause/effect, visible investments and useful feedback—to guide an original direction. No named designer's IP or existing game assets are copied. Ten generated transparent sprites share an internally generated cottage reference; document provenance and keep source detail while capping runtime imports. Market bouquets use unreserved stock; navigation badges reflect total inventory, fulfillable recipes and earned unclaimed goals. Shared-stock recipes need explicit tooltip wording. Installation props reflect saved ranks without adding NPC simulation, production or new economic behavior. Keep the existing model and schema 5 stable.
