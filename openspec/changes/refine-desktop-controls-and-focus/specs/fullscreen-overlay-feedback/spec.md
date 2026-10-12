## ADDED Requirements

### Requirement: True fullscreen preserves feedback overlays
During native Hyprland fullscreen, the qsm scene SHALL map on the compositor
overlay layer. Every popup already admitted to `NotificationService.popups`
after DND filtering and the event-driven OSD SHALL remain visible and
interactive; all other shell surfaces SHALL remain hidden or inert.

#### Scenario: Normal notification arrives over fullscreen
- **WHEN** a normal notification arrives on the focused fullscreen monitor and
  DND is disabled
- **THEN** its popup MUST appear above the client with an active input region

#### Scenario: OSD event occurs over fullscreen
- **WHEN** volume, microphone, or brightness changes on the focused fullscreen
  monitor
- **THEN** the right OSD MUST appear above the client with its live controls

#### Scenario: Shell chrome stays suppressed
- **WHEN** a monitor enters native fullscreen
- **THEN** the rail, rail popouts, idle handles, panel, launcher, clipboard,
  cheat sheet, session, and their catch regions MUST be hidden or inert

### Requirement: Fullscreen feedback uses detached SDF capsules
The fullscreen overlay path SHALL render independent inset SDF capsules with
qsm fill and glass edge without rendering the ordinary qsm frame, rail, or
screen-attached source edge. Each visible notification row SHALL own a fully
rounded capsule that grows with expanded content. The OSD SHALL own one
self-contained vertical capsule.

#### Scenario: Notification capsule renders over fullscreen
- **WHEN** a notification popup is visible over native fullscreen
- **THEN** its inset rounded capsule MUST show dark fill and glass edge behind
  its content without exposing the client or connecting to a screen edge

#### Scenario: OSD capsule renders over fullscreen
- **WHEN** the event-driven OSD is visible over native fullscreen
- **THEN** its inset vertical capsule MUST show dark fill and glass edge around
  the controls without connecting to the right screen edge
