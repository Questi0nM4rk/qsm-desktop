import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.state
import qs.theme

// The bell in the top-right corner (04, owner 2026-10-17, read state
// 2026-10-18). Two places, one glyph:
//   unread, menu open or pointer on it: a bulge out of the top band, flush
//     with the right frame, carrying the bell and the unread count;
//   everything read: the bulge retracts and the bell travels DIAGONALLY up
//     and right into the frame's top-right corner, where it sits on the band.
// The glyph rides the bulge's own reveal (`revealProgress`), so the two are
// one motion on the library's reveal curves and honour reduced motion with
// it. The corner has a generous hover zone (Style.hoverReach past the
// glyph), not the glyph's 16px. Entering it opens the notification menu (the
// `notifications` modal) with no delay; the scene closes the menu 180ms
// after the pointer has left both the bell zone and the menu.
Item {
    id: root

    required property var scene
    required property var host
    readonly property int unread: NotificationService.unreadCount
    readonly property bool menuOpen: ShellState.modal === "notifications"
    // Live popups roll out of the same corner; the bell steps back while
    // they are on screen, and in fullscreen or focus mode like every handle.
    readonly property bool shown: !root.scene.fullscreen && !root.scene.focusMode
        && !root.scene.popupActive

    // Where the glyph lives: on the band's corner, or centred in the bulge.
    readonly property point cornerCenter: Qt.point(root.width - Theme.frameThickness,
        Theme.frameThickness)
    readonly property rect cornerRect: Qt.rect(cornerCenter.x - Theme.iconSm / 2,
        cornerCenter.y - Theme.iconSm / 2, Theme.iconSm, Theme.iconSm)
    readonly property rect bulgeRect: Qt.rect(root.width - Theme.notificationBellWidth,
        Theme.frameThickness, Theme.notificationBellWidth, Theme.notificationBellHeight)
    readonly property point bulgeCenter: Qt.point(bulgeRect.x + bulgeRect.width / 2,
        bulgeRect.y + bulgeRect.height / 2)

    // Hover zones, painted shape grown by the reach. The corner zone finds
    // the glyph at rest; the bulge zone covers glyph and bulge together while
    // the bulge is up, so a pointer that drifts off the glyph inside the
    // bulge does not retract it.
    readonly property rect _bounds: Qt.rect(0, 0, root.width, root.height)
    readonly property rect cornerZone: QsmShellStyle.Style.hoverZone(cornerRect, _bounds)
    readonly property rect bulgeZone: QsmShellStyle.Style.hoverZone(Qt.rect(
        Math.min(cornerRect.x, bulgeRect.x), Math.min(cornerRect.y, bulgeRect.y),
        Math.max(cornerRect.x + cornerRect.width, bulgeRect.x + bulgeRect.width)
            - Math.min(cornerRect.x, bulgeRect.x),
        Math.max(cornerRect.y + cornerRect.height, bulgeRect.y + bulgeRect.height)
            - Math.min(cornerRect.y, bulgeRect.y)), _bounds)

    // The bulge stays up for unread or an open menu; otherwise only while
    // the pointer is on the corner. `hovered` reads the pointer, not the
    // bulge, so it cannot depend on the bulge it decides.
    readonly property bool sticky: root.unread > 0 || root.menuOpen
    readonly property bool hovered: !!root.host.pointer
        && root.host.pointer.contains(root.sticky ? root.bulgeZone : root.cornerZone)
    readonly property bool bulged: root.sticky || root.hovered
    // The input mask must hold the zone for the pointer to be seen at all.
    readonly property rect maskZone: root.shown
        ? (root.sticky ? root.bulgeZone : root.cornerZone) : Qt.rect(0, 0, 0, 0)

    anchors.fill: parent

    onHoveredChanged: {
        if (hovered && root.shown && ShellState.modal === "none")
            ShellState.toggleModal("notifications");
    }

    QsmShellComponents.Rollout {
        id: bulge
        host: root.host
        rolloutId: "notify-bell"
        edges: ["top", "right"]
        tier: "small"
        edgeInsetH: 0
        shouldBeActive: root.shown && root.bulged
        suppressed: root.scene.fullscreen || root.scene.focusMode
        fullscreenDetached: false
        fullscreenCapsule: false
        animateBodySize: false
        bodyWidth: Theme.notificationBellWidth
        bodyHeight: Theme.notificationBellHeight
        anchors.top: parent.top
        anchors.right: parent.right

        Item {
            parent: bulge.contentItem
            anchors.fill: parent

            QsmShellComponents.Badge {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spaceTight
                visible: root.unread > 0
                tone: "accent"
                filled: true
                text: String(root.unread)
            }

            QsmShellComponents.StateLayer {
                anchors.fill: parent
                target: null
                interactive: root.shown
                onClicked: if (ShellState.modal !== "notifications") ShellState.toggleModal("notifications")
            }
        }
    }

    // The glyph is not bulge content: the bulge's clip would cut it off the
    // moment it retracts, and it has to stay on the band.
    Item {
        id: glyph
        width: Theme.iconSm
        height: Theme.iconSm
        visible: root.shown
        x: root.cornerCenter.x + (root.bulgeCenter.x - root.cornerCenter.x) * bulge.revealProgress
            - width / 2
        y: root.cornerCenter.y + (root.bulgeCenter.y - root.cornerCenter.y) * bulge.revealProgress
            - height / 2

        QsmShellComponents.SvgIcon {
            anchors.centerIn: parent
            name: "bell"
            size: Theme.iconSm
            color: root.unread > 0 ? Theme.text : Theme.textMuted
        }

        // Tucked into the corner with nothing unread, the bell is a hint,
        // not a control asking to be read: it recedes as the bulge retracts
        // and comes back to full strength as the bulge returns (owner
        // 2026-10-19: "vic opaque, jakoze little invisible").
        opacity: Theme.opacityRecede + (1 - Theme.opacityRecede) * bulge.revealProgress
    }

    // The corner's click target is the whole zone, like its hover.
    QsmShellComponents.StateLayer {
        x: root.cornerZone.x
        y: root.cornerZone.y
        width: root.cornerZone.width
        height: root.cornerZone.height
        target: glyph
        interactive: root.shown
        onClicked: if (ShellState.modal !== "notifications") ShellState.toggleModal("notifications")
    }
}
