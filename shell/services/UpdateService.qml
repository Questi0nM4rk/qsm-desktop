pragma Singleton

import QtQuick
import Quickshell.Io
import qs.services

// Pending system updates (HyDE parity): a count the rail's
// updates cell wears as a badge, and ONE click action — the full upgrade in a
// terminal, exactly like the old HyDE icon.
//
// The count is passive and read-only: `checkupdates` compares the local sync
// database against installed packages, so it costs no network and never
// changes the system. The UPGRADE is the owner's explicit click; this service
// only hands the job to the delegated terminal (Delegate "upgrade" role) and
// re-counts once the upgrade has had time to finish.
QtObject {
    id: root

    // -1 = unknown (first run in flight, or the tool is missing); 0 = up to
    // date; N = packages waiting. The badge shows only N > 0, so an unknown
    // never lies as "zero".
    property int count: -1
    readonly property bool available: count > 0

    function refresh(): void {
        countProcess.running = true;
    }

    // The cell's one action (09 one-path): full upgrade in a terminal. The
    // count is re-read after a generous delay — an upgrade runs for minutes,
    // and re-reading early would just report the stale number again.
    function upgrade(): void {
        Delegate.open("upgrade");
        refreshAfterUpgrade.restart();
    }

    // Boot settle: the sync DB is local, but the shell starts beside a storm
    // of other startup work — give it a beat.
    property Timer bootTimer: Timer {
        interval: 5000
        running: true
        onTriggered: root.refresh()
    }

    // Periodic re-check (30min): the sync DB only changes on -Sy or an
    // upgrade, but a daily-driver machine does both without telling us.
    property Timer periodicTimer: Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    property Timer refreshAfterUpgrade: Timer {
        interval: 120 * 1000
        onTriggered: root.refresh()
    }

    property Process countProcess: Process {
        command: Delegate.argv("updates")
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                // One line per pending package; empty output = none.
                root.count = trimmed.length === 0 ? 0 : trimmed.split("\n").length;
            }
        }
        onExited: exitCode => {
            // checkupdates exits non-zero when there is nothing to do; that
            // is an ANSWER (count already 0), not a failure. 127 is the
            // shell's "command not found" — name the package rather than
            // going quiet (the colour editor's degraded-state law).
            if (exitCode === 127) {
                console.warn("UpdateService: checkupdates not found — install pacman-contrib");
                root.count = -1;
            }
        }
    }
}
