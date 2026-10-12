## Why

The shell lost the coherent external theme that HyDE supplied, leaving portal
pickers and authentication dialogs visually disconnected from qsm. Its
keyboard path also exposes isolated shortcuts rather than a navigable control
system, and true fullscreen suppresses the shell's useful transient feedback.

## What Changes

- Bridge the active qsm deep-night palette to Qt portal dialogs and GTK dialogs.
- Evolve the existing `>action` launcher mode into a keyboard-first command
  centre for every rail control, delegated settings route, and adjustable level.
- Adopt the accepted shell inline editor first for output volume and mute,
  retain action identity through state updates, and add non-text Colemak-DH
  `n/e/i/o` navigation plus `/` to focus the existing search field.
- Keep notifications and the event-driven OSD usable over true fullscreen as
  detached SDF capsules, not transparent content or frame-attached rollouts.
- Add QSM focus mode: a framed, opaque focused-client viewport with a collapsed
  rail, notification and OSD-only interruptions, and exact restoration on exit.
- Keep a separate true Hyprland fullscreen path for games and apps that need
  native fullscreen behavior.

## Capabilities

### New Capabilities
- `external-dialog-theme-bridge`: Maps the qsm palette into Qt and GTK dialogs
  launched in the desktop session.
- `keyboard-command-centre`: Provides searchable, keyboard-first navigation of
  rail controls, settings routes, levels, and panel tabs.
- `fullscreen-overlay-feedback`: Keeps SDF-backed notifications and OSD usable
  over true fullscreen without exposing general shell chrome.
- `qsm-focus-mode`: Provides a framed viewport focus mode distinct from native
  application fullscreen.

### Modified Capabilities

None. The repository has no durable OpenSpec capability catalog yet; existing
`spec/` documents remain the implementation-era design authority until these
capabilities are promoted.

## Impact

- Shell state, keyboard shortcuts, launcher results, edge-scene layer behavior,
  rollout rendering, fullscreen smoke coverage, and Hyprland bindings.
- User session configuration under `~/.config/hypr`, `qt5ct`, `qt6ct`, and GTK
  user stylesheets.
- Hyprland's true-fullscreen binding gains a separate focus-mode counterpart;
  games and native fullscreen applications remain on the true path.

## Critiques

### Devil's Advocate

- **Focus-mode restoration needs real ownership.** Accepted: a dedicated
  `FocusModeService`, rather than `ShellState` or `HyprClientsService`, owns an
  address-keyed client and rail snapshot plus explicit restore dispatches. On
  shell startup it detects and clears an unfinished focus transformation before
  offering a new entry.
- **Fullscreen detection can lag compositor churn.** Accepted: fullscreen
  refresh coverage and isolated smoke tests must include workspace, monitor,
  and target changes. A brief transition is tolerated only while no stale input
  region remains active.
- **A flat launcher cannot deliver nested control behavior.** Accepted: the
  command centre adds explicit parent/detail path and cursor state rather than
  overloading the existing query reset path.
- **Mouse-only controls would leave the keyboard path incomplete.** Superseded
  by owner direction: every mouse-reachable rail control gains a command-centre
  route, with keyboard confirmation replacing mouse-specific safety friction.
- **External colors cannot update existing dialogs.** Accepted: the bridge
  guarantees only newly opened Qt/GTK dialogs after portal environment reload.

### Future Archaeologist

- **Command-centre ownership was ambiguous.** Resolved: it is the existing
  launcher `>action` mode, not a new modal. `Super+N`, `Super+W`, and
  `Super+D` remain direct panel shortcuts; the Panel category is their keyboard
  browser, not a replacement.
- **Command-centre scope was safe-controls-only.** Superseded: it now covers
  quick actions, levels, device selection, connectivity, power profiles,
  delegated settings, and session routes. Cache cleanup, radio-off, device
  forget, and colour picking use explicit keyboard confirmation or takeover
  acknowledgement rather than being omitted.
- **Fullscreen notification scope was ambiguous.** Resolved: every popup that
  reaches `NotificationService.popups` renders over true fullscreen; existing
  DND filtering happens before that list, so normal notifications remain
  suppressed during DND and critical notifications remain available.
- **Focus-mode recovery was missing.** Resolved: the service owns its state and
  must restore or clear focus transformation on target loss and shell startup.
- **Bridge lifecycle was ambiguous.** Resolved: this change documents a
  deep-night session-static bridge. Mountain-dusk writing and live updates are
  deferred rather than implied.

### Scope Sniper

- **The change combines four capabilities.** Accepted with sequence: external
  bridge and current fullscreen allowlist are reconciliation work; command
  centre is one launcher mode; focus mode is phased behind its own service and
  must not block true-fullscreen stability.
- **Focus mode could grow unbounded.** Accepted: first delivery supports one
  active client on one monitor with explicit target-loss restoration. Shortcut
  migration occurs only after its restore path is proven. Native fullscreen is
  bound to `Super+Shift+F` when qsm focus mode takes `Super+F`.
