## 1. External Dialog Bridge

- [ ] 1.1 Audit the current Qt, GTK, and portal changes against the bridge capability spec.
- [x] 1.2 Document deep-night session-static scope at the theme-switch entry and defer mountain-dusk external parity to a follow-up change.
- [ ] 1.3 Verify newly opened Qt portal and GTK authentication dialogs visually use qsm material without restarting Quickshell or unrelated applications.

## 2. Command Centre

- [x] 2.1 Replace the shallow direct-toggle `>action` results with a two-level command-centre model that retains parent query and selection on return.
- [x] 2.2 Add keyboard detail contracts for Keep awake and Night light, including visible state acknowledgement after activation.
- [x] 2.3 Add a Panel category and keyboard tab selection using the same arrow, Enter, Left, and Escape vocabulary without removing direct panel shortcuts.
- [x] 2.4 Add IPC and smoke coverage for command-centre seeding from closed and competing modal states, detail navigation, and ordinary launcher toggle behavior.
- [x] 2.5 Add categories and detail models for every mouse-reachable rail capability, including delegated settings routes, device selection, connectivity, power profiles, and session controls.
- [ ] 2.6 Complete keyboard-adjustable level adoption; output uses the accepted inline Slider segment below, while brightness/microphone adoption remains deferred until its owner review.
- [x] 2.7 Add arm-then-fire keyboard contracts for cache cleanup, connectivity-disrupting actions, device forgetting, and colour picking.
- [x] 2.8 Add IPC and smoke coverage for the expanded control catalogue, level adjustment, delegation, and confirmation paths.

## 3. True Fullscreen Feedback

- [x] 3.1 Add a fullscreen-only SDF rendering path that paints each notification row and the OSD as detached inset capsules with fill and glass edge, without painting the normal frame, rail, or source edge.
- [x] 3.2 Verify overlay stacking and input masks for normal notifications, critical notifications, and OSD while native fullscreen is active.
- [x] 3.3 Verify non-allowlisted surfaces and stale modal catches stay hidden or inert and cannot resurrect after native fullscreen exits.

## 4. QSM Focus Mode Foundation

- [x] 4.1 Add a FocusModeService that owns an address-keyed eligible-client and rail snapshot plus shell-startup recovery.
- [x] 4.2 Implement opaque framed viewport entry, collapsed rail behavior, client placement, and deterministic restoration for one tiled or floating target.
- [x] 4.3 Add target-loss handling for closed, moved, workspace-changed, and monitor-changed clients.
- [x] 4.4 Restrict focus mode to notifications and event-driven OSD, then add IPC and smoke coverage for entry, restore, and target loss.
- [x] 4.5 Bind `Super+F` and `Super+Shift+F` to native workspace-local Hyprland fullscreen; retain the geometry transformation only as an explicit IPC facility.

## 5. Per-Capability Acceptance

- [ ] 5.1 Run bridge and command-centre static validation plus their focused interaction trials.
- [x] 5.2 Run fullscreen-overlay shader, compositor-layer, input-mask, and isolated smoke validation.
- [x] 5.3 Run focus-mode entry, restore, target-loss, native-fullscreen fallback, and isolated smoke validation.

## 6. Accepted menu composition → output audio

- [x] 6.1 Update the existing launcher contract for stable selection, literal search, Colemak-DH motions and inline output audio before source edits.
- [x] 6.2 Let ResultRow preserve its accepted heading without overriding expanded natural size; report revealed expansion height into the existing launcher screen clamp.
- [x] 6.3 Preserve stable result identity through service refresh/re-ranking and focus region through repeated activation; remove timeout-based search-focus restoration.
- [x] 6.4 Add menu `n/e/i/o` and `/` through shared surface functions; preserve modified keys and text input; navigate Up/Down from the editor and return Enter/Escape to its row.
- [x] 6.5 Bind inline output Slider and mute Switch to existing AudioService routes; disable absent output, preserve microphone/device/mixer routes, and keep live readings out of the structural model.
- [x] 6.6 Hand over this one desktop audio item for owner review; no production restart, hardware mutation, tests, validation, captures or automatic input without an explicit request.
- [x] 6.7 Register action-menu-audio in the desktop Workbench using the production launcher, thin native-target/event forwarding and existing isolated service projection; constrain it to audio and disable production ranking persistence.
- [ ] 6.8 Owner accepts desktop audio interactions before Wi-Fi/BLE or further level adoption.

