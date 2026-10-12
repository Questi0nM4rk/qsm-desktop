## Why

Notifications should surface the useful message immediately and let a person act on it where it arrives. Keep Quickshell's existing notification server and bounded searchable JSON history; neither a new daemon nor protocol-level persistence solves the missing interaction.

## What Changes

- Make the popup's primary body action invoke only the client's exact `default` action, once, through the existing protocol-backed action route; keep named actions in the notification center.
- Put useful app-provided context and a readable body preview in the resting popup, with bounded expansion for longer text.
- Specify action lifetime, replacement, retirement, dismissal and gesture arbitration against the upstream protocol's actual semantics.
- Correct the existing notification planning contract and backlog to reflect the settled architecture and distinguish source preparation from external-client verification.

## Capabilities

### New Capabilities
- `notification-production-actions`: Production popup content and safe invocation of client-provided default actions.

### Modified Capabilities

## Impact

Planning targets `spec/04-notifications.md`, `docs/BACKLOG.md`, `NotificationService.qml`, `NotificationStore.qml`, `NotificationEntry.qml`, the popup wrapper and shared `NotificationCard`/`NotificationStack`. The implementation extends these existing paths; this planning step changes no application code or runtime configuration. No new daemon, systemd/Dunst migration or Discord-specific integration is proposed. Exact Quickshell action and expiry semantics, including expiry units and any Wayland activation-token support, require version-specific source verification before implementation claims.

## Critiques

- **Devil's advocate:** an invoked callback does not prove that an app opened; cached actions and competing swipe/click gestures can invoke the wrong action. Addressed by current-source lookup, explicit gesture arbitration, and separate callback/application outcome evidence.
- **Future archaeologist:** prior capsule acceptance and IPC checks do not establish this new composition or external action behavior. Addressed by preserving prior evidence separately and requiring owner review after the component and its host are both wired.
- **Scope sniper:** this could become a new daemon, Discord API integration or action resurrection framework. Rejected: reuse Quickshell, display only supplied content, and keep the JSON archive inert. Archive deletion is a separate center item after popup review.
