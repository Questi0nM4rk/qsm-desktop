import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// One >theme carousel card (07 RATIFIED, caelestia WallpaperList idea):
// wallpaper thumbnail + name, scaled/dimmed off-center so the centered card
// reads as the selection.
//
// UX-3 (07 RATIFIED 2026-08-25): hover SELECTS, like every other result
// surface. The hovered card becomes the centered one — one cursor shared by
// pointer and keyboard — so Enter always applies the card that is visibly
// marked. Hover adds no growth of its own: selection IS the response, and a
// 1.04 hover scale outrunning the selected card's 1.0 was the defect.
QsmShellComponents.Card {
    id: root

    // { kind: "theme", label, sub, thumb, data } — see LauncherSurface.results.
    required property var item
    required property bool centered
    signal activated
    signal hoveredEntered

    implicitWidth: Theme.launcherThemeCardWidth
    implicitHeight: Theme.launcherThemeCardHeight
    surfaceColor: Theme.surfaceRaised
    // Opaque: this card carries a full-bleed photo, not the translucent
    // wash Card defaults to for a panel sitting over the band.
    surfaceOpacity: 1
    clip: true
    border.width: centered ? 2 : 0
    border.color: Theme.accent
    scale: centered ? 1 : 0.85
    opacity: centered ? 1 : 0.55

    Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing } }
    Behavior on opacity { NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing } }

    Image {
        anchors.fill: parent
        source: root.item.thumb ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.4
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.65) }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space3
        spacing: 0

        QsmShellComponents.Prose {
            width: parent.width
            role: "title"
            text: root.item.label
        }

        QsmShellComponents.Prose {
            width: parent.width
            visible: text.length > 0
            role: "metadata"
            color: Theme.accent
            text: root.item.sub ?? ""
        }
    }

    QsmShellComponents.StateLayer {
        anchors.fill: parent
        hoverScale: 1.0
        pressScale: 0.98
        onClicked: root.activated()
        onHoveredEntered: root.hoveredEntered()
    }
}
