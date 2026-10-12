import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.theme

Item {
    id: root

    required property var host
    property string registryId: "panel-handle"
    property string readerId: registryId
    property bool sampleResources: true
    property real cpuUsage: PerformanceService.cpuUsage
    property real memoryUsed: PerformanceService.memUsed
    signal activated
    readonly property var actions: [({ name: "open-panel", invoke: () => root.activate() })]

    implicitWidth: Theme.panelHandleWidth
    implicitHeight: Theme.panelHandleHeight
    Accessible.role: Accessible.Button
    Accessible.name: `Open panel. CPU ${root.reading(cpuUsage)}, RAM ${root.reading(memoryUsed)}`
    Accessible.onPressAction: root.activate()
    activeFocusOnTab: visible && enabled

    function reading(value: real): string {
        return Number.isFinite(value) && value >= 0 ? `${Math.round(value * 100)}%` : "—";
    }
    function activate(): void {
        if (visible && enabled) root.activated();
    }
    function sync(): void {
        if (!host) return;
        if (!visible) { host.unregisterBulge(registryId); return; }
        const p = root.mapToItem(host, 0, 0);
        const r = Theme.radiusMd;
        // Preserve the moving-rim body; screen-edge snapping would stretch it
        // through the full open panel instead of keeping a compact handle.
        host.registerBulge(registryId, Qt.rect(p.x, p.y, width, height),
            Qt.vector4d(r, r, r, r), 1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true);
    }
    onXChanged: sync()
    onYChanged: sync()
    onWidthChanged: sync()
    onHeightChanged: sync()
    onVisibleChanged: { sync(); PerformanceService.watch(readerId, sampleResources && visible); }
    Component.onCompleted: { sync(); PerformanceService.watch(readerId, sampleResources && visible); }
    Component.onDestruction: {
        PerformanceService.watch(readerId, false);
        if (host) host.unregisterBulge(registryId);
    }
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.space2
        QsmShellComponents.Prose {
            role: "metadata"
            technical: true
            text: `CPU ${root.reading(root.cpuUsage)}`
        }
        QsmShellComponents.Prose {
            role: "metadata"
            technical: true
            text: `RAM ${root.reading(root.memoryUsed)}`
        }
    }
    QsmShellComponents.StateLayer {
        anchors.fill: parent
        focused: root.activeFocus
        focusRadius: Theme.radiusMd
        onClicked: root.activate()
    }
}
