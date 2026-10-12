pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string commandPath: Quickshell.shellPath("scripts/main-keyboard")
    property bool available: false
    property bool disabled: false
    readonly property string glyph: root.available && root.disabled ? "keyboard-off" : "keyboard"
    readonly property bool busy: operation.running
    property string operationError: ""
    property string statusFailure: ""
    property int stateRevision: 0
    readonly property string error: root.operationError || root.statusFailure
    readonly property string actionLabel: root.disabled ? "Enable main keyboard" : "Disable main keyboard"
    readonly property string description: root.busy ? "Updating main keyboard…"
        : root.error ? root.error + " · retry"
        : !root.available ? "Main keyboard unavailable"
        : root.disabled ? "Disabled · enable with Super+Ctrl+Shift+D or click"
        : "Enabled · disable with Super+Ctrl+D or click"
    signal operated(string operation, string phase, var value)

    function readState(text: string): bool {
        const state = text.trim();
        if (state !== "ENABLED" && state !== "DISABLED") return false;
        root.disabled = state === "DISABLED";
        root.available = true;
        return true;
    }

    function refresh(): void {
        if (statusProcess.running || root.busy) return;
        statusProcess.revision = root.stateRevision;
        statusProcess.running = true;
    }

    function toggle(): bool {
        if (!root.available || root.busy) return false;
        root.operationError = "";
        root.stateRevision++;
        operation.running = true;
        root.operated("main-keyboard", "pending", null);
        return true;
    }

    property Process statusProcess: Process {
        id: statusProcess
        property int revision: 0
        command: ["bash", root.commandPath, "status"]
        stdout: StdioCollector { id: statusOutput }
        stderr: StdioCollector { id: statusError }
        // Quickshell metadata omits QProcess::ExitStatus; it is present at runtime.
        // qmllint disable signal-handler-parameters
        onExited: (code, exitStatus) => {
            if (root.busy || statusProcess.revision !== root.stateRevision) return;
            root.available = exitStatus === 0 && code === 0 && root.readState(statusOutput.text);
            root.statusFailure = root.available ? ""
                : statusError.text.trim() || "Could not read main keyboard state";
        }
        // qmllint enable signal-handler-parameters
    }

    property Process operation: Process {
        id: operation
        command: ["bash", root.commandPath, "toggle"]
        stdout: StdioCollector { id: operationOutput }
        stderr: StdioCollector { id: operationErrorOutput }
        // qmllint disable signal-handler-parameters
        onExited: (code, exitStatus) => {
            const succeeded = exitStatus === 0 && code === 0 && root.readState(operationOutput.text);
            root.operationError = succeeded ? ""
                : operationErrorOutput.text.trim() || "Could not change main keyboard state";
            if (succeeded) root.statusFailure = "";
            root.operated("main-keyboard", succeeded ? "completed" : "failed",
                { disabled: root.disabled, error: root.error });
            root.refresh();
        }
        // qmllint enable signal-handler-parameters
    }

    property Timer poll: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    Component.onCompleted: root.refresh()
}
