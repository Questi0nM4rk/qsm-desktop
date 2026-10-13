## ADDED Requirements

### Requirement: Stable responsive outer panel
All five tabs SHALL share one outer panel footprint for a given viewport. The
preferred baseline SHALL be 854x520 logical px, clamped to the available scene.
Tab choice, missing sensors, media availability and history length MUST NOT
resize the outer panel or move its navigation strip.

#### Scenario: Tab and data-state changes
- **WHEN** the owner navigates among Dashboard, Media, Performance, Workspaces
  and Notifications while content changes
- **THEN** the outer size and navigation position stay fixed and content updates
  inside its assigned viewport

### Requirement: Bounded content remains usable
Static compositions SHALL have bounded overflow, short content SHALL be
deliberately centered or laid out, and model-backed tabs SHALL retain their
own scrolling route. The panel MUST preserve existing keyboard tab navigation
and Down into content.

#### Scenario: Short or narrow screen
- **WHEN** the available viewport cannot contain a tab's natural composition
- **THEN** the owner can reach its content by the appropriate viewport scroll
  without truncated controls, nested competing model scrollers or outer resizing

### Requirement: Panel demand has a stable owner
The permanent panel host SHALL own detailed sampling demand by identity.
Outgoing tab destruction MUST NOT clear another host's active demand.

#### Scenario: Panel migrates to another monitor
- **WHEN** one panel retracts while the focused monitor's panel becomes active
- **THEN** the incoming Dashboard/Performance demand remains present after the
  outgoing tab is destroyed, independently of lightweight CPU/RAM watchers
