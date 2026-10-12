pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available
    property bool initialized
    // True while a reconcile read is in flight. The value may change during
    // one, but nobody asked for it, so the OSD must not roll out — OsdState
    // reads this to tell "the user pressed a key" apart from "we noticed
    // someone else moved it".
    property bool reconciling
    property real value
    property real queuedValue: NaN
    property real restoreValue: 1
    // A read started before a user write reports the old backlight level. Tag
    // reads so that stale result cannot replace the UI's optimistic response.
    property int changeGeneration: 0
    property int readGeneration: 0

    function bounded(value: real): real {
        return Math.max(0.01, Math.min(1, value));
    }

    function refresh(): void {
        // A read started while brightnessctl is writing can sample the old
        // value. A failed write already refreshes after it exits.
        if (writeProcess.running)
            return;
        if (!readProcess.running) {
            readGeneration = changeGeneration;
            readProcess.running = true;
        }
    }

    function setValue(nextValue: real): void {
        const target = bounded(nextValue);
        if (!available)
            return;
        if (writeProcess.running) {
            queuedValue = target;
            return;
        }

        changeGeneration += 1;
        value = target;
        writeProcess.command = ["brightnessctl", "set", `${Math.round(target * 100)}%`];
        writeProcess.running = true;
    }

    // Keyboard-only brightness action: dim to the lowest usable level, then
    // return to exactly the level the user was working at.
    function toggle(): void {
        if (!available)
            return;

        if (value <= 0.01) {
            setValue(restoreValue);
            return;
        }

        restoreValue = value;
        setValue(0.01);
    }

    // Reconcile with reality. The shell should be the only thing writing this
    // backlight now that the keys route through it, but hypridle's dim
    // listener still does (brightnessctl -s / -r around the idle window), and
    // sysfs announces nothing — so without a slow poll the slider keeps
    // reporting the pre-dim value and the next key press steps from a number
    // that is no longer true.
    property Timer reconcileTimer: Timer {
        interval: 30000
        repeat: true
        running: root.initialized
        onTriggered: {
            if (root.writeProcess.running)
                return;
            root.reconciling = true;
            root.refresh();
        }
    }

    property Process readProcess: Process {
        id: readProcess
        command: Delegate.argv("brightness", ["-m"])
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/,(\d+)%/);
                root.available = match !== null;
                if (match && root.readGeneration === root.changeGeneration
                        && !root.writeProcess.running)
                    root.value = root.bounded(parseInt(match[1], 10) / 100);
            }
        }

        onExited: exitCode => {
            root.available = exitCode === 0 && root.available;
            root.initialized = true;
            root.reconciling = false;
        }
    }

    property Process writeProcess: Process {
        id: writeProcess

        onExited: exitCode => {
            // `value` was already set optimistically in setValue; only a
            // failed write needs a re-read to resync with reality. The old
            // unconditional refresh spawned a read process per slider step.
            if (!isNaN(root.queuedValue)) {
                const nextValue = root.queuedValue;
                root.queuedValue = NaN;
                root.setValue(nextValue);
            } else if (exitCode !== 0) {
                root.refresh();
            }
        }
    }
}
