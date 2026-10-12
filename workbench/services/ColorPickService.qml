pragma Singleton

import QtQuick

QtObject {
    readonly property string notifyAppName: "Colour picker"
    property bool busy: false
    property string lastColor: "#C5A5E9"
    property var history: ["#C5A5E9", "#91D6C2", "#E8C58A"]
    property string copied: ""
    property bool editing: false
    property bool editorAvailable: true

    // What this in-memory stand-in was asked to do and what it answered with.
    // Copying the same hex twice is a real operation that changes no property
    // at all, so the record cannot come from the state.
    signal operated(string operation, string phase, string value)

    function remember(value: string): void {
        history = [value].concat(history.filter(entry => entry !== value)).slice(0, 24);
    }

    function forget(value: string): void {
        history = history.filter(entry => entry !== value);
    }

    function copy(value: string): void {
        if (value.length === 0)
            return;
        copied = value;
        copiedSettle.restart();
        operated("copy", "completed", value);
    }

    function pick(): void {
        if (busy)
            return;
        busy = true;
        operated("pick", "started", "");
        picked.restart();
    }

    function edit(value: string): void {
        if (editing || value.length === 0)
            return;
        editing = true;
        operated("edit", "started", value);
        edited.restart();
    }

    function reset(): void {
        picked.stop();
        edited.stop();
        copiedSettle.stop();
        busy = false;
        lastColor = "#C5A5E9";
        history = ["#C5A5E9", "#91D6C2", "#E8C58A"];
        copied = "";
        editing = false;
        editorAvailable = true;
    }

    property Timer picked: Timer {
        id: picked
        interval: 260
        onTriggered: {
            lastColor = "#9FC2EA";
            remember(lastColor);
            copy(lastColor);
            busy = false;
            operated("pick", "completed", lastColor);
        }
    }

    property Timer edited: Timer {
        id: edited
        interval: 260
        onTriggered: {
            lastColor = "#E1B7E1";
            remember(lastColor);
            copy(lastColor);
            editing = false;
            operated("edit", "completed", lastColor);
        }
    }

    property Timer copiedSettle: Timer {
        id: copiedSettle
        interval: 1600
        onTriggered: copied = ""
    }
}
