## ADDED Requirements

### Requirement: OSD consumes the shared shell label operation
Output and microphone OSD labels SHALL call the existing AudioService mute
operation through their current host callback after shared Slider activation.
Their accessible names SHALL describe the actual operation. Brightness SHALL
remain a caption with no mute action; unavailable channels SHALL refuse input
and API activation consistently.

#### Scenario: Keyboard activates output mute in a focus-capable host
- **WHEN** the actionable output label has actual keyboard focus and receives Enter or Space
- **THEN** the shared label intent reaches AudioService once and stored output level remains unchanged

#### Scenario: Unavailable microphone or passive brightness is activated
- **WHEN** a caller requests the label operation on an unavailable microphone or the brightness caption
- **THEN** activation is refused and no mute service operation is reported

### Requirement: OSD story exposes callable mute actions
The existing OsdStory SHALL declare `toggle-output-mute` and
`toggle-microphone-mute`, dispatch by action-name-to-function mapping and call
the actual channel's activateLabel function. Successful calls SHALL report
component intent and service result separately; unknown, hidden or unavailable
targets SHALL return false without fabricating success.

#### Scenario: External action toggles microphone without pointer input
- **WHEN** the isolated visible story receives toggle-microphone-mute for an available channel
- **THEN** the real OsdChannel emits its existing intent and the fake AudioService changes microphone-muted exactly once

### Requirement: Integration evidence preserves production boundaries
Requested checks SHALL exercise the production OsdContent with isolated fake
services in normal and simulated-fullscreen presentations. They SHALL NOT change
live audio, synthesize OS input, restart production or claim real-device or owner
acceptance. Production keyboard focus policy SHALL remain unchanged.

#### Scenario: Presentation changes around an available label
- **WHEN** the same OSD content switches between normal and simulated-fullscreen presentation
- **THEN** its callable mute action continues to reach the same host service state, and evidence identifies simulation rather than compositor fullscreen
