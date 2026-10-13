# 03 — Rail (left band)

The 60px left band hosting entries top-to-bottom; the only always-visible surface.

## Pin / collapse / peek

- **RATIFIED (2026-08-16)**: pin/unpin stays, **per monitor**. Pinned = band at 60px, windows
  reserve around it. Unpinned = band collapses to the plain 12px edge, windows take the space;
  hovering the collapsed edge peeks the full band OVER the windows (no re-tiling); leaving or
  retracting always clears the peek (explicit state, never a raw hover binding).
- **DEFAULT (2026-08-16)**: the peeked band renders through the same silhouette shader
  (elevated over windows) and its full 60px is mask-active while peeked; peek and an open
  popout may coexist (leaving both retracts both).
- **RATIFIED (2026-08-16)**: peek zone = the whole collapsed 12px strip, full height; opens
  instantly, clears **150ms** after the cursor leaves the revealed band.

## Entries

NetworkManager's cached Internet state is separate from the radio/link. The
network action-menu reading distinguishes full access, limited access, captive
portal and unknown. A previously online connection needs two consecutive valid
loss samples before one loss notification; continued polling cannot duplicate it.
Full access restores that episode once. Startup offline and failed/unknown probes
never fabricate an outage. The query is read-only, bounded to five seconds and
does not request an active connectivity check.

The network popout and command picker share NetworkService for radio, scanning,
connect/disconnect and VPN operation lifetime. Passwords go through stdin, never
argv or profile deletion. An unloaded prompt releases its keyboard grab and
cannot reopen from a late operation. Enterprise networks delegate to the manager.
The popout keeps its inline password, confirm-off, wired status and multi-VPN
routes; pointer and Return call the same submit function. Each input reports
intent separately from the backend result, with no password in event payloads.

- Icons only, vertically stacked; entries may expose a popout on hover.
- **RATIFIED (2026-08-16, amended 2026-08-17 twice — caelestia order, owner; amended
  2026-08-24 — TRAY moved into the workspace group, owner)**: lineup top→bottom: logo,
  then ONE group holding workspace dots, PIN and the tray icons, then the
  current-workspace app list (the middle section, spread across the free area — it
  REPLACES the old separate active-window entry; the active window is the highlighted
  row), then clock+date, status island (quick actions FIRST, then network, bluetooth,
  battery, sound — RATIFIED 2026-08-22, owner: the actions cell is the most reached-for
  and takes the most reachable slot; supersedes caelestia's awake-last order), power
  (danger-tinted).
  The 2026-08-24 amendment moves ONLY the tray, and moves it INTO the workspace/pin
  group rather than giving it one of its own. Two reasons, both owner-stated. At the head
  of the bottom cluster the tray sat directly beneath the app list, so an app's tray icon
  read as one more app row (the owner's Discord icon under his foot windows, separated by
  nothing but a divider). And a group of its own means a divider plus a gap that persist
  on a machine running nothing with a tray — inside the group, no tray icons is simply
  nothing to see. Tray rows take the group's 40px cell rhythm, not the 26px row they had
  before. The status island did NOT move: it stays below the clock, where it was.
- **DEFAULT (2026-08-16)**: logo entry is decorative — no click action, no popout.
- **RATIFIED (2026-08-25, owner — HyDE parity; amended same day)**: a SYSTEM UPDATES cell lives
  in the logo's group, directly under the arch mark: a Pacman-and-pellet glyph with the
  pending-package count as a
  small accent badge on the cell's corner (same pill language as the workspace number; badge
  absent at zero and while unknown — an absent badge never claims "up to date", the hover
  card does the telling). Count via `checkupdates` (read-only, local DB, 30min cadence).
  Click opens the FULL upgrade (repo + AUR) in a terminal and is the cell's one action; the
  hover card names the state and the count.
