# Backlog

Things deliberately deferred, with enough context to pick them up cold. Not a task tracker —
each entry records what was found, so the next session does not re-derive it.

Current checks and the remaining release gates: [Release handoff](#release-handoff).

## Source-reviewed interaction gaps

- Owner-directed visual touchups preserve vertical app captions and the acceptable
  menus. The first source-prepared item is the stable upper panel with a preferred
  854x520 logical px footprint, bounded static overflow and unchanged model-tab
  scrolling. Supporting changes are a shared violet surface ladder, larger HH/mm
  above a smaller single-line DD.MM, a 224x36 mirrored CPU/RAM handle and 12px ordinary frame
  edges with the left band/rail retained at 60/40px. The Performance stories expose
  normal and short/narrow viewports plus unavailable/zero/full samples with a
  fixed battery record. Other preview tabs remain navigation-only until their
  isolated fixtures are prepared. All live geometry, focus, transitions, both
  outputs/themes and owner visual acceptance remain unverified because the
  owner did not request runtime checks. The remaining plan, including rounded
  notification rows without action-policy changes, is tracked in
  `openspec/changes/refine-quiet-luminous-desktop/tasks.md` and `qsd-r87.1`.
- Workspace-local fullscreen has read-only live evidence for a fullscreen client
  retained on a hidden workspace while both displayed workspaces keep normal
  frame, rail and exclusion state. Fullscreen entry/exit, simultaneous displayed
  fullscreen clients, special-workspace switches, client moves and owner acceptance
  remain unverified. The agent performed no restart, input injection or hardware
  operation. `qsm status` reports `workspacePresentation` for each output.
- Theme artwork is local-only: both committed theme JSONs and the Theme fallback
  reference `dark-rain-world.png` or `light-forest-dark-winter.jpg`, but Git tracks
  only the generated `deep-night.png` and `mountain-dusk.png` assets. A fresh checkout
  therefore lacks the referenced images. This is a source-confirmed distribution
  defect, left unfixed because the scope audit does not choose between distributable
  artwork and a local override (`qsd-i63`). Mapped wallpaper layers on both outputs do not
  establish image readiness or rapid-theme-swap behavior.
- Source-confirmed ownership gaps remain unexercised: `EdgeScene.handlesArmed`
  disables all monitors for one global modal, although the spec limits suppression
  to its monitor. `keyboardGrab` names a prompt kind without a surface/screen owner,
  retains every rail stack, and grants keyboard focus to whichever output is focused.
  Prompt closure/destruction can release another instance's grab. Left for a named
  scope repair, not silently changed during the audit (`qsd-om3`).
- Launcher retirement follows the global modal name rather than each monitor's
  activation. A hidden instance can retain its password/editor and restart focus
  work on a late failure. `submitNetwork()` also clears the password only after an
  accepted backend start, contrary to the rejected-submission contract. Both paths
  are source-reviewed, not runtime-exercised, and await the launcher lifecycle repair.

- Launcher audio, Wi-Fi, Bluetooth, repeatable toggles and panel tabs are
  source-prepared and exercised through isolated desktop Workbench stories.
  Live owner review, actual hardware and screen-reader behavior remain open
  (`openspec/changes/refine-desktop-controls-and-focus`); production was not restarted.

- The revised notification popup is source-reviewed and loaded on the existing Quickshell
  `NotificationServer`; D-Bus activation maps to the existing `Type=exec` unit
  and qsm-run supervisor, and startup waits for the bus-name owner PID. This is
  not a fresh production-session verification. `scripts/test-notification-bus`
  passes external-client Notify/replacement/action/close/expiry routes on a private
  bus through the production service and renderer. The notification
  production/actions OpenSpec change still owns live acceptance and Wayland
  activation-token questions. Keep JSON as bounded searchable text history;
  upstream protocol persistence remains unsupported.
- Quickshell upgrade: installed 0.3.1, stable 0.3.2 is available in Arch and fixes
  notification action-label updates. The package upgrade is deferred; it needs
  a separately approved full system transaction. Its action `textChanged` signal
   now reaches the service's copied presentation records through per-action
   connections. Re-check upstream label-only replacement after the upgrade;
   the current private-bus check is not proof of the upstream fix.

The remaining source-reviewed gaps are outside the current release repair scope.
The personal production goal includes real desktop use;
the ordered component roadmap is `../qsm-shell/GOAL.md` (relative to repo root).

- R4: dashboard cards keep the library radius while several PerformanceTab cards override
  it with `Theme.rolloutRadius`. Confirm intended consistency during parent-view review;
  overrides alone are not a defect and need no blanket removal.

- Rail wheel routing now uses one MouseArea dispatch path, including workspace
  switching. Real Wayland wheel and overlapping targets remain unverified.
- Network/Sound/Bluetooth/Battery popout intents now forward through BarPopouts
  and RailPopoutStack. Whole-popout native pointer and keyboard routes remain
  owner-review work, separate from backend completion signals.
- Colour swatches fit the fixed content width through a tighter token gap;
  long shortcuts scroll horizontally rather than clipping. Native readability,
  horizontal wheel/drag and screen-reader routes remain unverified.
- `ModalHost.qml:52` only announces activation. Launcher calculator/probe and clipboard
  thumbnail work can complete after dismissal. Define which read-only work should cancel
  and reject stale results; do not cancel intentional clipboard-copy work on close.
- `LauncherSurface.qml` retains unreachable dispatch branches; clean up with its
  lifecycle work rather than adding alternate routes.
  A 248px content-width comment is not inherently stale: the 280px popout has 32px padding.

## Own the crash UX — BUILT 2026-08-22 (`scripts/qsm-run`)

The supervisor below exists now: `QS_DISABLE_CRASH_HANDLER=1`, relaunch on any exit,
3-crashes-in-60s loop cap, crash notice through the shell's own bus, flock against config
reloads, crash-dir pruning (keep 5), and an explicit stop protocol (`qsm-run --stop` —
exit codes cannot distinguish crash from kill because of the PipeWire teardown abort below).
The hyprland.lua autostart launches it. Lifecycle proven live: SIGKILL → relaunch + bus
notice; --stop stays down. The original analysis is kept below for the env-var reference.

Follow-up 2026-08-27: the supervisor's lock descriptor had been inherited by
qsm-spawned helpers (observed: `hyprsunset`), so a surviving helper could retain
`qsm-run.lock` after Quickshell exited and block every restart. `scripts/qsm-run`
now closes fd 9 in the `qs` child (`9>&-`) before it can be inherited.

## Own the crash UX (original analysis)

**Can we write our own crash window?** Not in-process, and the reason matters: Quickshell's
crash handler runs **post-mortem**. By the time it draws, the process has aborted and the QML
engine is gone, so there is no engine left to render a QML window with. The dialog is C++ inside
the `quickshell` binary (`Crash Handling: ON` in the build info).

What IS available — three env vars found in the binary:

| Var | Effect |
| --- | --- |
| `QS_DISABLE_CRASH_HANDLER` | Suppresses the built-in handler and its dialog entirely |
| `QS_CRASHREPORT_URL` | Repoints the dialog's "Open report page" button |
| `QS_NO_RELOAD_POPUP` | Suppresses the reload popup (separate annoyance, same family) |

So the shape of the work is a **supervisor**, not a window:

1. Launch with `QS_DISABLE_CRASH_HANDLER=1` so the upstream dialog never appears.
2. A small wrapper owns the lifecycle: start `qs`, watch for a non-zero exit, relaunch it.
3. The wrapper reports through the shell's OWN notification bus once the restart is up —
   the shell owns `org.freedesktop.Notifications`, so a crash notice can be a normal
   notification with the crash directory as its body, instead of a foreign Qt dialog.
4. Optionally point `QS_CRASHREPORT_URL` at our own tracker instead of upstream's.

The one thing to be careful about: a crash loop must not become a notification loop. The
wrapper needs a backoff and a cap (e.g. give up after 3 crashes in 60s and leave the dialog
enabled for that run, so the failure is visible rather than silently churning).

## Upstream: Quickshell aborts during PipeWire teardown on every shutdown

**Not ours.** Every shutdown — `qs kill` and reload alike — ends in `Signal: Aborted (6)` with
an identical stack: `abort` ← `QDebug::~QDebug()` ← Qt Core, i.e. Qt's `qFatal` path. The last
log lines are always Quickshell unbinding PipeWire objects:

```text
Unbinding object PwNode(0x…, id=59/bound)
Unbinding object PwDevice(0x…, id=52/bound)
```

Confirmed pre-existing: a crash from **2026-08-19**, before any of this session's work, has
byte-for-byte the same signature. It only became noticeable on 2026-08-20 because that session
restarted the shell ~9 times, producing 9 crash directories in an afternoon.

Consequences worth knowing:

- Crash directories accumulate in `~/.cache/quickshell/crashes/` (18 as of 2026-08-20). Nothing
  prunes them.
- The shell **auto-restarts** after the abort ("Quickshell has been restarted" in the log),
  which is why `qs kill` followed by a check can still find a live instance — and why
  `scripts/validate`'s smoke suite refuses to run, reporting a live instance seconds after a
  kill. Wait for the restart to settle, or kill twice.

Next step if it is worth chasing: reproduce with `QS_DISABLE_CRASH_HANDLER=1` and a debug build
to get symbols past frame #6, then file upstream. Nothing in `shell/` touches PipeWire teardown,
so there is no local fix.

## Deferred from the 5+5 round (2026-08-20)

Picked but not yet built:

- **F3 — keybind cheat sheet: BUILT 2026-08-20.** `SUPER + /` rolls a top-center reference
  card out of the top band (`shell/modules/cheatsheet/CheatSheetSurface.qml`); it reads
  `hyprctl binds -j` live on every open, fuzzy-filters over combo+description, Escape and
  click-outside close, rows are reference-only. The data-source blocker (lua binds report
  as opaque `__lua` with no text) was solved at the source: every bind in
  `~/.config/hypr/hyprland.lua` now carries `{ description = "..." }` — documented on the
  wiki, probe-confirmed in `hyprctl binds -j` (93/93 described). A future undescribed bind
  is FILTERED from the sheet, not shown empty; the fix is describing it in the lua.
  Sizing is LIVE-TUNE (owner has not seen it yet).
- **F5 — notification popup actions.** MEASURED FALSE 2026-08-20: the popup CAN act. Action
  buttons render in the hover-expanded card (shared `NotificationCard.qml`) and a real
  round-trip was proven — `notify-send -A ok=Confirm`, cursor-driven click on the button,
  client printed `ok` and exited. The stale "cannot act at all" observation predates the
  shared card, or was masked by the critical-expiry bug fixed the same day (criticals
  expired in 1ms, so sticky actioned notifications were never on screen to click). Remaining
  gap is keyboard Enter on the POPUP, which spec/04 requires only for the centre — and a
  second route may violate 09's one-path law. Owner call: close F5, or ratify popup Enter.
- **Clipboard rollout** — `SUPER + V` opens a dedicated top-left rollout, reachable no other
  way. Requires REMOVING `>clip` from the launcher (down to `>calc >kill >theme`), or clipboard
  has two routes.
- **S1 — DONE 2026-08-22** (`4fe9da6`): cap 5, evicted entries slide up into the band
  clipped and unfaded, newcomers enter from below, 250ms — plus the same-day one-state-file
  merge (`a04fa0a`, DND now persists) and the dashboard radius unification (`e108a1a`).
- **S2** — keyboard focus affordance across launcher, panel tabs, notification centre.
  Narrowed after the owner ruled the rail hover-only.
- **S4** — launcher polish: row rhythm, empty and degraded states.
- **S5** — cross-rollout token audit against the one ladder (`spec/11`).

**The closing code review — CLOSED 2026-08-25.** The original review ran in
`b8259e4` (−248 lines); the leftover candidates from that round are all
resolved:

- ~~`AwakeEntry.qml` unreferenced~~ — already removed in `b8259e4` (the
  BACKLOG claim was stale; `shell/scripts/awake` is the LIVE AwakeService
  script and stays).
- ~~`BarPopouts.minBodyHeight`~~ — already removed with the rejected
  shared-height approach; only the historical comment remains.
- ~~`hover-probe`/`cursor-warp` overlap~~ — DONE 2026-08-25: hover-probe now
  drives the pointer through the marketplace `qsm-compuse` drive; the
  repo-local `cursor-warp` is deleted (see the tooling section below).
- `Delegate.argv` — CHECKED, earns its generality: six roles call it
  (compositor, brightness, powerProfile, colorEditor, clipboard, lock) across
  services and surfaces. No action.

Unpaid spec bills, cheap:

- ~~DND does not persist~~ / ~~three state files~~ — both PAID 2026-08-22 (`a04fa0a`):
  one `~/.local/state/qsm/state.json`, dnd among its keys.
- **`qalc` IS installed and `>calc` works** (owner 2026-08-25, after the old
  "not installed" claim kept resurfacing across sessions). Do not re-raise it.

## RESOLVED: the colour pick lands end-to-end (2026-08-25)

Closed by driven proof, no owner hover needed. The service-side fixes from
2026-08-24 (drop `-q`, keep `-r`) were the root cause; what was missing was the
live proof through the menu's OWN swatch:

- `popoutTest colorpick 2 true HDMI-A-1` → `hitProbe` at the top swatch's
  center lists its StateLayer — the click path was live.
- Driven click on the swatch → `pickBusy` true (swatch reaches `pick()`).
- Driven pixel click → `pickLast "#131011"`, history 2→3, notification posted.

Follow-up the proof surfaced: the pick notification's icon box drew a wrong
purple square (`--icon=color-select` resolves to a theme icon that is not a
swatch). The card now derives a colour swatch from the announcement itself —
appName "Colour picker" + hex summary → the box shows THE picked colour,
including archived rows.

## Little-things round — BUILT 2026-08-24

All four measured items landed, plus the owner's same-day asks. Commits:
`b6be7a4` (network), `239c711` (colour workspace), `e5ed510` (audit minors +
notification spacing), `1d362aa` (night light), `0fdbd9b` (battery),
`0f72c64` (session keyboard), `2e5d1b1` (rail tray), `9b7c04c` (LevelBar).

- **Rescan** — DONE. Re-timed at 0.049s, confirming the measured cause. Says
  "Scanning…", re-reads 3× over ~3.6s, disabled while the radio is off.
- **Wi-Fi foot-gun** — DONE. Off arms-then-fires (3s disarm), off state is
  danger-coloured and names itself, empty list carries its reason.
- **Notification-centre spacing** — DONE, and it was NOT the knobs the earlier
  round listed. The list spacing (4) and section header (8) were already right;
  the cost was `Theme.space2 * 3` of trailing pad inside an always-expanded
  card whose headline is a fixed 36px box. Now space2. ~77px → ~61px per
  one-line row. Owner still gets the final say on the feel.
- **Colour-picker workspace** — DONE. Swatch + Harmony (opposite + both triads)
  + Shades (3 fixed lightness steps), copy-on-click, one hover/copied readout.
  No HSL helper needed: QML's color type carries hslHue/hslSaturation/
  hslLightness and Qt.hsla() rebuilds one.

### Still open from the 5+5 and the audit

- **S2 — keyboard focus affordance.** Launcher and notification centre already
  mark their selection (tick + row dim, tick thickening). PANEL TABS — BUILT
  2026-08-25: Left/Right step the tab selection while the panel is open
  (clamped, session-surface vocabulary), with an IPC seam + smoke coverage.
- **UX-3 — `>theme` carousel.** BUILT 2026-08-25: hover now SELECTS (one
  cursor, like every result surface) — the hovered card becomes the centered
  card, hover growth removed, and Enter applies the selected card.
- **UX-8 — `>kill` rows.** BUILT 2026-08-25: kill mode separates rows with
  space3 (12px) instead of 4px — a mis-hover no longer sits one row-gap from
  an irreversible kill; Enter-kill stays deliberate with no confirm (07).
- **F5 — superseded contract:** popup body activation is planned for the exact live
  `default` action only; named-action choices remain in the notification center.
  This is a planning decision, not an implementation or external-client proof.

## Little-things round (owner 2026-08-22, original measurements)

The owner's ask: "focus on the little things so everything is working and usable" — with
Ox Alpha (opencode `big-pickle`) as implementation helper per the qsm-opencode module.
Found/measured before the session wrapped:

- **Rescan is a dead button (MEASURED).** `nmcli device wifi rescan` returns instantly,
  `actionRunner.onExited → refresh()` fires before scan results exist, so the list never
  changes and nothing says "scanning". Fix shape: on rescan, show a scanning state on the
  capsule, delay the refresh ~3s (or poll twice), and let the list visibly reorder.
  `NetworkPopoutContent.qml` (rescan capsule + actionRunner).
- **Wi-Fi toggle is a foot-gun (LIVED).** One click kills the radio with no confirmation
  and no dramatic "wifi is OFF, click to re-enable" state — the session itself turned the
  machine's wifi off while testing. Radio-off should read loudly and re-enable in one
  obvious place; consider arm-then-fire like destructive session buttons.
- **Notification-center rows "too spaced out" (owner feel, not yet tuned).** Measured
  knobs: `NotificationCenterTab.qml` historyList `spacing: Theme.space1`, section header
  `topPadding: Theme.space2`, card internals in `NotificationCard.qml`. LIVE-TUNE with the
  owner watching — do not blind-tune.
- **Colour picker wants a workspace (FEATURE).** Today the quick-action fires hyprpicker
  and copies the hex; the owner wants to WORK with the picked colour: opposites
  (complement), palette generation (shades/triads), copy rows. Design sketch: the pick
  reports into the quick-action's level-2 detail card (the rail's expand-one-step-right
  vocabulary; one path law) — picked swatch + complement + 3 shades + copy-on-click rows.
  Needs a small HSL helper lib in QML; Ox Alpha can generate the colour math.
