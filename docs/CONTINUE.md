# Continue work

Latest: app 0.8.0 / save schema 6. Read PROGRESSION_08.md first; older version notes below are historical.
1. Read CODEX_MASTER_SPEC.md, DECISIONS.md, IMPLEMENTATION_STATUS.md, TEST_PLAN.md and the historical SIMULATION_RESULTS.json and new REQUEST_SIMULATION_RESULTS.json.
2. Run tools/verify.sh with Godot 4.6.3. Run rendered interaction smoke and preview commands in README if a display is available.
3. Review both economy simulation methods. Compare request-focused versus sale-focused policies under matched visits before changing the balance. Simulated strategies are not human behavior; tune timing through usability sessions before adding content or monetization.
4. Finish M3 acceptance: physical-device accessibility/touch, safe areas, audio/haptics and usability.
5. Finish M4: install matching Android toolchain/templates per ANDROID.md; build/install APK and record real-device performance and lifecycle QA.
6. M5 needs independent testers and measured observations. Do not fabricate retention, user feedback or product validation.
7. Deferred by design: variant breeding, decoration systems, multiple garden businesses, accounts, remote analytics, ads and IAP. MVP collection shows the standard variety. Programmatic panels and explicitly injected services replace the spec's suggested scene/autoload decomposition; consider splitting UI scenes before major additions.

0.4 introduced: requests/reservations, batch controls and new garden art. Next useful product work: independent noticeboard usability and shared-stock clarity, matched economy experiments, then property beautification/decoration if players want it. Preserve v4 request ids/reservations and previous player progress in later migrations.

0.5 redesign: read UI_REDESIGN.md and UI_RENDER_METRICS.json first. Core features and save compatibility are desktop-verified. Finish physical-device touch/dp and safe-area checks, contrast/screen-reader review, profiling of frame-time spikes, battery/thermal tests and Android build QA before claiming mobile acceptance. Use tools/verify.sh and both rendered smoke scripts after UI changes. Preserve the application name, schema migration chain and request ids/reservations. Do not reset user progress to simplify layouts.

0.6 art pass: read ART_DIRECTION_06.md and assets/world/README.md. App version is 0.6.0; save schema remains 5. Both side blossoms on all full-size beds are real-pointer tested. Autosave checkpoints preserve open control identity/focus. Current verification is 630 headless + 160 rendered checks. Start future visual work by inspecting the actual normal/320px screenshots; keep physical-device profiling and independent art/usability review as explicit open acceptance work.


0.7: read ART_DIRECTION_07.md, assets/painted/README.md and provenance.json. App version 0.7.0, schema 5 unchanged. Current verification is 679 automated and 176 rendered checks. Presentation badges/market stock must remain derived from actual inventory, reservations and quest state. Keep generated sprites as separate objects; retain import size caps and mipmaps. Review actual garden-estate/320 screenshots before further art changes. Physical-device profiling and independent art/usability review remain open.


0.8: keep the approved painted theme. Capacity is 20 (5x4); preserve IDs 0–15 and append new beds when migrating schema 5. Areas share the same crops/inventory and unlock at 9/16 open beds. Garden contains visits and all cosmetic looks. Road/bed bounds must remain disjoint at narrow sizes. Current verification: 1,194 automated + 267 rendered checks, two 100-player synthetic smoke reports. Run test_areas and smoke_areas with future progression changes. Next product work: independent pacing sessions and properly designed nursery/greenhouse businesses, not fake map-production rewards. Device/accessibility acceptance remains open.