- **AMENDED (2026-08-17, owner)**: a NETWORK entry exists in the settings group — nmcli
  status + VPN up/down in its popout; anything deeper spawns nm-connection-editor. Sound and
  Bluetooth entries likewise popout quick controls and spawn the real app (pavucontrol /
  blueman-manager) — the shell never rebuilds settings UIs (delegation law).
- **RATIFIED (2026-08-24, owner)**: turning the Wi-Fi radio OFF **arms first** (one click arms,
  the next fires, 3s disarm) — it is the one control in that popout able to take the machine
  off the network it is being used over. Turning it back ON is a single click: restoring
  connectivity is never the mistake. An off radio reads LOUD — danger-coloured pill, `wifi-off`
  glyph, "Wi-Fi OFF · click to enable" — and the empty network list carries its reason, because
  a radio switched off three minutes ago otherwise looks like a shell that stopped finding
  networks.
- **RATIFIED (2026-08-24, owner)**: **Rescan reports.** `nmcli device wifi rescan` returns in
  ~50ms and the scan lands seconds later, so refreshing on its exit re-read the same list and
  the button did visibly nothing (measured). Rescan now shows "Scanning…" and re-reads three
  times over ~3.6s so the list visibly reorders, then stops saying it. It is DISABLED while the
  radio is off — a control with nothing to scan does not pretend otherwise.
- **RATIFIED (2026-08-16, relocated 2026-08-24)**: TRAY icons live in the workspace/pin group
  (see the lineup amendment above — they used to sit at the head of the bottom cluster);
  clicking one rolls out its menu as a standard popout (per
  `references/bluetooth-menu-popout.png`).
- **DEFAULT (2026-08-16)** tray menu rendering: the DBusMenu tree renders as popout rows —
  separators as faded short lines, submenus expand inline (indented) on click, checkable items
  use the icon-swap law, disabled items dim to 40%.
