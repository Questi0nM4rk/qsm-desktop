# 09 — Input and states

## Fullscreen

- Fullscreen belongs to a workspace, not the session or focused window. Each monitor
  uses its currently displayed workspace (the special workspace when one is open).
  Fullscreen clients on hidden workspaces never suppress another workspace's UI.
  Several workspaces and monitors can retain independent native fullscreen clients.
  Compositor maximization is not fullscreen; client-only fullscreen hints do not
  suppress chrome when the compositor still displays a normal window.
- On a visible workspace with a true fullscreen client, the band, rail,
  rail popouts, invisible handles, launcher, panel, clipboard, cheat sheet and session hide.
  Notification popups and the event-driven right-edge OSD remain above fullscreen clients on the
  compositor overlay layer; the OSD's idle hover handle stays inert. Other monitors are
  unaffected. This is an explicit allowlist, not a general exemption for shell surfaces.
- Super+F and Super+Shift+F toggle native Hyprland fullscreen for the active client.
  They do not enter the single-target QSM geometry transformation. Browser F11 and
  application fullscreen requests use the same per-workspace presentation policy.
- `FullscreenService.workspaceFor` resolves the displayed workspace;
  `fullscreenFor` reads compositor fullscreen from the shared client snapshot.
  Workspace, special-workspace, client moves and monitor changes refresh the
  metadata. Frame paint, input masks, exclusion zones, modals, backdrop, OSD and
  notifications all consume this screen-local state. A blocked workspace cannot
  block a modal on another monitor's normal workspace.

## Wallpaper

- Each monitor has an always-mapped, click-through Background-layer wallpaper.
  Fullscreen neither unloads it nor changes its source: the compositor covers it
  only where a fullscreen client is displayed. It fills the output with aspect crop,
  has no keyboard, pointer, wheel or accessibility target, and reserves no space.
- Deep Night uses `dark-rain-world.png`; Mountain Dusk uses
  `light-forest-dark-winter.jpg`. Theme selection owns the source and palette.
- `WallpaperWindow` loads the incoming image asynchronously, keeps the current
  image until readiness, then crossfades using the theme clock. Output geometry
  stays constant; missing/failed images keep the previous image or theme ground.
  This follows Caelestia's Background-layer host and ready-image handoff, not its
  desktop widgets or missing-wallpaper interaction. No interactive control pattern
  from Material, Radix or Fluent applies to a passive compositor background.

## Multi-monitor

- **RATIFIED (2026-08-16)**: global surfaces (launcher, top panel, session, OSD, notification
  popups) appear on the FOCUSED monitor. One global modal open at a time.
- Rail pin state is per monitor (03-rail).

Non-modal keyboard retention has one explicit owning surface, screen and purpose.
Only that screen gains exceptional keyboard focus and keeps its owning prompt
open. Only the owner releases its claim. A new claimant, modal replacement,
monitor departure, suppression or owner destruction retires the obsolete prompt
and secret; a kind string is not instance identity. Another monitor's popouts
and discovery handles remain independent. The global modal policy is unchanged.

## Click-through

- The scene is click-through everywhere except: the band/rail (peeked band included, full
  60px while peeked), open rollouts (their live revealed rect), and the invisible handle
  hover-areas (OSD handle, top-panel dots) — handle zones and the peek strip enter the input
  mask alongside the rollout registry (12-mechanism).
- **RATIFIED (2026-10-18, owner)**: one law for every hover-opened surface. "vsechno on hover
  elements maji exact on hover area jako jejich item hitbox ... ty ctyri tecky nahore, tam musim
  byt upe super presny ... musime to roztahnout, abych nemusel mit pixel perfect aim." A hover
  surface opens on ENTRY with NO delay, stays open while the pointer is inside the union of its
  trigger, its panel and the path between, and closes 180ms (`Motion.hoverGrace`) after it
  leaves. The trigger is never the painted shape: it is the shape grown by `Style.hoverReach`
  (20) on every side, clipped to the screen, and it sits in the input mask so the pointer is
  seen there at all (top-panel dots, OSD nub, notification bell corner). A rail cell is already
  a full tile and is its own trigger. The scene pointer reads the zones, never a HoverHandler a
  surface above would shadow.
- **DEFAULT (2026-08-16)**: opening a global modal REPLACES the currently open one and closes
  any open rail popout; rail popouts on other monitors are unaffected.
