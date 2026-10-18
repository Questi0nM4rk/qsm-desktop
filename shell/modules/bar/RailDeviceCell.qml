import QtQuick
import Quickshell.Bluetooth
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// ONE cell for bluetooth, whatever is connected (owner 2026-08-18).
//
// Nothing connected  -> the bluetooth mark itself.
// One device         -> that device's glyph, full size.
// Two to four        -> the cell subdivides and the glyphs shrink with it,
//                       split by a thin cross. Past four, further devices
//                       simply do not appear — the cell stops subdividing
//                       rather than turning into confetti.
//
// WHY one cell: connected devices are secondary information, and the rail's
// preservation order (system-design: responsive) puts them below the clock
// and the app list. A cell per device grew the cluster and squashed the pills
// above it, which is exactly the failure that order exists to prevent.
RailEntry {
    id: root

    // NO local `popouts` property. RailEntry already owns one, and
    // re-declaring it here SHADOWED the base's: Rail filled the derived
    // property while the entry's own rollout wiring kept reading the base one,
    // which stayed null — so this cell had no rollout. That shadowing, found by
    // qmllint's property-override check, was the real cause of the dead
    // bluetooth hover; the hand-rolled HoverHandler that appeared to fix it was
    // only reading the derived property. Never redeclare a base property.
    readonly property var connected: (Bluetooth.devices?.values ?? [])
        .filter(device => device.connected)
        .slice(0, Theme.railDeviceMax)
    readonly property int shown: connected.length
    readonly property bool adapterOn: Bluetooth.defaultAdapter?.enabled ?? false

    // The empty state is the entry's own icon; anything connected is drawn by
    // the grid below, so the base glyph steps aside.
    icon: root.shown > 0 ? "" : (root.adapterOn ? "bluetooth" : "bluetooth-off")
    popoutKind: "bluetooth"
    popoutTitle: "Bluetooth"
    popoutDetail: ""
    // Behaves like every other cell: hover shows the rollout and tints, click
    // does the one cheap toggle (the adapter), and the rollout owns the escape
    // to blueman. The glyph grid goes in the base entry's content slot, so
    // hover keeps coming from the shared StateLayer.
    interactive: true
    onClicked: {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    }

    // Two columns once there is more than one device; the second row only
    // exists from the third device onward.
    readonly property int columns: shown > 1 ? 2 : 1
    readonly property int rows: shown > 2 ? 2 : 1
    // Any split at all drops to the smallest glyph: a subdivided 40px cell
    // gives each device a 20px box, and a 16px glyph in it touched the cross.
    // 12px leaves 4px of clearance on every side of the line. Undivided, the
    // cell matches RailEntry's own glyph so the cluster reads as one column.
    readonly property int glyphSize: shown > 1 ? Theme.iconXs : Theme.iconSm

    Item {
        id: grid

        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        visible: root.shown > 0

        Repeater {
            model: root.connected

            QsmShellComponents.SvgIcon {
                required property var modelData
                required property int index

                readonly property int column: root.columns > 1 ? index % 2 : 0
                readonly property int row: root.rows > 1 ? Math.floor(index / 2) : 0

                x: root.columns > 1
                    ? column * (grid.width / 2) + (grid.width / 2 - width) / 2
                    : (grid.width - width) / 2
                y: root.rows > 1
                    ? row * (grid.height / 2) + (grid.height / 2 - height) / 2
                    : (grid.height - height) / 2
                size: root.glyphSize
                name: Glyphs.forDevice(modelData.icon, modelData.name)
                color: Theme.textMuted
            }
        }

        // The cross: vertical bar with the second device, horizontal with the
        // third. Each arm is a stub sized to the glyphs it separates — a rule
        // spanning the whole cell dwarfed the 12px glyphs on either side of it.
        readonly property real armLength: Math.round(root.glyphSize * 1.2)

        // The rail's own rule, so weight and strength stay the divider's.
        RailDivider {
            anchors.centerIn: parent
            visible: root.shown > 1
            inset: 0
            width: grid.armLength
            rotation: 90
        }

        RailDivider {
            anchors.centerIn: parent
            visible: root.shown > 2
            inset: 0
            width: grid.armLength
        }
    }
}
