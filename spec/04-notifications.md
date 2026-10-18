# 04 — Notifications

References: `references/notification-anatomy-dark.png` (content anatomy: icon, app name, time,
title, wrapped body, action buttons — anatomy only, NOT the card styling), owner design below.

The revised resting preview and popup default-action contract below are implemented
in source under `openspec/changes/notification-production-actions/`. Owner visual
acceptance and fresh external-action checks remain pending; prior capsule/runtime
evidence applies to the previous composition.

The revised sources are loaded in the running production service. Startup IPC
readiness and notification bus ownership agree, with existing archive and DND
state retained. This deployment check did not post a notification or exercise
its default action; native interaction and the client's navigation outcome still
require review.

## Popup rollout

- Anchored top-right: flush under the top band, with the right content edge 16px from the
  screen border (8px rollout wall inset + 8px inner padding). Cards are 380px wide so short
  notifications sit close to the right edge and expanded body text wraps below. Large-surface
  reveal tier (500ms). Over a fullscreen client there is no band to flush into, so the popup
  is the real shell `DataCapsule` inset 8px from the same corner instead (see Presentation
  boundary below).
- Popup entries are `surface` cards of radius 12 on the rollout's `band`, separated by a
  token gap rather than a border or separator. The source icon, source/time and useful
  message remain legible within the padded body. This
  is opt-in library presentation, not notification protocol or lifetime policy.
  Other consumers may retain the transparent card default.
  Padding and gaps contribute to the actual retained/evicting geometry; removing
  a row must not introduce an extra extent jump or leave an input hole behind.
- **RATIFIED (2026-08-16)**: each entry carries an appropriate SVG icon (app/type).
- **RATIFIED (2026-10-16, owner)**: urgency has no tick bar; the app glyph carries it by
  colour: critical `danger`, normal `info`, low `textMuted`. Action buttons are quiet, drawn
  on `overlay`; the card's one primary action alone uses `primary` with `textOnPrimary` text.
- **RATIFIED (2026-08-16, clarified 2026-08-27)**: hover expands content and pauses expiry,
  but useful message content is visible at rest: app identity, summary and a bounded readable
  preview of the provided body. Longer content is readable by bounded expansion or scrolling.
  An explicit popup body click invokes only the current live action whose identifier is
  exactly `default`, through one shared action route. Accessibility/programmatic activation
  and Enter/Space in a focus-capable card host share that function. Production popups remain
  keyboard-passive: use the existing notification-center shortcut for keyboard actions.
  Never steal focus on arrival or guess from a named action. Named actions remain explicit
  choices in the notification-centre panel.
- **RATIFIED (2026-08-16)**: stack cap **5** visible. Overflow choreography: OLDER entries
  slide UP and back INTO the top band as NEWER ones slide out of the rollout's bottom — the
  rollout is a window onto the stream; entries enter from the bottom edge, exit through the
  top edge into the band.
- **DEFAULT (2026-08-16)** overflow choreography numbers: exiting entries slide up 250ms
  (main curve, no overshoot) and are CLIPPED by the silhouette — absorbed into the band, no
  alpha fade; entering entries slide in from below with the same values.
- **DEFAULT** resting content = app identity/icon + summary + body preview (up to two
  readable lines) + relative timestamp. Longer body remains readable through bounded expansion or scrolling;
  never grow the stack without bound. The new composition supersedes the former one-line 36px
  collapsed-row acceptance; dimensions come from the theme/component design decision. Body
  renders sanitized rich text (b/i/u/br only); inline body images are not rendered.
- **DEFAULT (2026-08-16)**: icon fallback when the app sends none = urgency-type glyph.
- **RATIFIED (2026-08-16)**: middle-click closes an entry.

### Display lifetime boundary

