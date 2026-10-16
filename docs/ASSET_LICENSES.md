# Asset provenance
All procedural graphics and UI authored for this project. No third-party art, audio, fonts or runtime dependencies added. Godot built-in font is distributed by Godot under its bundled licenses. No ownership or trademark clearance is asserted.

Original synthesized audio: scripts/services/audio_service.gd, generated sine wave with envelope, no samples or external assets.
Screenshots in docs/screenshots are actual Godot 4.6.3 OpenGL renders via Mesa llvmpipe. garden-start is a fresh game. garden-demo and garden-320 are deterministic test fixtures, not real player progression.

0.4 art additions: procedural flower petals, lavender stems, rose curls, sunflower centres, carrot leaves, garden rim/fence and irrigation can in scripts/ui/{plot,garden_board}.gd. All drawn for this project, no imported image assets or external licenses added. The additional garden-requests screenshot uses fictional neighbour names and a seeded inventory fixture.

0.5 artwork: original SVG source for five plants plus coin, inventory, requests, journal, settings, cottage, stand and decor icons in assets/ui/. See assets/ui/README.md for provenance. No external asset pack, downloaded illustration, custom font or reference-image crop was introduced. Plant textures are imported once and reused by selector and world; scenery/buildings are separate original Godot vector objects. Visible plant pixels have their own alpha-aware hit regions. The font remains Godot's bundled font under its bundled notices.

Screenshots are actual engine captures. Dense garden, decor, inventory and confirmation images use explicit test fixtures; garden-start is a fresh game. This is not player-research or device validation.

0.6 artwork: five original editable world SVGs in assets/world/ (cottage, market, well, tree, pond), plus refined original five-plant SVGs in assets/ui/. Authored for this repository with Codex assistance; no external source images, competitor assets, reference crops, font downloads or third-party asset packs. See assets/world/README.md. Landscape/soil/button additions are original native Godot drawing. World buildings remain independent visible controls; mature plant clusters share alpha-aware bed hit regions.