- **General**: the owner's standing note — "there is so much that isn't tested". The
  human-trial list in docs/audit-2026-08-20.md plus a driven pass over bluetooth/battery/
  sound popouts, media transport, calendar paging, `>calc` (qalc now installed), remain
  unexercised.

## Tooling: fold the repo's drive scripts into qsm-compuse — DONE 2026-08-25

Owner ruling 2026-08-21, now paid. The marketplace `drive move` was already
the one calibrated-ydotool implementation, so the repo side was all that
remained: `scripts/hover-probe --move` now positions and restores the cursor
through `drive pos`/`drive move` (resolving `$QSM_MARKETPLACE`), and
`scripts/cursor-warp` is deleted. Verified live: `hover-probe --move eDP-1
25 450` fires real hover (StateLayer hovered, app popout rolls out) and
restores the pointer.

## Not a shell problem, but worth doing

`~/.cache` is **65G**: `uv` 30G, `yay` 14G, `omarchy` 4.8G, `pre-commit` 2.8G. All live caches
with recent access times, so the quick-action cache sweep correctly leaves them alone — it only
takes stale files and regenerable derived data. Reclaiming the big ones is a manual call with
their own tools (`uv cache prune`, `yay -Sc`).

Note when measuring: `du` on this machine is aliased to a graphical tree tool, so
`du -sb X | cut -f1` returns a tree fragment rather than an integer. Use `/usr/bin/du`.

