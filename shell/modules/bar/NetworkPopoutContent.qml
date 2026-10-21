pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.components
import qs.services
import qs.state
import qs.theme

// Network popout, caelestia's setup (their bar popout Network.qml): wifi
// enable toggle, the top 8 APs sorted active-first then by strength with
// connect/disconnect, rescan; plus ethernet + VPN rows and the editor for
// anything deeper — NetworkManager owns networking (delegation law).
//
// PASSWORD PROMPT: a secured network that
// needs a password expands the field DIRECTLY UNDER ITS OWN ROW — the answer
// appears where the question was asked, never at the bottom of the list. The
// prompt carries the full feedback loop (09: every input gets a visible
// response): Enter locks the field and shows "joining…", success
// shows an accent check and collapses after a beat, failure keeps the field
// with the reason and the text selected for retype. An eye toggle reveals
// the password. While the prompt is open the popout holds the scene keyboard
// (ShellState.keyboardGrab) and refuses to auto-close.
ColumnLayout {
    id: root

    // [{ active, ssid, signal, secure }]
    readonly property var networks: NetworkService.networks.slice(0, Theme.popoutDeviceListMax)
    readonly property bool wifiEnabled: NetworkService.wifiEnabled
    // [{ device, type, state, connection }]
    readonly property var devices: (NetworkService.wiredDevices ?? [])
        .filter(entry => !/^(veth|docker|br-|virbr|tun|tap|vmnet|wg)/.test(entry.device))
    // [{ name, active }]
    readonly property var vpns: NetworkService.vpnProfiles ?? []
    property string connectingTo: ""
    property string connectError: ""
    property bool ownsOperation: false
    property bool promptMayOpen: false
    property string promptPassword: ""
    property bool passwordVisible: false
    signal interacted(string kind, var payload)
    property Item passwordTarget: null
    // The secured network currently asking for its password ("" = none) and
    // the prompt's lifecycle: "ask" (typing) | "joining" | "ok" | "failed".
    property string promptSsid: ""
    property string promptState: "ask"

    // Turning the radio OFF is the one control in here that can take the
    // machine off the network it is being used over, so it ARMS first, like the
    // destructive session buttons and the destructive quick actions. The owner
    // LIVED the alternative: one click killed the radio
    // mid-session, and nothing on screen afterwards connected the empty list to
    // the cause. Turning it back ON is a single click -- restoring connectivity
    // is never the mistake.
    property bool wifiOffArmed: false
    readonly property bool scanning: NetworkService.scanning
    onWifiEnabledChanged: {
        if (!wifiEnabled) { root.closePrompt(); root.wifiOffArmed = false; wifiDisarm.stop(); }
    }
    onNetworksChanged: {
        if (root.promptSsid && !root.networks.some(network => network.ssid === root.promptSsid)) root.closePrompt();
    }

    // 4 between rows, not 8: whatever groups elements must have MORE space
    // around the group than within it (visual-craft). The section labels below
    // carry the group gap; a uniform 8 made three kinds of thing read as one
    // undifferentiated list.
    spacing: QsmShellStyle.Style.space1

    function refresh(): void {
        NetworkService.refresh();
    }

    Component.onCompleted: refresh()

    function openPrompt(ssid: string): void {
        if (promptSsid !== ssid) { promptPassword = ""; passwordVisible = false; }
        promptSsid = ssid;
        promptState = "ask";
        ShellState.keyboardGrab = "wifi-password";
    }

    function closePrompt(): void {
        promptMayOpen = false;
        promptSettle.stop();
        promptSsid = "";
        passwordTarget = null;
        promptPassword = "";
        passwordVisible = false;
        promptState = "ask";
        if (ShellState.keyboardGrab === "wifi-password")
            ShellState.keyboardGrab = "";
    }

    function submitPassword(ssid: string, password: string): void {
        if (password.length === 0 || NetworkService.busy || ssid !== root.promptSsid)
            return;
        promptState = "joining";
        ownsOperation = true;
        connectingTo = ssid;
        connectError = "";
        root.interacted("connect", { ssid: ssid, credential: "provided" });
        if (!NetworkService.connect(ssid, password)) {
            ownsOperation = false;
            connectingTo = "";
            promptState = "ask";
        }
    }

    // The popout unloads when it closes; a grab must never outlive its owner.
    Component.onDestruction: {
        if (ShellState.keyboardGrab === "wifi-password")
            ShellState.keyboardGrab = "";
    }

    Connections {
        target: NetworkService
        function onOperated(operation: string, phase: string, value: var): void {
            if (!root.ownsOperation || phase === "pending" || operation === "wifi-scan") return;
            root.ownsOperation = false;
            const target = root.connectingTo;
            root.connectingTo = "";
            if (phase === "completed") {
                if (target.length > 0 && target === root.promptSsid) {
                    // Joined THROUGH the prompt: show the check for a beat so
                    // the success is seen, then fold the prompt away.
                    root.promptState = "ok";
                    root.promptSettle.restart();
                }
            } else if (target.length > 0 && root.promptMayOpen) {
                const network = root.networks.find(entry => entry.ssid === target);
                if (network?.secure && !network.enterprise) {
                    // A secured join failing IS the missing/wrong-password
                    // signal — ask in place instead of pointing at the editor.
                    // (A failed nmcli connect also leaves a broken saved
                    // profile behind, so "is it saved" cannot make this call.)
                    root.openPrompt(target);
                    root.promptState = "failed";
                    root.connectError = NetworkService.operationError || "This network needs a password";
                } else {
                    root.connectError = NetworkService.operationError;
                }
            } else if (phase === "failed") root.connectError = NetworkService.operationError;
            root.refresh();
        }
    }

    property Timer promptSettle: Timer {
        interval: 900
        onTriggered: root.closePrompt()
    }

    function toggleWifi(): bool {
        if (!NetworkService.wifiAvailable || NetworkService.busy) return false;
        if (!root.wifiEnabled) {
            root.wifiOffArmed = false;
            return root.operate("wifi-on", "");
        }

        if (!root.wifiOffArmed) {
            root.wifiOffArmed = true;
            root.interacted("armed", { target: "wifi-radio" });
            wifiDisarm.restart();
            return true;
        }

        root.wifiOffArmed = false;
        wifiDisarm.stop();
        return root.operate("wifi-off", "");
    }

    // Same 3s as every other armed control in the shell.
    property Timer wifiDisarm: Timer {
        interval: 3000
        onTriggered: {
            root.wifiOffArmed = false;
            root.interacted("disarmed", { target: "wifi-radio" });
        }
    }

    function rescan(): void {
        if (NetworkService.rescan()) root.interacted("rescan", {});
    }

    function operate(operation: string, target: string): bool {
        if (NetworkService.busy) return false;
        if (operation === "connect" && NetworkService.networks.find(network => network.ssid === target)?.enterprise) {
            root.interacted("delegate", { target: "network", ssid: target });
            return Delegate.open("network");
        }
        connectError = "";
        connectingTo = operation === "connect" ? target : "";
        ownsOperation = true;
        const routes = {
            "wifi-on": () => NetworkService.setWifiEnabled(true),
            "wifi-off": () => NetworkService.setWifiEnabled(false),
            connect: () => { root.promptMayOpen = true; return NetworkService.connect(target, ""); },
            disconnect: () => NetworkService.disconnect(target),
            vpn: () => NetworkService.toggleVpnProfile(target)
        };
        const invoke = routes[operation];
        if (!invoke || !invoke()) { ownsOperation = false; connectingTo = ""; return false; }
        root.interacted("activated", { target: target || "wifi-radio", operation: operation });
        return true;
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: QsmShellStyle.Style.space2

        QsmShellComponents.Capsule {
            size: "sm"
            // The glyph says which way round this is even before the words are
            // read, and the OFF state is LOUD: danger-coloured, naming itself,
            // and saying what a click does about it. An off radio used to read
            // as an ordinary inactive pill next to an empty list.
            icon: root.wifiEnabled ? "wifi" : "wifi-off"
            label: !root.wifiEnabled ? "Wi-Fi OFF · click to enable"
                : root.wifiOffArmed ? "Turn Wi-Fi off?"
                : "Wi-Fi on"
            active: !root.wifiEnabled || root.wifiOffArmed
            enabled: NetworkService.wifiAvailable && !NetworkService.busy
            accentColor: !root.wifiEnabled || root.wifiOffArmed ? Theme.danger : Theme.accent
            onClicked: root.toggleWifi()
        }

        // The spacer sits BEFORE Rescan: the pill is pinned to the right edge,
        // so the Wi-Fi capsule changing its label never moves it.
        Item { Layout.fillWidth: true }

        QsmShellComponents.Capsule {
            size: "sm"
            icon: "motion"
            // Says it is working, then stops saying it. The label IS the
            // progress indicator: there is nothing else this pill can report.
            label: root.scanning ? "Scanning…" : "Rescan"
            active: root.scanning
            // Nothing to scan with the radio off, so the control does not
            // pretend otherwise.
            enabled: NetworkService.wifiAvailable && root.wifiEnabled && !root.scanning
            onClicked: root.rescan()
        }
    }

    Repeater {
        model: root.networks

        // Row plus its own expandable password slot — the prompt belongs to
        // the network it asks about.
        ColumnLayout {
            id: networkEntry

            required property var modelData
            readonly property bool prompting: root.promptSsid === modelData.ssid

            Layout.fillWidth: true
            spacing: 0

            onPromptingChanged: {
                if (prompting) {
                    root.passwordTarget = passwordInput;
                    // The focus grant lands a frame after the grab flips the
                    // layer's keyboard mode; same-tick focusing goes nowhere.
                    Qt.callLater(() => {
                        if (networkEntry.prompting && root.visible) passwordInput.forceActiveFocus();
                    });
                } else if (root.passwordTarget === passwordInput) root.passwordTarget = null;
            }

            PopoutRow {
                Layout.fillWidth: true
                // Clicking the network joins it, or drops it if it is the
                // active one. ONE glyph for every network: icon swaps say
                // what a thing IS, not how much of it there is — the exact
                // strength is already spelled out on the right.
                icon: "wifi"
                label: networkEntry.modelData.ssid
                badgeIcon: networkEntry.modelData.secure ? "lock" : ""
                value: root.connectingTo === networkEntry.modelData.ssid
                    ? "joining…" : `${networkEntry.modelData.signal}%`
                active: networkEntry.modelData.active
                disabled: NetworkService.busy || !root.wifiEnabled
                onClicked: {
                    if (networkEntry.modelData.active) {
                        root.closePrompt();
                        root.operate("disconnect", networkEntry.modelData.ssid);
                    } else if (networkEntry.prompting) {
                        // Clicking the asking row again withdraws the question.
                        root.closePrompt();
                    } else {
                        // Try the direct join; a secured one without a working
                        // profile fails into the service-owned prompt result.
                        root.closePrompt();
                        root.operate("connect", networkEntry.modelData.ssid);
                    }
                }
            }

            // The expanding slot. Height animates on the reveal vocabulary —
            // a plain transform, clipped, no fade.
            Item {
                Layout.fillWidth: true
                clip: true
                implicitHeight: networkEntry.prompting ? promptBody.implicitHeight : 0

                Behavior on implicitHeight {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : Motion.fast; easing.type: Motion.standardEasing }
                }

                ColumnLayout {
                    id: promptBody
                    width: parent.width
                    spacing: QsmShellStyle.Style.space1

                    QsmShellComponents.TextField {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.topMargin: QsmShellStyle.Style.space1
                        // Indented under the row's text column: the field
                        // reads as the row's own detail, not a new sibling.
                        Layout.leftMargin: QsmShellStyle.Style.space5
                        size: "sm"
                        inputType: "password"
                        passwordVisible: root.passwordVisible
                        text: root.promptPassword
                        placeholder: "Password"
                        enabled: networkEntry.prompting
                        readOnly: root.promptState === "joining" || root.promptState === "ok"
                        failed: root.promptState === "failed"
                        Accessible.name: `Password for ${networkEntry.modelData.ssid}`
                        onEdited: text => root.promptPassword = text
                        onAccepted: root.submitPassword(networkEntry.modelData.ssid, root.promptPassword)
                        onEscaped: root.closePrompt()
                        onFailedChanged: {
                            if (failed && networkEntry.prompting) passwordInput.selectAll();
                        }
                        leading: QsmShellComponents.SvgIcon {
                            name: root.promptState === "ok" ? "check" : "lock"
                            size: QsmShellStyle.Style.iconSm
                            color: root.promptState === "ok" ? Theme.accent : Theme.textMuted
                        }
                        trailing: QsmShellComponents.ControlLabel {
                            icon: root.passwordVisible ? "eye-off" : "eye"
                            clickable: true
                            accessibleName: root.passwordVisible ? "Hide password" : "Show password"
                            onClicked: root.passwordVisible = !root.passwordVisible
                        }
                    }

                    QsmShellComponents.Prose {
                        // The prompt's own status line: reason on failure,
                        // confirmation while joining/joined — the line that
                        // explains the row above it.
                        role: "supporting"
                        visible: text.length > 0
                        Layout.fillWidth: true
                        Layout.leftMargin: QsmShellStyle.Style.space5
                        text: root.promptState === "failed" ? root.connectError
                            : root.promptState === "joining" ? "Joining…"
                            : root.promptState === "ok" ? "Connected"
                            : ""
                        // Original size (textXs); supporting's role default is
                        // body-sized (textSm) — kept here so the status line
                        // stays subordinate to the field it sits under.
                        font.pixelSize: QsmShellStyle.Style.textXs
                        color: root.promptState === "failed" ? Theme.danger
                            : root.promptState === "ok" ? Theme.accent
                            : Theme.textMuted
                    }
                }
            }
        }
    }

    // The empty list gets a reason. Without one, a radio the owner switched off
    // three minutes ago looks like a shell that stopped finding networks.
    QsmShellComponents.Prose {
        role: "body"
        visible: !root.wifiEnabled
        Layout.fillWidth: true
        text: "Wi-Fi radio is off — nothing can be seen until it is back on"
        color: Theme.danger
        // Original size (textXs); body's role default is textSm — recorded.
        font.pixelSize: QsmShellStyle.Style.textXs
    }

    QsmShellComponents.Prose {
        role: "metadata"
        visible: root.wifiEnabled && root.networks.length === 0
        Layout.fillWidth: true
        text: root.scanning ? "Scanning for networks…" : "No networks in range"
    }

    QsmShellComponents.Prose {
        // List-level errors only; prompt errors render inside the prompt.
        role: "body"
        visible: root.connectError.length > 0 && root.promptSsid.length === 0
        Layout.fillWidth: true
        text: root.connectError
        color: Theme.warning
        // Original size (textXs); body's role default is textSm — recorded.
        font.pixelSize: QsmShellStyle.Style.textXs
    }

    QsmShellComponents.Section {
        Layout.fillWidth: true
        Layout.topMargin: QsmShellStyle.Style.space4
        visible: root.devices.length > 0
        title: "Wired"

        Repeater {
            model: root.devices

            PopoutRow {
                required property var modelData
                Layout.fillWidth: true
                icon: "cable"
                label: modelData.connection || modelData.device
                value: modelData.state
                active: modelData.state === "connected"
                // Nothing to click: nmcli owns wired profiles and this popout is
                // not going to rebuild that. A cursor and a press bounce on a row
                // that does nothing is a promise the row cannot keep.
                interactive: false
            }
        }
    }

    QsmShellComponents.Section {
        Layout.fillWidth: true
        Layout.topMargin: QsmShellStyle.Style.space4
        visible: root.vpns.length > 0
        title: "VPN"

        Repeater {
            model: root.vpns

            PopoutRow {
                required property var modelData
                Layout.fillWidth: true
                icon: "lock"
                label: modelData.name
                value: modelData.active ? "up" : "down"
                active: modelData.active
                disabled: NetworkService.busy
                onClicked: root.operate("vpn", modelData.name)
            }
        }
    }

    QsmShellComponents.Capsule {
        size: "sm"
        Layout.topMargin: QsmShellStyle.Style.space1
        icon: "wifi"
        label: "Network settings"
        onClicked: { root.interacted("delegate", { target: "network" }); Delegate.open("network"); }
    }
}
