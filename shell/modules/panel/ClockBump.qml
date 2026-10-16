import QtQuick
import Quickshell
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// The idle affordance of the top panel (06): the time and the date on a band
// bump that grows out of the panel's leading edge. Its width comes from the
// widest reading, so a minute change never moves it.
Item {
    id: root

    required property var host
    property string registryId: "panel-handle"
    readonly property date now: clock.date
    readonly property string timeText: Qt.formatTime(root.now, "HH:mm")
    readonly property string dateText: Qt.formatDate(root.now, "ddd d.MM")
    signal activated
    readonly property var actions: [({ name: "open-panel", invoke: () => root.activate() })]

    implicitWidth: Math.ceil(timeMetrics.advanceWidth + dateMetrics.advanceWidth) + 10 + Theme.space4 * 2
    implicitHeight: Theme.panelHandleHeight
    Accessible.role: Accessible.Button
    Accessible.name: `Open panel. ${root.timeText}, ${root.dateText}`
    Accessible.onPressAction: root.activate()
    activeFocusOnTab: visible && enabled

    // Minute precision: the display shows no seconds.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    TextMetrics {
        id: timeMetrics
        font: timeLabel.font
        text: "00:00"
    }
    TextMetrics {
        id: dateMetrics
        font: dateLabel.font
        text: "Wed 00.00"
    }

    function activate(): void {
        if (visible && enabled) root.activated();
    }
    function sync(): void {
        if (!host) return;
        if (!visible) { host.unregisterBulge(registryId); return; }
        const p = root.mapToItem(host, 0, 0);
        // CSS order (tl, tr, br, bl): square top where it grows out of the
        // panel's leading edge, 14px bottom corners.
        host.registerBulge(registryId, Qt.rect(p.x, p.y, width, height),
            Qt.vector4d(0, 0, 14, 14), 1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true);
    }
    onXChanged: sync()
    onYChanged: sync()
    onWidthChanged: sync()
    onHeightChanged: sync()
    onVisibleChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: { if (host) host.unregisterBulge(registryId); }
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    // The fill is painted by the shader through registerBulge; this only
    // carries the content.
    Row {
        anchors.centerIn: parent
        height: parent.height
        spacing: 10
        Text {
            id: timeLabel
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeText
            color: Theme.text
            font.family: Theme.technicalFontFamily
            font.pixelSize: 13
            font.weight: Theme.weightMedium
        }
        Text {
            id: dateLabel
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateText
            color: Theme.textMuted
            font.family: Theme.technicalFontFamily
            font.pixelSize: Theme.textSm
        }
    }
    QsmShellComponents.StateLayer {
        id: interaction
        anchors.fill: parent
        target: null
        interactive: root.visible && root.enabled
        focused: root.activeFocus
        focusRadius: 14
        onClicked: root.activate()
    }
}