- **RATIFIED (2026-08-16)**: NO window-preview popout (owner reversed after reflection: you'd
  only ever preview the workspace you're already on — useless).
- **RATIFIED (2026-08-16)**: toggle-state entries (awake/coffee, and all future toggles) show
  state by SWAPPING THE ICON (empty cup ↔ full cup), NEVER by a glow/light ring around it.
  The current highlight treatment is abolished.
- Clock entry = HH above mm, with a smaller single-line `DD.MM` beneath the time.
  Day and numeric month sit side by side, never as separate vertical readings
  or a month name. Time uses the 18px technical reading, the date 12px, with
  metric-locked time digits and no date auto-shrinking.
  It is text-only, without a clock icon; hovering still opens the calendar popout.
  Reduced motion settles digit changes immediately without positional travel.
- **RATIFIED (2026-08-16, re-amended 2026-08-18 v2 — owner iterated on glass: reel out,
  traveling pill in)**: workspace indicator = FIXED dots + a TRAVELING numbered pill:
  ALL Hyprland workspaces globally (monitor-synced — every rail renders the identical
  column, active = the globally focused workspace); dots hold fixed positions (occupied
  filled, empty faint, urgent ringed); the ACTIVE workspace is marked by an accent pill
  that GLIDES between dot slots (popout-morph tier, no overshoot) carrying the workspace
  NUMBER inside it — the pill is the only moving part; its dot fades aside beneath it.
  NO app icons — app identity lives ONLY in the center app list. Wheel switches; click a
  dot jumps.
- **DEFAULT (2026-08-16)**: workspace model = Hyprland's dynamic per-monitor workspaces; one
  dot per EXISTING workspace of that monitor.
- **DEFAULT (2026-08-16)**: battery popout content per
  `references/battery-popout-corner-join.png`: charge % + time estimate (or "No battery
  detected"), current power profile line, and a power-profile switch row.
- **RATIFIED (2026-09-05, owner)**: the battery cell shows the CHARGE READING, not a
  battery glyph ("nechci battery icon, chci percentage"). Four battery shapes answer
  "roughly how full" with a picture you have to learn; the number answers it outright, and
  it is the only thing anyone reaches to that cell for. Charging is said in the accent
  colour rather than by adding a second glyph beside it, and low stays danger-tinted. A
  machine with no battery keeps showing its power profile glyph, because there is no
  reading to show there.
- **RATIFIED (2026-09-05, owner)**: the draw feeding the estimate is SMOOTHED — an
  exponential average, 0.3 weight per 2s sample, roughly the last ten seconds. Raw
  `power_now` is instantaneous and swings with whatever the CPU did in the last half
  second, so the estimate climbed three minutes and then fell back while the owner watched
  it: "obcas naroste o 3 min a pak klesne, ale spis roste". A number that moves the wrong
  way is worse than no number, because it teaches you to distrust the card. The average
  still lets a power-profile change show up within a couple of samples, which is the whole
  reason this reads the kernel file instead of UPower's own rate. First sample seeds it
  outright so the card never eases up from zero.
- **RATIFIED (2026-08-24, owner)**: the time estimate is DERIVED from the live draw
  (`energy / watts`), never taken from UPower's `time-to-empty`, and the **watts are shown
  beside it** ("3h 12m left · 14.1 W"). Reason: UPower smooths time-to-empty over its own
  history and re-reads the battery on its own ~30s cadence, so switching to performance left
  the card claiming the same hours as power-saver — the owner's report was "I select
  performance and the battery has the same life as with eco". UPower implements no `Refresh()`
  to poke (introspectable on the device interface, answers UnknownMethod), so the draw is read
  from the same kernel file UPower reads (`power_now`, microwatts) every **2s while the card is
  on screen** and nowhere else — the popout's own lifetime is the poll's lifetime. Falls back
  to UPower's `changeRate` where `power_now` is absent or zero, then to UPower's own estimate,
  then to "Charged". The wattage is the load-bearing half: the hours only round differently
  once the draw has moved a fair way, but the watts move the moment the governor does.
- **RATIFIED (2026-08-24, owner)**: the profile switch is OPTIMISTIC — the segmented
  indicator glides on the press, then reconciles against `powerprofilesctl get`. Waiting for
  the round trip meant a press with no answer (09: every input gets a visible response, and
  the acknowledgement is the shell's, not the tool's).
- **DEFAULT (2026-08-16)**: awake = idle-inhibitor toggle (inhibits Hypridle via the standard
  inhibit protocol); icons full-cup = on, empty-cup = off. Pin entry icons: pin / pin-off.
- Clock is 24h HH:MM, with the rail date `DD.MM`; calendar weeks start Monday.
- **DEFAULT (2026-08-16, contradiction resolved 2026-08-17 owner)**: which entries popout
  on hover: battery, clock (calendar — matching the RATIFIED hover law above; the earlier
  click-only bullet was a spec self-contradiction, hover won), media when present
  (`references/media-popout-over-app.png`). Tray icons open their menus on click; workspace
  dots have no popout (wheel/click only).
- **VETOED (2026-08-20, owner)**: the "media when present" popout is REMOVED from the rail. It
  was built (a cell above the tray, transport in its rollout) and then cut the same day: the
  top panel's Media tab already carries full media control and the dashboard carries a
  mini-player, so a third transport made THREE routes to play/pause — exactly what 09's
  one-path law removes rather than keeps. A DEFAULT is owner-vetoable, so this is the law
  working, not an exception to it. `references/media-popout-over-app.png` documents caelestia's
  behaviour and is no longer a target. The rail's hover popouts are therefore battery, clock
  (calendar), and the label/description/app/tray tiers.
- **RATIFIED (2026-08-20)**: media keys still route THROUGH the shell (`mediaToggle`,
  `mediaNext`, `mediaPrev`), because the shell owns the active-player decision and playerctl in
  the compositor config held a second, blind opinion about it. They need NO readout surface:
  a level is invisible until something draws it, but play/pause/next is audible the instant it
  lands, so the medium the control acts on IS the visible-response answer.
- **RATIFIED (2026-08-16)**: the rail's MIDDLE section lists the CURRENT workspace's apps —
  icon + short app name each, per monitor. When the workspace is empty it shows the default:
  a monitor icon + "Desktop" (as in `references/rail-closeup.png`).
- **DEFAULT (2026-08-16, amended 2026-08-18 — owner: "app · tab")** app-list mechanics:
  26px icon with a SIDEWAYS caption beneath (rotated 90°, ellipsized with … against its
  space — caelestia's bar object) reading **"app · live-title"** — identity first so the
  ellipsis can only eat the context tail; leading unread counters ("(2864) …") stripped;
  brand suffixes after a dash still dropped. Rows are click-to-focus; more rows than fit →
  the list scrolls (wheel), never overflows the band.
- **RATIFIED (2026-08-25, owner)**: group boundaries retain the 12px spacing step and their
  dividers. Items inside a group use compact 32px rows; workspace dots use the 4px step. Rail
  glyphs use the compact 16px step, with the top Arch logo as the deliberate 20px exception.
  Every reused divider is a 2px, 80%-opacity boundary so group separation remains legible.
- **RATIFIED (2026-08-16)**: calendar popout = MONTH GRID only — today marked, wheel/arrows
  change month, no events backend.

## Quick actions (RATIFIED 2026-08-20, owner)

- The coffee/awake cell is REPLACED by a **quick actions** cell (`zap`). Hover only — there is
  nothing for a click to do that the column does not do better.
- Its popout is not a card but a **SECOND RAIL**: glyph cells stacked under each other, 40px,
  **no labels**, in the same visual vocabulary as the left band. Anything a cell needs to say
  expands ONE STEP FURTHER RIGHT, which is the left band's own gesture applied recursively.
- **RATIFIED (2026-08-24, owner)**: a rollout's SIZE is one of two named options, declared by
  the surface rather than guessed at.
  - **description** (default) — hug the content. The right size for a sentence about the cell
    you hovered: name, state, what a click will do.
  - **match** — copy the height of the rollout this one came out of. For a surface that is a
    MENU rather than a note; it needs the room whatever it happens to be showing, and the
    shared height makes the seam between the two a straight line.
- **RATIFIED (2026-08-24, owner)**: NO DIPS AND NO BULGES at a nested seam. Two hosts that
  share a span join along an EXACTLY STRAIGHT line: square corners on the shared edge **and a
  blend factor of zero**, which the shader's `k = max(smoothFactor * param.y, 0.01)` floor
  turns into a hard `min()` — an exact union. Both halves are load-bearing, and the owner
  photographed the failure of each in turn:
  - rounded corners + smooth union = a **dip**. Each rect's radius curves away from the other
    and the melt reach (20) is smaller than the radii (28), so the fillet cannot close the
    wedge. 12-mechanism's edge snap already states the corner half of the rule ("corners on a
    snapped edge go square: they are inside the merged body now, and a radius there draws a
    notch at the seam"); it was simply never applied to a popout-to-popout seam.
  - square corners + smooth union = a **bulge**. The circular smin ADDS material wherever both
    fields sit inside the reach, so a flush seam grows a fillet outward instead.
  A third piece was ratified for the line still drawn down the parent's right edge: the
  parent's **rim must extend THROUGH the seam** (rim bits). `edgemelt.frag` warns about exactly
  this for a rollout meeting its band, so a rollout meeting another rollout was given the same
  treatment.
- **AMENDED (2026-08-25, measured)**: the third piece is INERT, and a fourth piece is what
  actually closes the seam. `bandRimStrength` is 0 — the rim is switched off and contributes
  nothing — so extending the rim copy could never have removed anything. What draws the line is
  the **exact union itself**. Two rects that merely TOUCH leave the merged SDF at ZERO all along
  their shared edge, and zero is the shader's definition of "edge" in two independent places,
  both computed from `mergedSdf` alone and neither reachable by any rim change:
  - `alpha = 1 - smoothstep(-fw, fw, mergedSdf)` dips to ~0.5, so the wallpaper shows through as
    a translucent hairline. This is the "mini gap" the owner reported.
  - the glass stroke's `innerDepth = -mergedSdf` reads ~0, so a full-strength lit line is
    painted straight down the join.

  Measured on HDMI-A-1 with the colour menu open, one pixel row across the join at physical
  y=540: fill is a uniform `#15081E` from x=60 to x=490, then spikes at x=156..160, peaking
  `#655B6B` either side of a `#443E46` dip — a bright double-ridge with a dark core, present at
  every y down the shared span. The shape's REAL outer edge at x≈492 shows no such spike, which
  is what proves the seam is inventing an edge rather than receiving normal edge treatment.

  **The fourth piece, and it has two halves.** Both are needed; each alone leaves a visible
  artefact, and the owner saw each in turn.

  1. **The two silhouettes must OVERLAP, not merely touch.** A silhouette reaches
     `Theme.seamOverlap` INTO each neighbour it is flush against — the sides its rim bits
     already name, since that is the same question. Reaching in is invisible: that side is
     covered by the neighbour's body by definition. The overlap's SHALLOWEST point is its
     midpoint, at depth `overlap / 2`, so it must clear the stroke width; `bandStrokeWidth * 4`
     leaves the midpoint at twice the stroke with room for the ~1px derivative AA.
  2. **Blend 0 must be a real `min()`, not `smin` with a floored k.** This spec asserted that
     the shader's `k = max(smoothFactor * param.y, 0.01)` floor "turns blend 0 into a hard
     min()". It does not — the circular smin does not converge to min as k falls. For equal
     inputs it reduces to `smin(a, a, k) = sqrt(2) * a + k * (1 - sqrt(2))`, so at `a == b` it
     inflates the INTERIOR distance by 41% however small k is. The zero crossing is barely
     touched (at `a == b == 0` the deviation is only `-0.414 * k`), so the silhouette's outline
     and its input mask were always right; but the glass stroke measures
     `innerDepth = -mergedSdf` against `strokeWidth`, and a flush seam is the worst case
     because the two fields are EXACTLY equal there. Across the overlap the stroke believed it
     was 1.4x deeper inside and stopped drawing, so the edge kept its outer row and lost its
     inner one — which the owner reported as "a dent in the glass edge, from the inside only,
     not going outwards". Fixing the overlap without this half simply moves the artefact from a
     line to a dent.

  Verified by re-scanning the same row and the top edge: fill uniform `#15081E` straight
  through the join, and the glass edge is byte-identical at every x across it
  (`#3B3042` / `#32263A`), with the outer edge and the rail-to-popout join unchanged.
  All three apply ONLY where the two shapes actually meet edge to edge. A description-sized card
  sits mid-flank, keeps its blend, keeps its parent's rounding, and leaves real exposed edge
  above and below itself that the rim belongs on — a T-junction wants the fillet, and it never
  wedged.
- **The rightmost rollout keeps the whole column open.** A parent popout holding an open child
  does not retract, and the pair retires together only once the pointer has left both. Without
  this, travelling into the detail card reads as leaving the column and takes it down.
- Level-2 content is a **description tier** — name, current state, what a click will do.
  This is what makes an unlabelled glyph legible, so the tier is load-bearing here rather than
  a fallback. Quick actions declare their own kinds: `main-keyboard`, `keepawake` and `clearcache`. A cell
  needing a real CONTROL gets its own tier in the same place (night light, below) rather than a
  second route to the setting: the level-2 card is the one home for whatever a quick action can
  be adjusted by (09 one-path).
- **RATIFIED (owner)**: a rollout's `kind` is the COMPONENT's own identity — there is no
  generic `label` kind and no fallback. Every popout-owning cell declares one, so a report and a
  `selected` test name the component that opened the rollout: `network`, `bluetooth`, `battery`,
  `sound`, `app`, `tray`, `calendar`, `actions`, `nightlight`, `colorpick`, `updates`, `railpin`,
  `session`, `main-keyboard`, `keepawake`, `clearcache`. Sharing a BODY is not sharing an identity: the
  description body serves every descriptive kind (`updates`, `railpin`, `session`, `main-keyboard`, `keepawake`,
  `clearcache`) and none of them is identified by it. A component that appears many times (every
  app row, every tray icon) is distinguished by its ANCHOR cell, not by a kind invented per
  instance. `QuickActionCell` therefore requires `popoutKind`; a decorative entry with no popout
  simply declares none.
- **Destructive actions arm-then-fire**, confirming in the level-2 rollout (the same surface
  that names them) and disarming after 3s or when the pointer leaves. An unlabelled glyph that
  fires an irreversible action on one click is a trap.
- Actions REPORT. An irreversible action tells you what it did in the same detail card —
  bytes freed, the colour picked — because "something happened, amount unknown" is not an
  outcome.
- Contents: main keyboard (toggle, directly above keep awake), keep awake (toggle), night light (toggle + WARMTH
  slider, hyprsunset delegated), clean caches (destructive), pick a colour (hyprpicker, result
  to clipboard and to a notification on the shell's own bus). Growable; anything needing real
  UI belongs in its own popout or a delegated app instead.

- **RATIFIED (2026-08-24, owner)**: the colour picker's level-2 rollout IS its menu (a level
  THREE rollout was built and rejected: the features belong in the surface already open, not
  one step further out). It carries three features — **History** (every pick, newest first, deduped, bounded at 24: past what a person
  can scan it stops being a memory aid and becomes an archive, which is a different feature
  with a different storage answer), **Harmony** (opposite + both triads of the selected colour,
  same lightness and saturation so they read as a set), and **Shades** (a five-step fixed
  lightness ramp — a ramp has to land in the same places whatever it was picked from, or it is
  not a scale). The SELECTED colour is the newest pick by default and any history swatch by
  click, so the workspace is about a colour rather than about the last thing that happened;
  clicking a history swatch both selects and copies it, one action with two honest effects.
  Every swatch is copy-on-click and ONE readout line does the talking: hover discloses a value,
  a click says it was taken. The pick still ANNOUNCES through a notification (picking hijacks
  the screen and carries the cursor far from the rail, so the card that started it has closed
  by the time a colour exists); the workspace is what you come back to. There is deliberately
  no "pick again" control anywhere in the chain — the cell it all hangs off already is that
  control (09 one-path).
- **RATIFIED (2026-08-24, owner)**: the menu ends in an **Open colour editor** row, which hands
  the colour at the TOP to a real editor (`oklch-color-picker`, behind the `colorEditor`
  Delegate role) and takes back what comes out as a new pick — top row, history, clipboard,
  exactly as a screen pick lands. This is NOT a second picking route: picking reads a pixel off
  the screen, editing changes a colour already held. Different actions, one control each. The
  shell does not build an editor — delegation law, and 03's own "anything needing real UI
  belongs in a delegated app". Cancel is EMPTY STDOUT (the tool prints on Done and prints
  nothing on Quit — read from its source), handled exactly as hyprpicker's cancel is: a
  decision, not a failure, and it must not overwrite what was there. Missing tool names the
  package rather than going quiet.
- **RATIFIED (2026-08-24, owner)**: night light has a **strength slider** in its level-2 card.
  It is scaled as WARMTH (0 = neutral, 1 = warmest), not as Kelvin — warmth rises as Kelvin
  falls, so a Kelvin slider would put a control on screen whose right-hand end means less of
  the thing it is named after. The scale runs hyprsunset's own default **6000K** (strength 0,
  no visible warming) down to **2500K** (strength 1, roughly candlelight; below it the screen
  stops being usable rather than becoming warmer). The card shows the live value while the
  gesture runs — percent, with the Kelvin beside it because that is the number every other
  night-light tool speaks in (09: continuous controls show their value). Dragging while night
  light is OFF turns it ON: an input that changes nothing visible is not an answer. The chosen
  warmth PERSISTS (09 persistence key `nightLightTemperature`). The daemon restart is debounced
  ~150ms behind the finger, because hyprsunset has no live socket — changing the warmth means
  replacing the process, and a drag reports every pixel.

### Main keyboard quick action

| layer | decision | why | token or pattern | owner check |
| --- | --- | --- | --- | --- |
| posture/task | Temporarily disable the built-in keyboard, then restore it with pointer or another keyboard. External keyboards are untouched. | The owner's existing shortcuts target `at-translated-set-2-keyboard`, not Hyprland's current `main` device. | Transient quick action; one `main-keyboard` CLI/helper | Disable and recover with an external keyboard or pointer |
| ia/interaction | One cell directly above Keep awake; click toggles, description names current state, next action and recovery shortcut. The command picker mirrors the same service. | Existing rail description tier; UI Craft laws 3, 7 and 9 | QuickActionCell, DescriptionPopout, LauncherSurface dispatch tables | Repeated click/Enter retains the selected item and shows the outcome |
| hierarchy/token | Enabled: keyboard in text colour. Disabled: keyboard-off in quiet warning amber on the rail; the picker uses the same crossed-out glyph. Unavailable: muted. No background glow or badge. The picker Switch means **keyboard disabled**, not enabled. | Owner requests first-glance state; shape and colour both carry it. Amber means deliberately suppressed input, not selection or an operation error. Reuse the existing switch pattern. | MainKeyboardService.glyph; Theme.iconSm/text/warning/textMuted; Switch sm, Accessible.name | Distinguish enabled, disabled and unavailable without hover or colour alone |
| responsive | Rail size stays constant; its column gains one cell; description wraps and picker text elides in existing bounds. Wheel remains owned by the host. | Existing compact shell layout | QuickActionsColumn clearance, Theme.popoutWidth, ResultRow | No clipping at the screen edge or during reveal |
| state | Pending refuses repeat activation; unknown/missing device/helper refuses toggling; failures stay visible with retry. Poll and hover refresh changes made through shortcuts/CLI. | No optimistic success or invented enabled state | MainKeyboardService.available/busy/error; native control states | Enabled, disabled, pending, unavailable and failed states |
| input/reach | Preserve Super+Ctrl+D disable and Super+Ctrl+Shift+D enable. Both call the same helper as CLI; keyboard navigation and focus use the existing picker, rail stays pointer-led. | One operation, not synthesized key events | main-keyboard enable/disable/toggle/status; existing menu keys and Accessible naming | Recovery from the disabled state, focus visibility and spoken name |
| polish | Inherit existing hover/press/focus/disabled and reduced-motion behaviour; no new motion. | Owner-approved component system | RailEntry/StateLayer, Switch, Motion | Existing state feedback remains consistent |

Hyprland 0.56.2 does not expose per-device `enabled` through `devices`, `getoption`
or `hl.get_config`. A Lua helper holds the state it applies through `hl.device`;
initial configuration, both shortcuts and CLI use it. Config reload restores the
existing enabled default. Direct ad-hoc `hl.device` calls bypass this managed state.
No persistent flag file, compositor restart, new tokens or new library component.
Physical key delivery, live layout and screen-reader output await owner review.

## Popouts

- Open/retract motion belongs to the shared shell Rollout small tier. `BarPopouts`
  retains a render-only selection while closing, so content and dimensions ride
  the same extrusion until hidden. `currentBody` and named control targets stop
  reporting that dismissed item immediately; its retained Loader is disabled.
  Reopening during close updates selection and reverses the shared motion without
  a delayed fade/unload callback. Content switches use the existing size morph,
  not a second host-owned open/close effect.

- Popouts are rollouts (02-rollouts law): flush with the band, one silhouette, corner
  auto-join near top/bottom edges.
- **RATIFIED (2026-08-16)**: popouts open INSTANTLY on entry hover; while open, sliding to
  another entry MORPHS the popout in place (glides to the new entry's height, content swaps —
  one continuous shape). Reveal position rule: the popout appears AT the hovered entry's
  height — the morph animation runs only between two already-open positions, never on first
  reveal.
- **RATIFIED (2026-09-07, owner — SUPERSEDES the ~180ms closing grace):** ~~a rollout is
  never held open by TIME. It is held open by WHERE THE POINTER IS, and it closes the moment
  the pointer is somewhere else.~~ **SUPERSEDED the same day, below.**

- **RATIFIED (2026-09-07, owner — SUPERSEDES the wording immediately above):** every rollout
  uses one rule: a hitbox larger than the item, covering the corridors a pointer actually
  sweeps through, and 180ms after the pointer leaves that hitbox the rollout closes.

  The keep-open region is the union of: the anchor cell, the band the popout grew out of, the
  popout itself, every descendant popout currently open, and the TRAVEL TRIANGLE from the
  anchor cell to the popout's near edge — the wedge a hand actually sweeps when it moves
  diagonally from an entry to a card that is clamped away from that entry's height. This region
  is still what decides WHETHER the pointer is holding the rollout open — a timer alone answers
  "has enough time passed" when the only question that matters is "is the pointer still on this
  thing", and it cannot tell travelling from leaving. That is still true, and it is why the
  region does the real work: every stuck and every snap-back defect recorded against the old
  two-moment lifecycle (closeTimer/scheduleClose/childClosed) came from deciding closure at two
  moments with a timer in between rather than from one region test.

  What changes: the CLOSE is no longer instant on the region's true-to-false transition. It is
  delayed 180ms (`Motion.hoverGrace`), and a region re-entry within that window cancels the
  pending close. The region still supplies the corridor coverage a hand sweeps through; the
  delay only covers what a region test, evaluated once per frame at a hard boundary, cannot: the
  last few pixels of a fast exit and the frame in which the pointer is between two positions.

  ONE exception, and it is not about the pointer: while a keyboard grab stands (a Wi-Fi
  password being typed) the popout does not close, and the release re-decides immediately —
  no delay on that path.

  `BarPopouts` supplies these areas to the shared library Rollout. `RailPopoutStack` owns
  both controllers and applies keyboard/dismissal policy to their `keepOpen` verdicts.
  `EdgeScene` and the Workbench provider host that same stack; neither duplicates its
  lifecycle, containment or grace timer. Workbench native input reaches the same ancestor
  `ScenePointer` and the actual control handlers without moving the system cursor.

  A rollout opening is not the story's whole behaviour, so the controls INSIDE it report
  themselves too, through their own handlers: an entry or cell reports `hover-entered` and
  `hover-left` on arrival and departure (not on every move), `clicked` on a real click, and
  a destructive cell reports `armed`/`disarmed` around the confirmation and `fired` once it
  runs. The warmth slider reports the END of one gesture with the percentage it landed on
  and never claims whether that was a drag, a wheel notch or a key, because the control
  cannot tell them apart and a record that guesses is worse than one that does not. The
  colour menu reports each actionable row — pick, history select, both copy routes, the
  editor — since its delegates are not reachable by name from outside it.

  These are SEMANTIC events, not raw input: nothing reports a synthetic move or a repeat
  of a position. One pointer route produces them — a live click and a simulated click on
  the same cell are the same event, because both go through the same handler and the
  workbench driver never manufactures a record of its own. Where a result is the honest
  fact (a toggle's new state, a sweep's result, a copy of a hex already held), it is read
  from the service rather than from the click, so a repeat that changes nothing is still
  reported and a reset that restores defaults is claimed by nobody.

  ACCEPTED COST: the travel triangle has to be in the input mask to receive pointer events,
  and a mask is rectangles, so the wedge's bounding box is not click-through WHILE A POPOUT IS
  OPEN. Clicking there is already ambiguous — a click outside an open popout is a dismissal —
  so the cost buys the rule rather than fighting it.
