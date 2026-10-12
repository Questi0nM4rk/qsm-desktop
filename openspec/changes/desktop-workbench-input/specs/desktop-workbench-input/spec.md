## ADDED Requirements

### Requirement: Shared production rail lifecycle
Desktop and workbench SHALL use the same production component for the parent/child rollout lifecycle, geometry and dismissal. Only external state and services SHALL be substituted in workbench.

#### Scenario: Travel through nested rollouts
- **WHEN** the pointer enters Quick actions, enters Colours, travels into the child and returns to the parent
- **THEN** the real entries open the correct rollouts and the parent remains open while the child is hovered
- **AND** leaving both rollouts closes them after the production grace period, while returning during grace cancels dismissal

### Requirement: Real control input
Simulated input SHALL reach actual Qt controls in the scene without moving the system cursor. Flow user actions MUST NOT invoke fake services directly.

#### Scenario: Change night-light warmth
- **WHEN** the user opens Night light, toggles it and adjusts its slider through pointer, wheel or keyboard input
- **THEN** the fake service receives the production control's intent and the rendered control/readout reflects the resulting value

#### Scenario: Pick a colour
- **WHEN** the user activates the real picker control
- **THEN** busy state is visible followed by the picked colour and copied feedback

### Requirement: Deterministic isolated environment
The provider SHALL use in-memory state, controllable suppression and keyboard retention, and reset all scenario-owned state and timers. It MUST NOT read or write the owner's persisted desktop state or invoke host services.

#### Scenario: Reset after interaction
- **WHEN** the user changes service state, keyboard ownership, reduced motion or fullscreen and resets
- **THEN** the scene returns to documented defaults without persisted state leaking in or timers changing it later

#### Scenario: Keyboard retention and suppression
- **WHEN** keyboard ownership holds an open rollout after pointer exit, then ownership is released
- **THEN** production lifecycle closes it when keep-open has expired
- **AND** fullscreen or focus suppression hides the rollout using the same production suppression input

### Requirement: Honest transition evidence
The provider SHALL expose actual opening/closing state and qualified parent/child events for bounded flow waits.

#### Scenario: Interrupt an opening rollout
- **WHEN** a flow observes opening and moves outside or suppresses the surface before it settles
- **THEN** the production rollout completes the appropriate transition and a current event identifies which rollout changed