## Animation + keyboard polish round (2026-08-26)

Owner preference: keyboard-first, no mouse hover. Likes crisp icons, responsive selections,
nice spacing, slight in/out animations with easing out. Dismiss via search, not archiving.

Keyboard vocabulary: Colemak-DH Vim motions are the default where a surface has no text
entry: `n` = left, `e` = down, `i` = up, `o` = right. A focused search or text field always
keeps literal typing, so its list uses arrow keys instead; tab rows and carousels use `n`/`o`.
Never steal focus for transient UI. The action picker remains the
single route into control surfaces: `Super+A` toggles the existing `>action` command menu.

### Built

- **Notification card entrance** — popup cards fade in + scale up (opacity 0→1,
  scale 0.97→1.0, 180ms ease-out). The panel's always-expanded cards bypass the
  animation and remain visible. `entranceProgress` is set on the next event-loop
  turn after construction. NotificationCard.qml, line ~100.
- **Notification entry is action-picker-only** — popup notifications are visual
  and never claim keyboard focus. Reach the panel from `>action` → `Panel tabs`
  → `Notifications`; Super+D, Super+Shift+D, and Super+N intentionally have no
  qsm binding (Super+N is reserved for the owner's Colemak-DH navigation).
- **Direct notification action + keyboard centre flow** — `>action` also has a
  direct `Notifications` item. Centre rows start collapsed; Up/Down changes the
  selected row, Enter expands/collapses it, Delete dismisses a live entry, and
  Escape closes the panel. While expanded, Tab/Shift+Tab moves the action cursor
  and Enter invokes that deliberate action. The search field retains keyboard
  focus throughout, so ordinary typing remains ordinary typing.
- **Notification-panel entrance** — REJECTED after owner trial. A ListView
  populate/add transition flickered rather than sliding due to delegate setup;
  removed. Keep panel rows stable until a driven proof establishes a reliable
  animation mechanism.
- **Launcher selection pulse** — the existing 3×18 selection tick scales out
  by 25% and settles over 80ms whenever a launcher or clipboard row becomes
  selected. No layout movement or row background was added.
- **Action picker direct destinations** — Session menu and Notifications open
  their rollout/panel on the first Enter. Only actions with genuine child
  choices or safety confirmation retain a detail row.
- **More one-item detours removed** — Brightness now dims/restores and Keep
  awake now toggles on the first Enter. Cache cleanup and colour picking keep
  their confirmation step; network, Bluetooth, sound, power, night light, and
  panel tabs retain details because they expose multiple choices.
- **OSD micro-pop** — the channel column settles from 0.97 to 1.0 scale in
  120ms ease-out on OSD entry. It changes no rollout silhouette, connection,
  or handle geometry. `Motion.microPopScale` and `Motion.microPopDuration` are
  now the shared source for popup-notification entrance motion and every
  Rollout's content settle: panel, launcher, session, clipboard, popouts, OSD,
  notifications, and test surfaces. No rollout may own a local entrance pop.
- **Keyboard owns selection** — a deliberate search/navigation key now hides
  the pointer's ability to change selection and prevents resting hover targets
  from changing selection. Click interaction remains explicit. Hyprland's
  `cursor.hide_on_key_press` remains disabled: its global hide state leaves the
  pointer visible on the external monitor and then visibly warps it to physical
  movement on this multi-monitor setup. QSM no longer issues per-monitor cursor
  shape requests. Hyprland has no general cursor-warp IPC, so do not retry this
  without a deliberate replacement cursor controller.
- **Command palette category headers** — `>action` results grouped under section
  labels (Quick actions / Hardware / System / Tools), BUILT 2026-08-27:
  `actionDefs` gained a `group` field, `actionGroups` fixes the order, and the
  result builder buckets per group, emitting `{ kind: "header" }` rows. Headers
  render in ResultRow.qml as a full-width hairline with the label centered in
  it (owner: the bare muted label was "barely noticeable" — the line does the
  noticing; no tick, no icon gutter, no input targets); stepSelection(),
  firstSelectable(), and activate() all skip them so the one cursor never parks
  on a non-Enter row. A group with no match vanishes whole. Owner pass:
  header must sit AFTER its rows (BottomToTop, index0 at the bottom) or it
  reads under its own group; keyboard navigation centres an action target, so
  the top edge clamps with `Tools` visible above `Pick a colour`. Owner live
  acceptance 2026-08-27: it follows the focused monitor and mouse-wheel
  scrolling preserves the expected divider layout.

### Still open

- **Nested rollout seam -- CLOSED 2026-08-27.** A child BarPopouts host derives
  its origin recursively from its parent's settled edge, never the animated
  viewport width. The colour menu now extrudes from the quick-actions column;
  the smoke suite asserts the shared seam and vertical span. The scene shader
  currently supports eight simultaneous silhouettes, so unbounded concurrent
  chains require a separate shader-registry redesign.
- **Nested rollout retirement follow-up -- FIXED 2026-09-04.** The smoke suite
  found that dismissing the level-1 actions host could leave its level-2
  colour-picker child registered as `bar-action-popout`. Parent kind changes
  now always retire an active child, and an already-inactive parent ignores the
  child's callback. The same test had also targeted `eDP-1` while `status()`
  inspected whichever monitor was focused; it now drives and observes the same
  focused scene. The complete smoke passed before and after the first
  qsm-shell leaf-component migration.
- ~~**OSD entrance micro-pop** — closed 2026-08-27 by the shared Rollout
  content settle~~ (scale `Motion.microPopScale` 0.97→1.0, 120ms OutQuart) —
  the OSD is a Rollout consumer, so it now pops through `Rollout.qml`'s
  `inner` settle on every `shouldBeActive` flip, exactly like every other
  surface. No fade (02 no-opacity law).
- **Clock digits rolling -- CLOSED 2026-08-27.** Each metric-locked hour and
  minute row clips an old/new digit pair that rolls upward and crossfades on
  change. The initial render remains static.
- **OSD gradient slider -- CLOSED 2026-08-27.** The active level is brightest
  at the thumb and darkens toward its base while preserving the channel hue.
- ~~**Result highlight pulse** — closed 2026-08-27 by the ResultRow
  selection pulse~~ `selectionPulse` ticks during selection, driven from the
  shared `Motion.press`/`emphasizedEasing` vocabulary (settle in `press/2`,
  `press/2` out) — keyboard selection and pointer selection share it.
- **Workspace spill** — keyboard-driven cross-workspace window move. Hyprland dispatch or
  ShellState method.

### Ideas surfaced during implementation

- **Notification popup auto-dismiss on keyboard Escape** — closing the popup should also
  dismiss all visible notifications (owner decision needed).
- **Panel notification expand/collapse** — panel cards are always expanded; consider adding
  collapse for dense lists.
- **OSD channel emphasis animation** — when a channel becomes active, its thumb could pulse
  once (subtle 80ms scale bounce) to draw the eye.
- **Launcher result enter animation** — rows fade+slide from below when the launcher opens
  (staggered 30ms per row).
- **Theme carousel card entrance** — cards scale up from 0.95 when the carousel opens.
- **Rail workspace pill slide** — the active workspace pill could animate its position change
  instead of snapping (already has Behavior, verify easing).
- **Notification card exit animation** — when dismissed, card could slide out horizontally
  before being removed (complement to the entrance).
- **Panel tab content crossfade** — when switching tabs, content could crossfade instead of
  snapping (150ms opacity transition).
- **Session menu button press feedback** — session buttons could have a press scale + color
  shift before the action fires (100ms hold).
- **Launcher calc result flash** — when qalc returns a result, a brief highlight pulse on
  the result row.
- **OSD track fill gradient** — the filled portion could use a gradient from hue→darker hue
  instead of flat color, adding depth to the level indicator.
- **Clock digit roll stagger** — hour and minute digits roll at slightly different times
  (minute first, hour 50ms later) for a cascading feel.

## Audio profile can start silent until the stack is reinitialized — 2026-09-17

On this laptop (`Realtek ALC257`), the saved `output:analog-stereo+input:analog-stereo`
profile initially accepted PipeWire streams but produced no audible output. The sink still
reported 100% and `Mute: no`, so QSM's `AudioService` read a healthy-looking state. Selecting
`output:analog-stereo` made a direct `pw-play` tone audible, but removed the microphone from
the OSD by design. After restarting PipeWire, pipewire-pulse and WirePlumber, restoring the
duplex profile also produced an audible tone and restored the input source. QSM was restarted
and did not change the profile; it only binds PipeWire volume/mute and does not select card
profiles. If this recurs, reinitialize the audio stack and keep duplex rather than leaving the
desktop in the output-only workaround.

## Gotchas (runtime, measured)

- **No type annotation on a DEFAULTED function parameter.** `function f(n: int = 0)`
  passes `scripts/qml-lint` only AFTER the first fix; the Quickshell runtime
  rejects it outright with `Type annotations are not supported (yet)` at the
  line, which throws the live shell into a reload-fail loop until edited.
  Non-default annotations (`function f(n: int): void`) are fine. Drop the
  annotation on any parameter that carries a default and keep it elsewhere.

## Connectivity prompts and main-screen telemetry (deferred 2026-09-01)

These are product features deferred while qsm-shell establishes the universal
shader-backed ShellBorder and rollout architecture. Their visual hosts should
consume generic qsm-shell components, but protocol/service ownership remains in
qsm-desktop.

### Wi-Fi credential and verification flow

The action menu now has a row-attached password editor, reveal, progress and
failure feedback; credentials go to nmcli stdin and are cleared after handoff.
Real protected-network activation and final SSID identity remain unverified;
isolated fixture success is not that evidence. NetworkService/nmcli invocation,
secret handling, and connection-state truth remain desktop-owned. Enterprise
networks delegate to NetworkManager; do not persist or log plaintext credentials.

### Bluetooth LE pairing/passkey flow

Add a real BlueZ pairing-agent flow rather than treating every device as a
one-click connection. It must handle display-passkey, request-passkey/PIN,
confirmation, cancellation, timeout, and final connection identity. For devices
such as keyboards, the shell displays the numeric sequence while the user types
that sequence on the peripheral and confirms there; the prompt may also surface
through the notification field without making notifications the protocol owner.
qsm-shell may provide a generic pairing prompt/rollout; the BlueZ agent and
device identity checks stay in qsm-desktop.

### CPU and memory bulge indicator — OWNER DIRECTION 2026-09-04

The CPU/RAM handle replaces the eight-dot symbol and rides the panel rim;
the detailed Performance tab remains. Design and rendered-path decisions are in
`spec/06-top-panel.md`. PerformanceService owns lightweight sampling and CPU
averaging. Isolated input/suppression and an offscreen screenshot are prepared;
live load changes, moving-rim appearance and owner acceptance remain open.

### Sound rollout hover retention — OWNER REPORT 2026-09-04

The sound rollout closes if the pointer does not reach or select a target quickly
after hovering the sound entry. It should remain open for as long as the pointer
is within the rollout's general usable area; moving from the rail into the
rollout must not impose a rushed selection deadline. Reproduce with live pointer
geometry before changing timing: the controller currently has a 180ms close
grace while rollout reveal uses the 250ms small-reveal tier, and the effective
input region during that transition must be measured rather than guessed.

### Measured shader quirks — 2026-09-06

- **`dFdy` is NEGATIVE against the pixel y axis on this stack.** The RHI
  framebuffer is y-flipped relative to `qt_TexCoord0`, so `vec2(dFdx(f),
  dFdy(f))` is NOT the outward normal of an SDF: its y is inverted. This was
  harmless while the glass light was a fixed up-vector (it only decided which
  band read as lit, and was tuned by eye); a centre light cancelled the y term
  outright and both horizontal bands lost their edge. `edgemelt.frag` negates
  y. Re-probe on a Qt upgrade.
- **A `ShaderEffect` renders nothing under `QT_QPA_PLATFORM=offscreen`,** and
  hung when run against the live Wayland session. Two attempts at a standalone
  probe shader produced a blank grab while a plain Rectangle grabbed fine, so
  the scenegraph is on a path that drops ShaderEffect entirely. Shader
  questions have to be answered from `qsm status`'s `sceneBulgeDump` plus the
  owner's eyes, not from an offscreen render.
- **`blend` and `outness` are different facts and were conflated once.**
  `blend` is the melt radius; `BarPopouts` sets it to exactly 0 for a nested
  host FLUSH against its parent, because the shader floors its smin radius and
  0 therefore means an exact union with a straight seam. That is a settled,
  fully-out body. Gating the glass edge on `blend` blanked every level-two
  popout. `param.w` now carries outness separately, default 1.

### Flaky smoke check — 2026-09-06

`scripts/test-quickshell` failed once on "command-centre parent selection did
not restore" (`launcherRestoredParentActionId: "cache"`, query `>action `) and
passed on an immediate re-run with no code change in between. Nothing in that
run touched the launcher. Either the restore has a timing race or the check
samples before it settles. Repo law is fix it or delete it: find which, next
time the launcher is open anyway.

### One fact, one value — 2026-09-06

Two seam bugs in one day, opposite shapes, same root cause: the number of
FACTS and the number of VALUES did not match.

- **One fact split into two values.** `flushToParent` and `childAttached`
  describe a single fact (the nested host fills its parent's span, so their
  edges meet). The comment even called the second "the mirror of the first,
  decided locally" — and deciding it locally is what broke it, because each
  side picked its own source: destination height on one, live animated height
  on the other. Any boolean read from animating geometry is false for the
  whole animation, so a pair like that is not racy, it is GUARANTEED to
  disagree for exactly the length of every transition.
- **Two facts collapsed into one value.** `blend` was read as "how far out is
  this body" when it means "how wide is the melt". A flush host legitimately
  sets it to 0 while being fully out; gating the glass edge on it blanked
  every level-two popout.

The rule this leaves: a fact that two places need is computed ONCE and shared,
and a value that carries two facts gets split. For anything feeding the
silhouette, add the clock: every rect, radius and blend in one frame must come
from the same one, or the shader paints a shape that exists in no frame of the
design.

Both were found by reading `sceneBulgeDump`, not by reasoning about the code —
which is why the dump exists. Two hypotheses argued from the source (a lagging
child height, a lagging shader) were both wrong; the numbers took minutes.

## validate is non-deterministic on an unchanged tree (ui-guard clip-growth) — 2026-09-06

`scripts/validate` failed twice during phase 11a on a diff that moved a shader file and
touched no geometry, then passed. Measured on ONE unchanged commit, across shell instances:

| run | ui-guard --sweep result |
| --- | --- |
| validate #1, #2 | `clip-growth\|StateLayer\|34x34 grown x1.15` at 870.5,15.4 |
| validate #3, two standalone suites | 0 findings |
| after a shell restart, three sweeps | `clip-growth\|StateLayer\|24x24 grown x1.08` at 76,406 |

Deterministic WITHIN a shell instance, different ACROSS instances. Same commit every time.

**Ruled out by measurement, not argument.** The first reading of this was "the owner's physical
pointer is hovering something during the sweep". Wrong: with `ydotool` the cursor was parked at
989,12 and then moved to 1194,525, and the 76,406 finding did not change. Something is in a
GROWN state without a pointer on it, so the sweep does produce growth on its own, and the
earlier note that clip-growth was near-dead code in `--sweep` was wrong too.

**What actually makes it unstable.** The finding KEY embeds `scale`, a continuous runtime
value, so every distinct grown state is a distinct key and any key not already in
`ui-guard.baseline` fails the gate. The sweep opens surfaces over IPC but does not control
which items are in a grown state when it measures: selection, active state and whatever the
previous instance left behind all feed in. So which findings appear is a function of shell
state at sweep time, not of the diff.

**That is the defect.** A gate that fails on an unchanged tree costs a bisect every time it
fires, and this one cost four validate runs plus a stash-and-compare to disprove against a diff
that could not possibly have caused it.

**Still open, and worth separating.** Whether the shaved pixel is real. `24x24 x1.08 at 76,406`
does not exist at rest; it appears somewhere in the rail-popout half of the sweep and it is not
the network popout (checked). If it is a selected row whose growth its popout clips, that is a
genuine 09-interaction defect and the unstable gate is the only reason anyone saw it.

**Not decided.** Make the key state-qualified (quantise `scale`, or record which sweep step
produced it) so a finding is comparable across runs; or drive the grown states deliberately
(`scripts/hover-probe` exists and the sweep does not use it) so the set is closed rather than
incidental. The second is the honest one and it will add findings to the baseline before it is
green. Neither is phase 11 work.

## The desktop has no test below the end-to-end suite — 2026-09-07

OWNER-ASKED, and the answer is worse than the question: this repo has exactly
one behavioural gate, `scripts/test-quickshell`, and it is the most expensive
kind. It needs a live Wayland compositor, a real shell process, the owner's
panel taken down, and about two minutes. There is nothing underneath it. The
library, by contrast, has 66 interaction tests in six files that run in two
seconds.

That shape is why a session hunting one bug runs the end-to-end suite six
times. Tonight's notification-capsule regression is the case in point: a live
row versus a rendered row is a pure predicate, and it took a two-minute
compositor round trip to catch.

**Measured, not assumed: desktop components CAN be tested.** Probed 2026-09-07:

```
import "file:$HOME/qsm-desktop/shell/modules/bar" as Bar
```

`qmltestrunner` loaded and ran `PopoutController` in **2 ms**. Two things make
it work, and both are constraints on what can follow:

- The import must be a `file:` URL to the DIRECTORY. Quickshell's `qs.*`
  namespace is synthesised by the Quickshell runtime (its interceptor rewrites
  `qs:@/...`), so `-import shell` gives "module qs.modules.bar is not
  installed". A plain directory import needs no module at all.
- The component must not import `qs.*` itself. `PopoutController` qualifies
  only because the 2026-09-07 geometry rewrite left it at 44 lines with
  `QtQuick` as its single import. Components reaching for `qs.state` or
  `qs.services` would need those singletons stubbed, and THAT is not proven
  either way.

So the first tests are free and the rest is a real question about stubbing
singletons. Not started, because the owner asked why it does not exist rather
than for it to be built.

Fixed in the same pass: `scripts/validate` ran the smoke suite TWICE, once
before the guards that prove `qs` exists and once after. The slowest step in
the gate, doubled, with no comment at either call site explaining the second.

## Found while the owner reviewed the migration — 2026-09-07

### `BarPopouts` talks to the registry instead of using `Rollout`

It calls `registerBulge`/`unregisterBulge` directly and animates its own
retract, and its `Behavior` has no `enabled: !suppressed` guard. Two
consequences, one already paid for: a shrinking popout stays registered for a
full transition after fullscreen or focus mode flips, which is why
`ShellBorder` needed an `entryFilter` in 11c instead of relying on
`Rollout.suppressed`. It is the only seven-call caller in the shell that is not
a `Rollout`. Making it one is a real change (it hosts a nested stack), so it is
recorded rather than attempted.

### Nothing checks that a scroll fade reaches its actual ground

`ScrollCue.fadeColor` has to match whatever the list scrolls over, and its own
header says a gradient toward the wrong colour is more visible than no gradient
at all. Three of six desktop consumers had `Theme.surface` while sitting on a
shader silhouette, and the library's `NotificationCenter` hardcoded
`Style.surface` with no way for a consumer to correct it. All fixed 2026-09-07,
but only because the owner SAW it: no gate can catch a colour that is merely
wrong, and every one of these is a hand-matched value. If a third consumer
ground ever appears, expect the same class of defect again.

### `Theme.press` has no consumers

Noticed while pruning the motion tokens in 11c. It had none even before that
change, so it was left alone rather than swept into an unrelated commit.
Delete it or find the press it was meant for.

### The rail popout's hover window is the popout's own height — RESOLVED 2026-09-07

OWNER-REPORTED 2026-09-07: the region where the pointer keeps a rail popout
open is too small. It is geometry, not the 180ms grace: the popout is anchored
on the hovered entry's vertical centre and is shorter than the rail, so a
diagonal move from entry to popout can leave the rail strip's x-range while
still being outside the popout's y-range. That lands on the click-through
scene, hover drops, and the grace timer closes it.

~~Three candidate fixes, and the choice is a LIVE-TUNE the owner has to watch:
grow the popout's registered hover region vertically past its visible bounds;
add a corridor region spanning entry to popout; or lengthen the grace so a
brief excursion does not count. Not guessed at here.~~

Superseded the same day by a RATIFIED law (spec/03-rail.md "Popouts"): no
timer at all — one geometric region test (anchor cell ∪ band ∪ popout ∪ open
descendants ∪ travel triangle), decided fresh every pointer move
(`EdgeScene.qml` `popout1UnionContains`/`popout2UnionContains`,
`PopoutController.qml` stripped to `show()`/`dismiss()`). The dead zone this
entry reported is now closed by a DIFFERENT mechanism than any of the three
candidates above: the region test runs off ONE scene-wide `HoverHandler`
(`anchors.fill: root`), so the "band" member of the union is the rail's
always-on Wayland mask rect (`railMaskRect`, full height) rather than any
single entry's own hover shape — the old per-item HoverHandlers (RailEntry's
StateLayer, BarPopouts' content hover) left the GAPS between entries and
groups uncovered, which is exactly where the reported dead zone lived. See the
next entry for what that leaves the travel triangle actually doing.

## Found during the library migration — 2026-09-07

Six things three migration passes hit and deliberately did not fix. Each is
recorded because the reason NOT to act is the part that would be re-derived.

### The rail's numbers disagree with its spec

`spec/03-rail.md` states 40px and 4px where the code uses 32 and 8. The repo's
own law is that code loses every disagreement with the spec, so this is not a
detail: either the spec is stale and must be amended, or the rail is wrong and
three call sites move. It is an owner decision, not a cleanup, and it was found
at night with nobody to ask.

### Three families of hit target below 44x44, and why guessing is worse

The compact rail rows, the workspace dots, and the colour swatches all present
pointer affordances under 44x44. Growing any of them either overlaps the
neighbour above it or grows the icon itself, and which of those is acceptable
cannot be judged from the source -- it needs the shell in front of a person.
The dashboard's mini transport WAS fixed in the same pass (it hid a 28px target
behind a `-6` margin hack, which is the tell), so the rule is being applied
where the answer is unambiguous and recorded where it is not.

