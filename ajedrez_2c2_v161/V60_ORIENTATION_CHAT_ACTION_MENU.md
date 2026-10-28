# V60 — Orientation + Chat Sidecar + Compact Action Menu

## Gameplay HUD
- GameActionMenu exposes only `Rendirse` and `Tablas`; the `Partida` title and explicit close button were removed.
- Horizontal chat uses the right-side space below the player panel. The same chat icon toggles the panel open/closed.
- HUD viewport relayout requests are coalesced through one deferred pass to avoid repeated expensive reflows during orientation changes.
- Portrait remains board-first; the board keeps the full viewport width and a perfect square.
- Contextual suggestion menus are clamped to the real viewport and action buttons adapt to the number of choices.
- Mobile typography scaling is capped at 1.35x to preserve readability without overwhelming the board.

## QA measurements at 360x640
- Sugerir button: 74x42 px = 1.3% of screen area.
- Full suggestion decision menu: 316x176 px = 24.1% of screen area.
- Rendirse/Tablas menu: 188x80 px = 6.5% of screen area.

## Safety boundary
- No 2c2 rules changed.
- No Sugerir mechanics changed: Sugerir remains a proposal flow and never performs a real move.
- Sugerir and Cambio remain 2c2-only.
