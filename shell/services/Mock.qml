pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The one place a visual test run puts the readings the desktop shows instead
// of the machine's: named records (uptime, performance, processes). They come from the JSON file in DRIVE_MOCK, read blocking
// so the first frame has them, and change during a run only through the
// `mock` IPC call. A service shows its record when there is one and its live
// source when there is none; a run without DRIVE_MOCK has no records at all.
QtObject {
    id: root

    property var records: ({})

    function set(name: string, value: var): void {
        const next = Object.assign({}, root.records);
        next[name] = value;
        root.records = next;
    }

    property FileView file: FileView {
        path: Quickshell.env("DRIVE_MOCK") ?? ""
        blockLoading: true
        onLoaded: root.records = JSON.parse(text())
        onLoadFailed: error => {
            if (path.length > 0)
                console.error("Mock: cannot read", path, error);
        }
    }
}
