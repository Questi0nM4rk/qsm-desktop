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
// tile dispatches the compositor move (movetoworkspacesilent). The tab is one
// card that fills the panel's content box; the tiles sit in its middle.
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

    readonly property real cardPadding: QsmShellStyle.Style.space4
    readonly property real tileGap: QsmShellStyle.Style.space4

    // The tab fills the panel's content box, always, so the row of tiles does
    // not jump with the number of workspaces and starts where every tab does.
    implicitWidth: Theme.panelContentWidth
    implicitHeight: Theme.panelContentHeight

    // A hovered tile's body grows by whole device pixels (StateLayer), never
    // more than this a side. The strip clips, so it reaches this far past the
    // card's inside on every side and the tiles' resting edges stay on it.
    readonly property real growthReserve: QsmShellStyle.Style.space1

    // Tiles grow to the card's inside: three share its width, or its height when
    // the monitor is tall, whichever is smaller; the rest scroll. The schematic
    // keeps the monitor's aspect, to a whole step.
    readonly property int tilesAcross: 3
    readonly property real aspect: monitor ? monitor.height / Math.max(1, monitor.width) : 0.5625
    readonly property real tileWidth: Math.min(
        (width - cardPadding * 2 - tileGap * (tilesAcross - 1)) / tilesAcross,
        (implicitHeight - cardPadding * 2 - growthReserve * 2 - labelBand - areaInset) / aspect + areaInset * 2)

    // Window rects live in their own area, inset from the tile's rounded
    // corners, below a band that belongs to the workspace number: a number
    // painted on the tile was painted under any window that reached the
    // corner (the schematic keeps the monitor's aspect, so one often does).
    readonly property real areaInset: QsmShellStyle.Style.space2
    readonly property real areaWidth: tileWidth - areaInset * 2
    readonly property real areaHeight: QsmShellStyle.Style.rhythm(areaWidth * aspect)
    readonly property real labelBand: QsmShellStyle.Style.rhythm(areaInset + labelMetrics.height)
    readonly property real tileHeight: labelBand + areaHeight + areaInset

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
        tiles.itemAt(0)?.forceActiveFocus(Qt.TabFocusReason);
    }

    // Keyboard focus moves along the strip, so the strip follows it.
    function revealTile(tile: Item): void {
        const left = row.x + tile.x - growthReserve;
        const right = row.x + tile.x + tile.width + growthReserve;
        strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width,
            left < strip.contentX ? left
            : right > strip.contentX + strip.width ? right - strip.width : strip.contentX));
    }

    Component.onCompleted: HyprClientsService.refresh()

    Process {
        id: mover
        onExited: HyprClientsService.refresh()
    }

    QsmShellComponents.Card {
        anchors.fill: parent
    }

    // ONE ROW, never stacked (spec/06): workspaces
    // sit next to each other and the strip scrolls horizontally when more
    // exist than fit. The row hangs from the strip's start at a fixed width,
    // so a workspace appearing or closing adds or removes a tile at the end
    // and never re-centres the others.
    Flickable {
        id: strip
        x: root.cardPadding - root.growthReserve
        y: QsmShellStyle.Style.stroke((root.height - height) / 2, root)
        width: root.width - root.cardPadding * 2 + root.growthReserve * 2
        height: root.tileHeight + root.growthReserve * 2
        contentWidth: row.implicitWidth + root.growthReserve * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: row
            x: root.growthReserve
            y: root.growthReserve
            spacing: root.tileGap

            Repeater {
                id: tiles
                model: root.workspaces

                Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool current: root.monitor?.activeWorkspace?.id === modelData.id
                    readonly property var tileClients: root.clients.filter(client =>
                        client.workspace?.id === tile.modelData.id && client.mapped !== false)

                    width: root.tileWidth
                    height: root.tileHeight
                    readonly property real radius: QsmShellStyle.Style.radiusBody
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
                            target.forceActiveFocus(Qt.TabFocusReason);
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

                    // The body: hover and press recolour it (Style.tone) and the
                    // layer below grows it, while what is drawn on it keeps its
                    // size.
                    QsmShellComponents.Surface {
                        anchors.fill: parent
                        anchors.margins: -tileLayer.growth
                        radius: tile.radius
                        // A tile is a raised body on the card; its windows sit back a step.
                        base: Theme.overlay
                        hovered: tileLayer.hovered
                        pressed: tileLayer.pressed
                        // Current is a state, not a border: the ladder's selected tint.
                        selected: tile.current
                    }

                    QsmShellComponents.Prose {
                        role: "reading"
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: root.areaInset
                        anchors.leftMargin: root.areaInset
                        color: tile.current ? Theme.accent : Theme.textMuted
                        text: tile.modelData.id
                    }

                    // Hover grows the tile's body slightly; keyboard focus rings it.
                    QsmShellComponents.StateLayer {
                        id: tileLayer
                        anchors.fill: parent
                        focusRadius: tile.radius
                        hoverScale: QsmShellStyle.Motion.capsuleHoverScale
                        growthCap: root.growthReserve
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
                            // One ladder step below the tile separates it; no outline.
                            color: Theme.surface
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

    // The wheel scrolls the strip a tile at a time. A vertical wheel is the
    // common one, and a horizontal Flickable does nothing with it. The area takes
    // no button, so a tile under it still gets the click and the drag.
    MouseArea {
        anchors.fill: strip
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const notch = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y;
            const room = strip.contentWidth - strip.width;
            if (notch === 0 || room <= 0) {
                wheel.accepted = false;
                return;
            }
            const pitch = root.tileWidth + root.tileGap;
            scroll.stop();
            scroll.to = Math.max(0, Math.min(room, Math.round((strip.contentX - Math.sign(notch) * pitch) / pitch) * pitch));
            scroll.start();
        }
    }

    NumberAnimation {
        id: scroll
        target: strip
        property: "contentX"
        duration: QsmShellStyle.Motion.medium
        easing.type: QsmShellStyle.Motion.standardEasing
    }

    // The edge fade is the cue that more tiles lie past an edge; it fades to
    // the card the tiles sit on.
    QsmShellComponents.ScrollCue {
        view: strip
        orientation: Qt.Horizontal
        fadeColor: Theme.surface
        fadeDepth: QsmShellStyle.Style.space5
        indicator: false
    }
}
