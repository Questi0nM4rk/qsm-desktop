# Guide: prerequisites, helpers, Workbench

A minimal, spec-driven Quickshell desktop shell for Hyprland. One scene window per monitor
renders a frame band and fluid rollouts as one silhouette. Owner review and acceptance remain
pending for work in progress.

- `spec/` — THE authority on look and behavior. Start at `spec/00-overview.md`; current
  implementation boundaries and owner-led workflow are in `spec/13-implementation.md`.
- `shell/` — the Quickshell config (run: `qs --no-duplicate --path shell`).
- `scripts/` — `check` (static/import/theme gate), `check-action-menu`
  (isolated input), `test-notification-bus` (private D-Bus), and `validate`
  (includes the production-only smoke suite).

## Local prerequisites

Keep this checkout next to `qsm-shell`: `vendor/qsm-shell` is the committed
relative symlink to that library, not a downloaded package. Run with Qt 6,
Quickshell 0.3.x and Hyprland; the library's committed `.qsb` shader is required
at runtime. Rebuild it through `vendor/qsm-shell/scripts/build-shaders` only
when its source changes.

Capabilities use the existing desktop tools: PipeWire for audio, NetworkManager
(`nmcli`) for networking, BlueZ for Bluetooth, and the commands named in
`shell/services/Delegate.qml` for delegated settings. Isolated Workbench services
do not establish that those production tools are installed or working.

