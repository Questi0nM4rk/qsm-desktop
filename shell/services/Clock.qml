pragma Singleton

import QtQuick
import Quickshell

// The wall clock every visible date and time reads. A visual test run names a
// fixed time in DRIVE_CLOCK ("YYYY-MM-DD HH:MM:SS", local time), so the rail,
// the calendar and the dashboard show the same moment on every run. One shared
// clock at minute precision: nothing on screen shows seconds.
Singleton {
    id: root

    readonly property string fixed: Quickshell.env("DRIVE_CLOCK") ?? ""
    readonly property date date: root.fixed.length > 0 ? new Date(root.fixed.replace(" ", "T")) : system.date

    SystemClock {
        id: system
        enabled: root.fixed.length === 0
        precision: SystemClock.Minutes
    }
}
