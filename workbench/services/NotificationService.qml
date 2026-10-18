pragma Singleton
import QtQuick

QtObject {
    id: root
    readonly property var live: store.live
    readonly property var archive: store.archive
    property NotificationStore store: NotificationStore {}
    function dismiss(id: int): bool { return store.dismiss(id); }
    function invokeAction(id: int, actionId: string): bool { return store.invokeAction(id, actionId); }
    function removeArchived(record: var): bool { return store.removeArchived(record); }
    function markRead(record: var): bool { return store.markRead(record); }
    function clearArchive(): void { store.clearArchive(); }
    function setPaused(id: int, paused: bool): void { store.setPaused(id, paused); }
}
