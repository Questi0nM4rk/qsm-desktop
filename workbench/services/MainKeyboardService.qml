pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool available: true
    property bool disabled: false
    readonly property string glyph: root.available && root.disabled ? "keyboard-off" : "keyboard"
    readonly property bool busy: reply.running
    property bool nextFails: false
    property string error: ""
    readonly property string actionLabel: root.disabled ? "Enable main keyboard" : "Disable main keyboard"
    readonly property string description: root.busy ? "Updating main keyboard…"
        : root.error ? root.error + " · retry"
        : !root.available ? "Main keyboard unavailable"
        : root.disabled ? "Disabled · enable with Super+Ctrl+Shift+D or click"
        : "Enabled · disable with Super+Ctrl+D or click"
    signal operated(string operation, string phase, var value)

    function refresh(): void {}
    function toggle(): bool {
        if (!root.available || root.busy) return false;
        root.error = "";
        reply.restart();
        root.operated("main-keyboard", "pending", null);
        return true;
    }
    function reset(): void {
        reply.stop();
        root.available = true;
        root.disabled = false;
        root.nextFails = false;
        root.error = "";
    }
    property Timer reply: Timer {
        interval: 180
        onTriggered: {
            root.error = !root.available ? "Main keyboard unavailable"
                : root.nextFails ? "Could not change main keyboard state" : "";
            root.nextFails = false;
            if (!root.error) root.disabled = !root.disabled;
            root.operated("main-keyboard", root.error ? "failed" : "completed",
                { disabled: root.disabled, error: root.error });
        }
    }
}