Checks run only when requested. `scripts/validate` invokes a suite that stops and
starts the production shell, changes audio, manipulates windows and cleans caches;
never run it as a harmless install or pre-commit check. Current release evidence
and the remaining owner/hardware gates are in [docs/BACKLOG.md](BACKLOG.md#release-handoff).

### Main keyboard command

`shell/scripts/main-keyboard` controls only `at-translated-set-2-keyboard` (the
built-in keyboard), never the external keyboard marked `main` by Hyprland.
Expose it on PATH as `~/.local/bin/main-keyboard`:

```bash
main-keyboard status   # ENABLED or DISABLED; unknown/unavailable exits nonzero
main-keyboard disable
main-keyboard enable
main-keyboard toggle
```

Hyprland's Lua config loads the helper before its existing initial device setting:

```lua
qsm_main_keyboard = dofile(shell_root .. "/shell/scripts/main-keyboard.lua")
qsm_main_keyboard.set_enabled(true)
```

The existing Super+Ctrl+D and Super+Ctrl+Shift+D bindings call
`qsm_main_keyboard.set_enabled(false)` and `set_enabled(true)` respectively.
The command and both menu routes share that helper's state; no flag file is used.
Config reload restores the enabled default. Raw `hl.device` calls bypass the
helper; use these routes to keep managed state coherent. To recover when disabled,
use another keyboard for the enable shortcut or click Enable main keyboard.
Dependencies are Hyprland's Lua `repl`, `hyprctl`, `jq` and `timeout`.

## Workbench

With `qsm-workbench` installed and on `PATH`, run from this desktop project:

```bash
qsm-workbench
```

Or from anywhere: `qsm-workbench --provider /path/to/qsm-desktop`. The tool owns
its installed runtime; this project supplies the `workbench/` catalog and adapter.
Select **Notification Layer** (`notification-layer`) and use
**Controls → presentation → show-transfer** to populate its initially empty
scene. `complete-transfer` replaces that card, `show-overflow` adds a stack, and
`dismiss-newest` closes the current newest entry on each click; `dismiss-all`
closes the whole group, including overflow. Urgency and timeout are radio choices;
DND and reduced motion are checkboxes reflecting current state. Urgency and timeout
apply to the next publication; settings do not create notifications by themselves.
Installation is
documented in the QSM Workbench README.

The rail story hosts the production `RailPopoutStack`, entries and controls
with in-memory state and fake external services. The first-level Network popout
uses the shared expansion, as do other entries and nested details. Choose Simulated input to
drive controls without moving the system cursor; Live input is for manual
review. Reset restores the story and cancels pending service work.

**OSD layer** (`osd-layer`) uses production `OsdSurface`, current shell Sliders
and isolated fake audio/brightness services. The frame contour grows around
stationary sliders through the shared Rollout, with no comparison mode. Choose
**Presentation → Show output** (or microphone/brightness). The Workbench
**Fullscreen preview** toggle still selects DataCapsule with the same controls
and state. Availability controls are independent. Its shared desktop timer
expires after 1500ms without pointer/grace or pressed-gesture retention; focus
alone does not hold it open. Inspect the whole slider focus ring and closing
after leaving. The owner accepted this OSD's appearance and behaviour on the live
desktop before the shared rewrite; the current source and other callers still
await review. Restart Workbench after QML edits only when requested.
Use installed `qsm-workbench session` for explicit instance selection,
declared actions/input, fullscreen preview and in-memory render inspection;
system-mouse navigation and screenshots are not required for preparation.
Before attaching, request `describe` for the exact PID and confirm provider
`qsm-desktop` and the required story (including `notification-layer`). An older
session can retain an older catalog; do not reuse its session file blindly or
invoke a sibling Workbench checkout as a fallback.

In Simulated mode, use **Pointer → Rail**, then **Colours**, **Night light** or
**Clean caches** to reach the nested controls. **Child**, **Body** and **Outside**
exercise travel and dismissal; the action buttons click or scroll the actual
controls. **Clean caches** is two clicks, exactly as the cell is: the first arms
it, the second sweeps.

The three rail flows cover nested travel/dismissal, night-light controls and
colour picking, including keyboard retention, suppression and reset. They
exercise actual Qt input and production wiring offscreen. They do not establish
Wayland mask correctness, cross-window focus or visual acceptance.

Rollout `opened` / `dismissed` events carry `{ level, kind, title }`. A `kind` is
a component's own identity: there is no generic fallback, and every cell that
owns a popout declares one — `network`, `bluetooth`, `battery`, `sound`, `app`,
`tray`, `calendar`, `actions`, `nightlight`, `colorpick`, `updates`, `railpin`,
`session`, `keepawake`, `clearcache`. Descriptive kinds (`updates`, `railpin`,
`session`, `keepawake`, `clearcache`) share one description body; that body is
not what identifies them. A component shown many times (every app row is an
`app`, every tray icon a `tray`) is told apart by its anchor cell, and the title
is the controller's own text — "Keep awake", "Clean caches", "Night light",
"Colours". Reports are diffed on kind **and** anchor cell and emitted once
assignments settle, so moving between two cells records a real switch, and a
dismissal names the entry that just closed. `expectEvent` matches payloads by
exact JSON equality, so a flow asserting an event must name its `title`.

### Interaction events

Rollouts opening and closing is only half of what this story does. Every
control inside it also reports what it was asked to do, through the component's
own handler, so a live click and a simulated click on the same cell produce the
same records — the driver never manufactures one.

`interacted` (origin `component`) carries `{ kind, action, title }` plus
`target`/`value` where they mean something. `action` is the gesture, `kind` is
the component: `hover-entered` / `hover-left` on entry and departure, `clicked`
on a real click, `armed` / `disarmed` around a destructive cell's confirmation,
`fired` once it runs, `warmth` at the end of one warmth gesture, and
`pick` / `select` / `copy` / `edit` for the colour menu's swatches, copy
buttons, accent squares and editor row. A `warmth` record names the resulting
percentage, never which of drag, wheel or key produced it.

`operated` (origin `service`) is what the in-memory stand-ins then did:
`{ operation, phase, value }` with `phase` one of `started`, `completed`,
`state`, `warmth`. A sweep reports `started` when it is accepted and
`completed` with `Preview cache cleaned` after that result is assigned; a pick
and an editor run report the colour they returned; a copy reports every copy,
including a repeat of a hex it already held. Toggle state and warmth are read
from the services rather than from the click, so the record says what became
true and never pretends a key press caused it. Reset writes the defaults back
with observation off, so no default is ever claimed as something a person did,
and cancelled work emits no completion.

Two origins keep the story honest: `scenario` (`applied`) names a setup group —
suppression, motion, keyboard retention — which sets up state rather than
driving a control, and `action` names the toolbar button that asked for
something. Neither claims the work happened; the component answers for itself.

## Source readiness

This desktop is source-ready: the spec is the authority, the workbench provides
the verification infrastructure, and the owner reviews each item individually.
No unverified blanket claim `'everything works'` is made. Each component's
behavior is inspected in the live window with owner acceptance. Details of
what is verified and what remains open are in `spec/13-implementation.md`
(defect-family review) and `docs/BACKLOG.md` (open items only).
