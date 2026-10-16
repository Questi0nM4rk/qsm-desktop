import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// The rail (03-rail lineup, RATIFIED 2026-10-16): the mark and the updates
// cell, then workspace slots with the PIN and the TRAY icons, then the
// current workspace's apps spread across the middle, and at the bottom the
// READOUTS (CPU, RAM, the battery number), the QUICK MENU (actions, network,
// bluetooth, sound) and power. The clock lives in the top bump (06). Groups
// are separated by the rail's divider lines (owner 2026-10-16). The popout
// interaction lives in the PopoutController.
Item {
    id: root

    required property var screen
    required property PopoutController popouts

    // The readouts need the performance sampler running while this rail is
    // on screen; the key is per monitor so one rail retiring never cancels
    // another's demand.
    Component.onCompleted: PerformanceService.watch("rail-" + root.screen.name, true)
    Component.onDestruction: PerformanceService.watch("rail-" + root.screen.name, false)

    Column {
        id: topStack
        anchors.top: parent.top
        anchors.topMargin: Theme.space4
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.railItemGap

        // The mark and the updates cell are one compact group.
        Column {
            width: parent.width
            spacing: Theme.railItemGap

            // The mark: decorative, in the accent, the one 20px glyph of the
            // band (03 DEFAULT: no click, no popout).
            RailEntry {
                icon: "arch"
                iconSize: Theme.iconMd
                iconColor: Theme.accent
                compact: true
            }

            // System updates (owner 2026-08-25, HyDE parity): directly under
            // the mark. The badge carries the pending count; click opens the
            // full upgrade in a terminal — the ONE action. Hover names the
            // state instead.
            RailEntry {
                interactive: true
                icon: "updates"
                compact: true
                iconColor: UpdateService.available ? Theme.text : Theme.textMuted
                popouts: root.popouts
                popoutKind: "updates"
                popoutTitle: "System updates"
                popoutDetail: UpdateService.count > 0
                    ? `${UpdateService.count} packages can be updated · click to upgrade`
                    : UpdateService.count === 0
                        ? "Up to date · click to run the full upgrade anyway"
                        : "Counting… (is pacman-contrib installed?)"
                onClicked: UpdateService.upgrade()

                // The count riding the cell's corner. Hidden at zero and while
                // unknown — an absent badge never claims "up to date"; the
                // hover card does the telling.
                QsmShellComponents.Badge {
                    visible: UpdateService.available
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    tone: "accent"
                    filled: true
                    text: String(UpdateService.count)
                }
            }
        }

        RailDivider {}

        // Workspaces, the pin and the tray are ONE group: the pin acts on the
        // band the workspaces live in, and a tray icon under the pin never
        // reads as one more app row.
        RailGroup {
            Column {
                width: parent.width
                spacing: Theme.railItemGap

                WorkspaceStrip {
                    id: workspaces
                    width: parent.width
                    height: implicitHeight // plain Items do not self-adopt implicit size
                }

                // Pin/retract, per monitor: icon-swap, click only. Stays
                // visually secondary through its muted colour.
                RailEntry {
                    readonly property bool retracted: ShellState.isRailCollapsed(root.screen.name)

                    icon: retracted ? "pin" : "pin-off"
                    compact: true
                    iconColor: Theme.textMuted
                    interactive: true
                    popouts: root.popouts
                    popoutKind: "railpin"
                    popoutTitle: "Rail pin"
                    popoutDetail: retracted
                        ? "Collapsed to the edge · click to pin the band open"
                        : "Pinned open, windows reserve around it · click to collapse"
                    onClicked: ShellState.toggleRail(root.screen.name)
                }

                // Tray icons: clicking one rolls out its DBusMenu (03
                // RATIFIED). A machine with no tray icons shows nothing here.
                Repeater {
                    model: SystemTray.items.values

                    Item {
                        id: trayEntry
                        required property var modelData

                        width: parent.width
                        height: Theme.space6

                        Image {
                            anchors.centerIn: parent
                            width: Theme.iconSm
                            height: Theme.iconSm
                            source: trayEntry.modelData.icon
                            asynchronous: true
                        }

                        QsmShellComponents.StateLayer {
                            anchors.fill: parent
                            hoverScale: 1.12
                            pressScale: 0.9
                            onClicked: root.popouts.show("tray", trayEntry,
                                trayEntry.modelData.title || trayEntry.modelData.id, "",
                                trayEntry.modelData)
                        }
                    }
                }
            }
        }

        RailDivider {}
    }

    // The middle section: the current workspace's apps, icon only, top-aligned
    // under the workspace group; names and live titles are in the hover popout.
    RailAppList {
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
        anchors.bottomMargin: Theme.space4
        spacing: Theme.railItemGap

        RailDivider {}

        // ONE bottom cluster in one rhythm (owner 2026-10-16): the readouts
        // (CPU and RAM as glyph + number, then the battery reading) and the
        // quick menu, in the rail's one rhythm. A readout has a number and no
        // click.
        Column {
            width: parent.width
            spacing: Theme.railItemGap

            RailReadout {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: "cpu"
                value: PerformanceService.cpuUsage
                smoothed: true
            }

            RailReadout {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: "memory"
                value: PerformanceService.memUsed
            }

            RailEntry {
                id: batteryCell

                readonly property var battery: UPower.displayDevice
                readonly property bool laptop: battery?.isLaptopBattery ?? false
                readonly property bool charging: battery?.state === UPowerDeviceState.Charging
                readonly property real charge: battery?.percentage ?? 0
                readonly property bool low: laptop && !charging && charge <= 0.2

                // The NUMBER, not a glyph (owner 2026-09-05). A machine with
                // no battery still shows its power profile, because there is
                // no percentage to show there.
                icon: laptop ? "" : PowerProfileService.glyph
                iconColor: low ? Theme.danger : Theme.text
                compact: true
                interactive: true
                popouts: root.popouts
                popoutKind: "battery"
                clickable: false
                popoutTitle: "Power"
                popoutDetail: ""

                QsmShellComponents.Prose {
                    role: "reading"
                    anchors.centerIn: parent
                    visible: batteryCell.laptop
                    text: Math.round(batteryCell.charge * 100) + "%"
                    // Charging is the one state the number cannot state, so
                    // it says it in the accent rather than by growing a
                    // second glyph beside itself.
                    color: batteryCell.low ? Theme.danger
                        : batteryCell.charging ? Theme.accent
                        : Theme.text

                    Behavior on color {
                        ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing }
                    }
                }
            }

            // The quick menu: 32px cells, 16px glyphs. Active or connected
            // draws the glyph in text, off in textMuted; state changes the
            // glyph's SHAPE, never colour alone. Hover rolls out, click does
            // the cell's one cheap toggle, the rollout owns any escape to a
            // real app.
            RailEntry {
                icon: "zap"
                iconColor: Theme.textMuted
                compact: true
                interactive: true
                popouts: root.popouts
                popoutKind: "actions"
                clickable: false
                popoutTitle: "Quick actions"
                popoutDetail: ""
            }

            RailEntry {
                icon: NetworkService.glyph
                iconColor: NetworkService.ethernetActive || NetworkService.wifiConnected
                    ? Theme.text : Theme.textMuted
                compact: true
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
                compact: true
                popouts: root.popouts
            }

            // Sound: hover pops out quick controls, click MUTES. pavucontrol
            // is reachable from exactly one place, the row inside the rollout.
            RailEntry {
                icon: AudioService.outputMuted ? "volume-muted" : "volume"
                iconColor: AudioService.outputMuted ? Theme.textMuted : Theme.text
                compact: true
                interactive: true
                popouts: root.popouts
                popoutKind: "sound"
                popoutTitle: "Sound"
                popoutDetail: ""
                onClicked: AudioService.toggleOutputMuted()
            }
        }

        RailDivider {}

        // Opens the session surface (08): a 32px cell, the glyph in danger.
        // Click, no hover card beyond its name.
        RailEntry {
            icon: "power"
            iconColor: Theme.danger
            compact: true
            interactive: true
            popouts: root.popouts
            popoutKind: "session"
            popoutTitle: "Session"
            popoutDetail: "Lock, log out, hibernate, restart, shut down"
            onClicked: ShellState.toggleModal("session")
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
