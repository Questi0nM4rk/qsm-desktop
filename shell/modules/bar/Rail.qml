import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// The rail (03-rail lineup, owner-amended 2026-08-17): logo, workspace
// dots, PIN (under the dots), TRAY icons under the pin (owner 2026-08-24),
// then the current-workspace app list spread across the middle, and at the
// bottom the clock, the status cluster (quick actions, network, bluetooth,
// battery, sound) and power (danger-tinted). The popout interaction lives in
// the PopoutController.
Item {
    id: root

    required property var screen
    required property PopoutController popouts

    Column {
        id: topStack
        anchors.top: parent.top
        anchors.topMargin: Theme.space4
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.space3

        // The logo and update cell are one compact group; dividers preserve
        // the larger rhythm between this group and its neighbours.
        Column {
            width: parent.width
            spacing: 0

            // Logo: decorative — no click, no popout (03 DEFAULT).
            RailEntry {
                icon: "arch"
                iconSize: Theme.iconMd
                compact: true
            }

            // System updates (owner 2026-08-25, HyDE parity): lives in the logo's
            // group, directly under the arch mark. The badge carries the pending
            // count; click opens the full upgrade in a terminal — the ONE action,
            // same as the old HyDE icon. Hover names the state instead.
            RailEntry {
                interactive: true
                icon: "updates"
                compact: true
                iconColor: UpdateService.available ? Theme.accent : Theme.textMuted
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

        // Workspaces and the pin are ONE group (owner 2026-08-18): the pin
        // acts on the band the workspaces live in, so it belongs above the
        // divider with them, not alone between two lines.
        RailGroup {
            Column {
                width: parent.width
                spacing: Theme.space1

                WorkspaceStrip {
                    id: workspaces
                    width: parent.width
                    height: implicitHeight // plain Items do not self-adopt implicit size
                }

                // Pin/retract, per monitor: icon-swap, click only. Full-size
                // cell because pinning re-tiles every window on the monitor;
                // it stays visually secondary through its muted colour.
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

                // Tray icons live INSIDE this group, under the pin (owner
                // 2026-08-24), not in one of their own. Below the app list
                // they read as MORE APP ROWS — the owner's Discord icon sat
                // directly under his foot windows with only a divider claiming
                // otherwise. And a group of their own means a divider and a
                // gap that persist on a machine running nothing with a tray:
                // inside the group, no tray icons is simply nothing to see.
                //
                // Clicking one rolls out its DBusMenu (03 RATIFIED).
                Repeater {
                    model: SystemTray.items.values

                    Item {
                        id: trayEntry
                        required property var modelData

                        width: parent.width
                        // The group's own rhythm, not the 26px row these had
                        // in their old group: measured live at y=195 beside a
                        // 40px pin, a 26px row read as a half-height cell and
                        // gave the smallest hit target in the band (audit F10
                        // flagged the same value as off-ladder).
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

    // The middle section: current workspace's apps, top-aligned under the
    // workspace group so the whole rail is one 40px rhythm; names and live
    // titles are in the hover popout.
    RailAppList {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topStack.bottom
        anchors.bottom: bottomStack.top
        anchors.topMargin: Theme.space3
        // Reserve a full divider boundary before the independent clock group:
        // 12px after the app list, the 8px divider, then 12px before the clock.
        anchors.bottomMargin: Theme.space6
        screen: root.screen
        popouts: root.popouts
    }

    RailDivider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomStack.top
        anchors.bottomMargin: Theme.space3
    }

    Column {
        id: bottomStack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space4
        spacing: Theme.space3

        ClockEntry {
            popouts: root.popouts
        }

        RailDivider {}

        // Status cluster (caelestia's StatusIcons, owner keepers included):
        // quick actions, network, bluetooth (one cell, whatever is connected),
        // battery, sound. Every cell behaves the same: hover rolls out, click
        // does that cell's one cheap toggle, the rollout owns any escape to a
        // real app. Glyphs are DYNAMIC — state shows by icon-swap, never a glow.
        RailGroup {
            ColumnLayout {
                width: parent.width
                spacing: 0

                // Quick actions (owner 2026-08-20) — where the coffee cup used
                // to be. The cup itself moved INSIDE: keeping awake is one
                // quality-of-life toggle among several, and one cell that
                // rolls out four beats four cells competing for band height.
                // Hover only; there is nothing for a click to do that the
                // column does not do better.
                RailEntry {
                    icon: "zap"
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
                    compact: true
                    interactive: true
                    popouts: root.popouts
                    popoutKind: "network"
                    clickable: false
                    popoutTitle: "Network"
                    popoutDetail: ""
                }

                // Bluetooth: ONE cell that becomes what is connected, and
                // subdivides up to four ways. Never more than one cell, so it
                // cannot squash the clock above it.
                RailDeviceCell {
                    compact: true
                    popouts: root.popouts
                }

                RailEntry {
                    id: batteryCell

                    readonly property var battery: UPower.displayDevice
                    readonly property bool laptop: battery?.isLaptopBattery ?? false
                    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
                    readonly property real charge: battery?.percentage ?? 0
                    readonly property bool low: laptop && !charging && charge <= 0.2

                    // The NUMBER, not a glyph (owner 2026-09-05). Four battery
                    // icons answer "roughly how full" with a shape you have to
                    // learn; the reading answers it outright, and it is the
                    // thing anyone actually wants off a battery cell. A machine
                    // with no battery still shows its power profile, because
                    // there is no percentage to show there.
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
                        // The charge reading (03 RATIFIED 2026-09-05: the
                        // number, not a battery glyph) — a value, technical
                        // face by role default.
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

                // Sound: hover pops out quick controls, click MUTES. pavucontrol
                // is reachable from exactly one place — the "Open pavucontrol"
                // row inside the rollout (owner 2026-08-18: two doors to the
                // same action is two doors too many). Click is the cheap,
                // frequent, reversible toggle, like pin and coffee.
                RailEntry {
                    icon: AudioService.outputMuted ? "volume-muted" : "volume"
                    compact: true
                    interactive: true
                    popouts: root.popouts
                    popoutKind: "sound"
                    popoutTitle: "Sound"
                    popoutDetail: ""
                    onClicked: AudioService.toggleOutputMuted()
                }

            }
        }

        RailDivider {}

        // Opens the session surface (08) — its OWN group, so it gets its own
        // line above it. Click, no hover popout; keeps its danger-tinted
        // background while every other group lost theirs.
        RailEntry {
            icon: "power"
            iconColor: Theme.danger
            danger: true
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
