import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    color: Theme.background
    exclusiveZone: 0
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "qsm-wallpaper"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    // The ready incoming image fades above the opaque outgoing one. Loading
    // or failed images never replace the current frame.
    Item {
        id: crossfade
        anchors.fill: parent

        property bool showingFirst: true
        property bool hasImage: false
        property real reveal: 1
        readonly property string wallpaperSource: "file://" + Quickshell.shellPath(Theme.wallpaper)

        function loadWallpaper(): void {
            const current = showingFirst ? first : second;
            if (hasImage && String(current.source) === wallpaperSource)
                return;
            // A newer request settles the current frame before reusing the
            // outgoing image; an async load must not expose an empty layer.
            fade.stop();
            reveal = 1;
            const incoming = hasImage && showingFirst ? second : first;
            incoming.source = wallpaperSource;
            if (incoming.status === Image.Ready)
                present(incoming);
        }

        function present(image: var): void {
            if (String(image.source) !== wallpaperSource)
                return;
            const nextFirst = image === first;
            if (hasImage && showingFirst === nextFirst)
                return;
            fade.stop();
            const animate = hasImage && !Theme.reducedMotion && Theme.themeSwapDuration > 0;
            showingFirst = nextFirst;
            hasImage = true;
            reveal = animate ? 0 : 1;
            if (animate)
                fade.start();
        }

        onWallpaperSourceChanged: Qt.callLater(loadWallpaper)
        Component.onCompleted: loadWallpaper()

        NumberAnimation {
            id: fade
            target: crossfade
            property: "reveal"
            to: 1
            duration: Theme.themeSwapDuration
        }

        Image {
            id: first
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            z: crossfade.showingFirst ? 1 : 0
            opacity: crossfade.showingFirst ? crossfade.reveal : 1
            onStatusChanged: {
                if (status === Image.Ready)
                    crossfade.present(first);
            }
        }

        Image {
            id: second
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            z: crossfade.showingFirst ? 0 : 1
            opacity: crossfade.showingFirst ? 1 : crossfade.reveal
            onStatusChanged: {
                if (status === Image.Ready)
                    crossfade.present(second);
            }
        }
    }
}
