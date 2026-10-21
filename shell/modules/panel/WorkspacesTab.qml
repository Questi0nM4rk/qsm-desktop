pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
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

    readonly property real tileGap: QsmShellStyle.Style.space3

    // The tab is as tall as the panel's body (PanelSurface's column), always,
    // so the row of tiles does not jump with the number of workspaces.
    implicitWidth: Theme.mediaContentWidth
    implicitHeight: Theme.panelHeight - QsmShellStyle.Style.rolloutPadding * 2 - Theme.panelTabBarHeight - QsmShellStyle.Style.space3

    // Tiles grow to the body: three share the column width (a tile and its
    // hover growth are w * (2 + hoverScale) across, with two gaps), or the
    // body's height when the monitor is tall, whichever is smaller; the rest
    // scroll. The schematic keeps the monitor's aspect.
    readonly property int tilesAcross: 3
    readonly property real aspect: monitor ? monitor.height / Math.max(1, monitor.width) : 0.5625
    readonly property real tileWidth: Math.min(
        (width - tileGap * (tilesAcross - 1)) / (tilesAcross - 1 + hoverScale),
        ((implicitHeight - QsmShellStyle.Style.space2) / hoverScale - labelBand - areaInset) / aspect + areaInset * 2)

    // Window rects live in their own area, inset from the tile's rounded
    // corners, below a band that belongs to the workspace number: a number
    // painted on the tile was painted under any window that reached the
    // corner (the schematic keeps the monitor's aspect, so one often does).
    readonly property real areaInset: QsmShellStyle.Style.space2
    readonly property real areaWidth: tileWidth - areaInset * 2
    readonly property real areaHeight: areaWidth * aspect
    readonly property real labelBand: areaInset + labelMetrics.height
    readonly property real tileHeight: labelBand + areaHeight + areaInset

    // A hovered tile grows by this much (StateLayer, handed the same number
    // below); the strip clips, so it reserves the growth around the row
    // rather than cutting the tile's edge off.
    readonly property real hoverScale: QsmShellStyle.Motion.capsuleHoverScale
    readonly property real growthX: Math.ceil(tileWidth * (hoverScale - 1) / 2)
    readonly property real growthY: Math.ceil(tileHeight * (hoverScale - 1) / 2)

    TextMetrics {
        id: labelMetrics
        font.family: Theme.technicalFontFamily
        font.pixelSize: QsmShellStyle.Style.textSm
        font.weight: Font.Bold
        text: "0"
    }

    function moveWindow(address: string, workspaceId: int): void {
        mover.command = ["hyprctl", "dispatch", "movetoworkspacesilent",
            `${workspaceId},address:${address}`];
        mover.running = true;
    }

    // Down from the tab bar (06): the first tile.
    function focusFirst(): void {
        tiles.itemAt(0)?.forceActiveFocus();
    }

    // Keyboard focus moves along the strip, so the strip follows it.
    function revealTile(tile: Item): void {
        const left = row.x + tile.x - growthX;
        const right = row.x + tile.x + tile.width + growthX;
        strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width,
            left < strip.contentX ? left
            : right > strip.contentX + strip.width ? right - strip.width : strip.contentX));
    }

    Component.onCompleted: HyprClientsService.refresh()

    Process {
        id: mover
        onExited: HyprClientsService.refresh()
    }

    // ONE ROW, never stacked (spec/06): workspaces
    // sit next to each other and the strip scrolls horizontally when more
    // exist than fit. The row hangs from the strip's start at a fixed width,
    // so a workspace appearing or closing adds or removes a tile at the end
    // and never re-centres the others.
    Flickable {
        id: strip
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.tileHeight + root.growthY * 2
        contentWidth: row.implicitWidth + root.growthX * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: row
            x: root.growthX
            y: root.growthY
            spacing: root.tileGap

            Repeater {
                id: tiles
                model: root.workspaces

                QsmShellComponents.Surface {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool current: root.monitor?.activeWorkspace?.id === modelData.id
                    readonly property var tileClients: root.clients.filter(client =>
                        client.workspace?.id === tile.modelData.id && client.mapped !== false)

                    width: root.tileWidth
                    height: root.tileHeight
                    radius: QsmShellStyle.Style.radiusBody
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: `Workspace ${modelData.id}`
                    Accessible.onPressAction: modelData.activate()
                    onActiveFocusChanged: if (activeFocus) root.revealTile(tile)

                    // Return and Space switch to the workspace; Left and Right walk
                    // the tiles (the tab step takes only keys no content claimed)
                    // and with Shift carry the tile's first window to the neighbour.
                    function step(delta: int, carry: bool): void {
                        const target = tiles.itemAt(tile.index + delta);
                        if (!target)
                            return;
                        if (carry && tile.tileClients.length > 0)
                            root.moveWindow(tile.tileClients[0].address, root.workspaces[tile.index + delta].id);
                        else
                            target.forceActiveFocus();
                    }
                    Keys.onReturnPressed: modelData.activate()
                    Keys.onEnterPressed: modelData.activate()
                    Keys.onSpacePressed: modelData.activate()
                    Keys.onLeftPressed: event => {
                        event.accepted = true;
                        tile.step(-1, (event.modifiers & Qt.ShiftModifier) !== 0);
                    }
                    Keys.onRightPressed: event => {
                        event.accepted = true;
                        tile.step(1, (event.modifiers & Qt.ShiftModifier) !== 0);
                    }
                    base: Theme.surface
                    // Hover and press recolour the body (Style.tone); the layer
                    // below grows it.
                    hovered: tileLayer.hovered
                    pressed: tileLayer.pressed
                    // Current is a state, not a border: the ladder's selected tint.
                    selected: current

                    QsmShellComponents.Prose {
                        role: "reading"
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: root.areaInset
                        anchors.leftMargin: root.areaInset
                        color: tile.current ? Theme.accent : Theme.textMuted
                        text: tile.modelData.id
                    }

                    // Hover grows the tile slightly; keyboard focus rings it.
                    QsmShellComponents.StateLayer {
                        id: tileLayer
                        anchors.fill: parent
                        focusRadius: tile.radius
                        hoverScale: root.hoverScale
                        onClicked: tile.modelData.activate()
                    }

                    Item {
                        id: windowArea
                        x: root.areaInset
                        y: root.labelBand
                        width: root.areaWidth
                        height: root.areaHeight

                    Repeater {
                        model: tile.tileClients

                        Rectangle {
                            id: windowRect
                            required property var modelData
                            readonly property real scaleX: root.areaWidth / Math.max(1, root.monitor?.width ?? 1)
                            readonly property real scaleY: root.areaHeight / Math.max(1, root.monitor?.height ?? 1)

                            x: Math.max(0, (modelData.at[0] - (root.monitor?.x ?? 0)) * scaleX)
                            y: Math.max(0, (modelData.at[1] - (root.monitor?.y ?? 0)) * scaleY)
                            width: Math.min(root.areaWidth - x, modelData.size[0] * scaleX)
                            height: Math.min(root.areaHeight - y, modelData.size[1] * scaleY)
                            // Concentric with the tile, through the area's inset in it.
                            radius: QsmShellStyle.Style.childRadius(windowArea)
                            // One ladder step above the tile separates it; no outline.
                            color: Theme.overlay
                            opacity: windowDrag.active ? Theme.opacityDrag : 1

                            AppIcon {
                                anchors.centerIn: parent
                                icon: windowRect.modelData.class ?? ""
                                implicitSize: Math.min(QsmShellStyle.Style.iconSm, parent.height - QsmShellStyle.Style.spaceTight)
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
    }

    // The library's cue, which is the same fade language plus a position
    // mark. The two rectangles it replaces read raw `contentX`, which is the
    // arithmetic ScrollCue exists to avoid, and they snapped on and off
    // instead of fading.
    QsmShellComponents.ScrollCue {
        view: strip
        orientation: Qt.Horizontal
        fadeColor: Theme.band
        fadeDepth: QsmShellStyle.Style.space5
    }
}