`PopoutRow`'s trailing IconButton is the same family with a harder floor: at
24x24 inside a row about 30px tall, 44 does not fit at all. Fixing it means
changing the row height, which is a spec question about how tall a popout row
is, not a component question.

### Two components the library genuinely does not cover

`BatteryPopoutContent`'s profile switch looks like `Segmented` and is not one:
its selection GLIDES between cells, which the library type does not do. Making
`Segmented` glide is a real change to a shipped type with other consumers.

`RailDeviceCell`'s divider is a cross, not a rule. `Divider` is edge-to-edge by
contract and bending it to cover this would be the "type per call site" failure
the library's own laws name.

### The token gaps the migration could not close

Values with no `Theme` equivalent, left as raw numbers rather than invented as
tokens: letter spacing on the vertical app labels, a handful of margins,
opacities and border widths in the bar popouts, the preview canvas dimensions
(980/690/420/360/76/152/188/102) and one `SvgIcon size: 58`. The preview ones
are harness geometry and probably should stay numbers; the bar ones are the
argument for a token.

## Next up — 2026-09-07

Ordered. Each is startable cold. Items 1 and 2 are small and unlock the rest,
so nothing below them is worth starting first.

### 0. NOT DONE: the owner has not looked at this session's work yet

Every gate is green and nothing here has passed a human eye. That is the
outstanding gate, not a formality: `spec/13-implementation.md` ends every phase
with "owner visual check", and three of the changes below alter behaviour
rather than structure.

