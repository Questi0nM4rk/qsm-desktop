pragma Singleton

import QtQuick

QtObject {
    property real outputValue: 0.62
    property bool outputMuted: false
    property bool outputAvailable: true
    property real microphoneValue: 0.38
    property bool microphoneMuted: false
    property bool microphoneAvailable: true
    readonly property var sinks: []
    readonly property var sources: []
    readonly property var sink: null
    readonly property var source: null

    signal operated(string operation, string phase, var value)

    function setOutput(value: real): void {
        if (!outputAvailable)
            return;
        outputValue = Math.max(0, Math.min(1, value));
        outputMuted = false;
        operated("output-level", "completed", outputValue);
    }

    function setMicrophone(value: real): void {
        if (!microphoneAvailable)
            return;
        microphoneValue = Math.max(0, Math.min(1, value));
        microphoneMuted = false;
        operated("microphone-level", "completed", microphoneValue);
    }

    function toggleOutputMuted(): void {
        if (!outputAvailable)
            return;
        outputMuted = !outputMuted;
        operated("output-mute", "completed", outputMuted);
    }

    function toggleMicrophoneMuted(): void {
        if (!microphoneAvailable)
            return;
        microphoneMuted = !microphoneMuted;
        operated("microphone-mute", "completed", microphoneMuted);
    }

    function reset(): void {
        outputAvailable = true;
        outputValue = 0.62;
        outputMuted = false;
        microphoneValue = 0.38;
        microphoneMuted = false;
        microphoneAvailable = true;
    }
}
