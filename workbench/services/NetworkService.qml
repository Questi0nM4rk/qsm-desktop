pragma Singleton
import QtQuick

// Isolated Wi-Fi fixture: the shape of NetworkService with a scripted answer,
// so a story and a flow can reach every state without touching nmcli.
QtObject {
    id: root
    property bool wifiEnabled: true
    property bool wifiAvailable: true
    property bool vpnAvailable: false
    property bool vpnActive: false
    property string vpnName: ""
    property var wiredDevices: []
    property var vpnProfiles: []
    property var networks: []
    property bool scanning: false
    property string scanError: ""
    property string operationState: "idle"
    property string operationTarget: ""
    property string operationName: ""
    property string operationError: ""
    readonly property bool busy: operationState === "pending"
    property bool nextConnectFails: false
    property bool desiredState: false
    signal operated(string operation, string phase, var value)
    // The shell's own status over the fixture's answers, as nmcli's device rows.
    readonly property var activeNetwork: networks.find(network => network.active)
    property NetworkStatus reading: NetworkStatus {
        rows: (root.wifiAvailable ? [["wifi", root.wifiEnabled && root.activeNetwork ? "connected" : "disconnected",
            root.activeNetwork?.ssid ?? "", "preview-wifi"]] : [])
            .concat(root.wiredDevices.map(device => ["ethernet", device.state, device.connection, device.device]))
        wifiEnabled: root.wifiEnabled
        wifiSignal: root.activeNetwork?.signal ?? 0
    }
    readonly property string internetDescription: reading.internetDescription
    readonly property string internetState: reading.internet
    readonly property string status: reading.status
    readonly property var presentation: reading.presentation
    readonly property string linkName: reading.linkName
    readonly property string glyph: presentation.glyph
    readonly property bool glyphMuted: presentation.muted

    function refresh(): void {}
    function start(name: string, target: string): bool {
        if (root.busy) return false;
        root.operationName = name;
        root.operationTarget = target;
        root.operationError = "";
        root.operationState = "pending";
        root.operated(name, "pending", target);
        reply.restart();
        return true;
    }
    function setWifiEnabled(enabled: bool): bool {
        if (!root.wifiAvailable || root.busy) return false;
        root.desiredState = enabled;
        return root.start("wifi-radio", "wifi-radio");
    }
    function rescan(): bool {
        if (!root.wifiAvailable || !root.wifiEnabled || root.scanning) return false;
        root.scanning = true;
        root.operated("wifi-scan", "pending", null);
        scanReply.restart();
        return true;
    }
    function connect(ssid: string, password: string): bool {
        const network = root.networks.find(entry => entry.ssid === ssid);
        if (!root.wifiAvailable || !root.wifiEnabled || root.busy || !network) return false;
        if (network.enterprise) return Delegate.open("network");
        if (password.includes("\n") || password.includes("\r")) return false;
        return root.start("wifi-connect", ssid);
    }
    function disconnect(ssid: string): bool {
        if (!root.networks.some(network => network.ssid === ssid && network.active)) return false;
        return root.start("wifi-disconnect", ssid);
    }
    function toggleVpn(): bool {
        if (!root.vpnAvailable || !root.vpnName || root.busy) return false;
        root.desiredState = !root.vpnActive;
        return root.start("vpn", "vpn");
    }
    function toggleVpnProfile(name: string): bool {
        const profile = root.vpnProfiles.find(candidate => candidate.name === name);
        if (!profile || root.busy) return false;
        root.desiredState = !profile.active;
        return root.start("vpn", name);
    }
    function reset(): void {
        reading.observe("full");
        reply.stop();
        scanReply.stop();
        root.wifiEnabled = true;
        root.wifiAvailable = true;
        root.vpnAvailable = false;
        root.vpnActive = false;
        root.vpnName = "";
        root.vpnProfiles = [];
        root.wiredDevices = [];
        root.scanning = false;
        root.scanError = "";
        root.operationState = "idle";
        root.operationTarget = "";
        root.operationName = "";
        root.operationError = "";
        root.nextConnectFails = false;
        root.networks = [
            { ssid: "Studio Wi-Fi", active: true, secure: true, signal: 85, device: "preview-wifi" },
            { ssid: "Studio Guest", active: false, secure: true, signal: 65, device: "preview-wifi" },
            { ssid: "Guest network", active: false, secure: false, signal: 55, device: "preview-wifi" },
            { ssid: "Office: enterprise", active: false, secure: true, enterprise: true, signal: 45, device: "preview-wifi" }
        ];
    }
    property Timer reply: Timer {
        interval: 180
        onTriggered: {
            const target = root.operationTarget;
            const name = root.operationName;
            const error = name === "vpn" ? (root.vpnAvailable ? "" : "VPN profile disappeared")
                : !root.wifiAvailable ? "Wi-Fi adapter disappeared"
                : name === "wifi-connect" && root.nextConnectFails ? "Connection failed; check credentials and retry"
                : name !== "wifi-radio" && !root.networks.some(network => network.ssid === target) ? "Network is no longer available" : "";
            root.nextConnectFails = false;
            if (!error) {
                if (name === "vpn") {
                    root.vpnActive = root.desiredState;
                    root.vpnProfiles = root.vpnProfiles.map(profile => Object.assign({}, profile,
                        { active: profile.name === target ? root.desiredState : profile.active }));
                }
                else if (name === "wifi-radio") {
                    root.wifiEnabled = root.desiredState;
                    if (!root.wifiEnabled)
                        root.networks = root.networks.map(network => Object.assign({}, network, { active: false }));
                } else root.networks = root.networks.map(network => Object.assign({}, network, {
                    active: name === "wifi-connect" ? network.ssid === target
                        : network.ssid === target ? false : network.active }));
            }
            root.operationError = error;
            root.operationState = error ? "failed" : "completed";
            root.operated(name, root.operationState, { target: target, error: error });
        }
    }
    property Timer scanReply: Timer {
        interval: 180
        onTriggered: {
            root.scanning = false;
            root.operated("wifi-scan", "completed", root.networks.length);
        }
    }
}
