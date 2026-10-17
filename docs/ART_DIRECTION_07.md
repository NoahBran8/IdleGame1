# 0.7 — the garden as a living miniature

## Design brief and audit
The request calls for more detail and the spirit of a thoughtful simulation game. Interpret that through broad design principles: understandable cause and effect, useful visual feedback, human-scale details, and a place that records the player's investments. This is an original Garden Empire direction; it does not copy a named designer's game's artwork, branding or interface.

0.6 had a functional mobile shell, compatible saves and improved vector illustrations, but its flat/icon-like rendering still read as a prototype. Upgrades mostly changed numbers inside panels and the stand looked stocked even when empty. Preserve the shell, rules, seed costs, growth, upgrades, automation, requests/reservations and schema 5, while making the world more tactile and its state more legible.

## Architecture and asset strategy
Use ten project-specific generated transparent PNG objects with a consistent painted miniature aesthetic. Cottage architecture establishes terracotta, plaster, timber, sage shutters, climbing roses and warm directional light. Matching market, well, trees, pond and five crop types replace the simpler illustration textures. Each interactive object is still its own Control; the landscape is never an image of a functional interface. Shared imported textures are size limited and mipmapped. Native terrain geometry retains responsive bed positioning and hit shapes.

Asset generation used only a written original brief and the project-generated cottage as reference. No competitor source asset was used. Generated assets, provenance and checksums are in assets/painted/. Six original vector upgrade props and a transparent ground-detail tile are in assets/world/. The runtime font is unchanged.

## Implemented
- Painted miniature buildings, trees, lily pond and all five botanical crops, shared with the seed selector and real market inventory overlays.
- Quieter natural grass palette, fine tiled ground texture, shaded mortared terrace faces, planted seating area and stepping stones.
- Purchased upgrades have visible representations: compost bin and watering can at tools, baskets/sign at the market, helper and field book at home. These reflect existing saved ranks; they add no hidden income, planting, NPC behavior or new upgrade rules.
- A built stand shows real unreserved crop species on its counter. Its caption distinguishes sellable stock, all-reserved stock and an empty stand. Tooltip states actual unreserved/reserved quantities and current sale interval. Small captions abbreviate to fit narrow controls.
- Inventory badge shows all held crops; Requests shows currently fulfillable offers; Journal shows unclaimed earned goals. Badges cap at 99+ and clear as the player sells, delivers or claims. Request tooltip explicitly notes shared ingredients can overlap; three ready recipes do not imply all can be delivered in sequence.
- Presentation reads the existing model. No domain/service/data changes or migration. Garden Empire application name and schema 5 remain stable. Reduced motion retains static world/feedback behavior; no perpetual ambient animation was added.

## Verification
- 679 automated checks pass: 140 core, 104 requests, 386 redesign/layout/save and 49 presentation. Headless runtime smoke passes.
- 176 rendered interaction checks pass: 25 existing workflow and 151 expanded redesign checks. All five crop types are exercised at 320px and both side blossoms across dense 540px beds.
- Presentation regressions cover actual reserved/surplus stock, counter species, delivery and claim badge clearing, capped counts, saved upgrade binding, read-only refreshes, unchanged-schema persistence, smallest caption fit and texture budgets.
- Actual eight-screen captures refreshed and normal/narrow/established garden images inspected. Dense and established gardens are explicitly seeded test fixtures, not player progression or user research.
- No economy simulation rerun: domain/service/data rules are unchanged. Save migration/roundtrip/layout/reduced-motion regressions remain passing.
- PNG source art totals about 16 MiB. Godot imports are capped at 256px for world objects and 128px for crops with mipmaps; estimated pixel storage is about 2.1 MiB before overhead, not measured device memory.

## Outstanding
This milestone does not establish launch readiness or claim involvement by Will Wright. Android hardware performance, battery/thermal behavior, physical touch/safe areas, hardware audio/haptics, formal accessibility and independent usability/art review remain open. The mixed native terrain and painted object approach can be refined further through device screenshots and user observation. No APK, measured retention or device FPS claim is made.

Final desktop timing sample: 180 frames at 320x640, median 39.81ms, p95 83.48ms, 86 scene nodes using virtual Xorg/Mesa llvmpipe. Earlier software samples varied widely (including lower medians); this does not establish a speedup or stable mobile frame budget. Raw result: UI_RENDER_METRICS.json. Actual midrange Android profiling remains required.
