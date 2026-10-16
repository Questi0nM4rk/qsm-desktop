import QtQuick
import QtQuick.Layouts
import qs.services
import qs.state
import qs.theme

FocusScope {
    id: root

    required property var targetScreen

    // A captured drag may leave the pointer corridor; focus alone can outlive it.
    readonly property bool interactionHeld: outputChannel.pressed
        || microphoneChannel.pressed || brightnessChannel.pressed
    readonly property bool focusHeld: activeFocus
    readonly property OsdChannel outputTarget: outputChannel
    readonly property OsdChannel microphoneTarget: microphoneChannel
    readonly property OsdChannel brightnessTarget: brightnessChannel

    implicitWidth: channels.implicitWidth
    implicitHeight: channels.implicitHeight

    ColumnLayout {
        id: channels
        x: 0
        y: 0
        width: root.implicitWidth
        height: root.implicitHeight
        spacing: Theme.space3

        OsdChannel {
            id: outputChannel
            objectName: "output"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Theme.osdTrackHeight
                + outputChannel.topPadding + outputChannel.bottomPadding
            Layout.preferredWidth: Theme.osdWidth - Theme.space2 * 2
            icon: AudioService.outputMuted ? "volume-muted" : "volume"
            value: AudioService.outputValue
            muted: AudioService.outputMuted
            enabled: AudioService.outputAvailable
            emphasized: OsdState.kind === "output"
            onMoved: {
                AudioService.setOutput(outputChannel.value);
                OsdState.show("output", root.targetScreen);
            }
            onMuteToggled: {
                AudioService.toggleOutputMuted();
                OsdState.show("output", root.targetScreen);
            }
        }

        OsdChannel {
            id: microphoneChannel
            objectName: "microphone"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Theme.osdTrackHeight
                + microphoneChannel.topPadding + microphoneChannel.bottomPadding
            Layout.preferredWidth: Theme.osdWidth - Theme.space2 * 2
            visible: AudioService.microphoneAvailable || OsdState.kind === "microphone"
            icon: AudioService.microphoneMuted ? "microphone-muted" : "microphone"
            value: AudioService.microphoneValue
            muted: AudioService.microphoneMuted
            enabled: AudioService.microphoneAvailable
            emphasized: OsdState.kind === "microphone"
            onMoved: {
                AudioService.setMicrophone(microphoneChannel.value);
                OsdState.show("microphone", root.targetScreen);
            }
            onMuteToggled: {
                AudioService.toggleMicrophoneMuted();
                OsdState.show("microphone", root.targetScreen);
            }
        }

        OsdChannel {
            id: brightnessChannel
            objectName: "brightness"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Theme.osdTrackHeight
                + brightnessChannel.topPadding + brightnessChannel.bottomPadding
            Layout.preferredWidth: Theme.osdWidth - Theme.space2 * 2
            visible: BrightnessService.available
            icon: "brightness"
            mutable: false
            value: BrightnessService.value
            emphasized: OsdState.kind === "brightness"
            onMoved: {
                BrightnessService.setValue(brightnessChannel.value);
                OsdState.show("brightness", root.targetScreen);
            }
        }
    }
}
