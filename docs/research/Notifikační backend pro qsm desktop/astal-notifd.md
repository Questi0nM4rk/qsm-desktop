# AstalNotifd as a qsm-desktop notification backend

As-of date requested: 2026-10-08. External-source research only; no installed service, dependency, runtime, or repository application code was touched. Findings below are source inspection, not runtime verification.

## Maturity, release, dependency, packaging

### Takeaway

AstalNotifd is a real Freedesktop Notifications D-Bus server implemented as an embeddable Vala/GObject library plus CLI, with shared per-user GSettings persistence and a proxy mode. It is active upstream but is not a separately versioned/released product: source says 0.1.0/API 0.1, GitHub has no Releases; this is a credible backend candidate, not proof of production reliability or a turnkey independently supervised daemon.

### Cited Findings

- Current upstream `lib/notifd/version` is `0.1.0`; generated API docs also say library 0.1.0 / API 0.1 and license LGPL-2.1. [version](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/version), [API docs](https://docs.astal.dev/notifd/)
- GitHub repository is public, not archived/disabled, describes itself as desktop-shell building blocks; as observed it had 992 stars, 111 forks, pushed 2026-09-23, and 93 open issues overall. Those are repository-level signals, not notifd issue counts or quality metrics. [repo metadata](https://api.github.com/repos/Aylur/astal)
- GitHub Releases page explicitly reports none. The library is therefore sourced from a moving monorepo branch/tag/package, not a standalone stable release channel. [Releases](https://github.com/Aylur/astal/releases)
- Recent notifd history includes list-model addition (May 2026), coercion of malformed hint types (Aug 2026), and a CLI flag parser double-free fix (Sep 2026). A merged fix addressed a real transient-hint persistence bug where wrong-type values caused GLib criticals and incorrect persistence. [history](https://github.com/Aylur/astal/commits/main/lib/notifd), [PR #469](https://github.com/Aylur/astal/pull/469)
- Meson library dependencies: GLib, GObject, GIO, json-glib, GdkPixbuf; build generates VAPI, GIR, typelib and pkg-config metadata. CLI adds Quarrel 0.1 and POSIX Vala bindings. Source uses GSettings schema and compile/install hooks. [meson.build](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/meson.build), [schema](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/gschema.xml)
- Upstream install guide lists Meson, Vala, valadoc, GdkPixbuf, json-glib, gobject-introspection; CLI additionally needs libquarrel, or build can use `-Dcli=false` for library only. Upstream Nix recipe packages `astal-notifd`, Quarrel, json-glib and GdkPixbuf. Availability in qsm's target distro repositories is not established here. [install guide](https://astal.dev/guide/libraries/notifd), [Nix recipe](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/default.nix)
- License is LGPL-2.1; practical obligations depend on distribution/linking model and should be checked for qsm packaging. [API docs](https://docs.astal.dev/notifd/)

### Inferences

- “Mature enough to evaluate” is supported by active maintained source and actual fixes; “production-proven/stable” is not supportable from repo activity, version 0.1, no release artifacts, and no runtime validation.
- The desktop does not need AstalGTK/Astal4 widgets to use notifd. The library's documented dependency is GObject; build links GLib/GObject/GIO/GdkPixbuf/json-glib, not AstalGTK. It is Vala/GObject, not Qt-native, however.

### Gaps

- No release cadence, distro package/version matrix, supported Qt/Quickshell integration, security policy, or formal compatibility guarantees were established.

## Daemon/proxy, restart behavior, persistence and event guarantees

### Takeaway

Astal's first `Notifd` instantiation races to own `org.freedesktop.Notifications`; later Astal instances become proxies. A QML process that instantiates the library can therefore become the daemon accidentally. A separate supervised `astal-notifd daemon` process is necessary if the frontend must restart independently. Persistence is of unresolved non-transient notifications in GSettings, not a notification history; important timer, cache, and event-order edge cases mean the source does not establish a robust full-history/event-log service.

### Cited Findings

- Official guide says first Notifd instance becomes daemon and subsequent instances queue for ownership while proxying. The constructor calls `Bus.own_name` and `acquire_daemon` registers the standard Notifications object. [guide](https://astal.dev/guide/libraries/notifd), [Notifd source](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/notifd.vala)
- `astal-notifd daemon` CLI instantiates Notifd and blocks in a main loop; this is the standalone-process shape. It can emit serialized notifications/events. It is not shown as a systemd service unit or externally supervised auto-start facility. [CLI source](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/cli.vala)
- The daemon registers `/org/freedesktop/Notifications` under `org.freedesktop.Notifications`; handles `Notify`, `GetCapabilities`, `GetServerInformation`, and `CloseNotification`. Proxy uses the session bus, checks server identity name/vendor/version, then connects to `notified`/`resolved` signals. [daemon](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala), [proxy](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/proxy.vala)
- Unresolved notifications are serialized to GSettings `io.astal.notifd` key `notifications` (type `av`), except those with `transient=true`; writes are debounced by 100 ms. The cache includes time, ID, app name/icon, summary/body, hints, timeout, action ID/label. It is not a past-notification archive: resolution removes the item and flushes state. [daemon](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala), [schema](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/gschema.xml), [Notification serialization](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/notification.vala)
- On startup the daemon deserializes that shared settings snapshot and restores unresolved notifications. Proxy independently seeds from the same GSettings snapshot, then listens for changes. Thus QML can reconnect to a separately running daemon and obtain the unresolved cache through shared settings, and future events via D-Bus; the API has no explicit `GetAllNotifications` D-Bus method. [daemon](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala), [proxy](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/proxy.vala)
- `notified(id,replaced)` carries replacement information; `resolved(id,reason)` reasons are expired, dismissed-by-user, closed, undefined. `Notification.invoke(action_id)` is relayed to daemon, then emits D-Bus `ActionInvoked`; nonresident notifications resolve closed after invocation. Notification `dismiss()` produces user-dismissed. [Notifd docs](https://docs.astal.dev/notifd/class.notifd), [ClosedReason docs](https://docs.astal.dev/notifd/enum.closedreason), [source](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala)
- Timeout default is `-1` (no timeout); incoming positive timeout gets a GLib timeout. Setting `ignore-timeout` changes timeout behavior, and `dont-disturb` is a shared boolean for frontends to respect, not suppression in the daemon. Both are GSettings properties. [Notifd docs](https://docs.astal.dev/notifd/class.notifd), [schema](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/gschema.xml), [daemon](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala)
- Image-data is converted to PNG under `$XDG_CACHE_HOME/astal/notifd`; notification hints are changed to image-path. No source inspected here deletes old image files, so lifecycle/cleanup is an unresolved cache-growth concern. [daemon](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala)
- The Freedesktop spec is 1.3 (2024); Astal `GetServerInformation` advertises spec 1.2. Its default capability list includes action-icons/actions/body/body-hyperlinks/body-images/body-markup/icon-static/persistence/sound. [spec](https://specifications.freedesktop.org/notification-spec/latest/), [schema](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/gschema.xml), [daemon](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/daemon.vala)

### Inferences

- Standalone process survival across QML restart is architecturally possible, provided service management keeps CLI process alive and frontend never instantiates a competing Astal Notifd. Its current design does not make that isolation automatic.
- “Snapshot + notified/replaced + resolved + invoke/dismiss” is broadly present, but event delivery is not a durable ordered log. Proxy handles notified by asynchronously calling GetNotification; rapid replace/resolve can race fetch and resolution, and no source-level replay cursor/ack mechanism exists. Treat race-free semantics as unproven.
- Restored notifications are re-added but source does not recreate their expiration timers on restore. Original positive timeout therefore may not be honored after daemon restart. Timeout callbacks also close over mutable `ignore_timeout` local, so toggling it after scheduling may not work as property suggests. This merits a focused source issue/reproduction before relying on timeout fidelity.
- Proxy reads restored list from GSettings, not a server enumeration call. GSettings is the persistence/snapshot channel; D-Bus is the live event/action channel. Correctness depends on local schema/settings backend consistency and writes being flushed.
- Actions are relay to sender, not durable work. If sender process is gone, action invocation has no effect; resident only determines whether notification is closed after action.
- No API for snooze/pause-on-hover, remaining-time accounting, or per-notification timer pause was found. Since backend timers own expiry, custom pause semantics need explicit design; frontend cannot simply pause daemon's timer with current API.

### Gaps

- Did not run notification/restart/race probes by instruction. Whether each suspected race manifests under real GLib/D-Bus scheduling is not verified.
- Need inspect exact target's D-Bus client/reconnect semantics and service manager choice before claiming robust frontend reconnection.

## Qt integration decision, feature fit, issues and work estimate

### Takeaway

Direct QtDBus implementation of the standard protocol is feasible and avoids Python/GObject/AstalGTK entirely, but it would not inherit Astal's private GSettings snapshot/proxy model or persistence behavior. For qsm's Qt6/QML frontend, choose either (A) supervise Astal CLI/library as a distinct daemon and write/maintain an explicit QtDBus bridge for its CLI stream/control or standard protocol, or (B) finish a first-party standalone service/QtDBus backend. The former is less initial implementation only if current Astal package exists and its persistence limits fit; it is not a drop-in Qt QML API.

### Cited Findings

- Freedesktop protocol is D-Bus and specifies standard Notify, GetCapabilities, CloseNotification, GetServerInformation and signals. Qt has QtDBus bindings available within Qt; a client can issue D-Bus calls/signals without any Python, GTK, or GObject dependency (implementation choice; QtDBus API not researched here). [Freedesktop spec](https://specifications.freedesktop.org/notification-spec/latest/)
- Astal library offers GObject API (`GListModel`, signals, GObject properties), VAPI/GIR/typelib, not a Qt/QML API. CLI includes `daemon --events`, `get`, `list`, `dismiss`, `invoke`, `notify`, `dnd`; it is executable IPC/management surface, but docs/source do not describe it as a stable machine API contract. [API](https://docs.astal.dev/notifd/class.notifd), [CLI](https://raw.githubusercontent.com/Aylur/astal/main/lib/notifd/src/cli.vala)
- Frontend-relevant fields: identity ID, app name/icon, summary, body, timestamp, timeout, actions, hints/image, category, desktop-entry, resident, transient, urgency; standard hints include sound and x/y. Notification has received/draft states. [Notification API](https://docs.astal.dev/notifd/class.notification)
- No individual pause timer/expiry mutation contract in public Notifd API. DND is a globally shared setting; frontend decides whether to suppress popups. Default timeout -1. [Notifd API](https://docs.astal.dev/notifd/class.notifd)
- Repository-wide search/query of upstream issues was not a meaningful notifd bug census. Focused source-grounded recent merged defects: hint type coercion/transient persistence (#469), large-notification crashes/lockups and redesign to GSettings/debounced cache in #407, and late Sep CLI double free. Do not infer absence of open backend issues from search results. [#469](https://github.com/Aylur/astal/pull/469), [#407](https://github.com/Aylur/astal/pull/407), [recent history](https://github.com/Aylur/astal/commits/main/lib/notifd)

### Inferences

- **S (few days, conditional):** package/pin AstalNotifd; launch it as a per-user supervised daemon (never instantiate Notifd from QML); implement a small QtDBus adapter/client or parse CLI JSON events and pair with CLI `list/get`/`dismiss`/`invoke`; define reconnection and snapshot strategy. Scope assumes package builds on target, unresolved cache is enough, no pause timers, and CLI JSON is acceptable. This does not remove risk of notification snapshot/live-event races or missing timeout restoration.
- **M (about 1–2 weeks, conditional):** dedicated QtDBus bridge/service client with typed event normalization, snapshot reconciliation, reconnect/replacement/resolve/action/dismiss, DND and timeout policy; supervise Astal process separately; focused integration verification including QML restart and timer/replacement races. Estimates are engineering judgment, not measured.
- **L (several weeks, conditional):** first-party Qt/C++/QtDBus standalone notification daemon implementing protocol, independent service lifecycle, durable unresolved/history model, image-data handling and cleanup, timer restore/pause semantics, action routing/reconnect semantics, migration/policy. More predictable control and native fit, but recreate backend semantics and compatibility testing rather than reusing Astal. Estimate excludes polish/long-tail spec behavior and is not measured.
- Alternative against finishing first-party full implementation: if “full” means durable history, explicit replay and pause-on-hover, Astal does not provide those in its documented API; adopting it still leaves qsm-specific bridge and possibly state-management work. If requirement is only standards-based receipt, popup/center list, actions/dismiss and DND flag, Astal substantially overlaps and may avoid implementing core notification protocol—subject to validating packaging, process supervision and timeout/restart defects.
- A direct QtDBus client to an Astal daemon only gets standard D-Bus protocol. It cannot access Astal-private methods like `get_notification`, internal resolved(reason), GSettings item-list API, CLI-specific invoke path, or its custom notified(replaced) without either using the library proxy or adding IPC. Standard `NotificationClosed` and `ActionInvoked` signals provide standard outcomes, not all Astal-specific state semantics.

### Gaps

- QtDBus current API docs, actual distro package candidates, qsm desktop feature requirement distinctions (durable history vs only active, pause timer requirement), and existing first-party effort baseline were out of scope/unknown; compare exact product contract before choosing.
- No reliable exhaustive current/open notifd-specific issue list or independently verified regression state established. GitHub search returned unrelated/general PR entries and must not be presented as statistics.
