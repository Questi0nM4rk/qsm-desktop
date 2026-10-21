pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Idle-inhibitor state, owned once for the whole shell — per-monitor bar
// entries bind this instead of each running their own poll processes.
// The awake script is an external, delegated one.
QtObject {
    id: root

    readonly property string commandPath: Quickshell.shellPath("scripts/awake")
    property bool awake

    function refresh(): void {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function toggle(): void {
        toggleProcess.running = true;
    }

    property Process statusProcess: Process {
        command: ["bash", root.commandPath, "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.awake = text.trim() === "AWAKE"
        }
    }

    property Process toggleProcess: Process {
        command: ["bash", root.commandPath, "toggle"]
        onExited: root.refresh()
    }

    // Coarse safety-net poll for changes made outside the shell (terminal
    // toggles). Shell-origin changes refresh immediately via toggle(), and
    // hovering the entry refreshes before the popout shows its state.
    property Timer poll: Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
