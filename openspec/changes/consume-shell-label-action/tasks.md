## 1. Dependency and names

- [ ] 1.1 Confirm shell-label-action-parity's shared public label route is implemented and focused checks pass; consume its API without local keyboard handlers.
- [ ] 1.2 Give output/microphone OSD labels meaningful current-operation names and consistent availability; preserve the brightness caption and existing service callbacks.

## 2. Existing story API

- [ ] 2.1 Add toggle-output-mute and toggle-microphone-mute to the existing OsdStory action dictionary and declarations, calling actual channel.activateLabel and refusing unknown/hidden/unavailable targets.
- [ ] 2.2 Add one focused provider integration flow for actual label pointer/key input, public mute actions, stored-level preservation, unavailable refusal and normal/simulated-fullscreen presentation.

## 3. Requested verification and review

- [ ] 3.1 Run the focused flow with installed Workbench and isolated fake services; report component intent separately from service outcomes and distinguish simulated presentation from compositor fullscreen.
- [ ] 3.2 Update spec/05-osd.md with the current API and actual evidence scope, then validate this change strictly.
- [ ] 3.3 Prepare this one OSD label/mute item for owner review and wait; do not proceed to another shell component or desktop improvement before acceptance.

Execution: Strategy B, sequential after the shell segment; main owns planning,
one fresh Luna high worker owns this consumer segment, Luna medium runs requested
checks. Only OsdContent.qml, OsdChannel.qml if needed, workbench/OsdStory.qml, one
new workbench/flows/osd-label-action.json and spec/05-osd.md may change. No live
audio/brightness mutation, OS pointer use, production restart, new keyboard grab,
Workbench-core edit, package upgrade, commit or archive. A simulated/offscreen
pass does not complete owner acceptance or real-device verification.

## Active scope clarification

Source implementation is prepared; this segment's flow has not run. The owner
prioritizes easy action-menu control and keyboard navigation. Reuse existing
service functions or external commands; do not introduce a universal backend API
or require view-logic extraction. Keep this local OSD keyboard integration as
supporting work, not completion of action-menu reachability. No owner acceptance
is claimed.
