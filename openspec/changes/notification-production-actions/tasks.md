Execution strategy: segmented implementation with the owner-review checkpoint in 3.4. Complete the one hosted popup before proceeding to the center/archive item. Project instructions prohibit automatic TDD, runtime checks and audit sweeps; requested specification validation is separate from the pending checks in section 5.

## 1. Establish the live protocol boundary

Scope: installed Quickshell source/docs are read-only; implementation changes, if required by confirmed semantics, belong in `shell/services/NotificationService.qml`, `NotificationStore.qml` and `NotificationEntry.qml`. No daemon or session configuration changes.

- [x] 1.1 Inspect the exact installed Quickshell version/source and confirm action invocation, resident/nonresident closure, same-ID replacement/action updates, close reasons and whether expiry is expressed in seconds or milliseconds; update the adapter contract only to match verified semantics.
- [x] 1.2 Trace the existing service → store → entry action/lifetime path and define how current-source lookup, stale-action refusal and protocol-originated closure share one seam; do not add another notification owner.

## 2. Prepare the shared popup item

Depends on section 1. Scope: `../qsm-shell/docs/components/NotificationCard.md`, `NotificationStack.md`, `../qsm-shell/qml/QsmShell/Components/NotificationCard.qml`, `NotificationStack.qml` and their matching Workbench units; use owning theme tokens only where the design requires a new measurement.

- [x] 2.1 Read and revise the affected `NotificationCard`/`NotificationStack` component records in qsm-shell for the new resting body-preview composition, its fixed natural-size/theme-token decision, long-content behavior, five states, keyboard/screen-reader semantics and supported action/no-action states before editing either component.
- [x] 2.2 Update the shared card/stack composition so app identity, summary and a bounded readable sanitized-body preview are visible at rest; longer text remains readable through bounded expansion/scroll without unbounded stack growth or invented metadata.
- [x] 2.3 Add the card's explicit primary action function to `actions`, with one intent signal and host-supplied availability; pointer, accessibility/programmatic activation and Enter/Space in a focus-capable host call that function, and the stack forwards its intent without deciding protocol consequences. Arbitrate body activation against middle-click, swipe dismissal/spring-back, scrolling and controls in the owning component; static message text does not claim selection support.

## 3. Wire explicit default activation

Depends on section 2. Scope: `shell/services/NotificationService.qml`, `NotificationStore.qml`, `NotificationEntry.qml`, `shell/modules/notifications/NotificationPopupStack.qml` and `workbench/NotificationStory.qml`. Existing presentation and input-mask geometry remain unchanged.

- [x] 3.1 Connect the card/stack primary intent to one service action function that resolves the current live source's exact `default` identifier and invokes once; leave explicitly chosen named actions in the center. The host answers the component rather than adding parallel pointer/key handlers.
- [x] 3.2 Propagate current default-action availability and selected-presentation input readiness through the host; retire input immediately and refuse expired, dismissed, sender-closed or replaced stale callbacks.
- [x] 3.3 Ensure upstream resident/nonresident action behavior owns closure, with no duplicate host dismissal; keep archived entries inert and JSON history limited to searchable bounded text.
- [ ] 3.4 Prepare the fully hosted popup as one exact owner-review item, including default/no-default, long-body, keyboard and normal/fullscreen states; report what is prepared and wait for owner judgment before moving to another item. Do not infer acceptance from prior capsule reviews.

The checked implementation items are source-reviewed, not runtime-exercised. Card keyboard input requires a focus-capable host; the production popup retains `EdgeScene`'s passive keyboard policy and the center remains its keyboard route. Native interaction, external-client outcomes and owner acceptance are still pending below.

## 4. Follow up on the archive after popup acceptance

Depends on owner acceptance in 3.4. Scope: `shell/services/NotificationStore.qml`, `NotificationService.qml`, `shell/modules/panel/NotificationCenterTab.qml` and the shared center contract if needed; preserve existing fuzzy search and history limits.

- [ ] 4.1 Route archived-row removal by stable archive identity rather than a missing live notification ID, keep archived actions inert, and prepare the center operation as its own owner-review item.

## 5. Verify only with explicit owner request

These are pending verification gates, not permission to run checks during planning or an automatic next item after implementation.

- [ ] 5.1 If requested, exercise real changing states through a controlled external D-Bus client: post, sticky/default/positive expiry, DND and critical/transient behavior, replacement with a changed action set, exact-once default activation by each route, no-default, named center action, sender close, expiry, dismissal and both swipe outcomes; record protocol close reasons separately from visual evidence.
- [ ] 5.2 If requested, observe a real Discord notification that supplies a default action; distinguish callback invocation from whether Discord opens the requested conversation, and report only the outcome actually observed. Check Wayland activation-token behavior against the installed API; do not fabricate a token or claim app focus from action invocation alone.
- [ ] 5.3 If requested, exercise shell restart and archive restoration without clearing the owner's history, verify that archived text remains searchable and cannot resurrect protocol actions, and record service ownership/recovery separately from owner visual acceptance.
