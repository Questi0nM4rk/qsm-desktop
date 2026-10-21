import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// One >theme carousel card (07, caelestia WallpaperList idea):
// wallpaper thumbnail + name, scaled/dimmed off-center so the centered card
// reads as the selection.
//
// Hover SELECTS (07), like every other result
// surface. The hovered card becomes the centered one — one cursor shared by
// pointer and keyboard — so Enter always applies the card that is visibly
// marked. Hover adds no growth of its own: selection IS the response, and a
// 1.04 hover scale outrunning the selected card's 1.0 was the defect. The
// hover and press response is a colour veil over the photo, never a resize.
//
// One owner for scale and opacity: the card's own centred/receded binding.
// The StateLayer is told `target: null`, otherwise it would write `scale` over
// the same property.
QsmShellComponents.Card {
    id: root

    // { kind: "theme", label, sub, thumb, data } — see LauncherSurface.results.
    required property var item
    required property bool centered
    // How far the caption's ground fades toward the shadow colour: enough to
    // keep the name legible over any wallpaper.
    readonly property real captionScrim: 0.65
    signal activated
    signal hoveredEntered

    implicitWidth: Theme.launcherThemeCardWidth
    implicitHeight: Theme.launcherThemeCardHeight
    surfaceColor: Theme.surface
    clip: true
    // A photo card stays flat: no glow edge, no shadow over the picture.
    glow: false
    shadow: false
    // Off-centre cards recede by the nearest scale token and the pick-list
    // opacity token.
    scale: centered ? 1 : QsmShellStyle.Motion.rowPressScale
    opacity: centered ? 1 : QsmShellStyle.Style.opacityRecede

    Behavior on scale { NumberAnimation { duration: QsmShellStyle.Motion.fast; easing.type: QsmShellStyle.Motion.standardEasing } }
    Behavior on opacity { NumberAnimation { duration: QsmShellStyle.Motion.fast; easing.type: QsmShellStyle.Motion.standardEasing } }

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
        height: caption.implicitHeight + QsmShellStyle.Style.space3 * 3
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Qt.alpha(QsmShellStyle.Style.shadow, root.captionScrim) }
        }
    }

    // Hover and press are a veil of the text colour over the photo; the
    // photo has no body colour for Style.tone to lift.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.text
        opacity: interaction.pressed ? QsmShellStyle.Style.opacitySelected * 2
            : interaction.hovered ? QsmShellStyle.Style.opacitySelected : 0

        Behavior on opacity { NumberAnimation { duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing } }
    }

    Column {
        id: caption
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: QsmShellStyle.Style.space3
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
        id: interaction
        anchors.fill: parent
        target: null
        focusRadius: root.radius
        onClicked: root.activated()
        onHoveredEntered: root.hoveredEntered()
    }
}