What to look at, in risk order:

| what | why it is risky |
| --- | --- |
| fullscreen + focus mode | `EdgeScene.entryVisible` reproduces the old three-branch allowlist by hand after 11c |
| every rollout: panel, launcher, session, OSD, rail popouts | all six now run through the LIBRARY's `Rollout` |
| rail popout hover | the 180ms grace is GONE, replaced by a region. Test entries near the top and bottom of the rail, where the card is clamped furthest from its entry |
| dashboard mini transport | hit targets went from 28px to >=44px |
| notifications | expire one, dismiss one by hand, hover one (pause), and press Enter on an action |
| cheatsheet with an empty filter | its empty state moved out of the ListView |
| scroll fades | all seven now fade to `bandFill`; the owner reported the old grey smear |
| rail workspace dots | now on the 4px step per spec, so a tighter raster than before |

### 1. Cut the `Theme` edge — the highest-leverage change in this repo

`shell/theme/Theme.qml` is 485 lines and its ENTIRE dependency on Quickshell is
five of them: one `Process` (`themesProbe`) that scans `themes/*.json` for
theme discovery. It also reads exactly three things from `ShellState`:
`reducedMotion`, `reducedEffects`, `theme`.

Those five lines plus three reads make **40 of the repo's 43 UI files
unloadable outside a Quickshell process**, because 40 of them import
`qs.theme`. Exactly ONE file in `shell/modules` and `shell/components` is
testable today: `PopoutController.qml`, 44 lines, `QtQuick` as its only import.

