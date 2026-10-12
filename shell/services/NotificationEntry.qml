import QtQuick

// One owned notification. `data` is replaced as a whole so every presentation
// observer sees one coherent version of a replacement.
QtObject {
    id: root

    required property int notificationId
    property var data: ({})
    readonly property string appName: data.appName ?? "qsm-desktop"
    readonly property string summary: data.summary ?? ""
    readonly property string body: data.body ?? ""
    readonly property string urgency: data.urgency ?? "normal"
    readonly property bool isTransient: data.isTransient ?? false
    readonly property bool paused: data.paused ?? false
    readonly property var actions: data.actions ?? []
    readonly property string imagePath: data.imagePath ?? ""
    readonly property double createdAt: data.createdAt ?? 0
    readonly property int expiryMs: data.expiryMs ?? -1
    readonly property var presentationRecord: data

    property var invokeActionCallback: null
    property Timer expiryTimer: Timer {
        onTriggered: root.expired(root.notificationId)
    }

    signal expired(int notificationId)

    function copyRecord(record: var): var {
        const copy = ({});
        for (const key of Object.keys(record ?? {}))
            copy[key] = record[key];
        return copy;
    }

    function commit(record: var): void {
        const next = copyRecord(record);
        next.notificationId = root.notificationId;
        next.createdAt = root.createdAt || record.createdAt || Date.now();
        next.paused = root.paused;
        root.data = next;
        root.armExpiry();
    }

    function setPaused(value: bool): void {
        if (root.paused === value)
            return;
        const next = copyRecord(root.data);
        next.paused = value;
        root.data = next;
        root.armExpiry();
    }

    function armExpiry(): void {
        expiryTimer.stop();
        if (root.expiryMs > 0 && !root.paused) {
            expiryTimer.interval = root.expiryMs;
            expiryTimer.start();
        }
    }

    Component.onCompleted: root.armExpiry()

    function invoke(actionId: string): bool {
        return !!invokeActionCallback
            && invokeActionCallback(root.notificationId, actionId) === true;
    }
}
