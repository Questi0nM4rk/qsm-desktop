import QtQuick
import qs.modules.bar as Bar
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
    readonly property real contentExtentWidth: width
    readonly property real contentExtentHeight: height
    readonly property var controls: [{ label: "Radio", options: [{ label: "On" }, { label: "Off" }] }]
    readonly property var actions: [{ label: "Join network", trigger: "join-network" },
        { label: "Close password", trigger: "close-password" }, { label: "Toggle radio", trigger: "toggle-radio" }]
    readonly property var integration: ({
        events: ["interacted", "operated"], actions: root.actions.map(action => action.trigger),
        runAction: name => root.runAction(name),
        targets: { password: () => content.passwordTarget },
        observables: {
            "prompt": () => content.promptSsid,
            "prompt-state": () => content.promptState,
            "connected": () => NetworkService.networks.some(network => network.ssid === "Guest" && network.active),
            "keyboard-grab": () => ShellState.keyboardGrab,
            "draft-empty": () => content.promptPassword.length === 0,
            "radio": () => NetworkService.wifiEnabled,
            "radio-armed": () => content.wifiOffArmed,
            "operation-state": () => NetworkService.operationState
        },
        idle: () => !NetworkService.busy && !NetworkService.scanning
    })
    signal eventRecorded(var record)
    signal inspectionReady(var inspection)
    width: previewEnvironment?.screenRect?.width ?? viewportWidth
    height: previewEnvironment?.screenRect?.height ?? viewportHeight

    function resetStory(): void {
        content.closePrompt();
        content.wifiOffArmed = false;
        ShellState.reset();
        NetworkService.reset();
        NetworkService.networks = [{ ssid: "Guest", active: false, secure: true,
            signal: 65, device: "preview-wifi" }];
        NetworkService.nextConnectFails = true;
    }
    function applyControl(group: int, option: int): bool {
        if (group !== 0 || option < 0 || option > 1) return false;
        NetworkService.wifiEnabled = option === 0;
        return true;
    }
    function runAction(name: string): bool {
        const handlers = {
            "join-network": () => content.operate("connect", "Guest"),
            "close-password": () => {
                if (!content.promptSsid && !content.promptMayOpen) return false;
                content.closePrompt();
                return true;
            },
            "toggle-radio": () => content.toggleWifi()
        };
        if (!handlers[name]) return false;
        return handlers[name]() === true;
    }
    function triggerAction(index: int): bool { return runAction(actions[index]?.trigger ?? ""); }
    function dumpTree(): void { inspectionReady({ story: "network-popout", prompt: content.promptSsid }); }
    onResetGenerationChanged: resetStory()
    Component.onCompleted: resetStory()
    Component.onDestruction: { NetworkService.reset(); ShellState.reset(); }
    Rectangle { anchors.fill: parent; color: Theme.band }
    Rectangle {
        anchors.centerIn: content
        width: content.width + Theme.space4 * 2
        height: content.height + Theme.space4 * 2
        radius: Theme.rolloutRadius
        color: Theme.band
    }
    Bar.NetworkPopoutContent {
        id: content
        width: Theme.popoutWidth - Theme.space4 * 2
        anchors.centerIn: parent
        onInteracted: (action, payload) => root.eventRecorded({ origin: "component", kind: "network",
            name: "interacted", payload: Object.assign({ action: action }, payload) })
    }
    Connections {
        target: NetworkService
        function onOperated(operation: string, phase: string, value: var): void {
            root.eventRecorded({ origin: "service", kind: "network", name: "operated", payload: { operation, phase, value } });
        }
    }
}
