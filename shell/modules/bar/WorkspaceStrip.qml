import QtQuick
import Quickshell.Hyprland
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// Workspace slots (03): at most six Hyprland workspaces, the six nearest the
// active one, one slot each as wide as the rail and tall enough for a pointer,
// a mark per slot (occupied a textMuted dot, empty a ring, urgent a danger dot
// in a ring), and the active slot's dot is the library's accent count chip
// with the real number in textOnPrimary. A switch is the most frequent thing
// the rail does, so the chip hops and never glides. Wheel switches, click
// jumps, no popout.
Item {
    id: root

    // Every rail renders the identical column of ALL workspaces, active =
    // the globally focused one (03).

    // The globally focused workspace via the focused monitor — the same notify chain ShellState and
    // the pre-reel widget already rely on. (When testing
    // switches from a script on this Lua-dispatch Hyprland, use
    // `hl.dsp.focus({ workspace = "N" })`; plain `hyprctl dispatch workspace N`
    // errors and no-ops, which reads exactly like a stale binding — bit us.)
    readonly property int activeWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    readonly property var allWorkspaces: Hyprland.workspaces.values
        .filter(workspace => workspace.id > 0)
        .sort((left, right) => left.id - right.id);

    function workspaceFor(id: int): var {
        return Hyprland.workspaces.values.find(workspace => workspace.id === id) ?? null;
    }

    function activate(id: int): void {
        const workspace = workspaceFor(id);
        if (workspace) {
            workspace.activate();
            return;
        }

        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${id}" })`
            : `workspace ${id}`);
    }

    function moveRelative(delta: int): void {
        const target = Math.max(1, activeWorkspaceId + delta);
        activate(target);
    }

    // The six nearest the active workspace, in order: with more than six the
    // window keeps the active one in its third slot where the list allows, and
    // the chip names the real number whichever slots are shown.
    readonly property int activeIndexAll:
        Math.max(0, allWorkspaces.findIndex(workspace => workspace.id === activeWorkspaceId))
    readonly property int windowStart: Math.max(0,
        Math.min(activeIndexAll - 2, allWorkspaces.length - Theme.railWorkspaceSlots))
    readonly property var shownWorkspaces:
        allWorkspaces.slice(windowStart, windowStart + Theme.railWorkspaceSlots)
    readonly property int activeIndex: activeIndexAll - windowStart

    implicitWidth: Theme.railWidth
    implicitHeight: slots.implicitHeight

    Column {
        id: slots
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Repeater {
            model: root.shownWorkspaces

            Item {
                id: slot

                required property var modelData
                readonly property int workspaceId: modelData.id
                readonly property var workspace: modelData
                readonly property bool active: workspaceId === root.activeWorkspaceId
                readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
                readonly property bool urgent: workspace?.urgent ?? false

                // Two device pixels, whatever the scale.
                readonly property real ringStroke: 2 * QsmShellStyle.Style.stroke(QsmShellStyle.Style.hairline, slot)

                width: parent.width
                height: Theme.railWorkspaceSlot

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: `Workspace ${workspaceId}`
                Accessible.onPressAction: root.activate(slot.workspaceId)
                Keys.onReturnPressed: root.activate(slot.workspaceId)
                Keys.onEnterPressed: root.activate(slot.workspaceId)
                Keys.onSpacePressed: root.activate(slot.workspaceId)

                // Centred by arithmetic, never by `anchors.centerIn`: that
                // rounds to a whole LOGICAL pixel, which is between two device
                // pixels at 1.25 once hover has grown the body.
                Rectangle {
                    id: dot
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2
                    width: Theme.railWorkspaceDot + 2 * dotLayer.growth
                    height: width
                    radius: QsmShellStyle.Style.radiusPill
                    // Shape carries the state and colour repeats it: occupied
                    // is a filled dot, empty a ring, urgent a filled dot with
                    // a ring around it (below). Hover and press recolour it
                    // through the one state matrix, so it answers like every
                    // other target.
                    readonly property color ink: QsmShellStyle.Style.tone(
                        slot.urgent ? Theme.danger : Theme.textMuted,
                        dotLayer.hovered, dotLayer.pressed, false, true, Theme.accent)
                    readonly property bool filled: slot.occupied || slot.urgent
                    color: dot.filled ? dot.ink : "transparent"
                    border.width: dot.filled ? 0 : slot.ringStroke
                    border.color: dot.ink
                    // The pill covers the active slot; its dot steps aside
                    // instead of doubling under the number.
                    opacity: slot.active ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing }
                    }
                }

                // An urgent workspace asks for attention, so its dot wears a
                // ring as well as the danger colour.
                Rectangle {
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2
                    width: Theme.railWorkspaceRing + 2 * dotLayer.growth
                    height: width
                    radius: QsmShellStyle.Style.radiusPill
                    visible: slot.urgent && !slot.active
                    color: "transparent"
                    border.width: slot.ringStroke
                    border.color: Theme.danger
                }

                // The active slot's dot is the numbered accent chip: the library's
                // Badge at its own size, the same chip as the updates-cell
                // badge (03-rail), so a Badge has one height. Hovering the slot
                // grows it by whole device pixels and lifts its fill, like a
                // body.
                QsmShellComponents.Badge {
                    x: (parent.width - width) / 2
                    y: (parent.height - height) / 2
                    visible: slot.active
                    tone: "accent"
                    filled: true
                    text: String(slot.workspaceId)
                    color: QsmShellStyle.Style.tone(Theme.accent, dotLayer.hovered,
                        dotLayer.pressed, false, true, Theme.accent)
                    width: implicitWidth + 2 * dotLayer.growth
                    height: implicitHeight + 2 * dotLayer.growth
                }

                // The slot is the hit area, as wide as the rail and across the
                // band's gutter to the true screen edge like every rail cell.
                // Hover grows and recolours what is in it (09): the dot, or the
                // chip on the active slot; a press recolours without resizing.
                QsmShellComponents.StateLayer {
                    id: dotLayer
                    anchors.fill: parent
                    anchors.leftMargin: -Theme.railGutter
                    extent: slot.active ? QsmShellStyle.Style.badgeHeight : Theme.railWorkspaceDot
                    hoverScale: slot.active ? QsmShellStyle.Motion.hoverScale
                        : Theme.railWorkspaceDotHoverScale
                    focused: slot.activeFocus
                    focusRadius: QsmShellStyle.Style.radiusPill
                    onClicked: root.activate(slot.workspaceId)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y !== 0)
                root.moveRelative(event.angleDelta.y > 0 ? -1 : 1);
            else
                event.accepted = false;
        }
    }
}
