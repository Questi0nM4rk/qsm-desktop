## Context

qsm owns the desktop shell while Hyprland owns client placement. The session
previously relied on HyDE-derived Qt, GTK, and Kvantum configuration, so portal
and authentication dialogs could appear as unrelated light or Catppuccin
surfaces. The rail is pointer-oriented and the launcher is keyboard-oriented,
but there is no complete keyboard control model for desktop features.

The first implementation pass has added a Qt/GTK palette bridge, a seeded
`>action` launcher mode, and an overlay-layer fullscreen allowlist. It does not
yet provide command-centre detail navigation, SDF silhouettes over true
fullscreen, keyboard panel-tab navigation, or framed focus mode.

## Goals / Non-Goals

**Goals:**

- Make new Qt portal and GTK dialogs inherit the active qsm deep-night session
  appearance.
- Make the command centre the keyboard home for every mouse-reachable rail
  control, delegated settings route, and panel tab, with a consistent two-level
  navigation contract.
- Preserve true fullscreen for applications that require it while retaining
  SDF-backed notification and OSD feedback above it.
- Provide a separate qsm focus mode whose client viewport is framed, opaque,
  and reversible.

**Non-Goals:**

- Rebuild third-party application interfaces or replace their own themes.
- Rebuild NetworkManager, BlueZ, PipeWire, or colour-editor interfaces. The
  command centre drives the same shell controls and delegates deeper settings
  to their existing owners.
- Pretend qsm focus mode is native application fullscreen.
- Add media or unrelated desktop features.

## Decisions

### External dialogs use a session bridge

Hyprland exports `QT_QPA_PLATFORMTHEME=qt6ct` so the Qt6
`hyprland-share-picker` reads qt6ct. qsm deep-night semantic values are mapped
into qt5ct/qt6ct palettes, and small final GTK user-style overrides cover GTK3
polkit and GTK4 dialogs. This preserves installed themes while giving dialogs
the qsm background, raised controls, accent focus, and danger roles.

The first pass targets active deep-night. A later theme bridge writer is needed
before mountain-dusk can claim external-dialog parity.

### The command centre is a two-level control surface

`Super+A` opens the existing launcher in command-centre mode. Search filters
categories and controls. `LauncherSurface` owns an explicit parent/detail path,
parent query, and parent cursor so Enter on a multi-choice control enters a detail
view in the same surface. Left/Escape outside text restores the exact parent
view. Direct repeatable controls activate in place. Arrows move
the single visible selection cursor and Enter toggles or commits. The rail
remains the pointer representation of the same controls rather than receiving
keyboard focus. Direct panel shortcuts remain intact; the Panel category is a
browser, not a replacement route.

The alternative, moving keyboard focus through the physical rail, was rejected
because it would make a hidden, edge-attached structure the keyboard home and
would duplicate selection/focus machinery already present in the launcher.

The centre exposes the rail's full capability surface: quick actions (including
night-light warmth), brightness, output and microphone levels and mutes, audio
device selection and mixer, Wi-Fi and VPN controls plus network settings,
Bluetooth adapter/discovery/device controls plus manager, power profiles, and
session controls. Output volume uses the accepted ListRow inline Slider rather
than separate increase/decrease rows. Other level adoption follows owner review
of output volume and mute. Delegated settings open the same application as their rail row.
Operations with destructive or screen-taking consequences first Enter arms a
named confirmation and second Enter performs the action. Colour picking names
the pending screen takeover before it starts.

### Output audio and Colemak-DH menu input

The bounded current segment is output volume and mute in existing Sound details.
The launcher owns stable result identities and menu/search/editor focus regions.
Service-driven labels and ranking changes preserve identity; there is no delayed
index restore or forced search focus. Only user filtering deliberately selects a
new first match. Unavailable audio rows are visibly disabled and skipped.

`Super+A` opens with menu focus. On non-text targets unmodified `n/e/i/o` means
left/down/up/right; `/` focuses search. `i/e` navigate even from the Slider;
`n/o` adjust its value, otherwise return/open a detail. Enter/Escape returns from
the editor to its own row without rollback. Search retains literal text and caret
commands; its Up/Down enters menu navigation. Do not add speculative Vim commands.

