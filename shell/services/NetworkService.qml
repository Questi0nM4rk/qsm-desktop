pragma Singleton

import QtQuick
import Quickshell.Io
import qs.services

// NetworkManager through nmcli, in ONE place: status for the rail glyph, the
// network list for the popout and the action menu, and the operation lifetime
// (pending, completed, failed) so no surface has to own it.
QtObject {
    id: root

    property bool ethernetActive: false
    property bool wifiConnected: false
    property bool wifiEnabled: false
    property bool wifiAvailable: false
    property int wifiSignal: 0
    property bool vpnAvailable: false
    property bool vpnActive: false
    property string vpnName: ""
    property var wiredDevices: []
    property var vpnProfiles: []
    property var networks: []
    property string operationState: "idle"
    property string operationTarget: ""
    property string operationError: ""
    property string operationName: ""
    readonly property bool busy: operationState === "pending"
    property bool scanning: false
    property string scanError: ""
    property string connectivityOutput: ""
    readonly property string internetState: connectivity.state
    readonly property string internetDescription: connectivity.description
    property ConnectivityState connectivity: ConnectivityState {
        onLost: state => NotificationService.notify("Internet connection lost", {
            appName: "Network", body: state === "portal" ? "Sign in to the network to restore access."
                : "The network no longer reports Internet access. Check your connection.", urgency: "normal"
        })
        onRestored: NotificationService.notify("Internet connection restored", {
            appName: "Network", body: "NetworkManager reports full Internet access again.", urgency: "low"
        })
    }
    property string _password: ""
    signal operated(string operation, string phase, var value)

    readonly property string glyph: ethernetActive ? "cable"
        : !wifiEnabled || !wifiConnected ? "wifi-off"
        : wifiSignal >= 55 ? "wifi" : "wifi-low"

    // Terse mode escapes the separator and the escape character, so an SSID may
    // legitimately contain a colon. Splitting on ":" produced broken networks.
    function fields(line: string): var {
        const result = [];
        let value = "", escaped = false;
        for (const ch of line) {
            if (escaped) { value += ch; escaped = false; }
            else if (ch === "\\") escaped = true;
            else if (ch === ":") { result.push(value); value = ""; }
            else value += ch;
        }
        result.push(value);
        return result;
    }

    function refresh(): void {
        if (!probe.running) probe.running = true;
        if (!radioProbe.running) radioProbe.running = true;
        if (!vpnProbe.running) vpnProbe.running = true;
        if (!wifiListProbe.running && root.wifiEnabled) wifiListProbe.running = true;
        if (!connectivityProbe.running) connectivityProbe.running = true;
    }

    function start(name: string, target: string, command: var, password = ""): bool {
        if (root.busy || action.running) return false;
        root._password = password;
        root.operationName = name;
        root.operationTarget = target;
        root.operationError = "";
        root.operationState = "pending";
        root.operated(name, "pending", target);
        action.command = command;
        action.stdinEnabled = root._password.length > 0;
        action.running = true;
        deadline.restart();
        return true;
    }

    function setWifiEnabled(enabled: bool): bool {
        if (!root.wifiAvailable) return false;
        return root.start("wifi-radio", "wifi-radio",
            ["nmcli", "--wait", "30", "radio", "wifi", enabled ? "on" : "off"]);
    }

    function rescan(): bool {
        if (root.scanning || scanProcess.running || !root.wifiAvailable || !root.wifiEnabled) return false;
        root.scanError = "";
        root.scanning = true;
        root.operated("wifi-scan", "pending", null);
        scanProcess.running = true;
        scanDeadline.restart();
        return true;
    }

    function connect(ssid: string, password: string): bool {
        const network = root.networks.find(entry => entry.ssid === ssid);
        if (!root.wifiAvailable || !root.wifiEnabled || root.busy || !network) return false;
        // 802.1X needs a certificate and an identity, not a password; asking for
        // one would imply a connection this route cannot complete.
        if (network.enterprise) return Delegate.open("network");
        if (password.includes("\n") || password.includes("\r")) return false;
        // The secret goes to stdin and nowhere else: not argv, not the
        // environment, not a file, not an event payload.
        return root.start("wifi-connect", ssid, ["nmcli", "--wait", "30"]
            .concat(password.length ? ["--ask"] : [])
            .concat(["device", "wifi", "connect", ssid, "ifname", network.device]), password);
    }

    function disconnect(ssid: string): bool {
        const network = root.networks.find(entry => entry.ssid === ssid && entry.active);
        if (!network || !network.device || root.busy) return false;
        return root.start("wifi-disconnect", ssid,
            ["nmcli", "--wait", "10", "device", "disconnect", network.device]);
    }

    function toggleVpn(): bool {
        if (!root.vpnAvailable || !root.vpnName) return false;
        return root.start("vpn", "vpn", ["nmcli", "--wait", "30", "connection",
            root.vpnActive ? "down" : "up", "id", root.vpnName]);
    }

    function toggleVpnProfile(name: string): bool {
        const profile = root.vpnProfiles.find(candidate => candidate.name === name);
        if (!profile) return false;
        return root.start("vpn", name, ["nmcli", "--wait", "30", "connection",
            profile.active ? "down" : "up", "id", name]);
    }

    function finish(error: string): void {
        if (!root.busy) return;
        deadline.stop();
        root._password = "";
        root.operationError = error;
        root.operationState = error ? "failed" : "completed";
        root.operated(root.operationName, root.operationState,
            { target: root.operationTarget, error: error });
        root.refresh();
    }

    function finishScan(error: string): void {
        if (!root.scanning) return;
        scanDeadline.stop();
        root.scanning = false;
        root.scanError = error;
        root.operated("wifi-scan", error ? "failed" : "completed", error);
        root.refresh();
    }

    property Timer poll: Timer { interval: 10000; repeat: true; running: true; onTriggered: root.refresh() }
    property Timer deadline: Timer {
        interval: 35000
        onTriggered: {
            root.finish("Network operation timed out; check NetworkManager and retry");
            action.signal(9);
        }
    }
    property Timer scanDeadline: Timer {
        interval: 35000
        onTriggered: {
            root.finishScan("Network scan timed out; check NetworkManager and retry");
            scanProcess.signal(9);
        }
    }
    Component.onCompleted: root.refresh()

    property Process action: Process {
        id: action
        environment: ({ LC_ALL: "C", TERM: "dumb" })
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onStarted: {
            if (root._password) action.write(root._password + "\n");
            root._password = "";
            action.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            const reasons = { 3: "Network operation timed out",
                4: "Connection failed; check credentials and signal",
                5: "Could not disconnect", 6: "Could not disconnect",
                8: "NetworkManager is not running",
                10: "Network or adapter is no longer available" };
            // QProcess::NormalExit is 0; its exit code is invalid after a crash.
            root.finish(exitStatus !== 0 ? "Network operation interrupted; retry"
                : exitCode === 0 ? ""
                : reasons[exitCode] || "Network operation failed; check permissions and retry");
        }
    }

    property Process probe: Process {
        id: probe
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "device"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const devices = text.trim().split("\n").map(line => root.fields(line));
                root.wiredDevices = devices.filter(device => device[0] === "ethernet" && device[3])
                    .map(device => ({ device: device[3], type: device[0], state: device[1], connection: device[2] }));
                root.ethernetActive = devices.some(device => device[0] === "ethernet" && device[1] === "connected");
                root.wifiAvailable = devices.some(device => device[0] === "wifi");
                root.wifiConnected = devices.some(device => device[0] === "wifi" && device[1] === "connected");
            }
        }
        onExited: code => {
            if (code !== 0) { root.wifiAvailable = false; root.networks = []; root.wiredDevices = []; }
        }
    }
    property Process connectivityProbe: Process {
        id: connectivityProbe
        // Without 'check' nmcli only reads NetworkManager's cached result.
        command: ["timeout", "5s", "nmcli", "-t", "general", "connectivity"]
        stdout: StdioCollector { onStreamFinished: root.connectivityOutput = text }
        // qmllint disable signal-handler-parameters
        onExited: (code, status) => root.connectivity.observe(code === 0 && status === 0
            ? root.connectivityOutput : "unknown")
        // qmllint enable signal-handler-parameters
    }
    property Process radioProbe: Process {
        id: radioProbe
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
                if (!root.wifiEnabled) root.networks = [];
                else if (!wifiListProbe.running) wifiListProbe.running = true;
            }
        }
    }
    property Process scanProcess: Process {
        id: scanProcess
        command: ["nmcli", "--wait", "30", "device", "wifi", "rescan"]
        onExited: (code, exitStatus) => root.finishScan(exitStatus === 0 && code === 0
            ? "" : "Could not scan for networks; check the radio and permissions")
    }
    property Process wifiListProbe: Process {
        id: wifiListProbe
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,DEVICE", "device", "wifi", "list", "--rescan", "no"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wifiEnabled) return;
                // One row per network: the same SSID on several bands is one
                // choice, and the strongest or active one is that choice.
                const unique = new Map();
                for (const line of text.trim().split("\n")) {
                    const parts = root.fields(line);
                    if (parts.length !== 5 || !parts[1] || !parts[4]) continue;
                    const network = { active: parts[0] === "*", ssid: parts[1],
                        signal: parseInt(parts[2], 10) || 0,
                        secure: parts[3].length > 0 && parts[3] !== "--",
                        enterprise: parts[3].includes("802.1X"), device: parts[4] };
                    const old = unique.get(network.ssid);
                    if (!old || network.active || (!old.active && network.signal > old.signal))
                        unique.set(network.ssid, network);
                }
                root.networks = [...unique.values()].sort((a, b) =>
                    Number(b.active) - Number(a.active) || b.signal - a.signal
                    || a.ssid.localeCompare(b.ssid));
                root.wifiSignal = root.networks.find(network => network.active)?.signal ?? 0;
            }
        }
    }
    property Process vpnProbe: Process {
        id: vpnProbe
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                root.vpnProfiles = text.trim().split("\n").map(line => root.fields(line))
                    .filter(fields => ["vpn", "wireguard"].includes(fields[1]))
                    .map(fields => ({ name: fields[0], active: fields[2] === "yes" }));
                const vpn = root.vpnProfiles.find(profile => profile.active) ?? root.vpnProfiles[0];
                root.vpnAvailable = !!vpn;
                root.vpnName = vpn?.name ?? "";
                root.vpnActive = vpn?.active ?? false;
            }
        }
    }
}
