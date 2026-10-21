import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The idle affordance of the top panel (06, owner 2026-10-17): a small band
// bulge on the panel's leading edge carrying four dots, the drawer's
// grip, as small as a grip can be (owner 2026-10-17).
// Hover (the generous zone EdgeScene owns, no delay) or click opens the
// panel on Dashboard. The fill is painted by the shader through
// registerBulge; this only carries the dots and the click area.
Item {
    id: root

    required property var host
    property string registryId: "panel-handle"
    // The host says the panel is already open: the grip then only rides the
    // rim and holds the panel open under the pointer, so it stops offering
    // the open action it no longer performs.
    property bool open: false
    readonly property bool pointerOver: interaction.hovered
    readonly property bool dotsLit: !open && (interaction.hovered || interaction.pressed)
    signal activated
    readonly property var actions: [({ name: "open-panel", invoke: () => root.activate() })]

    implicitWidth: grip.implicitWidth + QsmShellStyle.Style.space1 * 2
    implicitHeight: Theme.panelHandleHeight
    Accessible.role: Accessible.Button
    Accessible.name: "Open panel"
    Accessible.onPressAction: root.activate()
    activeFocusOnTab: visible && enabled

    function activate(): void {
        if (visible && enabled) root.activated();
    }
    function sync(): void {
        if (!host) return;
        if (!visible) { host.unregisterBulge(registryId); return; }
        const p = root.mapToItem(host, 0, 0);
        const r = height / 2;
        // CSS order (tl, tr, br, bl): square top where it grows out of the
        // panel's leading edge, half-height bottom corners.
        host.registerBulge(registryId, Qt.rect(p.x, p.y, width, height),
            Qt.vector4d(0, 0, r, r), 1, Qt.vector4d(1, 0, 0, 1), 1, 0, 0, true);
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

    Row {
        id: grip
        anchors.centerIn: parent
        spacing: Theme.dotSpacing

        Repeater {
            model: 4

            Rectangle {
                // dotGlyphSize, not dotRadius * 2: a 2px circle rasterises soft
                // and its peak fell to 2.4:1; the text role clears 3:1.
                width: Theme.dotGlyphSize
                height: width
                radius: width / 2
                // Hover is the grip about to act: the dots take the accent.
                color: root.dotsLit ? Theme.accent : Theme.text

                Behavior on color {
                    ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                }
            }
        }
    }

    QsmShellComponents.StateLayer {
        id: interaction
        anchors.fill: parent
        // The dots grow under the pointer; the bulge is the shader's.
        target: grip
        hoverScale: root.open ? 1 : QsmShellStyle.Motion.hoverScale
        interactive: root.visible && root.enabled
        focused: root.activeFocus
        focusRadius: root.height / 2
        onClicked: root.activate()
    }
}
