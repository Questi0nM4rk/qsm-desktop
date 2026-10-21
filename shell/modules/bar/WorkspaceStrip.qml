import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// Workspace slots (03): every Hyprland workspace, in one compact slot each, a
// dot per slot (occupied textMuted, urgent danger, empty overlay), and ONE
// moving part: the library's accent count chip with the active number in
// textOnPrimary, gliding between slots. Wheel switches, click jumps, no popout.
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

    readonly property int activeIndex:
        Math.max(0, allWorkspaces.findIndex(workspace => workspace.id === activeWorkspaceId))
    readonly property real slotStride: Theme.railWorkspaceSlot + QsmShellStyle.Style.space1

    implicitWidth: Theme.railWidth
    implicitHeight: slots.implicitHeight

    ColumnLayout {
        id: slots
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // The 4px step between slots; slotStride above must move with it,
        // because the travelling pill walks slotStride.
        spacing: QsmShellStyle.Style.space1

        Repeater {
            model: root.allWorkspaces

            Item {
                id: slot

                required property var modelData
                readonly property int workspaceId: modelData.id
                readonly property var workspace: modelData
                readonly property bool active: workspaceId === root.activeWorkspaceId
                readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
                readonly property bool urgent: workspace?.urgent ?? false

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Theme.railWorkspaceSlot
                implicitHeight: Theme.railWorkspaceSlot

                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: `Workspace ${workspaceId}`
                Accessible.onPressAction: root.activate(slot.workspaceId)
                Keys.onReturnPressed: root.activate(slot.workspaceId)
                Keys.onEnterPressed: root.activate(slot.workspaceId)
                Keys.onSpacePressed: root.activate(slot.workspaceId)

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width: Theme.railWorkspaceDot
                    height: width
                    radius: QsmShellStyle.Style.radiusPill
                    // Hover and press recolour the dot through the one state
                    // matrix, so it answers like every other target.
                    color: QsmShellStyle.Style.tone(
                        slot.urgent ? Theme.danger
                            : slot.occupied ? Theme.textMuted
                            : Theme.overlay,
                        dotLayer.hovered, dotLayer.pressed, false, true, Theme.accent)
                    // The pill covers the active slot; its dot steps aside
                    // instead of doubling under the number.
                    opacity: slot.active ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing }
                    }
                }

                // Hover grows and recolours the dot (09); the slot stays the
                // hit area, and a press recolours without resizing.
                QsmShellComponents.StateLayer {
                    id: dotLayer
                    anchors.fill: parent
                    target: dot
                    hoverScale: Theme.railWorkspaceDotHoverScale
                    focused: slot.activeFocus
                    focusRadius: QsmShellStyle.Style.radiusPill
                    onClicked: root.activate(slot.workspaceId)
                }
            }
        }
    }

    // The numbered accent chip — the one moving part. Glides between the
    // fixed slots on the popout-morph tier and carries the active number.
    // The library's Badge at its own size, never resized: it is the same chip
    // as the updates-cell badge (03-rail), so a Badge has one height.
    QsmShellComponents.Badge {
        id: activePill

        tone: "accent"
        filled: true
        text: String(root.activeWorkspaceId)
        anchors.horizontalCenter: parent.horizontalCenter
        y: slots.y + root.activeIndex * root.slotStride
            + (Theme.railWorkspaceSlot - height) / 2

        Behavior on y {
            NumberAnimation { duration: QsmShellStyle.Motion.morphGlide; easing.type: QsmShellStyle.Motion.standardEasing }
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
