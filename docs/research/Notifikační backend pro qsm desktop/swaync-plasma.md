# SwayNC and Plasma backend suitability

## Is SwayNotificationCenter a complete headless backend for a custom QML frontend?

### Takeaway
No. SwayNC is a maintained, production-distributed notification daemon, but its public API is a control/summary API rather than a notification-model API. Its daemon also owns GTK popup and control-center surfaces; current evidence does not show an official headless mode. It is useful as an alternative complete notification UI, not as a drop-in backend for qsm-desktop's UI.

### Cited Findings
- Latest GitHub stable release visible as of 2026-10-08 is v0.12.6, released 2026-03-23. It fixes an input-stealing issue; project has release builds and distro packaging/build workflows. This supports active maintenance/distribution, not an independently audited production guarantee. [Release](https://api.github.com/repos/ErikReider/SwayNotificationCenter/releases/latest); [CI workflows](https://github.com/ErikReider/SwayNotificationCenter/tree/v0.12.6/.github/workflows)
- Project describes itself as a GTK GUI notification daemon for notifications and control center, with history, DND/inhibition, actions, markup/image support, inline replies and GTK CSS customization. It targets compositors supporting `wlr_layer_shell_unstable_v1`, not a compositor-neutral backend contract. [README/wiki](https://github.com/ErikReider/SwayNotificationCenter/wiki)
- Actual daemon source implements the FreeDesktop `org.freedesktop.Notifications` server; this is the inbound client-notification protocol, not an API for a frontend client to enumerate/render daemon-owned notification objects. [notiDaemon.vala](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/src/notiDaemon/notiDaemon.vala); [notification model](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/src/notiModel/notiModel.vala)
- SwayNC's own control interface exposes state/commands (including count, DND, visibility and closing), and CLI offers event subscription; a 2025 request specifically asks for a method/signal to retrieve all notifications because only count/DND/control-center/inhibited status were exposed. Thus no full snapshot + incremental changed-object feed + action metadata path is evidenced. [Feature request #660](https://github.com/ErikReider/SwayNotificationCenter/issues/660); [client source](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/src/client.vala); [Context7 interface summary](https://github.com/ErikReider/SwayNotificationCenter/wiki)
- The upstream model persists notification history/configuration, but that is not proof of restart-resumable live objects with actionable identity and remaining timeout. Standard Notifications protocol IDs are server-process identifiers; persistent history should be treated as archival, not as a live action RPC after restart. [notification model](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/src/notiModel/notiModel.vala); [freedesktop spec](https://specifications.freedesktop.org/notification/latest/)
- The daemon owns distinct notification-window and control-center GTK implementations in its source tree; build declares GTK dependencies and Wayland protocol support. No documented `--headless`, popup suppression-with-retained-server, or no-control-center mode found. Hiding/opacity/config hacks would still leave its daemon owning policy and could alter timers/hover behavior. [meson](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/meson.build); [notification window](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/src/notificationWindow/notificationWindow.vala); [control center](https://github.com/ErikReider/SwayNotificationCenter/blob/v0.12.6/src/controlCenter/controlCenter.vala)
- A reported issue documents inline reply text not being sent to the notification sender (only ActionInvoked action key), version 0.11.0; it is a version-specific user report, not proof current 0.12.6 remains broken. [Issue #551](https://github.com/ErikReider/SwayNotificationCenter/issues/551)

### Inferences
- Estimated integration size: **SwayNC as full UI: S** (standard desktop daemon setup); **SwayNC behind qsm custom UI: L / effectively blocked without upstream API or fork**. A custom bridge cannot reconstruct complete live state/actions from count-only status/events. A fork to add model snapshot, replacement/removal events, exact action invocation, headless mode and timer/hover ownership becomes ongoing service maintenance, erasing much of the third-party-cost advantage.
- qsm-desktop should own compatibility policy and the custom presentation if product needs portable Qt/QML semantics; SwayNC can remain an opt-in alternative UI, not be launched beside qsm's notification surface.
- No official headless mode was found in examined docs/source; absence in those sources is not proof that no undocumented switch exists.

### Gaps
- Did not build or run SwayNC; no claim about observed runtime behavior. Not asked to probe/install.
- Did not establish whether each current release's inline reply behavior changed since issue #551.

## Is KDE/Plasma a reusable production notification backend without Plasma session/UI?

### Takeaway
Plasma's notification implementation is mature and Qt-based, but the reusable-looking `libnotificationmanager` is a Plasma Workspace library/model, not a separately documented, standalone headless notification server. A qsm integration must not confuse its `KNotifications` client library with a server. Reuse may be possible with substantial KDE runtime/library coupling, but evidence is insufficient to call it a supported no-plasmashell backend.

### Cited Findings
- Plasma Workspace README identifies `libnotificationmanager` as responsible for listing, closing and interacting with notifications and exposes Qt models for notifications/jobs. This confirms useful model-side functionality, not that it owns/registers the freedesktop server independently of plasmashell. [Plasma Workspace README](https://github.com/KDE/plasma-workspace/blob/master/README.md)
- Plasma source includes notification server/API integration and startup coordination; `waitforname` queues messages until plasmashell starts and a notification server is running. This is evidence of shell lifecycle coupling and a possible startup dependency. [startkde README](https://github.com/KDE/plasma-workspace/blob/master/startkde/README.md)
- `KNotifications` is a KDE Frameworks library for applications to SEND notifications; it is a client, not a daemon/model server. [KNotifications docs](https://api.kde.org/frameworks/knotifications/html/index.html)
- Context7 documentation lookup for Plasma source reports `libnotificationmanager` model responsibilities and source references; this is discovery aid only, corroborated by upstream README/source. [Context7 Plasma docs](https://github.com/KDE/plasma-workspace)

### Inferences
- Estimated effort: **reuse Plasma implementation inside Plasma session: M**, because qsm still needs an adapter and should avoid duplicate server ownership; **reuse in standalone Quickshell session: L/uncertain**, owing to KLibrary/Qt/KF dependencies, service ownership/startup, and no documented supported standalone deployment contract. Do not ship both Plasma and qsm as competing notification servers.
- A purpose-built qsm Qt service has higher initial cost than configuring a daemon, but uniquely delivers custom QML rendering, explicit host-owned timer/hover semantics, persistence guarantees and non-Plasma portability. A carefully bounded adapter over a genuinely complete external model could reduce it, but neither candidate is established here.

### Gaps
- Did not audit all KDE source/build targets for whether `NotificationManager::Server` can be instantiated and registered outside plasmashell; this is the key follow-up before ruling out a narrowly reused KDE backend.
- No other Linux headless daemon was researched; intentionally kept scope on SwayNC and KDE/Plasma.
