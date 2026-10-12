import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    color: "transparent"
    exclusiveZone: 0
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "qsm-wallpaper"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    // Per-theme wallpaper with a 200ms cross-fade (7b/11): two stacked
    // images swap roles so the outgoing frame stays under the incoming one.
    Item {
        id: crossfade
        anchors.fill: parent

        property bool showingFirst: true
        readonly property string wallpaperSource: "file://" + Quickshell.shellPath(Theme.wallpaper)

        onWallpaperSourceChanged: {
            if (showingFirst)
                second.source = wallpaperSource;
            else
                first.source = wallpaperSource;
            showingFirst = !showingFirst;
        }

        Component.onCompleted: first.source = wallpaperSource

        Image {
            id: first
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: crossfade.showingFirst ? 1 : 0

            // Wallpaper crossfade rides the same clock as the palette swap.
            Behavior on opacity { NumberAnimation { duration: Theme.themeSwapDuration } }
        }

        Image {
            id: second
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: crossfade.showingFirst ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: Theme.themeSwapDuration } }
        }
    }
}