The cut: move `themesProbe` into its own singleton that feeds `Theme.themes`,
and turn the three `ShellState` reads into plain settable properties that
`shell.qml` binds. `Theme` becomes `import QtQuick` only.

**The 40 import sites do not change.** `qs.theme` stays `qs.theme`. This is one
file, about ten relocated lines, and the difference between 1 testable file and
41.

It is the same inversion the library already uses for `Style` + `backend`, and
the desktop's `Theme` is already that backend, so the pure half is exactly what
the library consumes.

### 3. Then, and only then, the first desktop tests

Proven possible 2026-09-07, measured not assumed: `qmltestrunner` loaded and
ran a desktop component in **2 ms** using

```
import "file:$HOME/qsm-desktop/shell/modules/bar" as Bar
```

Two constraints, both discovered by probing:

- the import must be a `file:` URL to the DIRECTORY. Quickshell synthesises the
  `qs.*` namespace at runtime (its interceptor rewrites `qs:@/...`), so
  `-import shell` gives "module qs.modules.bar is not installed".
- the component must not import `qs.*` itself. After item 1 that stops being a
  constraint for the 40 `qs.theme` files.

First targets after item 1: `entryVisible`'s three branches (which surfaces
survive fullscreen and focus mode), the notification wrapper's live-vs-rendered
capsule predicate, and `PopoutController`.

### 4. The smoke suite is not hermetic, and it is the only behavioural gate

Three distinct ways it failed this session on code that was not in the diff.
That is expensive because it is also the most expensive test in the repo: a
live compositor, a real shell, the owner's panel down, two minutes.

| mode | status |
| --- | --- |
| `ui-guard` clip-growth keys embed a live `scale`, so findings depend on shell state | open, own entry above |
| `hyprctl dispatch fullscreenstate 0 0` is pre-Lua syntax; this config rejects it (exit 7, one stderr line, `set -e` kills the suite before a single assertion) | FIXED 2026-09-07 |
| the command-centre check reads whichever monitor is focused, not the one the suite drives | open, and it is the two-monitor dishonesty already recorded |

Also fixed 2026-09-07: `scripts/validate` ran the suite TWICE, once before the
guards that prove `qs` exists and once after.

### 5. Split `ShellState` the same way as `Theme`

15 files import `qs.state`. `ShellState` imports `Quickshell`,
`Quickshell.Hyprland` and `Quickshell.Io` for persistence and compositor
events. Same shape as item 1: pure state plus an adapter. Do it when something
needs it, not before -- item 1 is the one with the 40-file payoff.

### 6. `qs.services` in 23 UI files -- never a project

23 UI files import a service directly, which means importing PipeWire, DBus or
NetworkManager into a component. Those are real external boundaries and belong
mocked, not imported, so such a file cannot be tested at all.

The fix is not a split but an inversion: the component takes data as
properties, the surface wires the service. `NotificationStack` (2026-09-07) is
the worked example -- it takes `stack` and `isAlive` and the desktop wrapper
holds the bus.

Do this per file, as each surface is touched for another reason. Doing it as a
sweep would be 23 behaviour-changing edits with no owner watching.

### 7. Owner decisions still pending

None of these blocks anything; all are recorded in full elsewhere in this file.

- Notification group ordering: two apps tied on "has a live entry" compare
  equal, so a third group between them can split a section header. Pick the
  tiebreak (alphabetical? most recent?).
- `ui-guard` clip-growth: quantise the finding key, or drive the grown states
  deliberately with `scripts/hover-probe`. The second is honest and will add
  findings to the baseline before it goes green.
- `PopoutRow` row height: its trailing `IconButton` is 24x24 inside a ~30px
  row, so 44 does not fit. Growing the target means changing the row height,
  which is a spec question.
- Two remaining sub-44px hit-target families: the compact rail rows and the
  colour swatches. The workspace dots just got tighter (item above), so all
  three are now one question about the rail's raster.
- The travel triangle in the popout region is currently a geometric no-op,
  because the popout is flush with the band and the band already spans the full
  height. Either it is genuinely redundant and should be deleted, or the
  flushness does not hold in some state and the triangle is load-bearing there.
  Nobody has checked which.


## Rail popout region test — found while implementing the geometric law (2026-09-07)

### The travel triangle is currently a no-op at level 1 — the ratified geometry, implemented literally, still needs a decision

`spec/03-rail.md` "Popouts" names the travel triangle as apex = anchor cell,
base = the popout's near edge. Implemented literally
(`EdgeScene.qml` `popout1UnionContains`), that triangle's every point has
`x <= reservedLeft` — the same x-range `railMaskRect` (the "band" member of the
same union) already covers for ANY y, unconditionally, because the band is the
rail's own always-on Wayland mask rect, not a per-entry hover shape. A
degenerate proof, not a guess: for any point the triangle contains, the band
already contains it too, so removing the triangle from level 1's union today
changes nothing measurable. (Level 2's triangle is the same shape against
`popout1Rect` as its band and is equally inert for the same reason.)

This is NOT grounds to narrow the band or widen the triangle unasked —
either would be inventing geometry the spec didn't name (Rule 4 territory).
Implemented as literally specified instead, so the code matches the law even
though this particular layout makes one clause of it currently free. Two ways
this stops being free, either of which the owner would have to ratify:

- the band narrows to the visible rail column (`Theme.railWidth`, centred
  inside `Theme.reservedLeft`) instead of the full reserved strip, restoring a
  real gutter the triangle would then have to bridge; or
- a popout host is added whose near edge does NOT sit flush against its band's
  right edge (everything today — `popout.x`/`actionPopout.x` — is flush by
  construction).

