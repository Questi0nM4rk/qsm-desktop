import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.theme

// Performance tab (06 RATIFIED bullet superseded 2026-08-17 owner
// caelestia-parity ruling: this replaces the "three rings" anatomy with
// caelestia's card grid, simplified per owner keep-it-simple — no
// decorative morphing blob). CPU/GPU hero cards (usage ring + temp read-
// out), memory/storage rings, a network card with a live sparkline, and a
// battery tank (UPower) when a battery exists. CPU, memory and storage are
// always there and read "—" until their first sample, the same as the
// dashboard; the GPU card and the battery tank come and go with their sensor.
ColumnLayout {
    id: root

    property var batteryDevice: UPower.displayDevice
    spacing: Theme.space3

    // Every ring card is one width: its readout elides inside the ring's
    // diameter, so a ticking number never resizes the card or its neighbours.
    readonly property real ringCardWidth: Theme.ringDiameterDefault + Theme.space4 * 2

    // Icon + °C readout + thin thermal bar, shared by the CPU/GPU hero
    // cards. Flips to the danger color (icon swaps to alert-triangle) past
    // Theme.performanceThermalAlertC — hides entirely when the sensor is
    // missing (temp stays at PerformanceService's -1 sentinel).
    component TempRow: ColumnLayout {
        id: tempRow

        property int tempC: -1
        readonly property bool alert: tempC > Theme.performanceThermalAlertC

        visible: tempC >= 0
        spacing: Theme.space1

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.space1

            QsmShellComponents.SvgIcon {
                name: tempRow.alert ? "alert-triangle" : "thermometer"
                size: Theme.iconSm
                color: tempRow.alert ? Theme.danger : Theme.textMuted
            }

            QsmShellComponents.Prose {
                role: "reading"
                font.pixelSize: Theme.textXs
                color: tempRow.alert ? Theme.danger : Theme.textMuted
                text: `${tempRow.tempC}°`
            }
        }

        // The library's level bar. `high` is left unset deliberately: Meter
        // paints a breached threshold as WARNING, and an overheating CPU is a
        // failure rather than a caution here, so this passes the colour it
        // means through `fill`.
        QsmShellComponents.Meter {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Theme.ringDiameterDefault
            thickness: Theme.performanceThermalBarHeight
            value: tempRow.tempC / Theme.performanceThermalScaleC
            fill: Theme.loadTone(value)
        }
    }

    // Battery tank readout (icon + % + time remaining), rendered twice by
    // the tank card below: once in normal colors, once inverted and
    // clipped to the liquid fill so text stays legible in both zones.
    component BatteryReadout: Column {
        id: readout

        required property color fg
        required property color fgMuted
        property bool charging: false
        property real fraction: 0
        property string timeText: ""

        spacing: Theme.space1

        QsmShellComponents.SvgIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: readout.charging ? "battery-charging" : "battery"
            size: Theme.iconLg
            color: readout.fg
        }

        QsmShellComponents.Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "reading"
            font.pixelSize: Theme.textLg
            color: readout.fg
            text: `${Math.round(readout.fraction * 100)}%`
        }

        // Every other card on this tab names itself under its number; the
        // tank read as a glyph and a percentage with nothing saying what of.
        QsmShellComponents.Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "metadata"
            color: readout.fgMuted
            text: "Battery"
        }

        QsmShellComponents.Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "metadata"
            visible: readout.timeText.length > 0
            color: readout.fgMuted
            text: readout.timeText
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.space3

        // CPU hero card.
        QsmShellComponents.Card {
            radius: Theme.panelCardRadius
            Layout.preferredWidth: root.ringCardWidth
            Layout.preferredHeight: cpuContent.implicitHeight + Theme.space4 * 2
            Layout.fillHeight: true

            ColumnLayout {
                id: cpuContent
                anchors.centerIn: parent
                width: Theme.ringDiameterDefault
                spacing: Theme.space2

                // Every ring on this tab reads the same way: glyph, the
                // NUMBER, then what it is. CPU and GPU used to show a glyph
                // and a name with no number at all, so two of the four cards
                // answered "how much?" and two did not.
                //
                // Usage is -1 until the SECOND /proc/stat sample — a rate needs
                // two readings — and printing that as "0%" claims an idle
                // machine when the truth is "not measured yet".
                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    value: Math.max(0, PerformanceService.cpuUsage)
                    icon: "cpu"
                    reading: PerformanceService.cpuUsage < 0
                        ? "—" : `${Math.round(PerformanceService.cpuUsage * 100)}%`
                    label: "CPU"
                    fill: Theme.loadTone(PerformanceService.cpuUsage)
                }

                TempRow { Layout.alignment: Qt.AlignHCenter; tempC: PerformanceService.cpuTemp }
            }
        }

        // GPU hero card — hides entirely with no GPU sensor at all.
        QsmShellComponents.Card {
            visible: PerformanceService.gpuUsage >= 0 || PerformanceService.gpuTemp >= 0
            radius: Theme.panelCardRadius
            Layout.preferredWidth: root.ringCardWidth
            Layout.preferredHeight: gpuContent.implicitHeight + Theme.space4 * 2
            Layout.fillHeight: true

            ColumnLayout {
                id: gpuContent
                anchors.centerIn: parent
                width: Theme.ringDiameterDefault
                spacing: Theme.space2

                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    value: Math.max(0, PerformanceService.gpuUsage)
                    icon: "gpu"
                    reading: PerformanceService.gpuUsage < 0
                        ? "—" : `${Math.round(PerformanceService.gpuUsage * 100)}%`
                    label: "GPU"
                    fill: Theme.loadTone(PerformanceService.gpuUsage)
                }

                TempRow { Layout.alignment: Qt.AlignHCenter; tempC: PerformanceService.gpuTemp }
            }
        }

        // Memory ring.
        QsmShellComponents.Card {
            radius: Theme.panelCardRadius
            Layout.preferredWidth: root.ringCardWidth
            Layout.preferredHeight: memContent.implicitHeight + Theme.space4 * 2
            Layout.fillHeight: true

            ColumnLayout {
                id: memContent
                anchors.centerIn: parent
                width: Theme.ringDiameterDefault
                spacing: Theme.space2

                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    value: Math.max(0, PerformanceService.memUsed)
                    icon: "memory"
                    reading: PerformanceService.memUsed < 0
                        ? "—" : `${Math.round(PerformanceService.memUsed * 100)}%`
                    label: "Memory"
                    fill: Theme.loadTone(PerformanceService.memUsed)
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: PerformanceService.memText || "—"
                }
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.space3

        // Storage ring.
        QsmShellComponents.Card {
            radius: Theme.panelCardRadius
            Layout.preferredWidth: root.ringCardWidth
            Layout.preferredHeight: storageContent.implicitHeight + Theme.space4 * 2
            Layout.fillHeight: true

            ColumnLayout {
                id: storageContent
                anchors.centerIn: parent
                width: Theme.ringDiameterDefault
                spacing: Theme.space2

                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    value: Math.max(0, PerformanceService.storageUsed)
                    icon: "hard-drive"
                    reading: PerformanceService.storageUsed < 0
                        ? "—" : `${Math.round(PerformanceService.storageUsed * 100)}%`
                    label: "Storage"
                    fill: Theme.loadTone(PerformanceService.storageUsed)
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: PerformanceService.storageText || "—"
                }
            }
        }

        // Network card: title, dual-line sparkline, download/upload rows.
        //
        // Height follows the ROW (the storage ring beside it is the tallest
        // thing here) and the graph takes the slack. A fixed 220 against ~152
        // of content left about 68px of card reserved and never used, which is
        // the tell of a box drawn before its contents were known.
        QsmShellComponents.Card {
            radius: Theme.panelCardRadius
            Layout.preferredWidth: Theme.performanceNetworkCardWidth
            Layout.minimumHeight: networkContent.implicitHeight + Theme.space4 * 2
            Layout.fillHeight: true

            ColumnLayout {
                id: networkContent
                anchors.fill: parent
                anchors.margins: Theme.space4
                spacing: Theme.space2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space2

                    QsmShellComponents.SvgIcon { name: "activity"; size: Theme.iconSm; color: Theme.textMuted }

                    QsmShellComponents.Prose {
                        role: "title"
                        text: "Network"
                    }
                }

                // Down and up on ONE scale, so the two are comparable at a
                // glance: both Sparklines pin the same maximum instead of
                // each auto-scaling to its own peak, which would make a quiet
                // upload look like a busy one.
                Item {
                    id: netGraph

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Theme.performanceSparklineHeight

                    readonly property var rx: PerformanceService.netRxHistory
                    readonly property var tx: PerformanceService.netTxHistory
                    readonly property real peak: Math.max(1, ...rx, ...tx)
                    readonly property real lineThickness: Theme.sparklineThickness

                    // The zero line, always drawn: with no traffic both
                    // series sit on it, so idle reads as quiet rather than as
                    // a graph that failed to load.
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: netGraph.lineThickness
                        radius: height / 2
                        color: Theme.overlay
                    }

                    QsmShellComponents.Sparkline {
                        anchors.fill: parent
                        values: netGraph.rx
                        minimum: 0
                        maximum: netGraph.peak
                        // Two lines share this box, so the weight is stated:
                        // derived from the height they would be ~4.7px each
                        // and merge into one band.
                        thickness: netGraph.lineThickness
                        color: Theme.accent
                    }

                    QsmShellComponents.Sparkline {
                        anchors.fill: parent
                        values: netGraph.tx
                        minimum: 0
                        maximum: netGraph.peak
                        thickness: netGraph.lineThickness
                        color: Theme.info
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space2

                    QsmShellComponents.SvgIcon { name: "download"; size: Theme.iconSm; color: Theme.accent }

                    QsmShellComponents.Prose {
                        role: "metadata"
                        text: "Download"
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0

                        QsmShellComponents.Prose {
                            role: "reading"
                            Layout.alignment: Qt.AlignRight
                            // The RATE is what the row is about. At the caption
                            // size it read as one of three equal numbers next to
                            // its own label and its session total; size carries
                            // the hierarchy here, not colour alone.
                            font.pixelSize: Theme.textMd
                            text: PerformanceService.netRxRateText
                        }

                        QsmShellComponents.Prose {
                            role: "metadata"
                            technical: true
                            Layout.alignment: Qt.AlignRight
                            text: PerformanceService.netRxTotalText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space2

                    QsmShellComponents.SvgIcon { name: "upload"; size: Theme.iconSm; color: Theme.info }

                    QsmShellComponents.Prose {
                        role: "metadata"
                        text: "Upload"
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0

                        QsmShellComponents.Prose {
                            role: "reading"
                            Layout.alignment: Qt.AlignRight
                            // The RATE is what the row is about. At the caption
                            // size it read as one of three equal numbers next to
                            // its own label and its session total; size carries
                            // the hierarchy here, not colour alone.
                            font.pixelSize: Theme.textMd
                            text: PerformanceService.netTxRateText
                        }

                        QsmShellComponents.Prose {
                            role: "metadata"
                            technical: true
                            Layout.alignment: Qt.AlignRight
                            text: PerformanceService.netTxTotalText
                        }
                    }
                }
            }
        }

        // Battery tank (caelestia "liquid" card) — present only when a
        // battery exists.
        QsmShellComponents.Card {
            id: batteryCard
            visible: root.batteryDevice?.isLaptopBattery ?? false
            radius: Theme.panelCardRadius
            Layout.preferredWidth: Theme.performanceBatteryTankWidth
            Layout.preferredHeight: Theme.performanceBatteryTankHeight

            readonly property var device: root.batteryDevice
            readonly property real fraction: Math.max(0, Math.min(1, device?.percentage ?? 0))
            readonly property bool charging: device?.state === UPowerDeviceState.Charging
            readonly property string timeText: {
                const seconds = charging ? device?.timeToFull : device?.timeToEmpty;
                if (!(seconds > 0))
                    return "";
                const hours = Math.floor(seconds / 3600);
                const minutes = Math.floor((seconds % 3600) / 60);
                return `${hours}h ${minutes}m ${charging ? "to full" : "left"}`;
            }

            // The level is a thin meter on the overlay track, filled by what it
            // means (healthy, low, critical), never by the accent: the old tank
            // painted a tinted accent block behind the text and dragged its
            // caption under 3:1. The text stays on the plain card.
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.space3

                BatteryReadout {
                    Layout.alignment: Qt.AlignHCenter
                    fg: Theme.text
                    fgMuted: Theme.textMuted
                    charging: batteryCard.charging
                    fraction: batteryCard.fraction
                    timeText: batteryCard.timeText
                }

                QsmShellComponents.Meter {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Theme.ringDiameterDefault
                    thickness: Theme.performanceThermalBarHeight
                    value: batteryCard.fraction
                    // The popout's own rule: danger only when low and not charging.
                    fill: batteryCard.fraction < Theme.lowBatteryFraction && !batteryCard.charging ? Theme.danger : Theme.success
                }
            }
        }
    }
}