ResultRow keeps its accepted heading height through ListRow.headingHeight instead
of overriding the whole implicitHeight. The row exposes actual expansionHeight
so EdgeScene adds only the revealed viewport to its existing bounded launcher
height. Paint and input still follow ListRow's clip and the existing rollout path.
Live readings bind in the delegate, not in the structural result model, avoiding
delegate destruction on each volume change. Slider moved calls existing
AudioService.setOutput; mute activation calls toggleOutputMuted once, sharing row,
Switch, keyboard and accessible routes. Existing microphone/device/mixer routes
stay intact. Services, OSD focus policy and Workbench runtime remain unchanged.

Owner review of shell Compositions / menu-items permits this desktop segment.
Do not run checks or operate/restart production without a fresh explicit request.
Runtime and owner acceptance remain open after source preparation.

### True fullscreen remains native, with a narrow overlay allowlist

The shared EdgeScene maps on `WlrLayer.Overlay`. During native fullscreen it
MUST render only notification popups that reached `NotificationService.popups`
after DND filtering and event-driven OSD silhouettes, not the frame, rail,
modal catches, rail popouts, or idle handles. The fullscreen shader path
renders independent inset capsules: each notification row owns a fully rounded
capsule that expands with its content, while the OSD owns one self-contained
vertical capsule. These carry qsm fill and glass edge but never attach to a
screen side. Transparent notification/OSD content is invalid.

The alternative, restoring the full frame or source edge for every notification,
was rejected because it makes true fullscreen visually unstable and overstates
shell chrome. Frame-attached rollouts remain exclusive to qsm focus mode.

### QSM focus mode is distinct from true fullscreen

`FocusModeService` owns qsm focus mode. It saves an address-keyed snapshot of
the active client's placement, monitor, workspace and floating/fullscreen state;
collapses the rail presentation on that workspace without changing persisted
preferences; supplies an opaque qsm
viewport background; and places the client exactly inside the 16px frame. On
exit, target loss, or shell startup recovery it restores or clears that
transformation. It permits only notifications and OSD on the target's visible
workspace and never blocks another workspace's UI.

`Super+F` and `Super+Shift+F` both invoke native Hyprland fullscreen. The geometry
transformation remains an explicit IPC facility, not a replacement for fullscreen.
Native fullscreen belongs to each workspace; shell suppression depends only on
the workspace currently displayed by each monitor, including special workspaces.
This preserves game, direct-scanout, HDR/VRR, browser F11 and client protocol behavior.
Focus mode MUST NOT send a fake fullscreen state to clients as its primary
mechanism; its viewport is compositor-managed client geometry.

## Risks / Trade-offs

- [External dialog changes need process restart] -> Restart only portal units
  after updating their activation environment; already-open dialogs require
  reopening.
- [External theme drift after qsm theme switch] -> Mark deep-night-only bridge
  as an explicit limitation and add a generated bridge before claiming parity.
- [Focus mode loses a client's original state] -> Snapshot identity, monitor,
  workspace, floating/tiled state, geometry, fullscreen state, and rail state;
  restore on every exit path.
- [Games need native fullscreen] -> Keep a separate true-fullscreen binding and
  never silently replace an application's own fullscreen request with focus
  mode.
- [Overlay content is transparent] -> Add a fullscreen-only SDF mode and a
  compositor-layer smoke assertion before enabling the allowlist by default.
- [Command-centre action is unsafe] -> Every rail action receives an explicit
  keyboard contract. Destructive, connectivity-disrupting, and screen-taking
  routes use a named arm-then-fire confirmation and visible result state.

## Migration Plan

1. Keep the existing `Super+Space` launcher and native fullscreen behavior
   intact while command-centre detail navigation and overlay SDF rendering are
   completed.
2. Add qsm focus mode behind its own test seam and prove enter/restore across
   tiled and floating windows.
3. Route both fullscreen shortcuts to native Hyprland fullscreen and keep the
   optional geometry transformation behind its explicit IPC seam.
4. Roll back by restoring the original Hyprland binding and disabling the focus
  mode service; startup recovery clears any stale focus transformation rather
  than relying on a persisted snapshot.

## Open Questions

- Should mountain-dusk generate a matching external dialog bridge in this
  change or a follow-up?
