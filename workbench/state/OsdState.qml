pragma Singleton

import QtQuick
import qs.services

QtObject {
    id: root

    property OsdPresentation presentation: OsdPresentation {
        id: presentationObject
    }
    property alias visible: presentationObject.visible
    property alias hovered: presentationObject.hovered
    property alias kind: presentationObject.kind
    property alias targetScreen: presentationObject.targetScreen
    property var screen: null
    property bool observing: false

    function show(control: string, target: var): bool {
        return presentation.show(control, target);
    }

    function showObserved(control: string): void {
        if (observing && screen !== null)
            show(control, screen);
    }

    function setHovered(value: bool): void {
        presentation.setHovered(value);
    }

    function setRetention(target: var, held: bool): void {
        presentation.setRetention(target, held);
    }

    function reset(): void {
        presentation.reset();
    }

    property Connections audioConnections: Connections {
        target: AudioService
        function onOutputValueChanged(): void { root.showObserved("output"); }
        function onOutputMutedChanged(): void { root.showObserved("output"); }
        function onMicrophoneValueChanged(): void { root.showObserved("microphone"); }
        function onMicrophoneMutedChanged(): void { root.showObserved("microphone"); }
    }

    property Connections brightnessConnections: Connections {
        target: BrightnessService
        function onValueChanged(): void {
            if (BrightnessService.initialized && !BrightnessService.reconciling)
                root.showObserved("brightness");
        }
    }
}
