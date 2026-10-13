Implementation checkboxes mean source-prepared and reviewed, not runtime proof.
Section 7 remains open until the owner requests and performs the named checks.
No automatic tests, validation, captures, native input or hardware operations.

The first prepared item is the stable Performance-panel composition and its
supporting theme/frame, clock and resource handle. Luna high's corrected partial
source review has zero findings, after fixing live UPower leakage from the
preview. That does not complete the whole change or its owner-review gate.

## 1. Plan and contracts

- [x] 1.1 Confirm repository-local OpenSpec root; write proposal, design and capability scenarios before implementation.
- [x] 1.2 Bind this change to the task tool and record the owner's batch authorization and resolved frame/date/notification choices (epic qsd-r87, change qsd-r87.1, owner review qsd-r87.2).
- [x] 1.3 Replace conflicting current decisions in spec/01, 03, 04, 06, 07, 09 and 11; update the affected library notification records before their code changes.

## 2. Shared material and frame foundation

- [x] 2.1 Update both theme palettes and default fallback; derive desktop raised/hover/outline from the shared Style ladder. Source-review color pairs and dependency direction, without claiming rendered contrast.
- [x] 2.2 Reduce only ordinary frame thickness to 12; retain 60px left band and 40px rail. Trace Theme → FrameExclusions → EdgeScene/ShellBorder → rollout origins, bounds and mask regions; preserve shader formulas.
- [x] 2.3 Introduce named panel/resource material and footprint tokens needed by later phases. No decorative global gradient flags, new fonts or wholesale icon replacement.

## 3. Stable upper panel and sampling demand

- [x] 3.1 Give PanelSurface one preferred 854x520 outer footprint clamped to available viewport; keep navigation fixed across all five tabs and changing data states.
- [x] 3.2 Bound static content inside a scroll viewport, preserve native model-tab scrolling, center short/empty content and retain tab/Down focus routes; account for short/narrow screens.
- [x] 3.3 Use source-verified Dashboard/Performance icon alternatives and consistent tokenized spacing without changing tab identities or actions.
- [x] 3.4 Move detailed sampling demand to keyed permanent panel hosts; remove Dashboard/Performance destructor writes to a global polling boolean. Keep independent handle watchers and sampling periods.
- [ ] 3.5 Extend existing panel stories with all real tab compositions, safe deterministic service snapshots, short viewport and missing/long-content states. Do not create or run automated flows.

Partial 3.5: `panel-performance` and `panel-performance-short` load the actual
Performance tab with deterministic resources and battery. Existing panel tab
group and resource story keys remain available. All other tab fixtures remain
unloaded to avoid accidental production service calls from the preview.

## 4. Equal-size clock and purposeful resource handle

- [x] 4.1 Replace ClockEntry's fitted date line with metric-locked DD/MM above HH/mm; retain calendar behavior and immediate reduced-motion digit updates.
- [x] 4.2 Build PanelHandle's fixed 224x36 lighter capsule face, two neutral mirrored level fills, stable labels/values and unavailable/boundary handling from existing service data.
- [x] 4.3 Preserve the handle's one action, five states, moving-rim registry, input rectangle and fullscreen/focus withdrawal; add boundary/missing combinations to the existing story controls.

## 5. Related surface ownership

- [ ] 5.1 Add owner/screen-qualified claimKeyboard, releaseKeyboard and keyboardFor to ShellState; update production and mock callers and retire obsolete claims without touching hardware.
- [ ] 5.2 Scope discovery suppression and modal-triggered rail dismissal to the occupied EdgeScene; pass screen identity through RailPopoutStack/BarPopouts to network prompts.
- [ ] 5.3 Make network prompt retirement clear only its own grab and secret; prevent late failures from reopening retired prompts. Preserve confirm-off and operation outcomes.
- [ ] 5.4 Give LauncherSurface its actual host activation and one retire path; stop read-only probes/timers, qualify seeds and reject obsolete focus/results. Preserve accepted launches/copies.
- [ ] 5.5 Clear the supplied Wi-Fi password before backend handoff even on rejected starts; update the existing isolated surface/API examples, not a parallel behavior model.

## 6. Rounded notification row material

- [ ] 6.1 Add opt-in surfaceColor/surfaceRadius/surfacePadding to the existing library NotificationCard, preserving transparent defaults, meaningful states, bounded preview/expanded content and action policy.
- [ ] 6.2 Forward material and optional rowSpacing through NotificationStack; account for gaps in eviction extents, retained paint, clipping, row geometry and removal. Keep eligible-input retirement exact.
- [ ] 6.3 Bind the desktop popup to quiet raised row surfaces and concentric radii; preserve normal Rollout/fullscreen DataCapsule hosts, center styling and default/named-action boundaries.
- [ ] 6.4 Update notification stories/records for compact rounded rows, empty/long/replaced/retiring records and both presentations. No tests, captures or new notification-bus operations.

## 7. Integration review and owner evidence

- [ ] 7.1 Source-review the combined changes with Luna high, fix confirmed in-scope findings and review the corrections. Distinguish source-confirmed behavior from unexercised routes.
- [ ] 7.2 Commit logical implementation pieces on each repository's main; update backlog/task progress. Do not push, archive or include unrelated user changes.
- [ ] 7.3 Owner checks one prepared Performance-panel item: stable footprint, tab navigation, real changing data and overflow. No claim of acceptance before feedback.
- [ ] 7.4 Owner requests/checks frame and clock, resource handle, both monitors/themes and normal/fullscreen/focus presentations, then revises the same named item as needed.
- [ ] 7.5 Owner requests/checks notification replacement/retirement/gestures/default action and keyboard-grab/editor/sampling ownership during monitor migration; real hardware and accessibility remain separately scoped.
