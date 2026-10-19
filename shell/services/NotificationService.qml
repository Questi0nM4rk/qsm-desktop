pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Notifications
import qs.state

// Production adapter for the shared desktop-owned store. This singleton owns
// protocol objects and persistence; NotificationStore owns policy and lifetime.
QtObject {
    id: root

    readonly property int popupLimit: store.popupLimit
    readonly property int defaultTimeoutMs: store.defaultTimeoutMs
    readonly property int bodyByteLimit: store.bodyByteLimit
    readonly property int archiveRecordLimit: store.archiveRecordLimit
    readonly property int archiveByteLimit: store.archiveByteLimit
    property alias live: store.live
    property alias nextId: store.nextId
    readonly property var popups: store.popups
    readonly property var archive: store.archive
    readonly property int unreadCount: store.unreadCount
    readonly property var urgencyNames: store.urgencyNames
    property var sources: ({})
    property var sourceLinks: ({})

    signal notifyRejected(string field, string message)

    property NotificationStore store: NotificationStore {
        id: store
        dnd: ShellState.dnd
        closeSource: (notificationId, reason) => root.closeProtocolSource(notificationId, reason)
        invokeSourceAction: (notificationId, actionId) => root.invokeProtocolAction(notificationId, actionId)
    }

    property NotificationServer server: NotificationServer {
        keepOnReload: false
        // The text archive cannot preserve live protocol notifications, IDs, or actions.
        persistenceSupported: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: false
        bodyHyperlinksSupported: false
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: false
        inlineReplySupported: false
        onNotification: notification => root.admit(notification)
    }

    property Component protocolLinks: Component {
        Connections {
            id: link
            required property int notificationId
            required property var notification
            target: link.notification
            ignoreUnknownSignals: true
            function onClosed(): void {
                if (root.sources[link.notificationId] === link.notification)
                    root.closeFromProtocol(link.notificationId);
            }
            function onSummaryChanged(): void { root.sync(link.notificationId); }
            function onBodyChanged(): void { root.sync(link.notificationId); }
            function onUrgencyChanged(): void { root.sync(link.notificationId); }
            function onActionsChanged(): void { root.sync(link.notificationId); }
            function onImageChanged(): void { root.sync(link.notificationId); }
            function onAppIconChanged(): void { root.sync(link.notificationId); }
            function onExpireTimeoutChanged(): void { root.sync(link.notificationId); }
        }
    }

    function resolveImage(notification: var): string {
        if (notification.image)
            return notification.image;
        const named = notification.appIcon || notification.desktopEntry;
        if (!named)
            return "";
        if (named.startsWith("/") || named.startsWith("file:"))
            return named;
        return Quickshell.iconPath(named, true);
    }

    function copyObject(value: var): var {
        const copy = ({});
        for (const key of Object.keys(value ?? {}))
            copy[key] = value[key];
        return copy;
    }

    function resolveBusExpiry(notification: var): int {
        const ms = notification.expireTimeout;
        // D-Bus 0 means never expire; -1 selects the urgency default.
        if (ms === 0)
            return 0;
        const urgency = urgencyNames[notification.urgency] ?? "normal";
        return store.resolveExpiry(urgency, ms > 0 ? Math.round(ms) : 0);
    }

    function recordFromProtocol(notification: var): var {
        const urgency = urgencyNames[notification.urgency] ?? "normal";
        return {
            appName: notification.appName || "Notification",
            summary: String(notification.summary ?? "").slice(0, 1024),
            body: store.sanitize(notification.body),
            urgency: urgency,
            isTransient: notification.transient === true,
            imagePath: resolveImage(notification),
            actions: (notification.actions ?? []).map(action => ({
                id: action.identifier,
                label: action.text
            })),
            expiryMs: resolveBusExpiry(notification)
        };
    }

    function admit(notification: var): void {
        notification.tracked = true;
        const notificationId = store.addSource(recordFromProtocol(notification));
        const nextSources = copyObject(sources);
        nextSources[notificationId] = notification;
        sources = nextSources;
        const link = protocolLinks.createObject(root, { notificationId, notification });
        const nextLinks = copyObject(sourceLinks);
        nextLinks[notificationId] = link;
        sourceLinks = nextLinks;
    }

    function sync(notificationId: int): void {
        const notification = sources[notificationId];
        if (!notification)
            return;
        store.syncSource(notificationId, recordFromProtocol(notification));
    }

    function closeFromProtocol(notificationId: int): void {
        detachProtocol(notificationId);
        store.close(notificationId, "closed");
    }

    function detachProtocol(notificationId: int): var {
        const source = sources[notificationId] ?? null;
        const link = sourceLinks[notificationId] ?? null;
        const nextSources = copyObject(sources);
        const nextLinks = copyObject(sourceLinks);
        delete nextSources[notificationId];
        delete nextLinks[notificationId];
        sources = nextSources;
        sourceLinks = nextLinks;
        if (link)
            link.destroy();
        return source;
    }

    function closeProtocolSource(notificationId: int, reason: string): void {
        const source = detachProtocol(notificationId);
        if (!source)
            return;
        if (reason === "expired")
            source.expire();
        else
            source.dismiss();
    }

    function invokeProtocolAction(notificationId: int, actionId: string): bool {
        const entry = store.live.find(candidate => candidate.notificationId === notificationId);
        const currentRecordAction = entry?.actions?.find(
            candidate => String(candidate.id) === actionId && !(candidate.disabled ?? false));
        const source = sources[notificationId] ?? null;
        if (!entry || !currentRecordAction || !source)
            return false;
        const action = source.actions?.find(candidate => candidate.identifier === actionId) ?? null;
        if (!action)
            return false;
        action.invoke();
        return true;
    }

    function sanitize(raw: var): string { return store.sanitize(raw); }
    function resolveExpiry(urgency: string, timeoutMs: int): int {
        return store.resolveExpiry(urgency, timeoutMs);
    }
    function notify(summary: var, options: var): int { return store.notify(summary, options); }
    function post(appName: string, summary: string, body: string, urgency: string,
            timeoutMs: int, replaceId: int, isTransient: bool): int {
        return store.post(appName, summary, body, urgency, timeoutMs, replaceId, isTransient);
    }
    function dismiss(notificationId: int): bool { return store.dismiss(notificationId); }
    function invokeDefault(notificationId: int): bool { return store.invokeDefault(notificationId); }
    function invokeAction(notificationId: int, actionId: string): bool { return store.invokeAction(notificationId, actionId); }
    function dismissAll(): bool { return store.dismissAll(); }
    function setPaused(notificationId: int, paused: bool): void {
        store.setPaused(notificationId, paused);
    }
    function clearArchive(): void { store.clearArchive(); }
    function removeArchived(record: var): bool { return store.removeArchived(record); }
    function markRead(record: var): bool { return store.markRead(record); }
    function markAllRead(): bool { return store.markAllRead(); }
    function isValidRecord(record: var): bool { return store.isValidRecord(record); }

    property Connections storeConnections: Connections {
        target: store
        function onNotifyRejected(field: string, message: string): void {
            root.notifyRejected(field, message);
        }
        function onHistoryChanged(): void {
            if (JSON.stringify(ShellState.notificationHistory ?? []) !== JSON.stringify(store.history))
                ShellState.notificationHistory = store.history;
        }
    }

    property Connections persistenceConnections: Connections {
        target: ShellState
        function onNotificationHistoryChanged(): void {
            if (JSON.stringify(store.history) !== JSON.stringify(ShellState.notificationHistory ?? []))
                store.history = ShellState.notificationHistory ?? [];
        }
    }

    Component.onCompleted: store.history = ShellState.notificationHistory ?? []
}
