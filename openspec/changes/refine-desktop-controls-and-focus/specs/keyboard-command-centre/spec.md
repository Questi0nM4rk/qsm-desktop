## ADDED Requirements

### Requirement: Command centre is the keyboard home for rail controls
The existing launcher `>action` mode SHALL become the command centre and SHALL
open with `Super+A`. The centre SHALL fuzzy filter every direct rail control,
delegated settings route, adjustable level, and a Panel category without adding
a second standalone surface. `Super+Space` MUST retain ordinary launcher toggle
behavior, and existing direct panel shortcuts MUST remain available.

#### Scenario: Open command centre
- **WHEN** the user invokes `Super+A` from any shell modal state
- **THEN** the launcher MUST open in command-centre mode with its query seeded
  to the command-centre namespace

#### Scenario: Preserve ordinary launcher behavior
- **WHEN** the user invokes `Super+Space` while the ordinary launcher is open
- **THEN** the launcher MUST close rather than reseed command-centre mode

### Requirement: Command centre supports control detail navigation
The command centre SHALL show a detail view for multiple real choices in the same
surface and activate direct repeatable controls in place. It SHALL retain parent
query and stable cursor identity. Up and Down SHALL move one visible selection
cursor; Enter SHALL activate the selected control. Outside text input, Left and
Escape SHALL close an inline editor first, otherwise return to the parent control
list with its prior query and cursor restored. Service updates MUST NOT change
the selected operation or force focus back into search.

#### Scenario: Toggle a safe rail control
- **WHEN** the user selects Keep awake or Night light and presses Enter in its
  detail view
- **THEN** the service state MUST change and the detail view MUST visibly show
  the resulting state without closing the command centre

#### Scenario: Navigate panel tabs
- **WHEN** the user selects the Panel category in the command centre
- **THEN** the user MUST be able to choose a panel tab with the same arrow and
  Enter contract

#### Scenario: Return from control detail
- **WHEN** the user returns from a selected control detail view
- **THEN** the command centre MUST restore the prior filtered result list and
  its selected control

### Requirement: Rail detail contracts are complete and safe
The command centre SHALL provide keyboard routes for quick actions, brightness,
output and microphone levels and mutes, audio device and mixer controls,
network and Bluetooth controls and settings routes, power profiles, and session
controls. Output volume SHALL present its live value and the shared inline Slider
with increase/decrease actions rather than separate adjustment rows. Other level
adoption follows owner acceptance of this bounded audio item. Delegated settings SHALL open the same owner application as
the corresponding rail row.

#### Scenario: Adjust a level
- **WHEN** the user selects output volume in Sound details
- **THEN** the centre SHALL open a horizontal Slider directly below its row,
  update through AudioService.setOutput, and return focus to that same row on
  Enter/Escape without reverting the value or closing the centre

#### Scenario: Repeat output mute after a service update
- **WHEN** the user toggles output mute repeatedly with Enter or the row's Switch
- **THEN** each activation SHALL call the same existing service operation once,
  and the same operation SHALL remain selected even if results are rebuilt

### Requirement: Colemak-DH motions respect text input
The action menu SHALL initially hold menu focus. Outside text input unmodified
`n/e/i/o` SHALL mean left/down/up/right and `/` SHALL focus the existing search
field. `i/e` and Up/Down SHALL navigate even from the inline Slider; `n/o` and
Left/Right SHALL adjust its value. In search or password input these characters
MUST remain literal text; selection and clipboard modifiers MUST remain native.

#### Scenario: Search then return to navigation
- **WHEN** the user presses `/` in the menu, types `neio/`, then presses Up/Down
- **THEN** the exact text SHALL reach search, and arrow input SHALL return to menu
  focus where Colemak-DH motions operate the visible selection

#### Scenario: Open delegated settings
- **WHEN** the user selects Network settings, Bluetooth settings, or Sound
  settings
- **THEN** the centre SHALL delegate to the same application used by the rail

### Requirement: Destructive and takeover controls have keyboard safety
The command centre SHALL expose cache cleanup, connectivity-disrupting actions,
device forget, and colour picking with an explicit keyboard-safe contract.
The first Enter SHALL arm a named confirmation and the second Enter SHALL
perform the action. A successful colour-pick confirmation SHALL state that the
screen picker takes over input.

#### Scenario: Confirm a destructive action
- **WHEN** the user selects cache cleanup or a connectivity-disrupting action
- **THEN** the centre SHALL require a second Enter before it runs and SHALL
  display the service result after completion
