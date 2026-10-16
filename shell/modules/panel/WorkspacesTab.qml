import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.components
import qs.services
import qs.theme

// Workspaces tab (06): overview of the focused monitor's workspaces as
// SCHEMATIC tiles (the compositor cannot capture unfocused workspaces) —
// each tile draws its windows as positioned rounded rects with the app
// icon. Click focuses the workspace; DRAGGING a window rect onto another
// tile dispatches the compositor move (movetoworkspacesilent).
Item {
    id: root

    property var targetScreen: null
    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(workspace => workspace.id > 0
            && (workspace.monitor?.id ?? monitor?.id) === monitor?.id)
        .sort((left, right) => left.id - right.id)
    // Geometry/class come from the shared clients service (hyprctl
    // clients -j snapshots); Quickshell toplevels carry no window rects.
    readonly property var clients: HyprClientsService.clients

    readonly property real tileWidth: 180
    readonly property real tileHeight: monitor
        ? tileWidth * monitor.height / Math.max(1, monitor.width) : 100
    readonly property real tileGap: Theme.space3

    implicitHeight: strip.height + Theme.space2

    function moveWindow(address: string, workspaceId: int): void {
        mover.command = ["hyprctl", "dispatch", "movetoworkspacesilent",
            `${workspaceId},address:${address}`];
        mover.running = true;
    }

    Component.onCompleted: HyprClientsService.refresh()

    Process {
        id: mover
        onExited: HyprClientsService.refresh()
    }

    // ONE ROW, never stacked (owner 2026-08-21, spec/06 amended): workspaces
    // sit next to each other and the strip scrolls horizontally when more
    // exist than fit. Centred while they fit — two tiles pinned to the left
    // edge of a panel read as content that failed to load.
    Flickable {
        id: strip
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.width, row.implicitWidth)
        height: root.tileHeight
        contentWidth: row.implicitWidth
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: row
            spacing: root.tileGap

            Repeater {
                model: root.workspaces

                Rectangle {
                    id: tile
                    required property var modelData
                    readonly property bool current: root.monitor?.activeWorkspace?.id === modelData.id
                    readonly property var tileClients: root.clients.filter(client =>
                        client.workspace?.id === tile.modelData.id && client.mapped !== false)

                    width: root.tileWidth
                    height: root.tileHeight
                    radius: Theme.radiusSm
                    // Current is a state, not a border: accent at opacitySelected over the tile.
                    color: current
                        ? Qt.tint(Theme.surface, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Theme.opacitySelected))
                        : Theme.surface

                    QsmShellComponents.Prose {
                        role: "reading"
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: Theme.space1
                        font.pixelSize: Theme.textXs
                        color: tile.current ? Theme.accent : Theme.textMuted
                        text: tile.modelData.id
                    }

                    TapHandler {
                        onTapped: tile.modelData.activate()
                    }

                    Repeater {
                        model: tile.tileClients

                        Rectangle {
                            id: windowRect
                            required property var modelData
                            readonly property real scaleX: root.tileWidth / Math.max(1, root.monitor?.width ?? 1)
                            readonly property real scaleY: root.tileHeight / Math.max(1, root.monitor?.height ?? 1)

                            x: Math.max(0, (modelData.at[0] - (root.monitor?.x ?? 0)) * scaleX)
                            y: Math.max(0, (modelData.at[1] - (root.monitor?.y ?? 0)) * scaleY)
                            width: Math.min(root.tileWidth, modelData.size[0] * scaleX)
                            height: Math.min(root.tileHeight, modelData.size[1] * scaleY)
                            radius: Theme.radiusXs
                            color: Theme.overlay
                            // A diagram: window rects separate from the tile by one ladder step.
                            border.width: 0
                            opacity: windowDrag.active ? 0.85 : 1

                            AppIcon {
                                anchors.centerIn: parent
                                icon: windowRect.modelData.class ?? ""
                                implicitSize: Math.min(16, parent.height - 2)
                            }

                            transform: Translate {
                                x: windowDrag.active ? windowDrag.translation.x : 0
                                y: windowDrag.active ? windowDrag.translation.y : 0
                            }

                            DragHandler {
                                id: windowDrag
                                target: null
                                onActiveChanged: {
                                    if (active)
                                        return;

                                    // Drop: one row, so the target is purely
                                    // the x of the dragged rect's center in
                                    // ROW coordinates (mapToItem(row) already
                                    // includes the strip's scroll offset).
                                    const center = windowRect.mapToItem(row,
                                        windowRect.width / 2 + translation.x,
                                        windowRect.height / 2 + translation.y);
                                    const index = Math.floor(
                                        center.x / (root.tileWidth + root.tileGap));
                                    const target = root.workspaces[index];
                                    if (target && target.id !== tile.modelData.id)
                                        root.moveWindow(windowRect.modelData.address, target.id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // The library's cue, which is the same fade language plus a position
    // mark. The two rectangles it replaces read raw `contentX`, which is the
    // arithmetic ScrollCue exists to avoid, and they snapped on and off
    // instead of fading.
    QsmShellComponents.ScrollCue {
        view: strip
        orientation: Qt.Horizontal
        fadeColor: Theme.band
        fadeDepth: Theme.space5
    }
}
