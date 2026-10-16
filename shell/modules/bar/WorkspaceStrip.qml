import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

Item {
    id: root

    // Globally focused workspace via the focused monitor — the same notify
    // chain ShellState and the pre-reel widget already rely on. (When testing
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

    // Owner design v2 (03 re-amended): dots hold FIXED positions; the
    // numbered accent pill is the thing that travels, gliding dot-to-dot.
    readonly property int activeIndex:
        Math.max(0, allWorkspaces.findIndex(workspace => workspace.id === activeWorkspaceId))
    readonly property real slotStride: Theme.railWorkspaceDotSlot + Theme.space1

    implicitWidth: Theme.railWidth
    implicitHeight: dots.implicitHeight + Theme.space2 * 2

    ColumnLayout {
        id: dots
        anchors.centerIn: parent
        // 03-rail RATIFIED: workspace dots use the 4px step, not the 8px one
        // the rest of the column uses. The stride above must move with it --
        // the travelling active pill walks slotStride, so a spacing change
        // alone puts the pill beside the dots instead of on them.
        spacing: Theme.space1

        Repeater {
            model: root.allWorkspaces

            Item {
                id: indicator

                required property var modelData
                readonly property int workspaceId: modelData.id
                readonly property var workspace: modelData
                readonly property bool active: workspaceId === root.activeWorkspaceId
                readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
                readonly property bool urgent: workspace?.urgent ?? false

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Theme.railWidth
                implicitHeight: Theme.railWorkspaceDotSlot

                Rectangle {
                    anchors.centerIn: parent
                    width: indicator.occupied ? 8 : 6
                    height: width
                    radius: Theme.radiusPill
                    color: indicator.occupied ? Theme.primary : Theme.textMuted
                    border.width: indicator.urgent ? 2 : 0
                    border.color: Theme.warning
                    // The traveling pill covers the active slot; its dot
                    // steps aside instead of doubling under the number.
                    opacity: indicator.active ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                    }
                }

                // 03 DEFAULT: workspace dots have NO hover popout —
                // wheel switches, click jumps.
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.activate(indicator.workspaceId)
                }
            }
        }
    }

    // The numbered accent pill — the one moving part. Glides between the
    // fixed dot positions on the popout-morph tier and carries the active
    // workspace number.
    //
    // Badge, not a hand-built Rectangle+Text: "same pill language as the
    // workspace number" is the spec's own words for the updates-cell badge
    // (03-rail), and Rail.qml already uses Badge for that count — one type
    // for the one pill idiom instead of two builds of it.
    QsmShellComponents.Badge {
        id: activePill

        tone: "accent"
        filled: true
        text: String(root.activeWorkspaceId)
        width: Theme.railWorkspacePillWidth
        height: Theme.railWorkspaceActiveSlot
        anchors.horizontalCenter: parent.horizontalCenter
        y: dots.y + root.activeIndex * root.slotStride
            + Theme.railWorkspaceDotSlot / 2 - height / 2

        Behavior on y {
            NumberAnimation { duration: Motion.morphGlide; easing.type: Motion.standardEasing }
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
