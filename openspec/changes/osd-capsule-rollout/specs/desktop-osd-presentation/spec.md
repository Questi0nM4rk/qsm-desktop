## ADDED Requirements

### Requirement: Desktop story includes the production OSD handle
Normal-mode desktop OSD story SHALL use the same shader bulge, rotating arrow and
geometry facts as production. OsdSurface SHALL remain the sole owner of trigger
and hold corridors. The idle handle SHALL be absent in fullscreen and focus mode.

#### Scenario: Find the hidden normal-mode OSD
- **WHEN** the user hovers the visible OSD arrow/bulge in the story
- **THEN** the production surface's existing trigger corridor presents the OSD
  and the handle rides its shared opening edge

#### Scenario: Enter fullscreen
- **WHEN** fullscreen preview selects the capsule presentation
- **THEN** the same scene policy hides both idle bulge and arrow, without a second
  local opening handler or a permanent fullscreen trigger

### Requirement: Small desktop surfaces share reveal and retract
OSD and rail popouts SHALL use the shared Rollout small tier for attached reveal
and retract. A closing rail popout SHALL retain opaque outgoing content, natural
geometry and its anchor until shared retract finishes. Its semantic dismissal
SHALL still occur immediately and closing content SHALL NOT remain actionable.
No independent content fade/unload timer SHALL precede the common retract.

#### Scenario: Dismiss a populated rail popout
- **WHEN** its controller dismisses the item
- **THEN** the shared rollout retracts with the same content and dimensions, and
  unloads it only after the shared component is no longer visible

#### Scenario: Interrupt retract with another item
- **WHEN** a new item is selected while shared retract is running
- **THEN** the shared motion reverses to the new selection without a stale closing
  callback unloading it, and native targets report only the new active item

### Requirement: Mode chooses the genuine shell wrapper
The desktop SHALL render an active OSD in a real qsm-shell DataCapsule on its
target fullscreen screen and an attached qsm-shell Rollout otherwise. Fullscreen
SHALL have no idle handle and SHALL NOT use the detached-Rollout shader capsule
path for this OSD. Both wrappers SHALL preserve the existing compact width and
channel footprint, right-edge center placement and desktop channel styling.

#### Scenario: Enter and leave fullscreen with an active OSD
- **WHEN** the targeted screen enters and leaves application fullscreen
- **THEN** the genuine wrapper changes without changing stored values, mute,
  active kind, target screen or child control identity

#### Scenario: Fullscreen OSD is hidden
- **WHEN** a fullscreen OSD expires or is not targeted to that monitor
- **THEN** its shadow/fade/idle location contributes no clickable input region

### Requirement: One real channel composition
Both presentations SHALL host one persistent content object using current shell
Sliders, in output/microphone/brightness order with existing availability rules.
Pointer, keyboard, wheel and mute-label intent SHALL call existing desktop service
methods. Mute SHALL preserve level and a level write SHALL unmute; brightness
SHALL have no mute action. The surface width SHALL remain 56px, track 40x140px and
thumb 32px via the existing theme overrides, without cropping the controls.

#### Scenario: Change output volume and mute
- **WHEN** the user changes a real Slider or activates its mute label
- **THEN** the existing service receives the intent and supplies the resulting
  reading/mute state to the same control in either presentation

#### Scenario: Unavailable optional channel
- **WHEN** microphone or brightness availability changes
- **THEN** the existing desktop availability policy determines content and
  content-driven height without creating a second set of controls

### Requirement: One presentation lifetime
The desktop SHALL retain one OsdState visibility/target/kind and expiry owner with
1500ms timeout. Repeated presentation SHALL refresh this owner even for same-value
operations, and a held surface SHALL pause expiry. Mode switching alone SHALL NOT
restart expiry. Startup/reconcile setup SHALL NOT present an OSD. Only the target
screen SHALL report effective retention; mode/target transitions SHALL leave no
stale hold or late reset completion.

#### Scenario: Repeated event while held
- **WHEN** the current channel is presented again while pointer/focus retains it
- **THEN** it stays visible, retains one timer budget and expires after release
  according to the existing desktop lifetime

#### Scenario: Switch mode without a new event
- **WHEN** fullscreen changes during an unheld active OSD
- **THEN** the same pending lifetime continues instead of receiving a new budget

### Requirement: Desktop proof uses the production surface
The existing desktop provider SHALL expose an `osd-layer` story using production
OsdSurface and shared presentation state with isolated fake services. The injected
readonly previewEnvironment fullscreen flag SHALL select the same production
mode branch; actual Workbench window fullscreen SHALL remain separate. Native
targets SHALL resolve actual controls. Component intents, service results and
setup operations SHALL be distinguishable and reset SHALL cancel pending work.

#### Scenario: Toggle fullscreen preview with changed values
- **WHEN** fullscreen preview is toggled after changing volume/mute in the story
- **THEN** the capsule replaces the rollout without replacing controls or losing
  those values, and the mock application reflects the injected environment

#### Scenario: Reset or invalid route
- **WHEN** reset cancels an active story or a missing native/action target is requested
- **THEN** reset produces no stale completion, and a missing route refuses without
  impersonating a successful component or service result

### Requirement: Reusable defects have owning shell corrections
A discovered reusable component defect SHALL be corrected in qsm-shell rather
than worked around in desktop. Any such correction SHALL include coherent shell
component docs and specifications; desktop policy defects SHALL stay in desktop.

#### Scenario: Integration requires missing component behavior
- **WHEN** the production path demonstrates a missing reusable interaction fact
- **THEN** implementation pauses that dependent step for an owning shell fix and
  updates its shell docs/specs before continuing the desktop integration
