## ADDED Requirements

### Requirement: QSM focus mode frames the active client
The shell SHALL provide qsm focus mode distinct from native fullscreen.
`FocusModeService` SHALL own an address-keyed snapshot of the eligible active
client and focused-monitor rail state. On entry it SHALL collapse the focused
monitor's rail and place the active client inside the opaque viewport bounded
by the 16px qsm frame.

#### Scenario: Enter focus mode
- **WHEN** the user invokes qsm focus mode for an eligible active client
- **THEN** the rail MUST collapse, the viewport MUST become opaque, and the
  client MUST fill the inner framed viewport

### Requirement: Focus mode restores prior client and rail state
FocusModeService SHALL snapshot client placement, monitor, workspace,
floating/fullscreen state, and rail state before entering focus mode. It SHALL
restore them on explicit exit or when the mode becomes invalid. On shell
startup it SHALL clear or restore an unfinished focus transformation before
allowing another focus entry.

#### Scenario: Exit focus mode
- **WHEN** the user exits qsm focus mode
- **THEN** the client and rail MUST return to their saved state without leaving
  a forced floating, fullscreen, or collapsed-rail state behind

#### Scenario: Focus target disappears
- **WHEN** the focus-mode client closes, moves to another monitor, or otherwise
  becomes ineligible
- **THEN** qsm focus mode MUST exit and restore the saved rail state

### Requirement: Focus mode is quiet and native fullscreen remains available
Focus mode SHALL allow only notifications and event-driven OSD. After focus
mode restoration is proven, `Super+F` SHALL invoke it and `Super+Shift+F` MUST
invoke native Hyprland fullscreen for games and clients that require true
fullscreen behavior.

#### Scenario: Notification arrives in focus mode
- **WHEN** a notification arrives during qsm focus mode
- **THEN** the notification popup MAY appear while rail, panel, launcher,
  session, and rail popouts remain unavailable

#### Scenario: Native fullscreen requested
- **WHEN** the user invokes the native fullscreen binding
- **THEN** Hyprland MUST enter true client fullscreen rather than qsm focus
  mode