Until then this is dead code with a clear reason to exist (literal spec
compliance) and a clear reason it currently does nothing (the band it sits
beside is already unconditional). Left as-is; flagging so nobody spends a
session trying to "prove" the triangle live via a hover trace and comes up
empty for a reason that was never a bug.

### Pre-existing, unrelated: `NotificationCard.qml` throws on every popup while a scene is fullscreen-transitioning

Surfaced incidentally while diagnosing this task's own `mapToItem` mistake
(passing a `PanelWindow` where a `QQuickItem` was required — fixed in
`EdgeScene.qml`, see the commit). The shell's live log
(`$XDG_RUNTIME_DIR/qsm-run.log`) carries the SAME class of error already
present, unrelated to rail popouts:

```text
scene: @modules/notifications/NotificationCard.qml[45:-1]: TypeError: Passing
incompatible arguments to C++ functions from JavaScript is not allowed.
```

raised repeatedly from `syncFullscreenCapsule` (`NotificationCard.qml:45`) on
`onWidthChanged`/`onHeightChanged`/`onCompleted`/`onVisibleChanged`/
`onFullscreenCapsuleIdChanged`/`onFullscreenSceneChanged`, and once from
`NotificationPopupStack.qml:68`. Same shape as the bug this task's own fix
corrected: some argument passed to a Quickshell/Qt native call is not the
`QQuickItem`/type it expects. Not touched — out of this task's file
boundaries (`shell/modules/notifications/`) — but the log already has the
stack traces if the next session picks it up.

## Scene pointer moved to the `PanelWindow` ancestor, popout close delayed 180ms — FIXED 2026-09-07

