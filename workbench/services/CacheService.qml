pragma Singleton

import QtQuick

QtObject {
    property bool busy: false
    property string lastResult: ""

    // What this in-memory stand-in was asked to do and when it finished
    // answering. A property change cannot say this: the second sweep of an
    // already-reported result changes nothing at all.
    signal operated(string operation, string phase, string value)

    function clean(): void {
        busy = true;
        operated("clearcache", "started", "");
        finished.restart();
    }

    function reset(): void {
        finished.stop();
        busy = false;
        lastResult = "";
    }

    property Timer finished: Timer {
        id: finished
        interval: 280
        onTriggered: {
            busy = false;
            lastResult = "Preview cache cleaned";
            // After the assignment: the record must carry the result the
            // surface is now showing, not the one it was about to show.
            operated("clearcache", "completed", lastResult);
        }
    }
}
