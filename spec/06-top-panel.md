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

- **RATIFIED (2026-10-17, owner; replaces the clock bump of 2026-10-16)**: the panel handle
  is a tiny DOTS bulge: an 8 px tall bulge out of the top band, bottom corners 4 px, `band`
  fill, four 2 px `textMuted` dots 3 px apart as the drawer's grip, padding 0 4. The clock
  stays in the rail (03). It sits on the panel's LEADING (bottom) EDGE: as the
  panel rolls out it travels WITH that edge — always at the surface's outermost rim, like
  a tab on a drawer front — and rides it back on retract; never parked at the band while the
  surface moves beneath it. Hover over the bump opens
  the panel on Dashboard, with a **150ms hover-intent delay** (DEFAULT) so a screen-top brush
  doesn't open the panel; a click opens it at once. Its hover popout is the month calendar (kind `calendar`): today marked, weeks start
  Monday, wheel or arrows change the month. The clock is 24-hour HH:MM.
- **RATIFIED (2026-08-16)**: also opens via keyboard (09: Super+D last-used, Super+N
  notification center, Super+W workspaces).
- **RATIFIED (2026-08-25, owner)**: with the panel open, **Left/Right move the tab
  selection** — the same horizontal vocabulary as the >theme carousel. Clamped at the
  ends, never wrapping. A focused text field (notification search) keeps its own cursor
  keys first; the tab step takes only keys no content claimed.
- **DEFAULT (2026-08-16)**: closes on: Escape, click outside, shortcut re-press, or cursor
  leaving the panel for 400ms. The panel and handle are horizontally centered in the live
  frame viewport between the left band edge and the right frame edge; the center follows
  the live edge during pin, unpin, and peek. Tab bar at the panel's top, order: Dashboard,
  Media, Performance, Workspaces — icon + label. Notifications left the panel for the
  top-right bell (04, owner 2026-10-17).
- **RATIFIED (2026-10-16, owner)**: the current tab is `accent` text on an `accent` 12 percent
  pill, no underline bar. Panel cards are `surface` with radius 12.
- **TRIAL (2026-10-17, owner: "try all three")**: dashboard cards carry the library Card's
  granular edge glow (the silhouette's own treatment, inside the card's edge), each card's
  glyph takes its pastel (the mark `accent`, weather `info`, the resource rings
  `success`/`warning`/`danger` by load), and `surface` stands 1.45:1 off the band (11-theme).
  The owner judges which of the three stay.

## Tabs

Per the references: **Dashboard / Media / Performance / Workspaces**. The notification
center is no longer a tab (owner 2026-10-17): it is the bell's menu in the top-right corner
(04-notifications).

- **RATIFIED (2026-08-16, amended 2026-08-17 owner — caelestia-parity ruling)** Dashboard:
  the card grid of CURRENT caelestia (`~/Clonned/caelestia/repo` `modules/dashboard/Dash.qml`
  is the composition authority): user card (avatar + WM pill + uptime), weather card, media
  mini-card (cover + half-ring progress + transport), big datetime block, month calendar,
  resources card (three vertical usage rings — CPU/memory/storage), all cards `surface` radius
  12. `dashboard-tab.png` is a
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

- **RATIFIED (2026-08-16)**: opening the panel by keyboard lands on the LAST USED tab; the
  clock bump (hover or click) opens Dashboard.

## Numbers (RATIFIED 2026-08-16)

- Panel preferred outer footprint **854x520 logical px**, clamped to the scene's
  available viewport. All five tabs share that footprint and a stable navigation
  strip. Tab choice, empty/missing data and content length never resize the outer
  body. Static compositions overflow inside a bounded viewport; model-backed
  tabs keep their own scrolling route. The tab bar baseline is **48px**.
- Dots handle: 8 px tall, width = four 2 px dots + three 3 px gaps + padding 0 4 (25 px),
  bottom corners 4 px.
  Fullscreen/focus suppression withdraws both paint and input. Detailed sampling remains tied to the dashboard/performance tab.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | time and date glance and entry to the existing panel | clock leaves the rail; no permanent dashboard | existing panel hover/click | inspect reading then open panel |
| ia/interaction | time and date, one panel action | one glance, one entry | Prose metadata; accessible button | keyboard activation, minute rollover |
| hierarchy/token | `band` bulge, `text` time 13 px Mono medium, `textMuted` date 12 px | one silhouette with the band; lightness, not chrome, carries it | role `band`, text scale | live text and containment |
| responsive/state | rides leading edge; hidden in fullscreen/focus | no second travel animation | PanelHandle → host-space rect → ShellBorder registerBulge → existing shader; mask consumes same rect | open/retract and suppression |

The handle registers one undeformed body, with edge snapping disabled because its
attachment is the moving panel rim rather than a screen edge. It is removed
immediately on suppression/unload; the parent panel owns all reveal motion.
No shader formula changes, new global component, or Performance-tab redesign.

The permanent panel host owns keyed detailed-sampling demand while Dashboard or
Performance is active. A retiring tab never writes a global polling false that
cancels another monitor's demand. Lightweight handle subscriptions remain
independently keyed. Empty Media content is deliberately centered, and short or
narrow screens expose overflow rather than clipping controls or resizing a tab.

The permanent panel host owns keyed detailed-sampling demand while Dashboard or
Performance is active. A retiring tab never writes a global polling false that
cancels another monitor's demand. Empty Media content is deliberately centered, and short or
narrow screens expose overflow rather than clipping controls or resizing a tab.

## LIVE-TUNE

- Widget paddings and tab-bar styling details against the references.
