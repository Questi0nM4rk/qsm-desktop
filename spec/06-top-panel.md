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
takes over. Escape closes. The focus ring marks the picked tab while the group has keyboard focus:
from a key open, or from the first key after a pointer open; a click hides it. This is an explicit owner contract for THIS group,
not the library's default.

## Idle affordance + open

- **RATIFIED (2026-10-17, owner; replaces the clock bump of 2026-10-16)**: the panel handle
  is a tiny DOTS bulge: an 8 px tall bulge out of the top band, bottom corners 4 px, `band`
  fill, four `text` dots as the drawer's grip, each three device pixels (2.4 px at 1.25) and
  four device pixels apart (3.2 px), padding 0 4, so the row and the bump stand on whole device
  pixels. The clock stays in the rail (03). It sits on the panel's LEADING (bottom)
  EDGE: as the panel rolls out it travels WITH that edge — always at the surface's outermost rim, like
  a tab on a drawer front — and rides it back on retract; never parked at the band while the
  surface moves beneath it. Hover over the bump opens
  the panel on Dashboard AT ONCE, no hover-intent delay (owner 2026-10-18: "rollouts open on
  entry, no delay"; the 150ms intent of 2026-10-17 is gone); a click opens it at once too. The
  hover zone is never the 8 px paint: it is the bump as painted at rest grown by
  `Style.hoverReach` (20) on every side and clipped to the screen (owner 2026-10-18: "ty ctyri
  tecky nahore, tam musim byt upe super presny ... musime to roztahnout, abych nemusel mit
  pixel perfect aim"), so the 27.2 x 8 px bump is a 67.2 px wide target reaching from the screen
  edge down to 36 px. The zone stays parked at the rest position while the handle rides the
  panel rim and sits in the input mask, so the pointer is seen there. The handle has no popout
  of its own.
- **RATIFIED (2026-10-18, owner)**: the top panel holds the calendar that READS AND WRITES,
  synced with an external calendar app (khal with vdirsyncer, task `qsd-zss`); the rail
  clock keeps the read-only quick view (03). Not built yet.
- **RATIFIED (2026-08-16)**: also opens via keyboard (09: Super+D last-used, Super+N
  notification center, Super+W workspaces). A key, the IPC or a launcher command opens it at full
  depth in one frame and a key closes it the same way; the dots handle keeps the rollout's motion (10).
- **RATIFIED (2026-08-25, owner)**: with the panel open, **Left/Right move the tab
  selection** — the same horizontal vocabulary as the >theme carousel. Clamped at the
  ends, never wrapping. A focused text field (notification search) keeps its own cursor
  keys first; the tab step takes only keys no content claimed.
- **DEFAULT (2026-08-16)**: closes on: Escape, click outside, shortcut re-press, or cursor
  leaving the union of the handle zone and the panel for 180ms (`Motion.hoverGrace`, owner
  2026-10-18; was 400ms). The panel and handle are horizontally centered between the nearest
  structure on each side: the rail band while it is shown (the monitor's edge when it is not) and
  the monitor's right edge, never the frame that runs along it; the center follows the live
  edge during pin, unpin, and peek. Tab bar at the panel's top, order: Dashboard,
  Media, Performance, Workspaces — label only (a control is a glyph or a label, never both). Notifications left the panel for the
  top-right bell (04, owner 2026-10-17).
- **RATIFIED (2026-10-16, owner)**: the current tab is `accent` text on an `accent` 12 percent
  pill, no underline bar. Panel cards are `surface` with radius 12.
- **DEFAULT (2026-10-22, owner: rebuild to the research and the skills)**: dashboard cards carry
  the library Card's edge separation (the silhouette's own treatment, inside the card's edge) and
  `surface` stands one ladder step off the band (11-theme). A card's glyph is neutral (`textMuted`:
  weather, distro mark, network graph) and a load ring or meter is `text` until 70 percent, `warning`
  to 90 and `danger` above (`Theme.loadTone`), because the accent is for what is current and a
  colour appears only when its state is true.

## Tabs

Per the references: **Dashboard / Media / Performance / Workspaces**. The notification
center is not a tab (owner 2026-10-17): it is the bell's menu in the top-right corner
(04-notifications).

- **RATIFIED (2026-08-16, amended 2026-08-17 owner — caelestia-parity ruling)** Dashboard:
  the card grid of CURRENT caelestia (`~/Clonned/caelestia/repo` `modules/dashboard/Dash.qml`
  is the composition authority): user card (avatar + WM pill + uptime), weather card, media
  mini-card (cover + half-ring progress + transport), big datetime block, month calendar,
  resources card (three vertical usage rings — CPU/memory/storage), all cards `surface` radius
  12 and padding `rolloutPadding`. `dashboard-tab.png` is a
  capture of an OLDER caelestia: still valid for proportion/warmth checks, but its volume
  meters and identity-rows user card are superseded by the clone's anatomy.
- **DEFAULT (2026-08-16, amended 2026-08-17)** dashboard sources: weather = wttr.in fetch,
  cached 30min, location string from the persistence JSON (empty = IP-based), block hides
  when offline; identity = distro logo + WM pill + "up X unit, Y unit" (max 2 components);
  resources = usage fractions from PerformanceService (CPU/memory/storage).
- **RATIFIED (2026-08-16)** Media: exactly `media-tab.png` — circular artwork + progress ring,
  title/album/artist, transport + seek, per-player source picker (all MPRIS players).
  **RULED (2026-10-19, owner: "NENAVIDIM RANDOM UI JUMPING")** the tab is a constant width (the
  panel column, `Theme.mediaContentWidth`) and the text block hangs from the artwork's top with
  one fixed slot per line, so a track change moves neither the transport, the seek row nor the
  text; a long title, artist or album elides.
- **DEFAULT (2026-08-16)** media fallbacks: no artwork → type glyph in the circle; no player →
  centered "nothing playing" empty state; default player = playing > paused > first seen.
- **RATIFIED (2026-08-16)** Performance: exactly the performance captures — three rings (GPU
  temp+usage, CPU temp+usage, memory+storage); each ring hides individually if its sensor is
  missing. Three equal columns over two rows of one height: the rings, then the network card over two
  columns and the battery over the third.
- **RULED (2026-10-19, owner: "Pridej trochu shadows, separations. At to nevypada vibecoded")**
  Performance cards take the edge separation like the dashboard's; the battery shows its level
  as a thin meter (`text`, or `danger` below 15 percent and not charging) beside text on the
  plain card, not as a tinted tank. Every load ring and meter reads `Theme.loadTone`.
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
- **RATIFIED (2026-08-21, owner)**: workspaces lay out NEXT TO each other (one row, horizontal
  scroll when more workspaces than fit), never stacked below each other. The window rects inside
  a tile carry no outline: they sit one ladder step off the tile, like every other body. The
  tiles sit in one `surface` card that fills the content box, in its middle; the strip shows
  that more lie past an edge by the edge fade alone, with no scroll mark, and the wheel moves
  it a tile at a time.

- **RATIFIED (2026-08-16)**: opening the panel by keyboard lands on the LAST USED tab; the
  dots handle (hover or click) opens Dashboard.

## Numbers (RATIFIED 2026-08-16)

- Panel preferred outer footprint **848x536 logical px**, clamped to the scene's
  available viewport. The panel is a compact rollout like the rail's (owner: "vsechny rollouts
  jsou moc daleko a maji moc okoly, zmensil bych to na polovinu"): `Theme.panelPadding` (8, half of
  the shell's rollout padding) all round, its free corners at `Theme.panelRadius` (20, the body
  radius plus that padding) so every card inside stays concentric. The width is a multiple of 8,
  so both edges land on whole device pixels when the panel is centred between the rail band and
  the monitor's right edge, and its content (the width less the padding, 832) splits into three
  equal card columns of 272; the tab bar's four segments are whole device pixels wide (the
  library's `Segmented`), and the height leaves two card rows of 228.
  All four tabs share that footprint, a stable navigation strip and one content box: the tab
  bar's left and right edge, one `Theme.panelGap` below it. A tab never centres itself in that
  box; Dashboard and Performance fill it with cards, Media and Workspaces are one card that fills
  it with their content in its middle. Cards are `Theme.panelGap` (8) apart, as far from the
  panel's edge, and share one padding, `rolloutPadding`. Tab choice, empty/missing data and content length never resize the outer
  body. Dashboard and Performance fit the body without scrolling (owner, 2026-10-18:
  "rozsir ho tak, aby dashboard a performance nemuseli scrollovat"); only a screen too short for the clamp scrolls. Model-backed tabs keep their own scrolling route. The tab bar baseline is **48px**.
- Dots handle: 8 px tall, width = four 2.4 px dots + three 3.2 px gaps + padding 0 4 (27.2 px),
  bottom corners 4 px.
  Fullscreen/focus suppression withdraws both paint and input. Detailed sampling remains tied to the dashboard/performance tab.

The handle registers one undeformed body, with edge snapping disabled because its
attachment is the moving panel rim rather than a screen edge. It is removed
immediately on suppression/unload; the parent panel owns all reveal motion.
No shader formula changes, new global component, or Performance-tab redesign.

The permanent panel host owns keyed detailed-sampling demand while Dashboard or
Performance is active. A retiring tab never writes a global polling false that
cancels another monitor's demand. Lightweight handle subscriptions remain
independently keyed. Empty Media content is deliberately centered, and short or
narrow screens expose overflow rather than clipping controls or resizing a tab.

## LIVE-TUNE

- Widget paddings and tab-bar styling details against the references.
