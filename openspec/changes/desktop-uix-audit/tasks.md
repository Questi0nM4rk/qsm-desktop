## 0. How to pick this change up

Blocked by the library work in `../qsm-shell`: the owner ordered the library audit and repairs
first, and the desktop follows the owner-accepted library (`qss-9zk` there, plan
`openspec/changes/uix-component-audit/`). Read `../qsm-shell/docs/UIX-AUDIT.md` first: it states
the method, the owner decisions and the evidence rules. The desktop's own `spec/` files remain
the authority on how the desktop looks and behaves.

Do not start repairs in this change. It produces records and findings; the owner chooses the
first surface to repair afterwards.

Runtime evidence uses the installed Workbench, never a sibling checkout script:

```bash
qsm-workbench session start --provider "$PWD" --story <story-key> --headless \
  --session-file /tmp/opencode/<name>.json --log /tmp/opencode/<name>.log
qsm-workbench session request --pid <pid> --provider qsm-desktop --json \
  '{"version":1,"op":"capture","scope":"preview","output":"/tmp/opencode/<name>.png"}'
qsm-workbench session request --pid <pid> --provider qsm-desktop --json \
  '{"version":1,"op":"inspect"}'
qsm-workbench session stop --session-file /tmp/opencode/<name>.json
```

`scope: "window"` captures the whole Workbench window content. Capture keeps the current state,
so a closed rollout, a disabled control and a held press are all photographable.

Measured limit: the off-screen pipeline does not rasterise `SvgIcon` glyphs, so glyph-bearing
surfaces photograph empty. That is the library's known limit, not a desktop defect. Visual
evidence for glyphs needs a real window on workspace 10, opened with the owner's go.

## 1. Coverage of the desktop's surfaces

- [ ] 1.1 Enumerate the desktop's surfaces and give each one a coverage row: frame and rail, top
  panel and its tabs, notification popup and notification centre, OSD channels and their handle,
  launcher, session column, and every popout and hover surface. Name the spec section each row
  audits, the states it has, and the channels available.
- [ ] 1.2 Define the desktop's shared record shape and the pointer-math method, following
  `../qsm-shell/docs/UIX-AUDIT.md`, and state the desktop's own additions: role ownership,
  compositor masks, monitors and the reserved space.

## 2. Source review and intended behaviour

- [ ] 2.1 Frame and rail: geometry, the band, the reserved space, the entries, the workspace
  slots, the readouts, the popouts and the pin or collapse behaviour.
- [ ] 2.2 Top panel and its tabs: the tab group, the panels behind it, the scroll ownership and
  the overflow behaviour, the clock bump handle and the calendar split.
- [ ] 2.3 Notifications: the popup rollout, the centre, read against unread, the card body, the
  actions, the expand route, the scroll ownership and the dismissal.
- [ ] 2.4 OSD: the channels, the handle, the drag, the value while live, the mute route and the
  persistence of the live state.
- [ ] 2.5 Launcher and session: the query, the modes, the ranked list, the power column and the
  confirmation routes.
- [ ] 2.6 Every popout, hover surface and overlay: the trigger, the zone, the corridor, the
  dismissal, the focus path and the interruption cost.

## 3. Runtime evidence without production changes

- [ ] 3.1 Capture the supported states of each surface through owned installed-tool sessions.
  Preserve before and after state, the route identity and the story that produced the evidence.
- [ ] 3.2 Exercise the real input routes, the meaningful boundary, offset and overshoot paths,
  the bad paths, the interruption and the supported size and content states. Capture the pointer
  and focus states where the route supports them.
- [ ] 3.3 Add the measured visual, UX, motion and accessibility findings to each record, with the
  hitbox calculations, the geometry and scale sources, the palette and on-pair evidence, and the
  model assumptions labelled. Keep hypotheses and redesign proposals apart from observed defects.
- [ ] 3.4 Open a real window on workspace 10 only with the owner's go, and record what only a
  window can show: glyphs, the compositor's own surface, cross-window focus and the pointer's
  real landing.

## 4. Deliver the audit before repairs

- [ ] 4.1 Reconcile every coverage row with its record, link the open findings from
  `docs/BACKLOG.md`, and deliver the complete audit and its runtime gaps to the owner. Do not
  start repairs.
- [ ] 4.2 Let the owner choose the first surface and the repair order. Create one scoped change
  per selected surface, each with its own spec, its own task and its own owner acceptance. Keep
  the library's acceptance as the precondition for the desktop's own repairs.
