pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.components
import qs.services
import qs.theme

// Sound popout (03 AMENDED, owner-simplified): output-device list and
// input-device list as PopoutRows — click a device to make it the default,
// the current one carries the accent tick (a "Default" pill was never a
// control, and six pills in a 248px box left the device names 132px),
// a volume slider bound to the default sink (wheel-adjustable, OSD
// convention), and the "Sound settings" row. Deeper mixer controls stay with
// the delegated mixer (delegation law) — this popout never rebuilds it. The
// row is named for the JOB, not for the binary behind it: nobody wants to
// "open pavucontrol", they want sound settings.
ColumnLayout {
    id: root

    readonly property int activeSinkId: AudioService.sink?.id ?? -1
    readonly property int activeSourceId: AudioService.source?.id ?? -1
    signal interacted(string action, var payload)

    // Rows sit one step apart and a section starts a step clear of what
    // precedes it: whatever groups elements must have MORE space around the
    // group than within it.
    spacing: QsmShellStyle.Style.space1

    QsmShellComponents.Section {
        Layout.fillWidth: true
        title: "Output"

        Repeater {
            model: AudioService.sinks

            PopoutRow {
                required property var modelData
                Layout.fillWidth: true
                icon: "volume"
                label: modelData.nickname || modelData.description || modelData.name
                active: modelData.id === root.activeSinkId
                onClicked: { root.interacted("output-device", { id: modelData.id }); AudioService.setDefaultSink(modelData); }
            }
        }

        QsmShellComponents.Prose {
            role: "metadata"
            visible: AudioService.sinks.length === 0
            text: "No output devices"
        }

        RowLayout {
            Layout.topMargin: QsmShellStyle.Style.space1
            Layout.fillWidth: true
            spacing: QsmShellStyle.Style.space2

            QsmShellComponents.SvgIcon {
                name: AudioService.outputMuted ? "volume-muted" : "volume"
                size: QsmShellStyle.Style.iconSm
                color: Theme.textMuted
            }

            QsmShellComponents.Slider {
                id: outputSlider
                Layout.fillWidth: true
                value: AudioService.outputValue
                enabled: AudioService.outputAvailable
                Accessible.name: "Output volume"
                // Matches the OSD pill's nudge, so the wheel means the same amount
                // wherever you turn it at a volume.
                wheelUnits: Math.round(Theme.osdWheelStep / stepSize)
                onMoved: AudioService.setOutput(outputSlider.value)
                onCommitted: root.interacted("output-level", { value: outputSlider.value })
            }

            // Reserved for the widest reading, right-aligned, so 9% becoming 10%
            // never moves the slider's track.
            QsmShellComponents.Prose {
                id: outputReading
                role: "metadata"
                technical: true
                Layout.preferredWidth: widest.advanceWidth
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(AudioService.outputValue * 100)}%`

                TextMetrics {
                    id: widest
                    font: outputReading.font
                    text: "100%"
                }
            }
        }
    }

    QsmShellComponents.Section {
        Layout.fillWidth: true
        Layout.topMargin: QsmShellStyle.Style.space4
        title: "Input"

        Repeater {
            model: AudioService.sources

            PopoutRow {
                required property var modelData
                Layout.fillWidth: true
                icon: "microphone"
                label: modelData.nickname || modelData.description || modelData.name
                active: modelData.id === root.activeSourceId
                onClicked: { root.interacted("input-device", { id: modelData.id }); AudioService.setDefaultSource(modelData); }
            }
        }

        QsmShellComponents.Prose {
            role: "metadata"
            visible: AudioService.sources.length === 0
            text: "No input devices"
        }
    }

    // Deeper mixer controls stay with the real app (delegation law).
    QsmShellComponents.Capsule {
        size: "sm"
        Layout.topMargin: QsmShellStyle.Style.space1
        icon: "volume"
        label: "Sound settings"
        onClicked: { root.interacted("delegate", { target: "mixer" }); Delegate.open("mixer"); }
    }
}
