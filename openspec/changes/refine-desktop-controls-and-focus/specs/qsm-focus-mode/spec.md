## ADDED Requirements

### Requirement: QSM focus mode frames the active client
The shell SHALL provide qsm focus mode distinct from native fullscreen.
`FocusModeService` SHALL own an address-keyed snapshot of the eligible active
client. On entry it SHALL collapse the rail presentation only on that client's
visible workspace and place the active client inside the opaque viewport bounded
by the 16px qsm frame.

#### Scenario: Enter focus mode
- **WHEN** the user invokes qsm focus mode for an eligible active client
- **THEN** the rail MUST collapse, the viewport MUST become opaque, and the
  client MUST fill the inner framed viewport

### Requirement: Focus mode restores prior client and rail state
FocusModeService SHALL snapshot client placement, monitor, workspace,
floating/fullscreen state before entering focus mode. It SHALL restore them on
explicit exit or when the mode becomes invalid, without changing persisted rail
preferences. Snapshots made by the old rail-mutating route SHALL restore its saved
rail state. On shell
startup it SHALL clear or restore an unfinished focus transformation before
allowing another focus entry.

#### Scenario: Exit focus mode
- **WHEN** the user exits qsm focus mode
- **THEN** the client MUST return to its saved state and the normal rail presentation
  MUST return without leaving
  a forced floating, fullscreen, or collapsed-rail state behind

#### Scenario: Focus target disappears
- **WHEN** the focus-mode client closes, moves to another monitor, or otherwise
  becomes ineligible
- **THEN** qsm focus mode MUST exit and remove its workspace-local presentation

### Requirement: Focus mode is quiet and native fullscreen remains available
The optional geometry transformation SHALL allow only notifications and
event-driven OSD on its target's visible workspace. It MUST NOT block UI on
another monitor or workspace. It remains available through its explicit IPC seam,
not the fullscreen keyboard route. `Super+F` and `Super+Shift+F` SHALL invoke native
Hyprland fullscreen, independently on each workspace. The old `qsm:focusMode`
shortcut name SHALL forward to native fullscreen for already-loaded configs.

#### Scenario: Notification arrives in focus mode
- **WHEN** a notification arrives during qsm focus mode
- **THEN** the notification popup MAY appear while rail, panel, launcher,
  session, and rail popouts remain unavailable

#### Scenario: Native fullscreen requested
- **WHEN** the user invokes the native fullscreen binding
- **THEN** Hyprland MUST enter true client fullscreen rather than qsm focus
  mode
