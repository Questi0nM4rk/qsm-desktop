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
    property ConnectivityState connectivity: ConnectivityState {}
    property string _password: ""
    signal operated(string operation, string phase, var value)

    // NetworkManager answered the last device read. It starts true so a session
    // does not open on "not running" before the first read has said anything.
    property bool available: true
    property bool linkConnecting: false
    // The connection the status names: the cable's, else the Wi-Fi's.
    property string linkName: ""
    readonly property bool linkUp: ethernetActive || wifiConnected

    // The one network status, the first that holds (owner: a problem before a
    // connection). Portal and offline need a link, because NetworkManager
    // reports no Internet for a machine with no link at all as well.
    readonly property string status: !available ? "unavailable"
        : linkUp && internetState === "portal" ? "portal"
        : linkUp && (internetState === "none" || internetState === "limited") ? "offline"
        : linkConnecting ? "connecting"
        : ethernetActive ? "ethernet"
        : wifiConnected ? "wifi"
        : wifiAvailable && !wifiEnabled ? "radio-off"
        : "idle"
    readonly property string glyph: ({
        unavailable: "network", portal: "circle-alert", offline: "alert-triangle",
        connecting: "link", ethernet: "cable", wifi: wifiSignal >= 55 ? "wifi" : "wifi-low",
        idle: "network", "radio-off": "wifi-off"
    })[status]
    // No connection to speak of: the glyph reads muted.
    readonly property bool glyphMuted: ["unavailable", "idle", "radio-off"].includes(status)
    // What a notification reports: moving to another network is news too.
    readonly property string statusKey: `${status}:${linkUp ? linkName : ""}`
    // The last result notified; empty until the session's first settled status,
    // which is the baseline and not news.
    property string reportedKey: ""

    onStatusKeyChanged: settle.restart()
    // A status is a result once it has held 3 s (owner): one that flips back
    // inside that window was never news, and connecting is never a result.
    property Timer settle: Timer {
        interval: 3000
        running: true
        onTriggered: {
            if (root.status === "connecting" || root.statusKey === root.reportedKey) return;
            const baseline = root.reportedKey === "";
            root.reportedKey = root.statusKey;
            if (!baseline) root.notifyStatus();
        }
    }

    function notifyStatus(): void {
        const name = root.linkName;
        const copy = {
            wifi: [`Connected to ${name}`, "Wi-Fi"],
            ethernet: ["Connected by cable", name],
            idle: ["Disconnected", "Not connected to any network."],
            "radio-off": ["Wi-Fi is off", "Turn it on in the network popout."],
            offline: ["No Internet connection", root.internetState === "limited"
                ? `${name} has limited Internet access.` : `${name} is connected, but has no Internet access.`],
            portal: ["Sign in to the network", `${name} asks for a sign-in before it gives Internet access.`],
            unavailable: ["Network status unavailable", "NetworkManager is not running."]
        }[root.status];
        NotificationService.notify(copy[0], { appName: "Network", body: copy[1],
            urgency: root.status === "wifi" || root.status === "ethernet" ? "low" : "normal" });
    }

    // NetworkManager's own change stream: any line it prints is a change, and the
    // probes read what it was, so its wording is never parsed. One change prints
    // several lines, which one refresh answers. The 10 s poll stays for the Wi-Fi
    // signal, which the stream does not report.
    property Process monitor: Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: changed.restart() }
        onExited: code => {
            console.warn(`NetworkService: nmcli monitor exited (${code}), restarting`);
            monitorRestart.restart();
        }
    }
    property Timer monitorRestart: Timer { interval: 2000; onTriggered: root.monitor.running = true }
    property Timer changed: Timer {
        interval: 150
        // A probe still reading would skip this refresh, and the change with it.
        onTriggered: {
            if (probe.running || radioProbe.running || connectivityProbe.running) restart();
            else root.refresh();
        }
    }

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
                const links = devices.filter(device => device[0] === "ethernet" || device[0] === "wifi");
                const cable = links.find(device => device[0] === "ethernet" && device[1] === "connected");
                const wifi = links.find(device => device[0] === "wifi" && device[1] === "connected");
                root.ethernetActive = !!cable;
                root.wifiAvailable = links.some(device => device[0] === "wifi");
                root.wifiConnected = !!wifi;
                root.linkConnecting = links.some(device => device[1].startsWith("connecting"));
                root.linkName = (cable ?? wifi)?.[2] ?? "";
            }
        }
        // A failed read is a NetworkManager that does not answer (8 is "not
        // running"), and nothing it said before still holds.
        onExited: code => {
            root.available = code === 0;
            if (code === 0) return;
            root.ethernetActive = false;
            root.wifiConnected = false;
            root.wifiAvailable = false;
            root.linkConnecting = false;
            root.linkName = "";
            root.networks = [];
            root.wiredDevices = [];
        }
    }
    property Process connectivityProbe: Process {
        id: connectivityProbe
        // Without 'check' nmcli only reads NetworkManager's cached result.
        command: ["timeout", "5s", "nmcli", "-t", "networking", "connectivity"]
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