Scope: LauncherSurface.qml, ResultRow.qml, the launcher height expression in
EdgeScene.qml and the additive headingHeight/expansionHeight contract in shared
ListRow.qml. No new services, harness redesign, Wi-Fi/BLE adoption, other levels,
archive or unrelated dirty-work cleanup. Previous smoke evidence does not verify
these sources. Artifact validation is not run under the current no-check request.

Section 6 completion marks source preparation only, not runtime or owner
acceptance. Existing app search retains search focus after arrows; only action
navigation enters menu focus. Modal exit cancels layout/focus timers and deferred
focus refuses to activate a dismissed launcher. Explicit semantic identity on the
existing Wi-Fi radio row keeps the generic selector stable when its next-command
data changes from wifi-on to wifi-off; no connectivity operation was changed.
No tests, lint, artifact validation, captures, desktop input or production restart
ran for this segment. The old shell preview does not contain these desktop edits.

The owner's Workbench request adds ActionMenuStory.qml, the named Adapter/catalog
registration and bounded missing preview-service/state fields. Launcher receives
only allowlists, persistence isolation and intent/target exposure; no preview copy
of menu behavior. External Workbench runtime, production backend and all other
stories remain unchanged. Opening this one preview is not a test/capture sweep.

The installed Workbench reports qsm-desktop / action-menu-audio ready. Its own
window is on workspace 10; startup has no warnings. Session and log are in
`/tmp/opencode/action-menu-audio-preview/`. This establishes loading only: no
automatic key/pointer trials, tests, captures, validation or production restart
ran. The actual launcher reports natural body height to both EdgeScene and the
story's unchanged ModalHost, avoiding a second sizing implementation. Preview
applications and non-audio commands are disabled; ranking persistence never
loads, local audio has no devices, and external delegates return a refusal.

## 7. Owner-authorized overnight batch

The owner defers live judgement until morning and explicitly authorizes sequential
Wi-Fi → BLE → ON/OFF preparation plus targeted isolated input/integration checks.
This overrides the wait-between-items checkpoint for this bounded batch only;
no item is automatically accepted. Work happens in isolated snapshot worktrees,
not these live checkouts. No automatic merge, commits, push, archive, production
restart or real audio/network/Bluetooth mutation. The worker brief and morning
report live under `/tmp/opencode/qsm-menu-night/`.

- [x] 7.1 Prepare Wi-Fi networks/radio, row-attached password entry, pending/result/retry and cancellation using existing capability commands; add an isolated desktop Workbench item.
- [x] 7.2 Prepare Bluetooth/BLE adapter/device and pairing/connect/disconnect feedback using existing capability routes; add isolated deterministic fixture cases.
- [x] 7.3 Complete reachable repeatable ON/OFF cases for the existing Wi-Fi/Bluetooth radios and Keep awake/Night light, keeping audio behavior intact.
- [x] 7.4 Exercise actual isolated QML input through the relevant changing-state flows: stable identity, repeated activation, NEIO/slash, literal password/search, availability, failure/retry and reset cancellation. No full suite, source-shape tests, captures or live-device trials.
- [x] 7.5 Produce a morning report, worker-baseline-relative diff and verification logs; stop on completion or a scope/safety blocker. Source review/integration and owner acceptance remain separate.

## 8. Panel tab group and per-kind dispatch

The owner asked for Tab/Shift+Tab between the tabs of one panel group, and for
per-kind behaviour to live in tables instead of growing an if-chain per kind.
The work landed on `main` directly: the isolated worktree it started in was lost
before it was merged, and an agent's scratch directory is not a delivery.

- [x] 8.1 `Segmented` opt-in `tabNavigation`/`wrapNavigation`; default behaviour unchanged.
- [x] 8.2 `PanelSurface` owns its tabs through the shared control, opens focused on the group, Down enters the content.
- [x] 8.3 `panel-tabs` story hosting the production panel with its tab contents unloaded.
- [x] 8.4 Launcher dispatch tables: `kindActions`, `kindSupport`, `kindSelectable`, `detailBuilders`, `surfaces`, `detailActions`, `networkOperations`, read through one `callHandler`.

## Verification actually run

`bash scripts/check-action-menu` drives five offscreen flows through the installed
Workbench with simulated Qt input: six flows over audio, Wi-Fi, Bluetooth, toggles
and the panel tab group. All pass, including Wi-Fi draft disposal, late failure
after dismissal, VPN without Wi-Fi, rescan progress and Bluetooth forget/retry.
This is isolated integration evidence; live hit testing, real hardware, pairing
agents and speech remain unverified, and no item here is owner-accepted.
