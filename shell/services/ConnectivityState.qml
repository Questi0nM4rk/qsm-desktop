import QtQuick

// NetworkManager's cached Internet state, separate from the Wi-Fi link state. A
// failed probe or an answer it does not know reads unknown; NetworkService's
// status decides what a state means and when it is news.
QtObject {
    id: root
    property string state: "unknown"
    readonly property var descriptions: ({
        full: "Internet available", limited: "Connected · Internet access limited",
        portal: "Sign in to the network", none: "No Internet connection", unknown: "Internet status unknown"
    })
    readonly property string description: descriptions[state]

    function observe(value: string): void {
        const next = value.trim().toLowerCase();
        state = Object.keys(descriptions).includes(next) ? next : "unknown";
    }
}
