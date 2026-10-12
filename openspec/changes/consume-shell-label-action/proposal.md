## Why

The desktop OSD uses Slider's optional label to mute output and microphone.
Shell keyboard/API readiness must reach those actual host callbacks and observable
service state, not stop at a standalone label demo.

## What Changes

- Consume `shell-label-action-parity` after its shared component changes land.
- Give output/microphone label actions meaningful accessible names; brightness
  remains a caption with no mute operation.
- Expose named output/microphone mute actions in the existing isolated OSD story,
  calling the same component function as pointer/keyboard input.
- Exercise changing fake-service state through the real production OSD content
  in normal and simulated-fullscreen presentations, without changing live audio.

### Non-goals

New command infrastructure, OS input, production restart, live sound/brightness
mutation, networking features, broader desktop polish and package upgrades.
Production layer-shell keyboard focus remains desktop-owned and unchanged; the
existing action picker is the keyboard route when the OSD window is passive.

## Capabilities

### New Capabilities
- `desktop-label-action`: consume shell label actions through the existing OSD host.

### Modified Capabilities
None; the durable OpenSpec catalog is empty.

## Impact

`OsdChannel.qml`, `OsdContent.qml`, `workbench/OsdStory.qml`, one focused provider
flow and current `spec/05-osd.md`. Existing AudioService methods and host callbacks
remain the operation owner. The shell dependency is a separate repository change.

## Critiques

- Devil's advocate: a fake service does not prove actual audio changed. Report
  production component/host wiring separately from real-device verification.
- Future archaeologist: name output and microphone operations explicitly; icon
  filenames are not accessible names and brightness must not offer a dead action.
- Scope sniper: reuse the existing OSD story, service fakes and action dictionary;
  do not introduce another service, command bus or global keyboard grab.

All findings are addressed by the design and requirement scenarios; no waivers.
