import QtQuick

// The network's one status and how it reads, from what NetworkManager last
// said: shared by NetworkService and the workbench's fixture, so a story shows
// the status the shell computes. NetworkManager's Internet state is separate
// from the link: a failed probe or an answer it does not know reads unknown.
QtObject {
    id: root

    // NetworkManager answered the last device read.
    property bool available: true
    // That read's rows, [type, state, connection, device], wired and Wi-Fi only.
    property var rows: []
    property bool wifiEnabled: false
    property int wifiSignal: 0
    property string internet: "unknown"
    readonly property var descriptions: ({
        full: "Internet available", limited: "Connected · Internet access limited",
        portal: "Sign in to the network", none: "No Internet connection", unknown: "Internet status unknown"
    })
    readonly property string internetDescription: descriptions[internet]

    readonly property var cable: rows.find(row => row[0] === "ethernet" && row[1] === "connected")
    readonly property var wifiRow: rows.find(row => row[0] === "wifi" && row[1] === "connected")
    readonly property bool ethernetActive: !!cable
    readonly property bool wifiConnected: !!wifiRow
    readonly property bool wifiAvailable: rows.some(row => row[0] === "wifi")
    readonly property bool linkConnecting: rows.some(row => row[1].startsWith("connecting"))
    readonly property bool linkUp: ethernetActive || wifiConnected
    // The connection the status names: the cable's, else the Wi-Fi's.
    readonly property string linkName: (cable ?? wifiRow)?.[2] ?? ""

    // The first that holds (owner: a problem before a connection). Portal and
    // offline need a link, because NetworkManager reports no Internet for a
    // machine with no link at all as well.
    readonly property string status: !available ? "unavailable"
        : linkUp && internet === "portal" ? "portal"
        : linkUp && (internet === "none" || internet === "limited") ? "offline"
        : linkConnecting ? "connecting"
        : ethernetActive ? "ethernet"
        : wifiConnected ? "wifi"
        : wifiAvailable && !wifiEnabled ? "radio-off"
        : "idle"
    // What a notification reports: moving to another network is news too.
    readonly property string statusKey: `${status}:${linkUp ? linkName : ""}`

    // How each status reads, in one place: its glyph, muted when there is no
    // connection to speak of, the notification's summary, and the detail its
    // body and the popout's reason line share; a problem is named in the popout.
    readonly property var presentation: {
        const name = linkName;
        return ({
            unavailable: { glyph: "network", muted: true, problem: true, summary: "Network status unavailable",
                detail: "NetworkManager is not running, so the network cannot be read or changed." },
            portal: { glyph: "circle-alert", muted: false, problem: true, summary: "Sign in to the network",
                detail: `${name} asks for a sign-in before it gives Internet access.` },
            offline: { glyph: "alert-triangle", muted: false, problem: true, summary: "No Internet connection",
                detail: internet === "limited" ? `${name} has limited Internet access.`
                    : `${name} is connected, but has no Internet access.` },
            connecting: { glyph: "link", muted: false, problem: false, summary: "", detail: "" },
            ethernet: { glyph: "cable", muted: false, problem: false, summary: "Connected by cable", detail: name },
            wifi: { glyph: wifiSignal >= 55 ? "wifi" : "wifi-low", muted: false, problem: false,
                summary: `Connected to ${name}`, detail: "Wi-Fi" },
            idle: { glyph: "network", muted: true, problem: false, summary: "Disconnected",
                detail: "Not connected to any network." },
            "radio-off": { glyph: "wifi-off", muted: true, problem: true, summary: "Wi-Fi is off",
                detail: "Wi-Fi radio is off — nothing can be seen until it is back on." }
        })[status];
    }

    function observe(value: string): void {
        const next = value.trim().toLowerCase();
        internet = Object.keys(descriptions).includes(next) ? next : "unknown";
    }
}