`sceneHover` (the region test's `HoverHandler`) sat on an `Item { anchors.fill:
parent }` declared as a SIBLING beneath the interactive surfaces in
`EdgeScene.qml`. A `HoverHandler` is shadowed by stacking order, not shared by
it: only the one nearest the pointer along the z-stack is notified. Placed
below the surfaces it never saw the pointer at all — measured live
(`hyprctl cursorpos` + `qs ipc ... status`) with the cursor genuinely on the
rail: `popoutInRegion` was `false` at every position, while the rail entries
themselves kept reacting (the popout morphed under the cursor), proving input
reached the scene and only this one reader was blind. The close only fires on
the region's true-to-false transition, so it never fired and the popout never
closed on its own.

Fixed by moving the reader onto the ANCESTOR instead: the library's new
`ScenePointer` (`qs.QsmShell.Components`), declared directly in the
`PanelWindow` (`EdgeScene.qml` root), which lands on the window's contentItem
— the true ancestor of every surface. Verified live: same cursor position,
`popoutInRegion` now reads `true`. `ShellBorder.pointer` is assigned the same
instance so every rollout under that host reads pointer state from one place.
`popout1UnionContains`/`popout2UnionContains` now call
`scenePointer.contains(rect)` per rect instead of hand-rolling
`inside && rectContains(x, y)`; the old `rectContains` helper is deleted
(dead once every call site moved).

The close is now delayed 180ms (`QsmShellStyle.Motion.hoverGrace`, the same
token `Rollout.closeDelay` already reads in the library) after the region's
true-to-false transition, per a same-day owner ruling that supersedes
`spec/03-rail.md`'s earlier "never by time" wording (see that file — both
rulings are dated 2026-09-07, and the later one is dated as superseding the
former in place, not silently replacing it). The region still decides
*whether* the pointer holds the rollout open; the delay only covers the last
few pixels of a fast exit and the frame boundary a per-frame region test
cannot.

Still not done, deliberately: `BarPopouts` is not a `Rollout`. It is also a
HOST — `childHost`, `parentHost`, and a seam derived from its parent's settled
edge — and the library's `Rollout` cannot yet be the parent of a nested
rollout. Converting `BarPopouts` needs that library capability first; forcing
it here would mean improvising the missing piece inside this repo instead of
building it once in the library, so it is left as its own follow-up. As of
2026-09-07's OSD move, the rail popout still carries the only hand-rolled
keep-open in the shell for this reason: the 180ms itself comes from one
token (`Motion.hoverGrace`), but the region test that decides whether the
delay even starts still lives twice: once inside the library `Rollout` (every
other surface) and once in `EdgeScene`'s `popout1UnionContains`/
`popout2UnionContains` (the rail).

## `Rollout.contentCenterOffsetX` costs every rollout half a band-depth on the edge side, NOT CHECKED

`contentCenterOffsetX`/`contentCenterOffsetY` (`Rollout.qml`) exist because a
rollout is the band BULGING, not a panel sitting next to it: the shader melts
body and band into one silhouette, so content centred in the body alone sits
half a band-depth off the silhouette's real centre, on whichever side the
rollout is attached to. It bit the OSD first. `Theme.osdWidth` went to 48 on
2026-08-22 and was CORRECT there for a fortnight: the offset did not exist
yet. The library port on 2026-09-06 brought it, and from that moment four of
the OSD's own last pixels drew under the frame every frame, which is a day and
a half, not a fortnight. Nobody had reason to look until the owner saw it
(fixed 2026-09-08, `bdb733a`, back to the 56 the spec always said; that spec
file carries the arithmetic). The library's own comment on `contentCenterOffsetX` names a
SECOND case it was written for: the session column sat 8px off its own
centre the same way. That means this is not a one-off, it is a standing
cost every rollout pays and only the two already caught have been checked
against it.

NOT CHECKED: every other rollout with content close to its body's width,
the rail popouts, the top panel, the launcher, the notification centre. A
surface with generous slack either side of its content will not show it; one
sized close to its content (the OSD's own failure mode) will. Someone needs
to sit in front of each and look for the same 4px-under-the-frame tell the
OSD had, or read each one's own inset arithmetic the way `spec/05-osd.md` now
does for the OSD.

## `PopoutRow` and `ResultRow` are still two names for one row

Both wrap the library's `ListRow` (`shell/components/PopoutRow.qml`,
`shell/components/ResultRow.qml`) and both exist because two different call
sites needed to adapt two different model shapes onto it: a network/
bluetooth/sound device row, and a launcher/clipboard result row. That is a
real difference in what each one is FED, but not necessarily in what either
one IS. The library folded its own equivalent three surface names
(`MenuRowItem`, `PopoutRow`, `ResultRow`) into the single `ListRow` this repo
now consumes, and this repo has not done the equivalent fold on its own two
wrappers. Left open rather than merged here: telling apart "two components
because two shapes" from "two components because nobody has looked" needs
reading both call sites' actual model shapes side by side, which is a design
question about this repo's row vocabulary, not a mechanical rename.

## `scripts/validate` cannot reach the shader freshness check while a live instance holds the config path

`scripts/validate` runs `scripts/test-quickshell` before the shader
freshness check (committed `.qsb` vs a fresh `build-shaders` run) later in
the same script. `test-quickshell` refuses outright, exit 1, before a
single assertion, when a live `qsm` instance already holds the config path
(`qs ipc --path ... show` reports `target qsm`), which is deliberate: it
would otherwise poison the smoke suite's own counters and get killed by the
suite's cleanup. The script runs under `set -euo pipefail`, so that refusal
stops the whole gate on the spot: the shader freshness check after it never
runs. This is the smoke suite's own deliberate refusal, not a validate
failure, but it means a full, clean gate needs the shell stopped first; a
validation run against a running desktop is a partial gate that silently
skips the one check proving the committed `.qsb` still matches its `.frag`.

## Agent task backlog (folded in from `.codeagent`)

The codeagent task files are gone; these lines retain their scope. The isolated
`osd-label-action` flow exercises the shared production surface, pointer/key/action
mute routes and fullscreen wrapper switching. It does not establish live owner
acceptance of all seven tasks or real audio/brightness operation.

- **OSD-D1 Persistent real OSD channel content** — channel content extracted
  and public Slider/label targets exposed.
- **OSD-D2 Single shared OSD presentation owner** — one service-independent
  owner keeps a single timer and screen-safe retention.
- **OSD-D3 Desktop OSD genuine capsule and rollout wrappers** — one real
  content `FocusScope` shared by genuine wrappers with an exact fullscreen
  input rect.
- **OSD-D4 Isolated production OSD proof story** — fake services reuse the real
  presentation owner and the production `OsdSurface`; the harness environment
  stays read-only.
- **OSD-D5 Desktop OSD story provider routing** — the OSD story is routed with
  the live read-only environment; the rail branch stays isolated.
- **OSD-D6 Unified small rollout reveal and retract** — the rail uses the
  shared small-tier motion and keeps disabled opaque outgoing content until it
  is hidden.
- **OSD-D7 Shared desktop OSD handle in production and story** — production
  and story share one circle and rotating arrow; existing surface corridors own
  the input.

## Release handoff

The authorized feature batch does not restart production or mutate hardware.
Source-prepared: attached microphone/brightness sliders, notification archive
removal and snapshot-safe selection/hover, CPU/RAM handle, confirmed connectivity
loss/recovery, shared rail network/Bluetooth operation lifetime and control/QoL
repairs. BlueZ PIN/passkey agent and external Qt/GTK parity for a second theme
remain implementation gaps; manager delegation is a narrower MVP, not those features.

Current isolated evidence is under `/tmp/opencode/feature-*`: level and brightness
flows, notification-center search/Delete/archive flow, panel-resource click and
suppression flow, connectivity transitions, notification private-bus check and
six menu/tab regressions. `network-popout-input` exercises password retry via
native TextField input, draft/grab disposal, confirm-off and late-result refusal
through programmatic join/radio actions; it does not prove rail pointer routing.
NotificationCenter's focused checks include same-count
replacement and hovered-delegate preservation; the full shell suite predates
these edits. Offscreen captures are `feature-brightness.png`,
`feature-notification-center.png` and `feature-panel-resources.png`; SVG glyphs
still require a live window. Workbench capture uses the provider's namespace
staging and declared ready/idle state rather than a fixed delay.

- Main keyboard quick action is source-prepared above Keep awake, mirrored in the
  command picker, with `main-keyboard enable/disable/toggle/status` and a shared Lua
  helper for both existing shortcuts. Disabled has a keyboard-off glyph and quiet
  warning amber on the rail; enabled is a normal keyboard, unavailable is muted.
  Isolated preview states are in
   `action-menu-toggles`; no hardware toggle was run. The current isolated
   menu/typing flows and quick desktop gate include this addition; owner review
   and actual shortcut/CLI recovery remain open.

Source-reviewed: the existing action menu is wired to production services;
per-kind decisions use dispatch tables. The isolated stories host the real
surfaces but replace hardware services. This is not production-backend proof.

Runtime-exercised, without restarting production or changing real hardware:

| Check | Evidence |
| --- | --- |
| `bash scripts/check` | Pass: import smoke, 97/97 theme names, no new/increased lint findings; 118 findings remain against the unchanged baseline |
| `bash scripts/check-action-menu` | Pass: six flows over five stories: audio 28, Wi-Fi 52 + lifecycle 42, Bluetooth 52, toggles 29, panel tabs 25 steps; story count grows with the feature batch |
| `osd-label-action` | Pass: 32 steps, pointer/Space/programmatic mute, unavailable microphone, fullscreen wrapper switch |
| Three rail flows | Pass: popouts, descendant retention and dismissal |
| Seven `notification-*.json` flows | Pass: replacement, retarget/reset, hover/initial expiry, native dismiss/swipe, overflow/retract |
| `bash scripts/test-notification-bus` | Pass: private D-Bus external-client routes through production service/store/renderer; exact-once archive and input retirement |
| Sibling `qsm-shell`: last requested `npm test` | Passed 51 interaction + 261 unit checks, smoke and shader freshness; predates the Menu activation typing cleanup and added glyphs, not fresh whole-library proof |

The menu flows now wait for the actual reveal before clicking; repeated clicks
reach audio, Wi-Fi radio/secured-network editor, Bluetooth radio/device and
software toggles. Wi-Fi off explicitly checks arm-then-confirm. The earlier
claim that offscreen launcher clicks never arrive is superseded, not a live
pointer/drag acceptance claim. The gate also returns failure when a flow fails;
isolated pass/failure runner fixtures exercised that exit-status path.

The Wi-Fi lifecycle flow also exercises click-outside password disposal, late
failure after dismissal, VPN without a Wi-Fi adapter, VPN-off confirmation and
visible rescan progress. Bluetooth's actual Forget row exposes failure and retry
using device address, not its prefixed selection identity. Model replacement no
longer throws on a null attached view. Current menu logs contain no missing-glyph,
TypeError, ReferenceError or binding-loop diagnostics; native glyph appearance
still needs live judgement because offscreen SvgIcon rasterisation is unavailable.

Lint now rejects hard/tool failures before baseline update and detects increased
occurrences of an existing warning, not only new signatures. Disposable gate
fixtures confirm baseline preservation for error, tool failure and crash, rejection
of duplicate warnings, and acceptance of an unchanged warning. Only three stale
count entries were reconciled against unchanged BarPopouts/RailAppList/Motion
sources; no new warning signature was added or source error broadly suppressed.

Production boundary probes used disposable fixtures under `/tmp/opencode`:
`network-service-probe` runs the real NetworkService and Process with fake nmcli
(escaped/deduplicated SSIDs, password stdin, overlap/refused-secret handling,
completion/failure, signal termination, real 35-second action and scan deadlines,
exact-once timeout verdicts, delegation and radio state); `bluetooth-service-probe` resolves defaultAdapter on
a private bus and refuses unavailable operations. Neither proves actual nmcli
or BlueZ hardware success. These support the narrow baseline additions for
Quickshell metadata: BluetoothAdapter naming, QVariantHash and QProcess::ExitStatus.

Logs: `/tmp/opencode/desktop-release-ready-check.log`,
`/tmp/opencode/desktop-release-menu-ready.log` (individual logs in
`/tmp/opencode/release-menu-ready/`), `desktop-release-osd-final.log`,
`desktop-release-rail-*-flow.log`, `desktop-release-notification-*.log`,
`network-service-lifecycle.log`, `bluetooth-service-probe.log`, and
`shell-release-validation.log`, all under `/tmp/opencode`. Logs and probes are
temporary evidence, not shipped test infrastructure.
Lint gate fixture logs are under `/tmp/opencode/lint-gate-fixture/`.

To repeat a named isolated flow from this repo:

```bash
QT_QPA_PLATFORM=offscreen qsm-workbench flow run "$PWD/workbench/flows/osd-label-action.json" --provider "$PWD" --timeout-ms=30000
```

Use an absolute flow path; substitute a rail/notification filename for that
named check. These are reproduction commands, not permission to run a sweep.

Remaining release gates, in order:

- **Owner review**, one item in one live window: start with action-menu audio
  (repeated mute, row-attached volume editor, keyboard/menu return, literal NEIO
  and slash). Revise that item until accepted, then Wi-Fi, Bluetooth, toggles and
  panel tabs. Their isolated flows are not acceptance.
  The existing panel/Wi-Fi previews (`/tmp/opencode/am/preview-panel.json`,
  `preview-wifi.json`) were left untouched and predate these edits; QML has no
  hot reload. Do not judge the current source from them. When preview operation
  is requested, identify each session by PID/provider/story, retire only the
  agent's obsolete windows and open just the named item.
- **Live pointer/drag/focus and screen reader**: real hit testing, wheel, focus
  leaving/returning to the window and spoken output remain unverified.
- **Actual backends**, only with explicit permission: audio/brightness changes,
  protected Wi-Fi connection/failure/SSID verification, Bluetooth power/discovery/
  pairing and the real compositor. BlueZ passkey/PIN agent work remains deferred.
- **Full production gate**: `scripts/validate` is not run. It invokes
  `scripts/test-quickshell`, which stops/starts the production config, changes
  audio, manipulates windows and cleans caches. A green quick gate does not cover
  that suite; arrange a separately approved production check.
- **Residual lint debt**: the baseline is not warning-free verification; genuine
  existing source findings remain alongside introspection limits. Repair with
  the owning surface, never by blanket refresh.
- **Fresh whole-library evidence**: the small Menu activation typing cleanup and
  bundled glyph additions are source-reviewed; the prior full shell suite does not
  exercise those edits. A fresh full suite remains an explicitly requested check,
  not an automatic consequence of overnight release preparation.

Owner-accepted evidence is narrower: the rail parent withdraws input while a
painted child retains it. That decision does not accept the whole action menu,
panel, OSD or notification release. No push, OpenSpec merge or archive is done.

## Work lands on main

An isolated worktree held the network and Bluetooth work and was lost before it
was merged, because an agent's scratch directory is not a delivery. `AGENTS.md`
in both repos now says it: the next item is implemented on `main` and committed
there, a worktree is for parallel or throwaway work, and whatever comes out of
one is reviewed and merged before the owner ever sees it.
