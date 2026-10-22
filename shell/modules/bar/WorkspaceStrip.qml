pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The workspace strip (03): one capsule as wide as the rail holding every
// workspace, one slot each and all of them always there, so the strip never
// changes size and nothing under it moves. A slot is as wide as the rail and
// tall enough for a pointer, with a mark whose SHAPE is the state: an empty
// workspace a ring, one with windows a filled dot, an urgent one a danger dot
// in a ring. The selected slot wears the library's accent chip with the real
// number in textOnPrimary; the chip slides from slot to slot, and under reduced
// motion it jumps. Wheel switches, click jumps, no popout.
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
    readonly property int slotCount: Theme.railWorkspaceSlots
    // A workspace past the last slot keeps the chip on the last slot, and the
    // chip names the real number; a special workspace (a negative id) is none
    // of the slots, so no chip shows.
    readonly property bool hasActive: activeWorkspaceId > 0
    readonly property int activeIndex: Math.max(0, Math.min(slotCount - 1, activeWorkspaceId - 1))

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
        activate(Math.max(1, Math.min(slotCount, activeWorkspaceId + delta)));
    }

    // The slot the pointer is over, so the chip, which is not inside any slot,
    // answers hover and press like the dots do.
    property int hoveredIndex: -1
    property int pressedIndex: -1
    readonly property var activeSlot: slots.count > root.activeIndex
        ? slots.itemAt(root.activeIndex) : null
    readonly property real chipGrowth: root.hoveredIndex === root.activeIndex
        ? (root.activeSlot?.growth ?? 0) : 0

    implicitWidth: Theme.railWidth
    implicitHeight: slotCount * Theme.railWorkspaceSlot

    // The capsule: a body one step above the band, so the strip reads as one
    // object and not as dots scattered along the edge.
    Rectangle {
        anchors.fill: parent
        radius: QsmShellStyle.Style.radiusMd
        color: Theme.surface
    }

    // The selected slot's mark. It sits under the slots' layers, which paint
    // nothing but their hover tint, and its own slot hides the dot it covers.
    QsmShellComponents.Badge {
        id: chip

        readonly property real stride: Theme.railWorkspaceSlot
        x: (parent.width - Theme.railWorkspaceChipWidth) / 2 - root.chipGrowth
        y: root.activeIndex * chip.stride + (chip.stride - QsmShellStyle.Style.badgeHeight) / 2
            - root.chipGrowth
        width: Theme.railWorkspaceChipWidth + 2 * root.chipGrowth
        height: QsmShellStyle.Style.badgeHeight + 2 * root.chipGrowth
        visible: root.hasActive
        tone: "accent"
        filled: true
        text: String(root.activeWorkspaceId)
        color: QsmShellStyle.Style.tone(Theme.accent, root.hoveredIndex === root.activeIndex,
            root.pressedIndex === root.activeIndex, false, true, Theme.accent)

        Behavior on y {
            enabled: !QsmShellStyle.Style.reducedMotion
            NumberAnimation { duration: QsmShellStyle.Motion.fast; easing.type: QsmShellStyle.Motion.standardEasing }
        }
    }

    Repeater {
        id: slots
        model: root.slotCount

        Item {
            id: slot

            required property int index
            readonly property int workspaceId: index + 1
            readonly property var workspace: root.workspaceFor(workspaceId)
            readonly property bool active: root.hasActive && index === root.activeIndex
            readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
            readonly property bool urgent: workspace?.urgent ?? false
            readonly property real growth: dotLayer.growth

            // Two device pixels, whatever the scale.
            readonly property real ringStroke: 2 * QsmShellStyle.Style.stroke(QsmShellStyle.Style.hairline, slot)

            y: index * Theme.railWorkspaceSlot
            width: parent.width
            height: Theme.railWorkspaceSlot

            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: `Workspace ${workspaceId}`
            Accessible.description: [slot.active ? "current" : "",
                slot.urgent ? "needs attention" : slot.occupied ? "has windows" : "empty"]
                .filter(part => part.length > 0).join(", ")
            Accessible.onPressAction: root.activate(slot.workspaceId)
            Keys.onReturnPressed: root.activate(slot.workspaceId)
            Keys.onEnterPressed: root.activate(slot.workspaceId)
            Keys.onSpacePressed: root.activate(slot.workspaceId)

            // Centred by arithmetic, never by `anchors.centerIn`: that
            // rounds to a whole LOGICAL pixel, which is between two device
            // pixels at 1.25 once hover has grown the body.
            Rectangle {
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
                color: filled ? ink : "transparent"
                border.width: filled ? 0 : slot.ringStroke
                border.color: ink
                // The chip covers the active slot; its dot steps aside
                // instead of doubling under the number.
                visible: !slot.active
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

            Connections {
                target: dotLayer

                function onHoveredChanged(): void {
                    if (dotLayer.hovered)
                        root.hoveredIndex = slot.index;
                    else if (root.hoveredIndex === slot.index)
                        root.hoveredIndex = -1;
                }

                function onPressedChanged(): void {
                    if (dotLayer.pressed)
                        root.pressedIndex = slot.index;
                    else if (root.pressedIndex === slot.index)
                        root.pressedIndex = -1;
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
