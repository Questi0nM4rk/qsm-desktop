import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.components
import qs.modules.launcher as Launcher
import qs.services
import qs.state
import qs.theme

Item {
    id: root

    property var previewEnvironment: null
    property int viewportWidth: 980
    property int viewportHeight: 760
    property var inputDriver: null
    property bool interactive: false
    property int resetGeneration: 0
    property bool observing: false
    // The catalog's variant name reaches the Adapter as `variant`; `variant` is
    // a QML type name, so the story takes it under a name it can declare.
    property string menuVariant: "audio"
    readonly property real contentExtentWidth: width
    readonly property real contentExtentHeight: height
    // One scenario per variant: the route it opens, the actions it allows, the
    // buttons a control strip offers and how each button changes the fixture.
    // Nothing in this file reads the variant through a branch.
    readonly property var scenarios: ({
        "audio": {
            services: [AudioService, Delegate],
            route: "sound",
            actions: ["sound"],
             controls: [{ label: "Output", options: [{ label: "Available" }, { label: "Unavailable" }] },
                { label: "Value", options: [{ label: "Minimum" }, { label: "Everyday" }, { label: "Maximum" }] },
                { label: "View", options: [{ label: "Sound details" }, { label: "Parent menu" }] },
                { label: "Motion", options: [{ label: "Full" }, { label: "Reduced" }] },
                { label: "Microphone", options: [{ label: "Available" }, { label: "Unavailable" }] }],
            apply: (group, option) => {
                if (group === 0) AudioService.outputAvailable = option === 0;
                else if (group === 1) AudioService.outputValue = [0, 0.62, 1][option];
                else if (group === 2) {
                    root.openRoute();
                    if (option === 1) launcher.leaveDetail();
                } else if (group === 3) ShellState.reducedMotion = option === 1;
                else if (group === 4) AudioService.microphoneAvailable = option === 0;
                else return false;
                return true;
            }
        },
        "brightness": {
            services: [BrightnessService], route: "brightness", actions: ["brightness"],
            controls: [{ label: "Backlight", options: [{ label: "Available" }, { label: "Unavailable" }] }],
            apply: (group, option) => {
                if (group !== 0 || option < 0 || option > 1) return false;
                BrightnessService.available = option === 0;
                return true;
            }
        },
        "network": {
            services: [NetworkService, Delegate],
            route: "network",
            actions: ["network"],
            controls: [{ label: "Networks", options: [{ label: "Several" }, { label: "Empty" },
                { label: "Next connect fails" }, { label: "Unavailable" },
                { label: "VPN without Wi-Fi" }] },
                { label: "Internet", options: [{ label: "Online" }, { label: "Offline sample" },
                    { label: "Portal sample" }, { label: "Unknown sample" }] }],
            apply: (group, option) => {
                if (group === 1 && option >= 0 && option < 4) {
                    NetworkService.connectivity.observe(["full", "none", "portal", "unknown"][option]);
                    return true;
                }
                if (group !== 0 || option < 0 || option > 4) return false;
                NetworkService.reset();
                if (option === 1) NetworkService.networks = [];
                else if (option === 2) NetworkService.nextConnectFails = true;
                else if (option === 3) NetworkService.wifiAvailable = false;
                else if (option === 4) {
                    NetworkService.wifiAvailable = false;
                    NetworkService.wifiEnabled = false;
                    NetworkService.networks = [];
                    NetworkService.vpnAvailable = true;
                    NetworkService.vpnName = "Preview VPN";
                }
                return true;
            }
        },
        "bluetooth": {
            services: [BluetoothService, Delegate],
            route: "bluetooth",
            actions: ["bluetooth"],
            controls: [{ label: "Devices", options: [{ label: "Several" }, { label: "Empty" },
                { label: "Discovery" }, { label: "Next operation fails" }, { label: "Unavailable" }] }],
            apply: (group, option) => {
                if (group !== 0 || option < 0 || option > 4) return false;
                BluetoothService.reset();
                if (option === 1) BluetoothService.devices = [];
                else if (option === 2) BluetoothService.adapter.discovering = true;
                else if (option === 3) BluetoothService.nextFails = true;
                else if (option === 4) BluetoothService.available = false;
                return true;
            }
        },
        "toggles": {
            services: [Delegate, MainKeyboardService],
            route: "nightlight",
            actions: ["main-keyboard", "awake", "nightlight"],
            controls: [{ label: "Initial state", options: [{ label: "Off" }, { label: "On" }] },
                { label: "Main keyboard", options: [{ label: "Enabled" }, { label: "Disabled" },
                    { label: "Unavailable" }, { label: "Next change fails" }] }],
            apply: (group, option) => {
                if (group === 1) {
                    const states = [{ available: true, disabled: false },
                        { available: true, disabled: true }, { available: false },
                        { available: true, nextFails: true }];
                    const state = states[option];
                    if (!state) return false;
                    MainKeyboardService.reset();
                    for (const name of Object.keys(state)) MainKeyboardService[name] = state[name];
                    return true;
                }
                if (group !== 0 || (option !== 0 && option !== 1)) return false;
                AwakeService.awake = option === 1;
                NightLightService.active = option === 1;
                return true;
            }
        }
    })
    readonly property var scenario: root.scenarios[root.menuVariant] ?? root.scenarios.audio
    readonly property var controls: root.scenario.controls
    readonly property var actions: [
        { label: "Open route", trigger: "open-route" },
        { label: "Open volume", trigger: "open-volume" },
        { label: "Open microphone", trigger: "open-microphone" },
        { label: "Open brightness", trigger: "open-brightness" },
        { label: "Activate selected", trigger: "activate-current" },
        { label: "Focus search", trigger: "focus-search" },
        { label: "Close editor", trigger: "close-editor" }
    ]
    readonly property var integration: ({
        events: ["interacted", "operated", "applied"],
        actions: root.actions.map(action => action.trigger),
        runAction: name => root.runAction(name),
        observables: {
            "selected-identity": () => launcher.selectedIdentity,
            "selected-index": () => launcher.selectedIndex,
            "input-region": () => launcher.inputRegion,
            "detail": () => launcher.detailId,
            "query": () => launcher.query,
            "editor-open": () => launcher.expandedAudioId === "output-volume",
            "network-editor-open": () => launcher.expandedNetworkId.length > 0,
            "password-length": () => launcher.networkPassword.length,
            "confirmation": () => launcher.confirmId,
            "output-value": () => AudioService.outputValue,
            "output-muted": () => AudioService.outputMuted,
            "output-available": () => AudioService.outputAvailable,
            "microphone-value": () => AudioService.microphoneValue,
            "microphone-available": () => AudioService.microphoneAvailable,
            "brightness-value": () => BrightnessService.value,
            "brightness-available": () => BrightnessService.available,
            "active-level": () => launcher.expandedAudioId,
            "search-focused": () => launcher.searchTarget.focused,
            "menu-open": () => ShellState.modal === "launcher",
            "menu-ready": () => modal.active && modal.revealed && !modal.animating,
            "wifi-enabled": () => NetworkService.wifiEnabled,
            "wifi-available": () => NetworkService.wifiAvailable,
            "internet-state": () => NetworkService.internetState,
            "internet-losses": () => NetworkService.internetLosses,
            "internet-recoveries": () => NetworkService.internetRecoveries,
            "wifi-count": () => NetworkService.networks.length,
            "wifi-state": () => NetworkService.operationState,
            "wifi-scanning": () => NetworkService.scanning,
            "wifi-scan-reading": () => launcher.resultTargetIdentity("wifi-rescan")?.supporting ?? "",
            "wifi-guest-connected": () => NetworkService.networks.some(network => network.ssid === "Studio Guest" && network.active),
            "vpn-active": () => NetworkService.vpnActive,
            "vpn-selectable": () => launcher.isSelectable(launcher.results.find(row => row.data === "vpn")),
            "bluetooth-enabled": () => BluetoothService.adapter.enabled,
            "bluetooth-available": () => BluetoothService.available,
            "bluetooth-state": () => BluetoothService.operationState,
            "bluetooth-count": () => BluetoothService.devices.length,
            "bluetooth-first-connected": () => BluetoothService.devices[0]?.connected ?? false,
            "bluetooth-forget-reading": () => launcher.resultTargetIdentity("forget-00:11:22:33:44:55")?.supporting ?? "",
            "awake": () => AwakeService.awake,
            "main-keyboard-disabled": () => MainKeyboardService.disabled,
            "main-keyboard-available": () => MainKeyboardService.available,
            "main-keyboard-busy": () => MainKeyboardService.busy,
            "main-keyboard-error": () => MainKeyboardService.error,
            "night-light": () => NightLightService.active
        },
        targets: {
            "scene": () => root,
            "menu": () => launcher.menuTarget,
            "search": () => launcher.searchTarget,
            "volume-row": () => launcher.resultTarget("output-volume"),
            "mute-row": () => launcher.resultTarget("output-mute"),
            "volume-editor": () => launcher.expandedAudioId ? launcher.editorTarget : null,
            "level-editor": () => launcher.expandedAudioId ? launcher.editorTarget : null,
            "wifi-radio": () => launcher.resultTargetIdentity("wifi-radio")?.toggleTarget ?? null,
            "wifi-rescan": () => launcher.resultTargetIdentity("wifi-rescan"),
            "wifi-secured": () => launcher.resultTarget("Studio Guest"),
            "vpn-row": () => launcher.resultTargetIdentity("vpn"),
            "wifi-password": () => launcher.expandedNetworkId.length > 0
                ? launcher.resultTarget(launcher.expandedNetworkId)?.valueEditor ?? null : null,
            "bluetooth-radio": () => launcher.resultTargetIdentity("adapter-power")?.toggleTarget ?? null,
            "bluetooth-device-row": () => launcher.resultTarget("00:11:22:33:44:55"),
            "awake-switch": () => launcher.resultTarget("awake")?.toggleTarget ?? null,
            "main-keyboard-row": () => launcher.resultTarget("main-keyboard"),
            "main-keyboard-switch": () => launcher.resultTarget("main-keyboard")?.toggleTarget ?? null,
            "nightlight-switch": () => launcher.resultTarget("toggle")?.toggleTarget ?? null
        },
        idle: () => !restoreObservation.running && !NetworkService.busy && !NetworkService.scanning
            && !BluetoothService.busy && !MainKeyboardService.busy && !modal.animating
    })

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: root.previewEnvironment?.screenRect?.width ?? root.viewportWidth
    height: root.previewEnvironment?.screenRect?.height ?? root.viewportHeight

    function record(origin: string, name: string, payload: var): void {
        if (root.observing)
            root.eventRecorded({ origin: origin, kind: "action-menu", name: name, payload: payload });
    }

    // The story opens exactly what production opens: the action menu, then the
    // route this variant is about.
    function openRoute(): void {
        if (ShellState.modal !== "launcher") {
            ShellState.launcherSeed = ">action ";
            ShellState.modal = "launcher";
        }
        if (launcher.inDetail)
            return;
        const index = launcher.results.findIndex(row => row.data === root.scenario.route);
        if (index >= 0) launcher.activate(index);
    }

    function resetStory(): void {
        root.observing = false;
        restoreObservation.stop();
        if (root.inputDriver && typeof root.inputDriver.cancel === "function")
            root.inputDriver.cancel();
        ShellState.reset();
        AudioService.reset();
        BrightnessService.reset();
        NetworkService.reset();
        BluetoothService.reset();
        AwakeService.reset();
        MainKeyboardService.reset();
        NightLightService.reset();
        ShellState.focusedScreen = screenFacts;
        restoreObservation.restart();
    }

    // One dictionary per action name, and one `scenario.apply` per control
    // strip. Adding a scenario adds an entry, never another branch here.
    readonly property var actionHandlers: ({
        "open-microphone": () => root.openLevel("microphone-volume"),
        "open-brightness": () => root.openLevel("brightness-level"),
        "open-route": () => {
            const index = launcher.results.findIndex(row => row.data === root.scenario.route);
            if (index < 0) return false;
            launcher.activate(index);
            return true;
        },
        "open-volume": () => {
            const index = launcher.results.findIndex(row => row.data === "output-volume");
            if (index < 0 || !AudioService.outputAvailable) return false;
            launcher.openEditor(index);
            return true;
        },
        "activate-current": () => {
            if (!launcher.isSelectable(launcher.results[launcher.selectedIndex])) return false;
            launcher.activate(launcher.selectedIndex);
            return true;
        },
        "focus-search": () => { launcher.focusSearch(); return true; },
        "close-editor": () => {
            if (!launcher.expandedAudioId && !launcher.expandedNetworkId) return false;
            launcher.closeEditor();
            return true;
        }
    })

    function openLevel(id: string): bool {
        const index = launcher.results.findIndex(row => row.data === id);
        if (index < 0 || !launcher.isSelectable(launcher.results[index])) return false;
        launcher.openEditor(index);
        return true;
    }

    function applyControl(group: int, option: int): bool {
        if (!root.controls[group]?.options[option]) return false;
        if (!root.scenario.apply(group, option)) return false;
        root.record("scenario", "applied", {
            group: root.controls[group].label, option: root.controls[group].options[option].label
        });
        return true;
    }

    function runAction(name: string): bool {
        if (ShellState.modal !== "launcher") return false;
        const handler = root.actionHandlers[name];
        if (!handler || !handler()) return false;
        root.record("action", name, {});
        return true;
    }

    function triggerAction(index: int): bool {
        return root.runAction(root.actions[index]?.trigger ?? "");
    }

    function key(targetName: string, name: string): bool {
        const target = root.integration.targets[targetName];
        if (typeof target !== "function" || !root.inputDriver
                || typeof root.inputDriver.key !== "function") return false;
        const item = target();
        return item !== null && root.inputDriver.key(item, name) === true;
    }

    function dumpTree(): void {
        root.inspectionReady({ story: `action-menu-${root.menuVariant}`, detail: launcher.detailId,
            selectedIdentity: launcher.selectedIdentity, inputRegion: launcher.inputRegion,
            editor: launcher.expandedAudioId || launcher.expandedNetworkId });
    }

    onResetGenerationChanged: root.resetStory()
    onMenuVariantChanged: root.resetStory()
    Component.onCompleted: root.resetStory()
    Component.onDestruction: {
        root.observing = false;
        ShellState.closeModal();
        ShellState.focusedScreen = null;
    }

    Timer {
        id: restoreObservation
        interval: 0
        onTriggered: { root.openRoute(); root.observing = true; }
    }
    Rectangle { anchors.fill: parent; color: Theme.band }
    QsmShellComponents.ScenePointer {
        id: pointer
        onPointChanged: ShellState.keyboardOwnsSelection = false
    }
    QsmShellComponents.ShellBorder {
        id: border
        anchors.fill: parent
        leftEdge: QsmShellStyle.Style.frameThickness
        pointer: pointer
        entryFilter: id => id === "launcher" || id === "launcher-catch"
    }
    QtObject { id: screenFacts; readonly property string name: "action-menu-preview" }
    QtObject {
        id: sceneFacts
        readonly property var modelData: screenFacts
        readonly property bool fullscreen: false
        readonly property bool focusMode: false
    }
    ModalHost {
        id: modal
        scene: sceneFacts
        host: border
        name: "launcher"
        edges: ["bottom"]
        bodyWidth: Math.min(Theme.launcherWidth, root.width - QsmShellStyle.Style.space6 * 2)
        bodyHeight: Math.min(launcher.preferredBodyHeight, root.height - QsmShellStyle.Style.space6 * 2)
        onOpened: launcher.open()

        Launcher.LauncherSurface {
            id: launcher
            anchors.fill: parent
            commandNames: ["action"]
            actionIds: root.scenario.actions
            networkBackend: NetworkService
            bluetoothBackend: BluetoothService
            persistRanking: false
            applicationsEnabled: false
            onInteracted: (action, detail) => root.record("component", "interacted",
                Object.assign({ action: action }, detail))
        }
    }
    // Component intent and service outcome stay separate events, not one merged
    // line. Each scenario declares the services it can actually hear from: a
    // listener for a signal that does not exist is a startup warning, not a
    // record of anything.
    readonly property var services: root.scenario.services
    Instantiator {
        model: root.services
        delegate: Connections {
            required property var modelData
            target: modelData
            function onOperated(operation: string, phase: string, value: var): void {
                root.record("service", "operated", { operation: operation, phase: phase, value: value });
            }
        }
    }
}
