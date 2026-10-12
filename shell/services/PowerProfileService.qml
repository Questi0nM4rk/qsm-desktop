pragma Singleton

import QtQuick
import Quickshell.Io

// powerprofilesctl state, shared by the battery glyph and the battery
// popout's switch row.
QtObject {
    id: root

    property string profile: ""
    // False when no profiles provider answers (no power-profiles-daemon and
    // no tuned-ppd). The popout says so instead of silently hiding its
    // switch row, which read as "this shell forgot the feature".
    property bool available: false

    // Per-profile glyph (shared by the rail status glyph and the popout's
    // segmented switch, which needs it for all three options, not just the
    // current one).
    function iconFor(name: string): string {
        return name === "power-saver" ? "leaf"
            : name === "performance" ? "zap"
            : "gauge";
    }

    readonly property string glyph: iconFor(profile)

    function refresh(): void {
        if (!probe.running)
            probe.running = true;
    }

    function setProfile(name: string): void {
        // Optimistic, then reconciled by refresh() when the setter exits (same
        // shape as AwakeService and NightLightService). The segmented switch's
        // indicator glides on this property, so waiting for
        // `powerprofilesctl get` to come back meant a press with no answer for
        // the length of a round trip — 09: every input gets a visible response,
        // and the acknowledgement is the shell's, not the tool's.
        root.profile = name;
        setter.command = Delegate.argv("powerProfile", ["set", name]);
        setter.running = true;
    }

    property Timer poll: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    property Process probe: Process {
        id: probe
        command: Delegate.argv("powerProfile", ["get"])

        stdout: StdioCollector {
            onStreamFinished: root.profile = text.trim()
        }

        // A missing binary exits non-zero (or never starts at all), which is
        // how we learn there is no provider to switch.
        onExited: exitCode => {
            root.available = exitCode === 0;
            if (!root.available)
                root.profile = "";
        }
    }

    property Process setter: Process {
        id: setter
        onExited: root.refresh()
    }
}