- **RATIFIED (2026-08-24, owner)**: an open surface owns its TRIGGERS as well as its region.
  While a global modal is open, every invisible handle hover-zone on that monitor is INERT —
  the zones stay in the input mask but do not open their surface. A handle zone is a
  discoverability target, and discovery is meaningless while the screen already belongs to
  something; worse, the zones lie UNDER the modals. The session column and the OSD share the
  right edge, so aiming at a logout button crossed the OSD strip and rolled the brightness
  bulge out from beneath the buttons (owner report). The top-panel dots already carried this
  rule; it is now one rule for every handle.
- **DEFAULT (2026-08-16)**: fullscreen beginning while surfaces are open hides them INSTANTLY
  (no retract animation), except notification popups and an already event-driven OSD under the
  fullscreen allowlist above.
- **DEFAULT (2026-08-16, implemented 2026-08-22)**: persistence file =
  `~/.local/state/qsm/state.json` — ONE file (was three under Quickshell's by-shell dir) —
  keys: theme, reducedMotion, reducedEffects, railPinned (per monitor name, as
  collapsedRails), lastPanelTab, dnd, weatherLocation, notificationHistory (bounded 200),
  nightLightTemperature and colorHistory (bounded 24) (03 quick actions).
- **RULING (2026-08-24, owner asked, agreed)**: persistence stays JSON. A database was
  considered for the desktop as a whole and the honest answer is "not as a prerequisite":
  measured, the state file is 6 KB with 26 notifications, so no write cost or size argument
  holds. The ONE real reason to revisit is that `notificationHistory`'s 200-entry cap exists
  BECAUSE it is JSON — if notification history is ever wanted as a searchable archive, that is
  the pass that earns a DB, and it moves the key rather than duplicating it (settings stay in
  JSON, where they are small and hand-editable). If it happens, use the `sqlite3` CLI through
  `Process`, not `QtQuick.LocalStorage`: LocalStorage is synchronous on the GUI thread and
  files the database under a Qt-chosen hashed path in `OfflineStorage` that Quickshell cannot
  redirect, while the CLI is async, keeps the file in our own state dir, and matches the grain
  the shell already runs on (nmcli, cliphist, qalc).
  ShellState owns the file; Theme and NotificationService read through it.
- **RATIFIED (2026-08-16)**: a rollout's hit-rect activates only NEAR-SETTLED (past ~90%
  revealed); sliding/retracting shapes are never click targets.

## Keybinds (RATIFIED 2026-08-16, Super-based, rebindable in the Hyprland lua)

- **Super+Space** launcher · **Super+N** the notification menu (the top-right bell, 04) ·
  **Super+W** top panel → Workspaces tab · **Super+D** top panel → last-used tab.
- **AMENDED (2026-08-19)**: the shell DECLARES its actions as Hyprland global shortcuts under
  the `qsm` appid rather than being driven by `exec, qs ipc call ...` binds. The compositor
  config names an action; the shell owns what it does. Rebinding never touches QML, adding an
  action never touches the compositor config, and no press spawns a process.
- **DEVIATION (2026-08-19)**: the notification centre sits on **Super+Shift+D**, not Super+N,
  on this machine. N/O/I/E is the directional focus cluster (SHIFT resizes, CTRL moves);
  breaking a four-key movement set for a panel tab is the wrong trade, and the panel family
  stays together on D. Super+Space / Super+W / Super+D are unchanged.
- **RATIFIED (2026-08-19)**: level keys (volume, mic, brightness) route THROUGH the shell,
  never through wpctl/brightnessctl in the compositor config. A tool writing the level behind
  the shell's back is invisible to it — which is why the brightness keys changed the screen
  with no OSD at all. Owning the write means the readout, the slider and the rollout all
  follow from one event.
- **RATIFIED (2026-08-27, owner)**: every shortcut that opens a toggleable shell surface
  closes that SAME surface on its next press. The shared default is ShellState's toggle path;
  Super+A uses the seeded `toggleLauncher(">action ")` variant. Direct system actions (lock,
  level keys, media) are not openable surfaces and remain actions, not fake toggles.
- **RATIFIED (2026-08-25, amended 2026-08-27, owner)**: **Super+A** toggles the launcher's
  `>action` mode, a fuzzy,
  keyboard-first representation of the safe rail quick controls. Typing filters; arrows move the
  existing single selection cursor; Enter runs the selected action and leaves the palette open so
  its new state is readable; Escape closes. This is keyboard and pointer driving the same quick
  controls, not a second feature route. Destructive or screen-taking rail actions do not enter
  this mode until they have an equally safe keyboard contract.

