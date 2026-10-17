# 0.8 — smaller beds and visible property progression

## Audit and chosen scope
The 0.7 painted miniature theme is retained. The earlier 4x4 bed island occupied a path crossing through its footprint; one larger visual bed represented each crop. Capacity was fixed at 16 and property surroundings did not offer earned milestones. Domain and save checks confirmed original plot IDs could be retained while appending capacity.

Implement a 5-column by 4-row property (20 beds) with smaller visual beds/crops and a separate left-side road corridor. Add three earned property areas with persistent selection, distinct surroundings, building placement and bed-index arrangement. These are visits to the same persistent garden; inventory, crops, upgrades, quests and timers travel with it. They are not separate businesses or independent production queues.

## Functional progression
| Milestone | Result |
| --- | --- |
| Start: 4 open beds | Cottage Garden, familiar green setting and row-major beds. |
| Purchase bed 9 | Market Courtyard unlocks and is selected. Stone courtyard, swapped home/market frontage, serpentine bed ordering and repositioned seating/pond. |
| Purchase bed 16 | Lakeside Garden unlocks and is selected. Waterside setting, larger ornamental pond and reversed bed arrangement. |
| Purchase beds 17–20 | Continue expanding the same property to its new full capacity. |

Garden (formerly the Decor tab) contains the three area cards followed by all three existing cosmetic looks. Locked cards show current/required bed counts; unlocked cards visit their area and save the choice. Existing gardens at 9/16+ beds already qualify for the corresponding areas. Migration keeps their selected area at Cottage rather than unexpectedly moving their current garden. The world hint shows area, open/max bed counts and crop readiness; expansion notices announce actual area unlocks.

## Layout and interaction
The 5x4 isometric parallelogram sits entirely to the right of a reserved road corridor. Native road drawing remains inside that corridor. Each area reorders the same bed controls using stable plot IDs and sorts them by actual depth. Buildings keep their existing actions. Visual bed width is capped at 82px instead of 110px; crop sizes scale with bed height, and compact harvest checkmarks prevent label collisions. At 320px the controls remain at least 44 logical px wide and within the board. This is geometry and pointer evidence, not physical dp certification.

## Saves and economy
App version 0.8.0; save schema 6. The explicit v5→v6 migration copies the original state, adds garden_area=cottage, and appends four empty plot dictionaries to genuine 16-bed saves. It preserves IDs 0–15, crop species/timestamps, coins, XP, inventory, orders/reservations, upgrade ranks, goals and settings. Older migration steps still run in order. Future-version and corrupt-save protections remain.

The original twelve expansion prices are unchanged. Only the four additional beds introduce prices: 6,000; 9,500; 15,000; 24,000 coins. Expansion cap becomes rank 16 / 20 total beds. Seed costs, growth, sell values, XP curve and automation intervals are unchanged. Unlocking/visiting an area has no extra charge or fabricated income. Batch controls and the helper support the full capacity; stand sales still consume real unreserved crops.

## Verification
- tools/verify.sh: 1,194 checks, zero failures (140 core + 104 requests + 428 redesign/layout + 49 presentation + 473 area/migration/progression checks), plus headless runtime smoke.
- Rendered interaction: 267 checks, zero failures (25 workflow + 151 redesign + 91 new area checks). New checks perform 16 real expansion purchases, confirmations, both unlock transitions, area visits and 20 individual crop harvests in each of the three arrangements. All 60 harvested crops and the final area/capacity reload together.
- Real v5 JSON migration compares every existing field, keeps the original source dictionary unchanged and preserves plot 15's orchid/timestamps; repeated load is idempotent. Locked/unknown areas cannot mutate state. All 16 price steps and the 20-bed cap are checked.
- Geometry covers all areas at 320x568, 320x640 and 540x960, plus the existing normal/large-text matrix. Road and bed bounds never intersect. All 20 controls have unique in-bounds positions. Offline helper/stand tests include new bed 19 and repeated reconciliation.
- Two new deterministic 100-player simulation smoke reports (SIMULATION_08.json and REQUEST_SIMULATION_08.json) have zero invariant failures; historical simulation reports remain unchanged. Output-path flags let later runs preserve old evidence. These are synthetic tests, not human retention/pacing evidence.
- Actual engine previews include the three areas, starter locked-area cards, full 20-bed estate and narrow selector. All art remains independent/shared; no new generated asset pack or continuous animation is introduced.

## Remaining progression and acceptance work
This is the first property progression layer, not a complete long-term content plan. Nursery/greenhouse businesses, more species, area-specific production and later chapters remain future content. Simulations still expose rapid late XP growth and strategy-dependent pacing; tune milestones with independent sessions before promising days/weeks of content. Max-throughput capacity increases by 25% (16→20); it needs real-player balance review.

Midrange Android profiling, battery/thermal behavior, physical touch/safe areas, hardware audio/haptics and formal accessibility remain open. No APK, launch readiness, stable device FPS or retention is claimed. Keep the approved painted theme and stable plot identity in subsequent work.

Desktop timing fixture: 20 grown plants at 320x640, 180 sampled frames, median 33.95ms / p95 53.62ms, 90 scene nodes, virtual Xorg/Mesa llvmpipe. Raw result: UI_RENDER_METRICS.json. This single software-renderer sample does not establish a stable performance improvement or midrange Android acceptance.
