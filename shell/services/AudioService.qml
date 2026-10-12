pragma Singleton

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool outputAvailable: !!sink?.ready && !!sink?.audio
    readonly property bool microphoneAvailable: !!source?.ready && !!source?.audio
    readonly property real outputValue: sink?.audio?.volume ?? 0
    readonly property bool outputMuted: !!sink?.audio?.muted
    readonly property real microphoneValue: source?.audio?.volume ?? 0
    readonly property bool microphoneMuted: !!source?.audio?.muted

    // Real output/input devices only — excludes playback/capture streams
    // (PwNodeType.AudioOutStream/AudioInStream), which share the Sink/Source
    // bits but are per-app streams, not switchable destinations.
    readonly property var sinks: (Pipewire.nodes?.values ?? [])
        .filter(node => (node.type & PwNodeType.AudioSink) === PwNodeType.AudioSink
            && (node.type & PwNodeType.AudioOutStream) !== PwNodeType.AudioOutStream)
    readonly property var sources: (Pipewire.nodes?.values ?? [])
        .filter(node => (node.type & PwNodeType.AudioSource) === PwNodeType.AudioSource
            && (node.type & PwNodeType.AudioInStream) !== PwNodeType.AudioInStream)

    function setDefaultSink(node: var): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: var): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setOutput(value: real): void {
        if (!outputAvailable)
            return;

        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setMicrophone(value: real): void {
        if (!microphoneAvailable)
            return;

        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleOutputMuted(): void {
        if (outputAvailable)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicrophoneMuted(): void {
        if (microphoneAvailable)
            source.audio.muted = !source.audio.muted;
    }

    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node !== null)
    }
}
