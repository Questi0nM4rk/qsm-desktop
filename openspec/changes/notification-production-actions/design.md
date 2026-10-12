## Context

`NotificationServer` already owns the freedesktop notification protocol; `NotificationService` adapts its live objects into `NotificationStore` records. The store owns replacement, expiry, close and the bounded JSON text archive. The server correctly advertises no protocol persistence. Popup presentation already shares the card/stack path between the normal rollout and the fullscreen capsule; the notification center provides fuzzy searchable history and named actions. Current planning forbids popup actions and treats its resting row as a one-line title, leaving useful message content hidden until hover.

## Goals / Non-Goals

**Goals:** safely expose a provided default action from the popup, surface meaningful provided text immediately, and specify protocol/lifetime boundaries without duplicating upstream behavior.

**Non-Goals:** a persistent notification daemon, live-action resurrection after process loss, a second notification manager, inline reply, app-specific Discord API/deep-linking, fabricated server/channel/author metadata, archived-row actions, new popup named-action buttons, or changing systemd/Dunst ownership.

## Decisions

1. **Keep the existing upstream server and store.** Extend the service/store action seam and existing popup presentation; do not implement D-Bus methods, IDs, action objects, close semantics, or a new backend. JSON remains bounded searchable text history, not protocol persistence. Alternative: a separate daemon/backend would duplicate the installed server and is explicitly rejected.
2. **Default action is the only popup activation.** Body click and explicit accessibility/programmatic activation invoke identifier exactly `default` once, only if the current live source offers it. Enter and Space use that same function when a focus-capable host grants the card keyboard focus. The production popup remains keyboard-passive under the existing `EdgeScene` policy; the existing notification-center shortcut is the desktop keyboard route. Arrival never claims keyboard focus and no new global grab or hotkey is introduced. Do not infer a default from the first named action. Named actions stay in the center; middle-click/swipe dismiss remain distinct. The upstream action's resident/nonresident result governs lifetime; avoid a second host dismissal if invocation already closes it. Replacement re-reads the action set; retiring/expired/dismissed rows cannot call stale callbacks. Alternative: enable every action on the popup or trigger the first action; rejected as surprising/unsafe.
3. **Resting content presents the message, not just its title.** Show app identity with available icon/fallback, summary and a bounded readable body preview without requiring hover. Design a compact preview of up to two readable lines with a bounded full-body expansion/scroll; never grow without bound. Preserve only app-provided app name, summary and sanitized body; do not parse summary to invent Discord metadata. Current 36px one-line acceptance is invalid for this composition; use existing theme/type/spacing tokens and record a new size decision during the component design loop rather than guessing literals. Alternative: hover-only body is rejected because it hides the requested important information.
4. **The shared card reports primary intent; the host owns protocol meaning.** Extend the existing `NotificationCard` action contract with one explicit primary/body-activation intent, enabled only when the host supplies current default-action availability. The card owns one shared pointer/keyboard/programmatic function and reports intent; it does not inspect D-Bus IDs, invoke the service, decide whether a row is live, or dismiss itself. The desktop popup host answers that intent with the current exact `default` source action. Do not render the existing named-action row in popup mode. Alternative: host-specific pointer/key handlers would duplicate interaction logic and leave other card consumers inconsistent.
5. **Keep archived records inert.** Archive retains searchable title/body only and has no live action callback or protocol ID. Center actions on live records continue through the same service seam. Archive deletion, if included in implementation, uses archive identity and never calls protocol dismissal with a missing live ID.
6. **Verify protocol facts before changing the adapter.** Inspect the exact installed Quickshell version/source for action `.invoke()` resident semantics, notification expiry units, replacement/action updates, and activation-token support. Do not claim that invocation opens a Discord conversation merely because an action fired. With a client that supplies a default action, end-to-end success is its handler being invoked exactly once; real Discord opening its requested conversation is a separate compatibility observation, never an app-specific implementation promise.

For installed Quickshell 0.3.1, `Notify` forwards its millisecond timeout unchanged into the QML bindable property; the documentation's seconds label conflicts with that implementation. Keep millisecond passthrough and the existing zero/default sentinels for this version, and re-check before upgrading. Upstream action invocation closes nonresident notifications itself and leaves resident notifications live. Replacement updates the existing source object and its action set. No usable QML activation-token API is present in this version, so invocation does not imply focus or navigation. Sources: upstream `src/services/notifications/server.cpp`, `notification.cpp` and `notification.hpp` at tag `v0.3.1`.

## Risks / Trade-offs

- [The installed API may differ from assumptions about action residency or expiry units] → inspect version-pinned docs/source and capture a real controlled-client round trip before implementation decisions.
- [Pointer click and swipe arbitration can accidentally activate] → route only a completed non-dismiss body gesture; explicitly exercise middle-click and both swipe outcomes when runtime checks are requested.
- [Long bodies can crowd a transient surface] → cap the resting preview, permit bounded expansion/scroll, and keep the stack/capsule clipping and retirement-input rules intact.
- [Wayland may not support a usable activation token in this API/version] → test and report invocation separately from app focus/open success; never claim the latter without evidence.

## Migration Plan

Establish protocol/lifetime facts first, then implement the shared-card composition and primary intent and wire the popup host before preparing that one functioning item for owner review. Do not present a dead action as a review-ready control. Preserve the current server unit, D-Bus ownership, bounded archive, panel named actions, fullscreen single painted capsule, and eligible-row input holes. No systemd/config migration or rollback is needed. The revised composition does not inherit visual acceptance from the previous one. Center/archive removal is a separate follow-up item after popup acceptance.

## Open Questions

- What theme-backed compact row sizing and exact preview treatment does the owner accept in the live window?
- Does the installed Quickshell protocol API expose activation tokens, and can the tested desktop client use one to focus/open its target?

Critique dispositions are recorded in the proposal.
