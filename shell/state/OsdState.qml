pragma Singleton

import QtQuick
import qs.services

// Presentation state only: which OSD is up, where, and for how long.
// Values and mute flags live in AudioService/BrightnessService — sliders bind
// the services directly, so there is exactly one source of truth per control.
QtObject {
    id: root

    property OsdPresentation presentation: OsdPresentation { id: presentationObject }
    property alias visible: presentationObject.visible
    property alias hovered: presentationObject.hovered
    property alias kind: presentationObject.kind
    property alias targetScreen: presentationObject.targetScreen
    // Guards the service-change triggers below against the initial value
    // storm at startup, so logging in does not pop the OSD.
    property bool observing

    function show(control: string, screen: var): bool {
        return presentation.show(control, screen);
    }

    function showObserved(control: string): void {
        if (observing)
            show(control, ShellState.focusedScreen);
    }

    function setHovered(value: bool): void {
        presentation.setHovered(value);
    }

    function setRetention(screen: var, held: bool): void {
        presentation.setRetention(screen, held);
    }

    function reset(): void {
        presentation.reset();
    }

    Component.onCompleted: Qt.callLater(() => root.observing = true)

    property Connections audioConnections: Connections {
        target: AudioService

        function onOutputValueChanged(): void {
            root.showObserved("output");
        }

        function onOutputMutedChanged(): void {
            root.showObserved("output");
        }

        function onMicrophoneValueChanged(): void {
            root.showObserved("microphone");
        }

        function onMicrophoneMutedChanged(): void {
            root.showObserved("microphone");
        }
    }

    property Connections brightnessConnections: Connections {
        target: BrightnessService

        function onValueChanged(): void {
            // Not during a reconcile: that read exists to correct a value
            // something else changed while the user was away, and popping the
            // OSD for it would announce the shell's own bookkeeping.
            if (BrightnessService.initialized && !BrightnessService.reconciling)
                root.showObserved("brightness");
        }
    }
}
