import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.state
import qs.theme

// Four invisible 1x1 windows whose only job is reserving the frame's edge
// zones from tiling. One definition, one edge table — the left edge reserves
// the rail too.
Scope {
    id: root

    required property var modelData
    readonly property bool fullscreen: FullscreenService.fullscreenFor(modelData)
    readonly property bool focusMode: FocusModeService.active
        && FocusModeService.targetScreen === modelData.name

    // The left zone reserves the rail — unless this monitor's rail is
    // collapsed, in which case only the frame strip stays reserved and the
    // windows get the space back.
    Variants {
        model: [
            {
                side: "left",
                zone: (root.focusMode || ShellState.isRailCollapsed(root.modelData.name))
                    ? Theme.frameThickness : Theme.reservedLeft
            },
            { side: "top", zone: Theme.frameThickness },
            { side: "right", zone: Theme.frameThickness },
            { side: "bottom", zone: Theme.frameThickness }
        ]

        delegate: Component {
            PanelWindow {
                required property var modelData

                screen: root.modelData
                color: "transparent"
                exclusiveZone: root.fullscreen ? 0 : modelData.zone
                implicitWidth: 1
                implicitHeight: 1
                mask: Region {}
                WlrLayershell.namespace: "qsm-frame-" + modelData.side + "-exclusion"
                anchors.left: modelData.side === "left"
                anchors.top: modelData.side === "top"
                anchors.right: modelData.side === "right"
                anchors.bottom: modelData.side === "bottom"
            }
        }
    }
}
