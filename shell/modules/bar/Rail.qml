import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.state
import qs.theme

// The rail (03-rail lineup): the mark and the updates
// cell, then workspace slots with the PIN and the TRAY icons, then the
// current workspace's apps from the top of the middle, and at the bottom the
// READOUTS (clock, battery), the CONTROLS (quick actions, network, bluetooth,
// sound) and the SESSION (power). CPU and RAM live in the Dashboard only (06).
// Groups are told apart by space; a line is drawn only at the two ends of the
// app list and before power, where the groups either side look alike. The
// popout interaction lives in the PopoutController.
Item {
    id: root

    required property var screen
    required property PopoutController popouts

    Column {
        id: topStack
        anchors.top: parent.top
        anchors.topMargin: QsmShellStyle.Style.space4
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.railItemGap

        // The mark and the updates cell are one group.
        Column {
            id: markGroup
            width: parent.width
            spacing: Theme.railItemGap

            // The mark: identity and decoration, so it stays muted (accent
            // means current), the one larger glyph of the band (03 DEFAULT:
            // no click, no popout).
            RailEntry {
                icon: "arch"
                iconSize: Theme.railMark
                iconColor: Theme.textMuted
            }

            // System updates (HyDE parity): directly under
            // the mark. The badge carries the pending count; click opens the
            // full upgrade in a terminal — the ONE action. Hover names the
            // state instead.
            RailEntry {
                interactive: true
                icon: "updates"
                iconColor: UpdateService.available ? Theme.text : Theme.textMuted
                popouts: root.popouts
                popoutKind: "updates"
                popoutTitle: "System updates"
                popoutDetail: UpdateService.count > 0
                    ? `${UpdateService.count} packages can be updated · click to upgrade`
                    : UpdateService.count === 0
                        ? "Up to date · click to upgrade anyway"
                        : "Counting…"
                onClicked: UpdateService.upgrade()

                // The count riding the cell's corner. Hidden at zero and while
                // unknown — an absent badge never claims "up to date"; the
                // hover card does the telling.
                QsmShellComponents.Badge {
                    visible: UpdateService.available
                    // On the glyph's own top-right corner and no further than
                    // the capsule: the chip's right edge is the capsule's, so
                    // no pixel of it reaches the band's wall, and one rhythm
                    // step above the cell's centre line it leaves the glyph's
                    // body readable. All of its edges sit on whole device
                    // pixels.
                    anchors.right: parent.right
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: QsmShellStyle.Style.space1
                    tone: "accent"
                    filled: true
                    text: UpdateService.count > 99 ? "99+" : String(UpdateService.count)
                }
            }
        }

        // Glyph cells above, dots below: unlike kinds, so space alone parts
        // them.
        RailBreak { id: topBreak }

        // Workspaces, the pin and the tray are ONE group: the pin acts on the
        // band the workspaces live in, and a tray icon under the pin never
        // reads as one more app row.
        RailGroup {
            // What is left once the bottom cluster, the mark group, both
            // breaks, the stack's gaps and one app row are paid for: when
            // the group wants more than that, it scales down as one block
            // instead of pushing the clock off the band.
            maximumHeight: Math.max(0, root.height - bottomStack.height
                - QsmShellStyle.Style.space4 * 2 - markGroup.height - topBreak.height * 2
                - Theme.railItemGap * 5 - Theme.railCellHeight)

            Column {
                width: parent.width
                spacing: Theme.railItemGap

                WorkspaceStrip {
                    id: workspaces
                    width: parent.width
                    height: implicitHeight // plain Items do not self-adopt implicit size
                }

                // Pin/retract, per monitor: the glyph's SHAPE is the state
                // (a filled pin is pinned, an outline is not), click only.
                // Stays visually secondary through its muted colour.
                RailEntry {
                    readonly property bool retracted: ShellState.isRailCollapsed(root.screen.name)

                    icon: retracted ? "pin" : "pin-filled"
                    iconColor: Theme.textMuted
                    interactive: true
                    popouts: root.popouts
                    popoutKind: "railpin"
                    popoutTitle: retracted ? "Rail collapsed" : "Rail pinned"
                    popoutDetail: retracted
                        ? "Collapsed to the edge · click to pin the band open"
                        : "Pinned open, windows reserve around it · click to collapse"
                    onClicked: ShellState.toggleRail(root.screen.name)
                }

                // Tray icons: clicking one rolls out its DBusMenu (03). A
                // machine with no tray icons shows nothing here.
                Repeater {
                    model: SystemTray.items.values

                    Item {
                        id: trayEntry
                        required property var modelData

                        width: parent.width
                        height: Theme.railCellHeight

                        function open(): void {
                            root.popouts.show("tray", trayEntry,
                                trayEntry.modelData.title || trayEntry.modelData.id, "",
                                trayEntry.modelData);
                        }

                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: trayEntry.modelData.title || trayEntry.modelData.id
                        Accessible.onPressAction: trayEntry.open()
                        Keys.onReturnPressed: trayEntry.open()
                        Keys.onEnterPressed: trayEntry.open()
                        Keys.onSpacePressed: trayEntry.open()

                        // The capsule every rail item is: it recolours and grows by
                        // whole device pixels, the glyph keeps its size.
                        QsmShellComponents.Surface {
                            anchors.fill: parent
                            anchors.margins: -trayLayer.growth
                            radius: QsmShellStyle.Style.radiusMd
                            base: "transparent"
                            hovered: trayLayer.hovered
                            pressed: trayLayer.pressed
                        }

                        // One tone with the outline glyphs around it, like the
                        // rail's app rows.
                        Image {
                            id: trayImage
                            anchors.centerIn: parent
                            width: QsmShellStyle.Style.iconSm
                            height: QsmShellStyle.Style.iconSm
                            source: trayEntry.modelData.icon
                            asynchronous: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: Theme.textMuted
                                brightness: Theme.trayGlyphBrightness
                            }
                        }

                        QsmShellComponents.StateLayer {
                            id: trayLayer
                            anchors.fill: parent
                            anchors.leftMargin: -Theme.railGutter
                            growthCap: QsmShellStyle.Motion.hoverGrowthWithin(Theme.railItemGap)
                            focused: trayEntry.activeFocus
                            focusRadius: QsmShellStyle.Style.radiusMd
                            onClicked: trayEntry.open()
                        }
                    }
                }
            }
        }

        // The app list's length varies, so its top is marked.
        RailBreak { line: true }
    }

    // The middle section: the current workspace's apps, icon only, top-aligned
    // under the workspace group; names and live titles are in the hover popout.
    RailAppList {
        id: appList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topStack.bottom
        anchors.bottom: bottomStack.top
        anchors.topMargin: Theme.railItemGap
        anchors.bottomMargin: Theme.railItemGap
        screen: root.screen
        popouts: root.popouts
    }

    Column {
        id: bottomStack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: QsmShellStyle.Style.space4
        spacing: Theme.railItemGap

        // Three groups; inside a group the items sit one gap apart. What the
        // item is decides the group: the readouts (the time and the battery),
        // the controls (quick actions and the devices) and the session. The
        // app list's bottom is marked, as its top is.
        RailBreak { line: true }

        // Readouts: the time.
        ClockEntry {
            popouts: root.popouts
        }

        // Readouts: the battery reading.
        RailEntry {
            id: batteryCell

            readonly property var battery: UPower.displayDevice
            readonly property bool laptop: battery?.isLaptopBattery ?? false
            readonly property bool charging: battery?.state === UPowerDeviceState.Charging
            readonly property real charge: battery?.percentage ?? 0
            readonly property bool low: laptop && !charging && charge <= Theme.railLowBatteryFraction

            // The battery popout's profile switch reads this singleton,
            // and a laptop's cell never does: touching it here loads the
            // profile at startup, so the switch row is there when the card
            // opens instead of arriving a moment after it.
            Component.onCompleted: PowerProfileService.refresh()

            // The NUMBER, not a glyph. A machine with
            // no battery still shows its power profile, because there is
            // no percentage to show there.
            icon: laptop ? "" : PowerProfileService.glyph
            iconColor: low ? Theme.danger : Theme.text
            interactive: true
            popouts: root.popouts
            popoutKind: "battery"
            clickable: false
            popoutTitle: "Power"
            popoutDetail: ""

            QsmShellComponents.Prose {
                role: "reading"
                // The cell less one rhythm step above and below, so the box
                // sits on whole pixels and the digits centre inside it.
                anchors.fill: parent
                anchors.topMargin: QsmShellStyle.Style.space1
                anchors.bottomMargin: QsmShellStyle.Style.space1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: batteryCell.laptop
                text: Math.round(batteryCell.charge * 100) + "%"
                font.pixelSize: QsmShellStyle.Style.textMd
                font.weight: QsmShellStyle.Style.weightMedium
                // Charging is the one state the number cannot state, so
                // it says it in the accent rather than by growing a
                // second glyph beside itself.
                color: batteryCell.low ? Theme.danger
                    : batteryCell.charging ? Theme.accent
                    : Theme.text

                Behavior on color {
                    ColorAnimation { duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing }
                }
            }
        }

        // Text above, glyph cells below: unlike kinds, so space alone parts
        // them.
        RailBreak {}

        // Controls. Quick actions: active or connected
        // draws the glyph in text, off in textMuted; state changes the
        // glyph's SHAPE, never colour alone. Hover rolls out, click does
        // the cell's one cheap toggle, the rollout owns any escape to a
        // real app.
        RailEntry {
            icon: "zap"
            iconColor: Theme.textMuted
            interactive: true
            popouts: root.popouts
            popoutKind: "actions"
            clickable: false
            popoutTitle: "Quick actions"
            popoutDetail: ""
        }

        // Connectivity and audio devices.
        RailEntry {
            icon: NetworkService.glyph
            iconColor: NetworkService.ethernetActive || NetworkService.wifiConnected
                ? Theme.text : Theme.textMuted
            interactive: true
            popouts: root.popouts
            popoutKind: "network"
            clickable: false
            popoutTitle: "Network"
            popoutDetail: ""
        }

        // Bluetooth: ONE cell that becomes what is connected, and
        // subdivides up to four ways.
        RailDeviceCell {
            popouts: root.popouts
        }

        // Sound: hover pops out quick controls, click MUTES. pavucontrol
        // is reachable from exactly one place, the row inside the rollout.
        RailEntry {
            icon: AudioService.outputMuted ? "volume-muted" : "volume"
            iconColor: AudioService.outputMuted ? Theme.textMuted : Theme.text
            interactive: true
            popouts: root.popouts
            popoutKind: "sound"
            popoutTitle: "Sound"
            popoutDetail: ""
            onClicked: AudioService.toggleOutputMuted()
        }

        // Glyph cell above, glyph cell below: alike, so a line parts them.
        RailBreak { line: true }

        // Session: opens the session surface (08). Muted at rest; danger is
        // for what is about to happen, so it shows under the pointer. Click,
        // no hover card beyond its name.
        RailEntry {
            id: powerCell

            icon: "power"
            iconColor: powerCell.hovered || powerCell.selected ? Theme.danger : Theme.textMuted
            interactive: true
            popouts: root.popouts
            popoutKind: "session"
            popoutTitle: "Session"
            popoutDetail: "Lock, log out, hibernate, restart, shut down"
            onClicked: ShellState.toggleModalByPointer("session")
        }
    }

    // One wheel receiver owns routing so overlapping sibling handlers cannot
    // swallow workspace scroll. Qt Wayland delivers wheels to MouseArea.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y === 0) {
                event.accepted = false;
                return;
            }
            const point = root.mapToItem(workspaces, event.x, event.y);
            if (point.x >= 0 && point.x <= workspaces.width
                    && point.y >= 0 && point.y <= workspaces.height) {
                workspaces.moveRelative(event.angleDelta.y > 0 ? -1 : 1);
                return;
            }
            // A list that overflows owns the wheel over its rows.
            const listPoint = root.mapToItem(appList.view, event.x, event.y);
            if (appList.scrollable
                    && listPoint.x >= 0 && listPoint.x <= appList.view.width
                    && listPoint.y >= 0 && listPoint.y <= appList.view.height) {
                event.accepted = false;
                return;
            }
            const delta = event.angleDelta.y > 0
                ? Theme.osdWheelStep : -Theme.osdWheelStep;

            if (event.y < root.height / 2) {
                if (!AudioService.outputAvailable) { event.accepted = false; return; }
                AudioService.setOutput(AudioService.outputValue + delta);
                OsdState.show("output", root.screen);
            } else {
                if (!BrightnessService.available) { event.accepted = false; return; }
                BrightnessService.setValue(BrightnessService.value + delta);
                OsdState.show("brightness", root.screen);
            }
        }
    }
}
