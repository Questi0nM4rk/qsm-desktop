# 09 — Input and states

## Fullscreen

- **RATIFIED (2026-08-25, owner)**: on a monitor with a fullscreen client, the band, rail,
  rail popouts, invisible handles, launcher, panel, clipboard, cheat sheet and session hide.
  Notification popups and the event-driven right-edge OSD remain above fullscreen clients on the
  compositor overlay layer; the OSD's idle hover handle stays inert. Other monitors are
  unaffected. This is an explicit allowlist, not a general exemption for shell surfaces.

## Multi-monitor

- **RATIFIED (2026-08-16)**: global surfaces (launcher, top panel, session, OSD, notification
  popups) appear on the FOCUSED monitor. One global modal open at a time.
- Rail pin state is per monitor (03-rail).

## Click-through

- The scene is click-through everywhere except: the band/rail (peeked band included, full
  60px while peeked), open rollouts (their live revealed rect), and the invisible handle
  hover-areas (OSD handle, top-panel dots) — handle zones and the peek strip enter the input
  mask alongside the rollout registry (12-mechanism).
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

- **Super+Space** launcher · **Super+N** top panel → Notification center tab ·
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
