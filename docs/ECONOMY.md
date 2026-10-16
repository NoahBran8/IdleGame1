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
