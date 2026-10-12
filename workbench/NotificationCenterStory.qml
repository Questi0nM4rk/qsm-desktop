import QtQuick
import qs.modules.panel as Panel
import qs.services
import qs.state
import qs.theme

Item {
    id: root
    property var previewEnvironment: null
    property int viewportWidth: 980
    property int viewportHeight: 680
    property var inputDriver: null
    property bool interactive: false
    property int resetGeneration: 0
    readonly property real contentExtentWidth: width
    readonly property real contentExtentHeight: height
    readonly property var controls: [{ label: "History", options: [
        { label: "Mixed" }, { label: "Empty" }, { label: "Legacy archive" }
    ] }]
    readonly property var actions: [{ label: "Dismiss selected", trigger: "dismiss-selected" }]
    readonly property var integration: ({
        events: ["dismiss-requested"], actions: ["dismiss-selected"],
        runAction: name => root.runAction(name),
        targets: { "search": () => center.searchTarget },
        observables: {
            "live-count": () => NotificationService.live.length,
            "archive-count": () => NotificationService.archive.length,
            "visible-count": () => center.items.length,
            "selected-summary": () => center.selectedEntry()?.summary ?? "",
            "query": () => center.query,
            "first-source-summary": () => NotificationService.archive[0]?.summary ?? ""
        },
        idle: () => !center.restoringCursor
    })
    signal eventRecorded(var record)
    signal inspectionReady(var inspection)
    width: previewEnvironment?.screenRect?.width ?? viewportWidth
    height: previewEnvironment?.screenRect?.height ?? viewportHeight

    function resetStory(): void {
        ShellState.reset();
        NotificationService.store.reset();
        center.query = "";
        const now = Date.now();
        NotificationService.store.history = [
            { archiveId: "saved", archivedAt: now - 300000, appName: "Mail",
                summary: "Saved message", body: "Your archive remains searchable and individually removable.", urgency: "normal" },
            { archiveId: "download", archivedAt: now - 60000, appName: "Downloads",
                summary: "Download finished", body: "A report is ready to open.", urgency: "normal" }
        ];
        NotificationService.store.addSource({ appName: "Build", summary: "Build finished",
            body: "All targets built. This live record archives when dismissed.", urgency: "critical", expiryMs: 0, actions: [] });
    }
    function applyControl(group: int, option: int): bool {
        if (group !== 0 || option < 0 || option > 2) return false;
        resetStory();
        if (option > 0) NotificationService.store.reset();
        if (option === 2) NotificationService.store.history = [{ archivedAt: Date.now() - 10000,
            appName: "Legacy", summary: "Imported message", body: "No archive ID in older saved records.", urgency: "normal" }];
        return true;
    }
    function runAction(name: string): bool {
        if (name !== "dismiss-selected" || !center.selectedEntry()) return false;
        center.removeSelected();
        return true;
    }
    function triggerAction(index: int): bool { return runAction(actions[index]?.trigger ?? ""); }
    function dumpTree(): void {
        inspectionReady({ story: "notification-center", selected: center.selectedEntry()?.summary ?? "" });
    }
    onResetGenerationChanged: resetStory()
    Component.onCompleted: resetStory()
    Component.onDestruction: NotificationService.store.reset()
    Rectangle { anchors.fill: parent; color: Theme.background }
    Panel.NotificationCenterTab {
        id: center
        width: Theme.notificationWidth + Theme.space6 * 2
        anchors.centerIn: parent
        maxListHeight: root.height - Theme.space6 * 4
    }
    Connections {
        target: center
        function onDismissRequested(entry: var): void {
            root.eventRecorded({ origin: "component", kind: "notification-center", name: "dismiss-requested",
                payload: { summary: entry.summary, archived: entry.archivedAt !== undefined } });
        }
    }
}
