import QtQuick

// Two valid loss samples confirm an outage after online; unknown/probe failure
// never does. NetworkManager connectivity is separate from Wi-Fi link state.
QtObject {
    id: root
    property string state: "unknown"
    property bool previouslyOnline: false
    property bool outageReported: false
    property int lossSamples: 0
    readonly property var descriptions: ({
        full: "Internet available", limited: "Connected · Internet access limited",
        portal: "Sign in to the network", none: "No Internet connection", unknown: "Internet status unknown"
    })
    readonly property string description: descriptions[state]
    signal lost(string state)
    signal restored

    function observe(value: string): void {
        const next = value.trim().toLowerCase();
        state = Object.keys(descriptions).includes(next) ? next : "unknown";
        if (state === "unknown") { lossSamples = 0; return; }
        if (state === "full") {
            previouslyOnline = true;
            lossSamples = 0;
            if (outageReported) { outageReported = false; restored(); }
            return;
        }
        if (!previouslyOnline || outageReported) return;
        if (++lossSamples >= 2) { outageReported = true; lost(state); }
    }
    function reset(): void {
        state = "unknown";
        previouslyOnline = false;
        outageReported = false;
        lossSamples = 0;
    }
}
