pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// Performance tab (06): three columns over two rows of one height. Row one is
// the CPU, GPU and memory rings (the memory card also carries the storage);
// row two is a network card with a live sparkline over two columns and, when
// a battery exists, its level over the third, so both rows share the column
// edges. CPU and memory read "—" until their first sample, the same as the
// dashboard; the GPU card and the battery come and go with their sensor.
ColumnLayout {
    id: root

    property var batteryDevice: UPower.displayDevice
    spacing: Theme.panelGap

    // The tab is the panel's content box: two rows of one height.
    readonly property real rowHeight: (Theme.panelContentHeight - spacing) / 2
    // One column of the three; the cards of a row split the width in these.
    readonly property real columnWidth: (Theme.panelContentWidth - spacing * 2) / 3

    // Icon + °C readout + thin thermal bar, shared by the CPU/GPU hero
    // cards. Flips to the danger color (icon swaps to alert-triangle) past
    // Theme.performanceThermalAlertC — hides entirely when the sensor is
    // missing (temp stays at PerformanceService's -1 sentinel).
    component TempRow: ColumnLayout {
        id: tempRow

        property int tempC: -1
        readonly property bool alert: tempC > Theme.performanceThermalAlertC

        visible: tempC >= 0
        spacing: QsmShellStyle.Style.space1

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: QsmShellStyle.Style.space1

            QsmShellComponents.SvgIcon {
                name: tempRow.alert ? "alert-triangle" : "thermometer"
                size: QsmShellStyle.Style.iconSm
                color: tempRow.alert ? Theme.danger : Theme.textMuted
            }

            QsmShellComponents.Prose {
                role: "metadata"
                technical: true
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
            Layout.preferredWidth: QsmShellStyle.Style.ringDiameter
            value: tempRow.tempC / Theme.performanceThermalScaleC
            fill: Theme.loadTone(value)
        }
    }

    // Battery readout: icon, percentage, what it is and the time left.
    component BatteryReadout: Column {
        id: readout

        required property color fg
        required property color fgMuted
        property bool charging: false
        property real fraction: 0
        property string timeText: ""

        spacing: QsmShellStyle.Style.space1

        QsmShellComponents.SvgIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: readout.charging ? "battery-charging" : "battery"
            size: QsmShellStyle.Style.iconLg
            color: readout.fg
        }

        QsmShellComponents.Prose {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "reading"
            font.pixelSize: QsmShellStyle.Style.textLg
            color: readout.fg
            text: `${Math.round(readout.fraction * 100)}%`
        }

        // Every other card on this tab names itself under its number; the
        // level read as a glyph and a percentage with nothing saying what of.
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

    // A ring card: the ring, then what belongs to it. The content hangs from
    // the card's top padding, so the rings of one row share a top and the
    // readings under them share theirs.
    component RingCard: QsmShellComponents.Card {
        default property alias content: column.data

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: root.columnWidth
        Layout.minimumWidth: 0

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: QsmShellStyle.Style.space4
            spacing: QsmShellStyle.Style.space2
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight
        spacing: root.spacing

        // CPU hero card.
        RingCard {
            // Every ring on this tab reads the same way: glyph, the
            // NUMBER, then what it is, so every card answers "how much?".
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

            Item { Layout.fillHeight: true }
        }

        // GPU hero card — hides entirely with no GPU sensor at all.
        RingCard {
            visible: PerformanceService.gpuUsage >= 0 || PerformanceService.gpuTemp >= 0

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

            Item { Layout.fillHeight: true }
        }

        // Memory ring; the storage is the second line under it, as bytes.
        RingCard {
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

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: QsmShellStyle.Style.space1

                QsmShellComponents.SvgIcon {
                    name: "hard-drive"
                    size: QsmShellStyle.Style.iconSm
                    color: Theme.textMuted
                }

                QsmShellComponents.Prose {
                    role: "metadata"
                    technical: true
                    text: PerformanceService.storageText || "—"
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight
        spacing: root.spacing

        // Network card: title, dual-line sparkline, download/upload rows. It
        // spans two columns and the graph takes the height the row sets.
        QsmShellComponents.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: root.columnWidth * 2 + root.spacing
            Layout.minimumWidth: 0

            ColumnLayout {
                id: networkContent
                anchors.fill: parent
                anchors.margins: QsmShellStyle.Style.space4
                spacing: QsmShellStyle.Style.space2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: QsmShellStyle.Style.space2

                    QsmShellComponents.SvgIcon { name: "activity"; size: QsmShellStyle.Style.iconSm; color: Theme.textMuted }

                    QsmShellComponents.Prose {
                        role: "title"
                        text: "Network"
                    }
                }

                // Down and up on ONE scale, so the two are comparable at a
                // glance: both Sparklines pin the same maximum instead of
                // each auto-scaling to its own peak, which would make a quiet
                // upload look like a busy one. Colour is not the accent (that
                // is for what is current): download is the text role, upload
                // the muted one, and the row glyphs carry the difference.
                Item {
                    id: netGraph

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Theme.performanceSparklineHeight

                    readonly property var rx: PerformanceService.netRxHistory
                    readonly property var tx: PerformanceService.netTxHistory
                    readonly property real peak: Math.max(1, ...rx, ...tx)
                    readonly property real lineThickness: QsmShellStyle.Style.stroke(QsmShellStyle.Style.hairline, netGraph)

                    // The zero line, always drawn: with no traffic both
                    // series sit on it, so idle reads as quiet rather than as
                    // a graph that failed to load.
                    QsmShellComponents.Divider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
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
                        color: Theme.text
                    }

                    QsmShellComponents.Sparkline {
                        anchors.fill: parent
                        values: netGraph.tx
                        minimum: 0
                        maximum: netGraph.peak
                        thickness: netGraph.lineThickness
                        color: Theme.textMuted
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: QsmShellStyle.Style.space2

                    QsmShellComponents.SvgIcon { name: "download"; size: QsmShellStyle.Style.iconSm; color: Theme.text }

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
                            font.pixelSize: QsmShellStyle.Style.textMd
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
                    spacing: QsmShellStyle.Style.space2

                    QsmShellComponents.SvgIcon { name: "upload"; size: QsmShellStyle.Style.iconSm; color: Theme.textMuted }

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
                            font.pixelSize: QsmShellStyle.Style.textMd
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

        // Battery card — present only when a battery exists.
        QsmShellComponents.Card {
            id: batteryCard
            visible: root.batteryDevice?.isLaptopBattery ?? false
            Layout.fillHeight: true
            Layout.preferredWidth: root.columnWidth
            Layout.minimumWidth: 0

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
            // means (healthy, low, critical), never by the accent. It takes the
            // card's inner width, so its padding is the card's like every other.
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: QsmShellStyle.Style.space4
                spacing: QsmShellStyle.Style.space3

                Item { Layout.fillHeight: true }

                BatteryReadout {
                    Layout.alignment: Qt.AlignHCenter
                    fg: Theme.text
                    fgMuted: Theme.textMuted
                    charging: batteryCard.charging
                    fraction: batteryCard.fraction
                    timeText: batteryCard.timeText
                }

                QsmShellComponents.Meter {
                    Layout.fillWidth: true
                    value: batteryCard.fraction
                    // The popout's own rule: danger only when low and not charging.
                    fill: batteryCard.fraction < Theme.lowBatteryFraction && !batteryCard.charging ? Theme.danger : Theme.text
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
