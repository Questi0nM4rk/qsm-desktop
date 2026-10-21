import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.state
import qs.theme

// The bell in the top-right corner (04). Two places, one glyph:
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

    // Where the glyph lives: on the band's rounded corner fill, one frame
    // thickness in from each edge, or
    // centred in the bulge. Half a thickness would clip the 16px glyph.
    readonly property point cornerCenter: Qt.point(root.width - QsmShellStyle.Style.frameThickness,
        QsmShellStyle.Style.frameThickness)
    readonly property rect cornerRect: Qt.rect(cornerCenter.x - QsmShellStyle.Style.iconSm / 2,
        cornerCenter.y - QsmShellStyle.Style.iconSm / 2, QsmShellStyle.Style.iconSm, QsmShellStyle.Style.iconSm)
    readonly property rect bulgeRect: Qt.rect(root.width - Theme.notificationBellWidth,
        QsmShellStyle.Style.frameThickness, Theme.notificationBellWidth, Theme.notificationBellHeight)
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

    // One route for pointer, keyboard and screen reader.
    function open(): void {
        if (ShellState.modal !== "notifications")
            ShellState.toggleModal("notifications");
    }

    activeFocusOnTab: root.shown
    Accessible.role: Accessible.Button
    Accessible.name: "Notifications"
    Accessible.description: root.unread > 0 ? `${root.unread} unread` : "No unread notifications"
    Accessible.onPressAction: root.open()
    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)
            return;
        event.accepted = true;
        if (!event.isAutoRepeat)
            root.open();
    }

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

    }

    // The glyph is not bulge content: the bulge's clip would cut it off the
    // moment it retracts, and it has to stay on the band.
    Item {
        id: glyph
        width: QsmShellStyle.Style.iconSm
        height: QsmShellStyle.Style.iconSm
        visible: root.shown
        x: root.cornerCenter.x + (root.bulgeCenter.x - root.cornerCenter.x) * bulge.revealProgress
            - width / 2
        y: root.cornerCenter.y + (root.bulgeCenter.y - root.cornerCenter.y) * bulge.revealProgress
            - height / 2

        // The count is centred on the glyph's top-right corner and pulled in
        // by a hairline so it stays on screen: a 28px chip flush INSIDE a 16px
        // glyph covered the whole bell.
        QsmShellComponents.Badge {
            anchors.horizontalCenter: parent.right
            anchors.horizontalCenterOffset: -QsmShellStyle.Style.spaceTight
            anchors.verticalCenter: parent.top
            z: 1
            visible: root.unread > 0
            tone: "accent"
            filled: true
            text: String(root.unread)
        }

        QsmShellComponents.SvgIcon {
            anchors.centerIn: parent
            name: "bell"
            size: QsmShellStyle.Style.iconSm
            color: QsmShellStyle.Style.tone(root.unread > 0 ? Theme.text : Theme.textMuted,
                bellLayer.hovered, bellLayer.pressed, false, root.shown, Theme.accent)
        }

        // Tucked into the corner with nothing unread, the bell is a hint,
        // not a control asking to be read: it recedes as the bulge retracts
        // and comes back to full strength as the bulge returns.
        opacity: QsmShellStyle.Style.opacityRecede + (1 - QsmShellStyle.Style.opacityRecede) * bulge.revealProgress
    }

    // The one click target is the whole live zone, like its hover: the
    // corner at rest, glyph and bulge together while the bulge is up. The
    // glyph answers it, growing a little and pushing in on press.
    QsmShellComponents.StateLayer {
        id: bellLayer
        x: (root.sticky ? root.bulgeZone : root.cornerZone).x
        y: (root.sticky ? root.bulgeZone : root.cornerZone).y
        width: (root.sticky ? root.bulgeZone : root.cornerZone).width
        height: (root.sticky ? root.bulgeZone : root.cornerZone).height
        target: glyph
        pressScale: QsmShellStyle.Motion.pressScale
        focused: root.activeFocus
        focusRadius: QsmShellStyle.Style.radiusMd
        interactive: root.shown
        onClicked: root.open()
    }
}
