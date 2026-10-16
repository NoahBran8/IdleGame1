# 0.6 art direction milestone

## Audit and approach
The 0.5 interface already exposed all existing gameplay through a compact HUD, world objects, navigation rail and bottom selector. The visual weaknesses were flat soil and icon-like buildings, sparse scenery, repetitive plant silhouettes, weak action hierarchy and crowded harvest labels at 320px. Domain rules, persistence and the UI routing were reviewed before this pass. Keep the functional shell and schema 5; improve the rendering within those boundaries.

Direction: a sunny storybook garden with terracotta, cream plaster, honey timber, layered green foliage, warm soil and turquoise water. Use light on upper/left surfaces, darker undersides and contact shadows. Keep illustrated surfaces quiet enough for growth indicators and focus outlines.

Asset strategy: original editable SVGs, imported once as shared textures. Each building stays a separate real Button. Plot sprites retain their own alpha-aware hit regions. Decorative trees/pond are scenery, with no pretend interaction. No reference image is used as a backdrop. No external pack, custom font, runtime dependency, shader, account or network permission is added.

## Implemented
- Five world illustrations: cottage, market, well, tree and pond, with material gradients, structural detail and consistent shadows.
- Five refined botanical crop illustrations reused by world and seed tray.
- Larger buildings on tall layouts, layered grass/hills, curved path, pebbles, fence detail, garden bench, pond and perimeter planting.
- Bevelled soil beds, inset surfaces, furrows and sparse deterministic soil texture. Locked beds retain distinct meadow/weed treatment and accessible tooltips.
- Three-blossom mature beds at plot widths >=75px. Each blossom uses the same alpha-aware bed hit routing and still awards one harvest per bed. Smaller screens retain one silhouette and a harvest checkmark instead of colliding labels.
- More tactile panel/button edges and shadows, a prominent green harvest action, selected seed medallions and gold HUD trim. Existing focus, disabled, high-contrast, large-text and reduced-motion behavior remains.

No model/service rule was edited. Application name and save schema remain Garden Empire / 5. Version 0.6.0 is an application/art version, not a new save format. Asset provenance is in assets/world/README.md and ASSET_LICENSES.md.

## Verification
- tools/verify.sh: 630 automated checks (140 core + 104 requests + 386 redesign), zero failures, plus headless runtime smoke.
- tests/smoke_interaction.gd: 25 rendered pointer checks, zero failures; two actual 8.1-second growth waits, harvest/sale, reservations/delivery and reload.
- tests/smoke_redesign.gd: 135 rendered checks, zero failures. Includes both side blossoms on all 16 full-size beds, one crop per bed, narrow plot hits, buildings, purchase cancel/confirm, decor, restart and settings.
- A rendered workflow initially exposed a stale button during the periodic 30-second autosave. The controller now saves without rebuilding panels for checkpoint-only ticks. Three added regression checks prove control identity, focus and persistence. Stock/income changes still refresh the displayed content.
- Actual seven-screen captures regenerated. Normal and 320px large-text garden renders inspected; the ten existing viewport/text-size combinations still pass geometry checks, including 320x568.
- Screenshots are actual Godot renders; dense-garden captures use explicit test fixtures, not real progression. No economy simulation rerun was needed because economic rules/data were unchanged.

## Outstanding
This is a further visual milestone, not a claim of chart-leading or launch-ready quality. Physical Android touch/safe-area, GPU performance, battery/thermal behavior, hardware audio/haptics, formal accessibility and independent art/usability review remain open. No APK or device performance result is provided. The existing software-renderer performance caveats still apply. Further art work can add more species-specific growth silhouettes and building upgrade appearances without changing earned progress.

Final 0.6 desktop timing sample: 180 frames, median 34.87ms, p95 55.62ms, 86 nodes at 320x640 using virtual Xorg/Mesa llvmpipe. Only one run; no stable improvement or device FPS claim. The earlier samples varied substantially. Raw results: UI_RENDER_METRICS.json.
