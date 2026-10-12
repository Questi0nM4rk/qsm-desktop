pragma Singleton

import QtQuick
import Quickshell.Bluetooth
import qs.services

// Bluetooth operations in one place: Quickshell owns the adapter and devices,
// this service owns the LIFETIME of an operation (pending, completed, failed,
// gone, timed out) so a menu delegate is not the thing that has to remember
// it. Pairing that needs an agent or a passkey still belongs to the manager.
QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.devices.values ?? []
    readonly property bool available: !!adapter
    readonly property bool busy: operationState === "pending"
    property string operationState: "idle"
    property string operationTarget: ""
    property string operationError: ""
    property string operationName: ""
    property bool desiredState: false
    property int ticks: 0
    signal operated(string operation, string phase, var value)

    function deviceFor(address: string): var {
        return root.devices.find(device => device.address === address) ?? null;
    }

    function operate(target: string): bool {
        if (!root.available || root.busy) return false;
        const device = root.deviceFor(target);
        if (target !== "adapter-power" && target !== "discovery"
                && (!root.adapter.enabled || !device)) return false;
        if (device && !device.paired) return Delegate.open("bluetooth");
        root.operationName = target === "adapter-power" ? "bluetooth-radio"
            : target === "discovery" ? "bluetooth-discovery"
            : device.connected ? "bluetooth-disconnect" : "bluetooth-connect";
        root.operationTarget = target;
        root.desiredState = target === "adapter-power" ? !root.adapter.enabled
            : target === "discovery" ? !root.adapter.discovering : !device.connected;
        root.operationError = "";
        root.ticks = 0;
        root.operationState = "pending";
        root.operated(root.operationName, "pending", target);
        if (target === "adapter-power") root.adapter.enabled = root.desiredState;
        else if (target === "discovery") root.adapter.discovering = root.desiredState;
        else if (root.desiredState) device.connect();
        else device.disconnect();
        completion.restart();
        return true;
    }

    function forget(address: string): bool {
        const device = root.deviceFor(address);
        if (root.busy || !device || !device.paired) return false;
        root.operationName = "bluetooth-forget";
        root.operationTarget = address;
        root.operationError = "";
        root.ticks = 0;
        root.operationState = "pending";
        root.operated(root.operationName, "pending", address);
        device.forget();
        completion.restart();
        return true;
    }

    function finish(error: string): void {
        completion.stop();
        root.operationError = error;
        root.operationState = error.length ? "failed" : "completed";
        root.operated(root.operationName, root.operationState,
            { target: root.operationTarget, error: error });
    }

    property Timer completion: Timer {
        interval: 100
        repeat: true
        onTriggered: {
            const device = root.deviceFor(root.operationTarget);
            if (!root.available) root.finish("Bluetooth adapter disappeared");
            else if (root.operationName === "bluetooth-forget" && (!device || !device.paired)) root.finish("");
            else if (root.operationTarget === "adapter-power" && root.adapter.enabled === root.desiredState) root.finish("");
            else if (root.operationTarget === "discovery" && root.adapter.discovering === root.desiredState) root.finish("");
            else if (root.operationName !== "bluetooth-forget" && device && device.connected === root.desiredState) root.finish("");
            else if (root.operationTarget !== "adapter-power" && root.operationTarget !== "discovery" && !device)
                root.finish("Device is no longer available");
            else if (++root.ticks >= 300) root.finish("Bluetooth operation timed out; check the adapter and retry");
        }
    }
}
