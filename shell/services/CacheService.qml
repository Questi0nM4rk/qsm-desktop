pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Cache reclaim. The rules that make it safe live in `scripts/clean-caches`
// (never touch /tmp by hand, age-trim ~/.cache, clear only pure derived data);
// this side owns the reading the UI shows afterwards.
//
// Reporting is not decoration here. The action is irreversible and fires from
// an unlabelled glyph, so "it did something, amount unknown" is not an
// acceptable outcome — the script prints the bytes it actually freed and that
// number comes back to the row that ran it.
QtObject {
    id: root

    readonly property string commandPath: Quickshell.shellPath("scripts/clean-caches")

    property bool busy
    // Empty until something has been cleaned this session. The UI shows it as
    // the action's trailing reading, so it doubles as "did this already run".
    property string lastResult

    function clean(): void {
        if (busy)
            return;

        busy = true;
        cleanProcess.running = true;
    }

    // Binary units, matched to how a disk reports itself. One decimal place
    // past MB because "1.4 GB" is the reading someone acts on and "1 GB" is
    // not — under a megabyte the decimal is noise, so it is dropped.
    function formatBytes(bytes: real): string {
        if (bytes < 1024)
            return `${Math.round(bytes)} B`;
        if (bytes < 1024 * 1024)
            return `${Math.round(bytes / 1024)} KB`;
        if (bytes < 1024 * 1024 * 1024)
            return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
        return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
    }

    property Process cleanProcess: Process {
        command: ["bash", root.commandPath]

        stdout: StdioCollector {
            onStreamFinished: {
                const freed = parseInt(text.trim(), 10);
                // A script that printed nothing parseable did not free
                // nothing — it failed, and saying "0 B" would report a
                // successful no-op for what was actually an error.
                root.lastResult = Number.isFinite(freed)
                    ? (freed > 0 ? `Freed ${root.formatBytes(freed)}` : "Already clean")
                    : "Clean failed";
            }
        }

        onExited: root.busy = false
    }
}
