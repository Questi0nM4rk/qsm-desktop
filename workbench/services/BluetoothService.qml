pragma Singleton
import QtQuick

// Isolated Bluetooth fixture: synthetic adapter and devices, a scripted reply
// and no path to the real Bluetooth singleton.
QtObject {
    id: root
    property QtObject adapter: QtObject {
        property bool enabled: true
        property bool discovering: false
    }
    property bool available: true
    readonly property bool busy: operationState === "pending"
    property var devices: []
    property string operationState: "idle"
    property string operationError: ""
    property string operationTarget: ""
    property string operationName: ""
    property bool nextFails: false
    property bool desiredState: false
    signal operated(string operation, string phase, var value)

    function operate(target: string): bool {
        const device = root.devices.find(candidate => candidate.address === target);
        if (!root.available || root.busy
                || (target !== "adapter-power" && !root.adapter.enabled)) return false;
        if (target !== "adapter-power" && target !== "discovery" && !device) return false;
        if (device && !device.paired) return Delegate.open("bluetooth");
        root.desiredState = target === "adapter-power" ? !root.adapter.enabled
            : target === "discovery" ? !root.adapter.discovering : !device.connected;
        root.operationName = target === "adapter-power" ? "bluetooth-radio"
            : target === "discovery" ? "bluetooth-discovery"
            : device.connected ? "bluetooth-disconnect" : "bluetooth-connect";
        return root.start(target);
    }

    function forget(address: string): bool {
        if (!root.available || root.busy
                || !root.devices.some(device => device.address === address && device.paired)) return false;
        root.operationName = "bluetooth-forget";
        return root.start(address);
    }

    function start(target: string): bool {
        root.operationTarget = target;
        root.operationError = "";
        root.operationState = "pending";
        root.operated(root.operationName, "pending", target);
        reply.restart();
        return true;
    }

    function reset(): void {
        reply.stop();
        root.available = true;
        root.adapter.enabled = true;
        root.adapter.discovering = false;
        root.operationState = "idle";
        root.operationTarget = "";
        root.operationError = "";
        root.nextFails = false;
        root.devices = [
            { address: "00:11:22:33:44:55", name: "Desk headphones", paired: true, connected: true },
            { address: "00:11:22:33:44:66", name: "Desk keyboard", paired: true, connected: false },
            { address: "00:11:22:33:44:77", name: "BLE temperature sensor", paired: false, connected: false }
        ];
    }

    property Timer reply: Timer {
        interval: 180
        onTriggered: {
            const target = root.operationTarget;
            const device = root.devices.find(candidate => candidate.address === target);
            const error = !root.available ? "Bluetooth adapter disappeared"
                : root.nextFails ? "Device refused the operation"
                : target !== "adapter-power" && target !== "discovery" && !device ? "Device is no longer available" : "";
            root.nextFails = false;
            if (!error) {
                if (target === "adapter-power") {
                    root.adapter.enabled = root.desiredState;
                    if (!root.desiredState) {
                        root.adapter.discovering = false;
                        root.devices = root.devices.map(device => Object.assign({}, device, { connected: false }));
                    }
                } else if (target === "discovery") root.adapter.discovering = root.desiredState;
                else if (root.operationName === "bluetooth-forget")
                    root.devices = root.devices.filter(device => device.address !== target);
                else root.devices = root.devices.map(device => device.address === target
                    ? Object.assign({}, device, { connected: root.desiredState }) : device);
            }
            root.operationError = error;
            root.operationState = error ? "failed" : "completed";
            root.operated(root.operationName, root.operationState, { target: target, error: error });
        }
    }
}