The popup's required lifetime correction is implemented in
[`NotificationStack`'s component record](../../qsm-shell/docs/components/NotificationStack.md#lifetime-correction);
desktop publication and wrapper bind to that contract. The service remains
the sole source/expiry owner and may destroy a closed entry immediately. Publish
plain reactive popup records, including same-ID replacements; render keyed owned
snapshots, never those source objects. Last-body paint and dimensions survive
until the selected presentation reports itself gone, without an extra timer.
Retiring rows withdraw input immediately. Fullscreen input holes consume the
stack's clipped eligible row geometry rather than treating every still-live
notification as a target, and they are registered with `paint: false`: the
capsule paints the one fullscreen body, so a row's hole is an input area only
and never a second painted body. A hole is withdrawn the moment its row stops
being eligible, while the capsule keeps painting the retained or evicting
column; no padding or retiring row is captured.
The owner accepted the appearance of the previously reviewed capsule composition;
that acceptance does not cover the revised resting body preview/actions or service
integration. A production compositor-fullscreen run exercised the
shared store through the existing IPC `notify` path (not D-Bus): collapsed rows
were 380x36 inside a 396x52 capsule; expanded rows were 380x74 inside 396x90,
with 8px inset. Hover expansion, same-ID replacement, middle-dismiss, hover
expiry pause/resume, fullscreen keyboard and outside-click delivery with popup
containment passed. The native content/fade capture averaged about 25 fps,
appropriate for this simple motion; it is not native 60 fps.

### Presentation boundary

Normal mode is the attached top-band `Rollout`; fullscreen has no frame to grow
from, so it is a real shell `DataCapsule` that paints ONE enclosing body — the
same shape the OSD uses, never the popup stack's detached-Rollout shader path.
One `NotificationStack` object is created once and reparented between the
Rollout's slot and the capsule's `contentItem`, so rows keep their identity,
hover, expansion and gesture state across a mode switch. Both bodies inset the
column by the same explicit theme padding on all sides, and the stack is sized
to its own implicit extent and centred, so no row reaches outside the painted
body. The attached Rollout stays suppressed in fullscreen — no detached travel
for notifications. The capsule shows only while a popup is active on a
fullscreen screen, with `timeout: 0` and no action: the notification service
remains the only lifetime and dismissal owner. Input follows real readiness —
the Rollout's near-settled active aperture normally, `acceptsInput` on the
capsule in fullscreen. Fullscreen input comes from those eligible per-row
holes, which the scene mask consumes alongside its rollout rects; the capsule's
own body is never a mask region, so its fade retains nothing.

The isolated Workbench story hosts the production wrapper and shared store.
Its native Wayland flows also pass: fullscreen retarget/reset (28), native
dismissal (25), API replacement (30), initial expiry (8), hover expiry (15),
overflow retract (27) and native swipe (25). These functional results are
separate from the scoped owner visual acceptance above.

The earlier manual review task was to post file-transfer feedback, replace that same
notification on completion, then dismiss it or inspect overflow. The story's
first Controls group is `presentation`: `show-transfer`, `complete-transfer`,
`show-overflow`, `dismiss-newest`, `dismiss-all`, and `reset` call the existing
action API. Newest dismissal resolves the current live popup on every call;
bulk dismissal removes all live entries, including overflow, through one store
update while preserving archive and protocol close semantics. Urgency and timeout
are radio choices for the next publication; DND and reduced motion are independent
checkboxes reflecting provider-owned state. Commands have no checked state.
Every presentation option and action reports whether it can run right now, and
the Workbench disables the ones that cannot: completing or dismissing the transfer
needs it still live, bulk dismissal needs a live entry, newest dismissal needs a
popup or a live fallback, and arriving during retraction needs the selected
presentation actually closing. The predicate is the provider's alone — `triggerAction` refuses the same
set, so a disabled control cannot be a command the story would decline.
The scene stays empty at startup and after reset, with a visible
instruction to use `presentation → show-transfer`; DND suppression and reset
in progress are labelled rather than looking like a dead preview. Native
Workbench controls retain their pointer/keyboard/accessibility behaviour and
existing wrapping/scrolling layout; no new styling or tokens are introduced.
The popup/store lifetime and input paths have prior runtime evidence through
Workbench and production flows, but that does not establish external-client D-Bus
action behavior. Production ownership is already the existing Quickshell
`NotificationServer`; D-Bus activation maps to the existing `Type=exec` user unit
and qsm-run supervisor, with startup readiness tied to the bus-name owner PID.
This source-prepared ownership is not a claim that a fresh external client
round-trip, exact-once default action, action close reason, or app activation has
been verified. Those remain explicit owner-requested runtime checks.

The server advertises `body`, `body-markup`, `icon-static`, and `actions` through
`GetCapabilities`; it does not advertise `persistence`. The bounded text history
remains available, but it is not protocol persistence: it cannot retain live
notification IDs or actions until acknowledgement, user removal, or sender recall.

The installed Quickshell 0.3.1 implementation passes protocol millisecond timeouts
unchanged to `Notification.expireTimeout`, despite its documentation labelling
them seconds. Keep the existing millisecond adapter for this version; verify
the actual implementation before changing units on an upgrade. Nonresident
action invocation closes the source upstream; resident invocation does not.
Neither is a promise of application focus or navigation.

## Triggering desktop notifications

Any desktop event handler can publish a notification with one call, without
constructing an entry, card, timer or surface:

```js
NotificationService.notify("Internet odpojen", { urgency: "critical" });
```

The minimal call is `notify(summary)`; the optional second argument is a named
options object, not seven positional arguments. Extend the existing service,
not a second notification manager. Both this entry point and the bus feed the
same lifetime, archive, replacement and popup-record pipeline described above.

- Required: a string summary. Defaults: app name `qsm-desktop`, empty body,
  `urgency: "normal"`, normal expiry, non-transient, a new notification ID.
- `urgency` selects `low`, `normal` or `critical` consistently with external
  notifications; no parallel `importance` vocabulary. Urgency also follows the
  existing DND policy, so critical must be chosen deliberately, not for every event.
- Optional fields: `appName`, `body`, `imagePath`, `timeoutMs`, `isTransient` and
  `replaceId`. Omitted timeout uses urgency defaults; explicit `timeoutMs: 0`
  means sticky, positive milliseconds override the default even for critical
  urgency. Importance and
  lifetime are separate choices. Invalid option values are rejected with the
  offending field identified, not silently converted into a successful post.
- Return the notification ID. Pass it back as `replaceId` to update the same card;
  `dismiss(id)` remains the explicit close route. Sanitize body once in the
  service, publish a coherent value record, and leave all visual routing automatic.
- `NotificationService.notify(summary, options)` uses the same `NotificationStore`
  as the bus-backed production service; the isolated story instantiates that
  store without the bus or production history.
- The event producer owns when to notify. A stateful condition fires on the
  confirmed transition, not every refresh or initial unknown/offline reading.
  No event registry, subscription DSL, caller-managed timers or generic rule engine
  is required to make an ordinary handler one or two lines.

The network example is a target usage, not an existing network event API.
`NetworkService` currently publishes Wi-Fi/Ethernet link state and polls it;
it does not establish Internet reachability. A real Internet-loss event needs
an initialized, coherent connectivity state and a confirmed online-to-offline
transition before wiring this call. Link loss must not be labelled Internet loss.

## Notification center

- **RATIFIED (2026-10-17, owner; replaces the top-panel tab of 2026-08-16)**: everything
  about notifications lives TOP RIGHT. A BELL BULGE sits in the corner where the top band
  meets the right frame: 40x32, `band` fill, a 16px bell glyph (`text` with unread, else
  `textMuted`) and the UNREAD count as an `accent` badge. With everything read (owner
  2026-10-18: "notifications, when they are all read, should be on top of the border, and moved
  into the right corner diagonally not just vertically") the bulge RETRACTS and the bell glyph
  travels DIAGONALLY, up and to the right, into the top-right corner of the frame and sits on
  the band there (centre one frame thickness from each edge: the corner's inner radius is 28,
  so the band's corner fill has room for the 16px glyph on the diagonal). The glyph rides the
  bulge's own reveal (`Rollout.revealProgress`), so both move as one on the `revealSmall` tier
  and shorten under reduced motion with it. Unread above 0, the menu open, or the pointer on the
  corner brings the bulge back with the glyph riding into it. The hover zone is generous at
  the corner (the glyph grown by `Style.hoverReach`, 20, clipped to the screen; with the bulge up
  it covers glyph and bulge together), never the 16px glyph. Entering it, in either state, opens
  the NOTIFICATION MENU AT ONCE: a top-right modal rollout
  (`notifications`, 412 wide, up to 520 tall) in the clipboard's shape, search field at the
  top, then two views, **Unread** (with its count) and **All**, then the history grouped by
  app with FUZZY SEARCH across title AND body. The menu opens on Unread while anything is
  unread, else on All (owner 2026-10-18: unread "more separated than just dots, its own menu
  tab"). An unread row also carries a 6px `accent` dot by its app name; a plain click on it
  marks it READ, so it leaves the bell's count and the Unread view and stays in All.
- **RATIFIED (2026-10-18, owner)**: every menu entry is its own body, a `surface` card of the
  large radius with a slight shadow, `space2` apart; no divider and no urgency tick between
  them (a column of ticks read as one joined line). Hover never expands a menu entry, because
  the wheel over the list must scroll the list: the entry's LEADING column (its glyph, which
  turns into a chevron under the pointer) opens and closes it by click, the rest of the entry
  is its action. An open entry shows its whole body; the list scrolls, the entry does not. The menu closes 180ms after the
  pointer has left both the bell zone and the menu, on a click outside, on Escape, or by the
  keyboard shortcut that opened it (09-input). The bell steps back while live popups roll
  out of the same corner, and in fullscreen or focus mode.
- Unread is a fact of the archive: a popup that EXPIRED unseen is unread; one the person
  dismissed, swiped, or whose action ran was seen. `read` is persisted with the record.
- **RATIFIED (2026-08-16)**: layout = search field at TOP, below it the history GROUPED BY
  APP (app headers), entries as bodied cards (above); typing filters live across title+body;
  Enter invokes the default action (else just highlights), Del dismisses. The menu remains
  the route for explicitly choosing named actions; popup body activation is limited to the
  live protocol action whose identifier is exactly `default`.
- **DEFAULT (2026-08-16, widened 2026-08-19)**: DND toggle lives in the notification menu's
  header; while the TOP PANEL (any tab) or the SESSION surface is open, popups are
  suppressed — the panel rolls out of the SAME top band and is wide enough to sit under this
  stack, and two surfaces cannot share one wall; the session surface owns the screen by 08's
  fade-back law. Entries still arrive, expire and land in history; only the popup waits.
- **DEFAULT (2026-08-16)**: fuzzy = subsequence scoring (fzf-style) over title+body; app
  groups ordered by most-recent notification. History bound = 200 entries (09's "bounded").
- The former right-edge history sidebar is REMOVED from the design.
- Search includes the application name. Sorting works on a copy and cannot
  reorder the host's feed; same-count replacements preserve selected identity.
  Live presentation uses plain snapshots, not source objects that the service
  destroys on close. The next snapshot follows replacements and pause state.
- Delete/middle-dismiss on an archived row removes only that record by `archiveId`;
  legacy records remain removable by their timestamp/content tuple. New archive
  records carry stable IDs. Live dismissal still closes the protocol and archives
  normally; Clear remains archive-only. Missing IDs never reach protocol dismissal.

## Numbers (RATIFIED 2026-08-16)

- Rollout width **380px** (LIVE-TUNE).
- Expiry: normal **5s**, low **3s**, critical **sticky**; hover pauses expiry.
- Swipe-dismiss: horizontal, threshold **40%** of entry width, both directions, spring-back
  under threshold; works on critical too.
- DND: suppresses non-critical popups (they still reach history); critical always shows.
- Fullscreen: all popups remain visible and clickable over the fullscreen client (09-input
  fullscreen allowlist). DND still suppresses non-critical popups.
