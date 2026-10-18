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
// out), memory/storage 3/4-rings, a network card with a live sparkline,
// and a battery tank (UPower) when a battery exists. Every card/row hides
// individually when its sensor is missing.
ColumnLayout {
    id: root

    property var batteryDevice: UPower.displayDevice
    spacing: Theme.space3

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
            fill: tempRow.alert ? Theme.danger : Theme.accent
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
            Layout.preferredWidth: cpuContent.implicitWidth + Theme.space4 * 2
            Layout.preferredHeight: cpuContent.implicitHeight + Theme.space4 * 2

            ColumnLayout {
                id: cpuContent
                anchors.centerIn: parent
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
                }

                TempRow { Layout.alignment: Qt.AlignHCenter; tempC: PerformanceService.cpuTemp }
            }
        }

        // GPU hero card — hides entirely with no GPU sensor at all.
        QsmShellComponents.Card {
            visible: PerformanceService.gpuUsage >= 0 || PerformanceService.gpuTemp >= 0
            radius: Theme.panelCardRadius
            Layout.preferredWidth: gpuContent.implicitWidth + Theme.space4 * 2
            Layout.preferredHeight: gpuContent.implicitHeight + Theme.space4 * 2

            ColumnLayout {
                id: gpuContent
                anchors.centerIn: parent
                spacing: Theme.space2

                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    value: Math.max(0, PerformanceService.gpuUsage)
                    icon: "gpu"
                    reading: PerformanceService.gpuUsage < 0
                        ? "—" : `${Math.round(PerformanceService.gpuUsage * 100)}%`
                    label: "GPU"
                }

                TempRow { Layout.alignment: Qt.AlignHCenter; tempC: PerformanceService.gpuTemp }
            }
        }

        // Memory 3/4-ring.
        QsmShellComponents.Card {
            visible: PerformanceService.memUsed >= 0
            radius: Theme.panelCardRadius
            Layout.preferredWidth: memContent.implicitWidth + Theme.space4 * 2
            Layout.preferredHeight: memContent.implicitHeight + Theme.space4 * 2

            ColumnLayout {
                id: memContent
                anchors.centerIn: parent
                spacing: Theme.space2

                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    startAngle: Theme.ringQuarterStartAngle
                    sweepAngle: Theme.ringQuarterSweepAngle
                    value: Math.max(0, PerformanceService.memUsed)
                    icon: "memory"
                    reading: `${Math.round(PerformanceService.memUsed * 100)}%`
                    label: "Memory"
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    Layout.alignment: Qt.AlignHCenter
                    text: PerformanceService.memText
                }
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.space3

        // Storage 3/4-ring.
        QsmShellComponents.Card {
            visible: PerformanceService.storageUsed >= 0
            radius: Theme.panelCardRadius
            Layout.preferredWidth: storageContent.implicitWidth + Theme.space4 * 2
            Layout.preferredHeight: storageContent.implicitHeight + Theme.space4 * 2

            ColumnLayout {
                id: storageContent
                anchors.centerIn: parent
                spacing: Theme.space2

                QsmShellComponents.StatRing {
                    Layout.alignment: Qt.AlignHCenter
                    startAngle: Theme.ringQuarterStartAngle
                    sweepAngle: Theme.ringQuarterSweepAngle
                    value: Math.max(0, PerformanceService.storageUsed)
                    icon: "hard-drive"
                    reading: `${Math.round(PerformanceService.storageUsed * 100)}%`
                    label: "Storage"
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    Layout.alignment: Qt.AlignHCenter
                    text: PerformanceService.storageText
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

                    QsmShellComponents.Sparkline {
                        anchors.fill: parent
                        values: netGraph.rx
                        minimum: 0
                        maximum: netGraph.peak
                        // Two lines share this box, so the weight is stated:
                        // derived from the height they would be ~4.7px each
                        // and merge into one band.
                        thickness: 1.5
                        color: Theme.accent
                    }

                    QsmShellComponents.Sparkline {
                        anchors.fill: parent
                        values: netGraph.tx
                        minimum: 0
                        maximum: netGraph.peak
                        thickness: 1.5
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
            clip: true
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

            // Bottom-anchored liquid fill. Its own bottom corners carry the
            // card's radius: the card's `clip` is rectangular (Qt clips to the
            // bounding box, not the rounded shape), so a square-cornered fill
            // pushed its corners out through the card's rounding — visible at
            // any charge above about 90%. The top corners round only once the
            // fill reaches the card's own top curve.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * batteryCard.fraction
                bottomLeftRadius: Theme.panelCardRadius
                bottomRightRadius: Theme.panelCardRadius
                topLeftRadius: height > parent.height - Theme.panelCardRadius ? Theme.panelCardRadius : 0
                topRightRadius: topLeftRadius
                // A TINTED fill, not a solid accent one. At full charge a
                // solid accent tank was the single largest accent area in the
                // shell, spent on the most passive readout it has — and the
                // accent budget is what makes the interactive things stand
                // out (ui-craft: one accent budget). Tinted, the readout also
                // stays light-on-dark at every level, which is why the second
                // inverted-and-clipped copy of it is gone.
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)

                Behavior on height {
                    NumberAnimation { duration: Motion.normal; easing.type: Motion.standardEasing }
                }
            }

            BatteryReadout {
                anchors.centerIn: parent
                fg: Theme.text
                fgMuted: Theme.textMuted
                charging: batteryCard.charging
                fraction: batteryCard.fraction
                timeText: batteryCard.timeText
            }
        }
    }
}
