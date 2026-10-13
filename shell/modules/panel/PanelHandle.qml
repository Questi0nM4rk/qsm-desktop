import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
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
        return Number.isFinite(value) && value >= 0 ? `${Math.round(Math.min(1, value) * 100)}%` : "—";
    }
    function level(value: real): real {
        return Number.isFinite(value) && value >= 0 ? Math.min(1, value) : 0;
    }
    function activate(): void {
        if (visible && enabled) root.activated();
    }
    function sync(): void {
        if (!host) return;
        if (!visible) { host.unregisterBulge(registryId); return; }
        const p = root.mapToItem(host, 0, 0);
        const r = height / 2;
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
    onSampleResourcesChanged: PerformanceService.watch(readerId, sampleResources && visible)
    Component.onCompleted: { sync(); PerformanceService.watch(readerId, sampleResources && visible); }
    Component.onDestruction: {
        PerformanceService.watch(readerId, false);
        if (host) host.unregisterBulge(registryId);
    }
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            GradientStop {
                position: 0
                color: QsmShellStyle.Style.tone(Theme.resourceSurfaceTop,
                    interaction.hovered, interaction.pressed, false, root.enabled, Theme.accent)
            }
            GradientStop {
                position: 1
                color: QsmShellStyle.Style.tone(Theme.resourceSurfaceBottom,
                    interaction.hovered, interaction.pressed, false, root.enabled, Theme.accent)
            }
        }
    }

    component Resource: Item {
        id: resource
        required property string label
        required property real value
        property bool mirrored: false

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Theme.space1
            spacing: Theme.space1
            QsmShellComponents.Prose {
                role: "supporting"
                technical: true
                text: resource.label
                color: root.enabled ? Theme.textMuted : QsmShellStyle.Style.disabled(Theme.textMuted)
            }
            QsmShellComponents.Prose {
                role: "reading"
                technical: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.textSm
                text: root.reading(resource.value)
                color: root.enabled ? Theme.text : QsmShellStyle.Style.disabled(Theme.text)
            }
        }
        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.space2
            height: Theme.resourceMeterThickness
            radius: height / 2
            color: root.enabled ? Theme.resourceTrack : QsmShellStyle.Style.disabled(Theme.resourceTrack)

            Rectangle {
                width: Math.round(track.width * root.level(resource.value))
                height: track.height
                x: resource.mirrored ? track.width - width : 0
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: root.enabled
                            ? (resource.mirrored ? Theme.resourceFillHigh : Theme.resourceFillLow)
                            : QsmShellStyle.Style.disabled(resource.mirrored ? Theme.resourceFillHigh : Theme.resourceFillLow)
                    }
                    GradientStop {
                        position: 1
                        color: root.enabled
                            ? (resource.mirrored ? Theme.resourceFillLow : Theme.resourceFillHigh)
                            : QsmShellStyle.Style.disabled(resource.mirrored ? Theme.resourceFillLow : Theme.resourceFillHigh)
                    }
                }
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.space3
        anchors.rightMargin: Theme.space3
        spacing: Theme.space3
        Resource {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            label: "CPU"
            value: root.cpuUsage
            mirrored: true
        }
        Resource {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            label: "RAM"
            value: root.memoryUsed
        }
    }
    QsmShellComponents.StateLayer {
        id: interaction
        anchors.fill: parent
        target: null
        interactive: root.visible && root.enabled
        focused: root.activeFocus
        focusRadius: root.height / 2
        onClicked: root.activate()
    }
}
