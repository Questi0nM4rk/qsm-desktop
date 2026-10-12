# 06 — Top panel

The centerpiece rollout from the top band. References: `references/dashboard-tab.png`,
`references/media-tab.png`, `references/performance-tab-launcher.png` (light), and the dark
performance capture `references/launcher-command-wallpaper-dark.png`.

## Status

- **RATIFIED (2026-08-16)**: full part of this desktop.

## Keyboard tab group

The tab bar is the shared `Segmented` control with host-owned
`ShellState.panelTab`, `tabNavigation: true` and `wrapNavigation: false`. Tab and
Shift+Tab, Left/Right and Home/End all run the library's own selection action, so
the group's keys mean what they mean everywhere else, and navigation stops at the
visible ends instead of wrapping. The panel opens focused on the group; Down
enters the selected tab's content, where that content's own keyboard handling
takes over. Escape closes. This is an explicit owner contract for THIS group,
not the library's default.

## Idle affordance + open

- The panel handle shows labelled CPU and RAM percentages instead of eight dots,
  following the owner's resource-readout direction. A compact, quiet rounded bulge
  sits on the panel's LEADING (bottom) EDGE: as the
  panel rolls out they travel WITH that edge — always at the surface's outermost rim, like
  a tab on a drawer front — and ride it back on retract; never parked at the band while the
  surface moves beneath them. A hover area spanning the reading opens
  the panel on hover, with a **150ms hover-intent delay** (DEFAULT) so a screen-top brush
  doesn't open an 854px panel.
- **RATIFIED (2026-08-16)**: also opens via keyboard (09: Super+D last-used, Super+N
  notification center, Super+W workspaces).
- **RATIFIED (2026-08-25, owner)**: with the panel open, **Left/Right move the tab
  selection** — the same horizontal vocabulary as the >theme carousel. Clamped at the
  ends, never wrapping. A focused text field (notification search) keeps its own cursor
  keys first; the tab step takes only keys no content claimed.
- **DEFAULT (2026-08-16)**: closes on: Escape, click outside, shortcut re-press, or cursor
  leaving the panel for 400ms. The panel and handle are horizontally centered in the live
  frame viewport between the left band edge and the right 16px frame edge; the center follows
  the live edge during pin, unpin, and peek. Tab bar at the panel's top, order: Dashboard,
  Media, Performance, Workspaces, Notifications — icon + label.

## Tabs

Per the references: **Dashboard / Media / Performance / Workspaces**, plus
**RATIFIED (2026-08-16)**: a **Notification center** tab — full history with fuzzy search
over title and body (see 04-notifications).

- **RATIFIED (2026-08-16, amended 2026-08-17 owner — caelestia-parity ruling)** Dashboard:
  the card grid of CURRENT caelestia (`~/Clonned/caelestia/repo` `modules/dashboard/Dash.qml`
  is the composition authority): user card (avatar + WM pill + uptime), weather card, media
  mini-card (cover + half-ring progress + transport), big datetime block, month calendar,
  resources card (three vertical usage rings — CPU/memory/storage). `dashboard-tab.png` is a
  capture of an OLDER caelestia: still valid for proportion/warmth checks, but its volume
  meters and identity-rows user card are superseded by the clone's anatomy.
- **DEFAULT (2026-08-16, amended 2026-08-17)** dashboard sources: weather = wttr.in fetch,
  cached 30min, location string from the persistence JSON (empty = IP-based), block hides
  when offline; identity = distro logo + WM pill + "up X unit, Y unit" (max 2 components);
  resources = usage fractions from PerformanceService (CPU/memory/storage).
- **RATIFIED (2026-08-16)** Media: exactly `media-tab.png` — circular artwork + progress ring,
  title/album/artist, transport + seek, per-player source picker (all MPRIS players).
- **DEFAULT (2026-08-16)** media fallbacks: no artwork → type glyph in the circle; no player →
  centered "nothing playing" empty state; default player = playing > paused > first seen.
- **RATIFIED (2026-08-16)** Performance: exactly the performance captures — three rings (GPU
  temp+usage, CPU temp+usage, memory+storage); each ring hides individually if its sensor is
  missing.
- **DEFAULT (2026-08-16)** performance sources: CPU temp from hwmon (k10temp/coretemp
  autodetect), GPU from nvml or amdgpu hwmon (autodetect), usage from /proc/stat and the GPU
  stack; the third ring's ARC shows memory-used fraction while storage shows as the side text
  (exactly how the capture reads).
- **RATIFIED (2026-08-16)** Workspaces: overview GRID of the focused monitor's workspaces in
  the theme-picker's thumbnail style; click focuses, DRAG moves a window between workspaces;
  also opens directly via **Super+W**.
- **DEFAULT (2026-08-16)** thumbnail mechanism: SCHEMATIC tiles, not live pixels (the
  compositor cannot capture unfocused workspaces) — each tile draws its windows as
  positioned rounded rects with the app icon; dragging a window-rect between tiles dispatches
  the compositor move. FLAGGED to the owner (changes the word "live").
- **RATIFIED (2026-08-21, owner)**: the window rects inside workspace tiles KEEP their 1px
  outline — the tiles are a diagram, not a surface, so 11-theme's flat-fill law does not
  reach them. Same ruling: workspaces lay out NEXT TO each other (one row, horizontal
  scroll when more workspaces than fit), never stacked below each other.

- **RATIFIED (2026-08-16)**: opening the panel lands on the LAST USED tab.

## Numbers (RATIFIED 2026-08-16)

- Panel width **854px**; height content-driven per tab; tab bar **48px**.
- Resource handle: `Theme.panelHandleWidth` × `Theme.panelHandleHeight`, fixed
  footprint independent of readings. CPU/RAM use metadata/technical text and neutral
  ink; missing sensors show an em dash, never zero. Fullscreen/focus suppression
  withdraws both paint and input. CPU is averaged before display; detailed sampling
  remains tied to the dashboard/performance tab.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | auxiliary resource glance and entry to the existing panel | owner CPU/RAM direction; no permanent dashboard | existing panel hover/click | inspect reading then open panel |
| ia/interaction | CPU and RAM labels, percentage each, one panel action | distinguish two readings without learned glyphs | Prose metadata; accessible button | absent sensors and keyboard activation |
| hierarchy/token | quiet ink, fixed compact pill, no accent on metrics | shell surface ladder | panelHandleWidth/Height; space2; textMuted; radiusMd | live text and containment |
| responsive/state | fixed size rides leading edge; hidden in fullscreen/focus | no second travel animation | PanelHandle → host-space rect → ShellBorder registerBulge → existing shader; mask consumes same rect | open/retract and suppression |
| polish | CPU exponential average, no number animation | instant readings oscillate; one useful value | PerformanceService, two-second lightweight sampling | changing load and missing sample |

The handle registers one undeformed body, with edge snapping disabled because its
attachment is the moving panel rim rather than a screen edge. It is removed
immediately on suppression/unload; the parent panel owns all reveal motion.
No shader formula changes, new global component, or Performance-tab redesign.

## LIVE-TUNE

- Widget paddings and tab-bar styling details against the references.
