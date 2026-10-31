pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The wall clock every visible date and time reads: the `date` command's
// answer, asked again at each turn of the minute (nothing on screen shows
// seconds). A visual test run puts a `date` on PATH that answers its fixed
// moment, so the rail, the calendar and the dashboard show the same one.
Singleton {
    id: root

    // Invalid (shown as no text) until `date` first answers: a first frame
    // of another moment, replaced a moment later, left the rail clock's
    // glyphs with grayscale instead of subpixel antialiasing (measured).
    property date date: new Date(NaN)

    Process {
        id: ask
        command: ["date", "+%Y-%m-%dT%H:%M:%S"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const now = new Date(text.trim());
                root.date = now;
                minute.interval = (60 - now.getSeconds()) * 1000;
                minute.restart();
            }
        }
    }

    Timer {
        id: minute
        onTriggered: ask.running = true
    }
}
