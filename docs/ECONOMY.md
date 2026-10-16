# Economy
Initial plant and plot costs follow the supplied specification. Values are initial hypotheses. Currency uses bounded integer arithmetic.

## Implemented M2 rules
Carrot 5/8s/9, sunflower 12/20s/24, rose 30/45s/65, lavender 70/90s/155, orchid 180/180s/420 (seed/growth/sale). Base profits: 4, 12, 35, 85, 240. Seed costs and base prices unchanged.
- XP: harvest 2/4/8/15/30; each 40 XP adds a level. Planting currently grants no XP.
- Upgrade tables in data/upgrades.json; eight categories, bounded levels. Prices round(base × 1.55^level) except the exact supplied plot ladder.
- New growth duration: ceil(base × (100 − 5 × compost − 5 × irrigation) / 100).
- Sale value: floor(base × (100 + 5 × baskets) / 100).
- Harvest XP: floor(base XP × (100 + 25 × learning-garden) / 100).
- Flower stand: 150 coins, sells one real item every 10 seconds. Signage reduces interval to 8/6/4 seconds. Helper costs 600 and harvests ready plants every 5 seconds.
- Currency uses integer arithmetic with a 9e15 cap; capped sales keep unsold inventory.
- Offline cap: 28,800 seconds. No retroactive upgrade effect or duplicate payout cursor.
- These are implementation defaults, not empirically validated balance. Simulation and playtesting remain required.

## Executed simulation (10,000 runs)
Seed 20261015. One hour with visits every 8–20s in the first minute, then every 30–180s; one return at day 1 and at day 7, each subject to the 8h cap. Four strategies, 2,500 players each. JSON report: SIMULATION_RESULTS.json. No negative wallets, invalid states or empty-garden seed dead ends in these policies.

| Strategy | Median 1h coins | Median 1d coins | Median 7d coins | Median stand unlock |
| --- | ---: | ---: | ---: | ---: |
| Fast profit | 44,439 | 49,143 | 54,410 | 2,661s |
| High margin | 44,372 | 49,216 | 54,442 | 2,660s |
| Collector | 23,065 | 26,264 | 30,758 | 1,773s |
| Thrifty | 231 | 231 | 231 | 2,192s |

### Findings and limits
- Base profit/second and absolute profit rise together across species. Fast-profit/high-margin policies converge on orchids, reducing meaningful choice. This is a balance defect to revisit before retention tests.
- Most investment-heavy simulated players reach 16 plots inside one active hour; XP levels can grow into the hundreds with no further level-gated content. Do not present this as adequate long-term progression.
- Stand purchase is delayed by these policies' upgrade priorities. A stand-first player can reach 150 coins much sooner; simulated stand times are not inherent minimum unlock times and do not validate the 1–3 minute FTUE goal.
- Thrifty policy invests mostly in expansion/stand and plants carrots. Long waits waste short crop cycles; it falls far behind. Compare active play styles with real humans before retuning.
- No autoreplanting means long offline absences exhaust the planted garden and stocked inventory. Little growth in the wallet between day 1 and day 7 is expected, not unlimited passive production.
- Small zero coin balances in some collector snapshots are not dead ends: seeds are planted or stock exists.
- Whole-second growth and integer sale rounding mean the first 5% upgrade may not change carrot duration/value. Shop displays the actual selected-species before/after values.
- These are synthetic policies, not retention, monetization, user satisfaction or revenue estimates. No economic tuning was silently changed to make the simulation look successful.

Next: test early stand discovery and upgrade choices with independent players, then retune progression curve, plant ROI tradeoffs and investment pacing, rerunning deterministic simulations after each material change.