## System integration (RATIFIED 2026-08-16)

- The shell OWNS `org.freedesktop.Notifications`. Activation is a scripted swap: stop the
  previous daemon, claim the bus, verify a real notify/close round-trip, auto-restore the old
  daemon on any failure within seconds.
- Persistence (one small JSON): theme choice, per-monitor rail pin, bounded notification
  history, top panel's last tab, DND state.
- Delegation law: Hyprlock, Hypridle, external Polkit agent, NetworkManager, BlueZ, PipeWire
  stay untouched — the shell is UI only, delegating always.

## Session backdrop

- While the session surface is open: everything else dims and blurs; Escape and click-outside
  close (RATIFIED in 08-session — that file owns the law). NOTE: the blur backdrop is a
  second, dedicated overlay layer surface (compositor blurs beneath it) — the ONE sanctioned
  exception to the one-scene-window rule, since compositor blur requires its own surface.
- Backdrop namespaces and blur rules are output-specific. Opening or suppressing the
  session on one workspace must not blur another monitor; fullscreen/focus suppression
  disables both its dim paint and its compositor blur.

## Interaction laws (RATIFIED 2026-08-19, owner)

These bind EVERY interactive element in the shell — rail entries, popout rows, launcher
results, panel controls, notification cards, session buttons, sliders, tabs, handles.

- **No hover tint.** Hover NEVER answers with a background wash, fill, or tinted state layer.
  An element answers hover by GROWING — the affordance itself expands (scale, size, or a
  disclosed detail). Reason: a tint paints a box around something the design deliberately has
  no box for, and reads as a stuck selection; growth reads as a response.
- **Every input gets a visible response.** Hover, press and release are three distinct
  states. A press that produces no immediate change is a defect, even when the action itself
  takes time — the acknowledgement is the shell's, not the action's.
- **Continuous controls show their value while moving.** Any drag, scroll or wheel on a
  slider/seek/level control displays the live value (percent, or the control's own unit)
  for as long as the gesture runs, and for a short settle after it. "I moved it" is not
  feedback; "I moved it to 62%" is.
- **Typing owns the selection until the pointer moves** (RATIFIED 2026-08-24, owner). Pointer
  and keyboard drive ONE selection cursor on every list in the shell (see the one-path law
  below), so hovering a row selects it. But a list RESHUFFLES while you type, and a row that
  slides under a cursor that never moved is not a pointer gesture: from the first typed
  character until the pointer actually moves again, hover does not change the selection.
  Reason: searching with the pointer parked mid-launcher kept handing Enter to whatever
  landed under it. Moving the mouse a single pixel returns control — no timeout, no mode.
- **One path to one feature.** Each feature has exactly ONE route in the shell. Duplicate
  or competing routes are removed, not kept for convenience — a second route is a second
  thing to learn, to keep consistent, and to fix. Keyboard and pointer driving the SAME
  control is one path, not two.

## State vocabulary (RATIFIED 2026-10-16, owner)

Every interactive element speaks these states and no others; they sit under the laws above.

- **Hover** grows by transform (scale), never tints. A transform does not move layout bounds,
  so neighbours never jitter. Press pushes (scale down) in 80 ms; release returns in 130 ms.
- **Selected / current** is a state, not hover: `accent` at 12 percent opacity behind the row
  or tab (over `surface`), plus `accent` on its text or glyph. The current workspace is a
  20 px `accent` pill with its number in `textOnPrimary`. The current app row takes the 12 percent
  fill.
- **Focus** (keyboard): a 2 px `focus` ring outside the control, 2 px offset, visible on every
  focusable element, always, because the keyboard owns selection.
- **Disabled**: every colour of the control blended toward the band at `opacityDisabled`
  (0.35), never opacity on the composite. Non-current rows of a pick list recede by the same
  blend at `opacityRecede` (0.70), the lowest strength that keeps muted text above 4.5:1.
- **Status glyphs change shape** for state, not only colour (wifi, cable, wifi-off; bluetooth
  mark, the connected device's glyph; volume, volume-muted). Colour alone never carries
  meaning: a number or a glyph is the word, colour repeats it.
- **Thresholded readouts** (cpu, ram): the whole item (14 px glyph plus 12 px number, one
  thing) is `textMuted` below 70 percent, `warning` from 70, `danger` from 90.
