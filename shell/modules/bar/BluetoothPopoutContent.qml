pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.components
import qs.services
import qs.theme

// Bluetooth popout (caelestia's control set): adapter power + discovering
// toggles, devices sorted connected-first with connect/forget, manager for
// pairing depth (BlueZ stays the owner — delegation law).
ColumnLayout {
    id: root

    readonly property var adapter: BluetoothService.adapter
    readonly property var devices: BluetoothService.devices.slice()
        .filter(device => device.paired || device.connected)
        .sort((left, right) => (right.connected ? 1 : 0) - (left.connected ? 1 : 0))
        .slice(0, Theme.popoutDeviceListMax)
    signal interacted(string action, var payload)

    function operate(target: string): void {
        if (BluetoothService.operate(target)) root.interacted("activated", { target: target });
    }
    function forget(address: string): void {
        if (BluetoothService.forget(address)) root.interacted("forget", { address: address });
    }

    // 4 between rows, not 8: whatever groups elements must have MORE space
    // around the group than within it (visual-craft). The section labels below
    // carry the group gap; a uniform 8 made three kinds of thing read as one
    // undifferentiated list.
    spacing: Theme.space1

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space2

        QsmShellComponents.Capsule {

            size: "sm"
            icon: "bluetooth"
            label: (root.adapter?.enabled ?? false) ? "On" : "Off"
            active: root.adapter?.enabled ?? false
            enabled: BluetoothService.available && !BluetoothService.busy
            onClicked: root.operate("adapter-power")
        }

        QsmShellComponents.Capsule {

            size: "sm"
            visible: root.adapter?.enabled ?? false
            icon: "motion"
            label: "Scan"
            active: root.adapter?.discovering ?? false
            enabled: !BluetoothService.busy
            onClicked: root.operate("discovery")
        }

        Item { Layout.fillWidth: true }
    }

    Repeater {
        model: root.devices

        PopoutRow {
            required property var modelData
            Layout.fillWidth: true
            // Clicking the row connects or disconnects — the whole reason the
            // row exists. Forget stays as the tertiary action, and only for
            // bonded devices: an unbonded, discovered-only entry has nothing
            // to forget.
            icon: modelData.connected ? "bluetooth-connected" : "bluetooth"
            label: modelData.name || modelData.address
            value: (modelData.batteryAvailable ?? false)
                ? `${Math.round((modelData.battery ?? 0) * 100)}%` : ""
            active: modelData.connected
            disabled: BluetoothService.busy || !(root.adapter?.enabled ?? false)
            actionIcon: (modelData.bonded ?? false) ? "trash-2" : ""
            actionDanger: true
            onClicked: root.operate(modelData.address)
            onActionTriggered: root.forget(modelData.address)
        }
    }

    QsmShellComponents.Prose {
        role: "metadata"
        visible: root.devices.length === 0
        text: "No paired devices"
    }

    QsmShellComponents.Prose {
        role: "supporting"
        Layout.fillWidth: true
        visible: BluetoothService.operationError.length > 0
        text: BluetoothService.operationError
        color: Theme.warning
    }
    // Protected pairing belongs to the real manager.
    QsmShellComponents.Capsule {
        size: "sm"
        Layout.topMargin: Theme.space1
        icon: "bluetooth"
        label: "Bluetooth settings"
        onClicked: { root.interacted("delegate", { target: "bluetooth" }); Delegate.open("bluetooth"); }
    }
}
