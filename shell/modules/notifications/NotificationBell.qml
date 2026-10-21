import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.state
import qs.theme

// The bell in the top-right corner (04). Two places, one glyph:
//   unread, or the pointer on it: a bulge out of the top band, flush with the
//     right frame, carrying the bell and, with unread, its count beside it;
//   everything read: the bulge retracts and the bell travels DIAGONALLY up
//     and right into the frame's top-right corner, where it sits on the band.
// The glyph rides the bulge's own reveal (`revealProgress`), so the two are
// one motion on the library's reveal curves and honour reduced motion with
// it. Entering the control opens the notification menu (the
// `notifications` modal) with no delay; the scene closes the menu 180ms
// after the pointer has left both the bell zone and the menu. The menu grows
// out of this same corner, so the bell gives way to it: its glyph, count and
// click zone withdraw while the menu is open, and the menu's own header owns
// that corner.
Item {
    id: root

    required property var scene
    required property var host
    readonly property int unread: NotificationService.unreadCount
    readonly property bool menuOpen: ShellState.modal === "notifications"
    readonly property bool counted: root.unread > 0
    // Live popups roll out of the same corner; the bell steps back while
    // they are on screen, and in fullscreen or focus mode like every handle.
    readonly property bool shown: !root.scene.fullscreen && !root.scene.focusMode
        && !root.scene.popupActive

    // Where the glyph lives: on the band's rounded corner fill, one frame
    // thickness in from each edge, or in the bulge. Half a thickness would
    // clip the 16px glyph.
    readonly property point cornerCenter: Qt.point(root.width - QsmShellStyle.Style.frameThickness,
        QsmShellStyle.Style.frameThickness)
    readonly property rect cornerRect: Qt.rect(cornerCenter.x - QsmShellStyle.Style.iconSm / 2,
        cornerCenter.y - QsmShellStyle.Style.iconSm / 2, QsmShellStyle.Style.iconSm, QsmShellStyle.Style.iconSm)
    // The bulge's width is the rollout's own animated one, so the glyph and
    // the chip follow it when the count arrives under an open bulge.
    readonly property real bulgeWidth: bulge.bodyWidth
    readonly property rect bulgeRect: Qt.rect(root.width - root.bulgeWidth,
        QsmShellStyle.Style.frameThickness, root.bulgeWidth, Theme.notificationBellHeight)
    // Centred in the bulge; with the count, the glyph takes the left pad and
    // the chip the rest.
    readonly property point glyphCenter: Qt.point(root.counted
        ? bulgeRect.x + Theme.notificationBellPad + QsmShellStyle.Style.iconSm / 2
        : bulgeRect.x + bulgeRect.width / 2, bulgeRect.y + bulgeRect.height / 2)
    readonly property real chipX: bulgeRect.x + Theme.notificationBellPad
        + QsmShellStyle.Style.iconSm + QsmShellStyle.Style.space1

    // Hover zones: the control itself, never a reach grown around it. At rest
    // that is the glyph raised to the target floor, in the screen's corner;
    // with the bulge up it is the bulge, plus the strip of band between it and
    // the monitor edge so a pointer thrown into the corner still finds it.
    readonly property real _floor: QsmShellStyle.Style.size("Control", "xs")
    readonly property rect cornerZone: Qt.rect(Math.min(root.width - root._floor, cornerCenter.x - root._floor / 2),
        Math.max(0, cornerCenter.y - root._floor / 2), root._floor, root._floor)
    readonly property rect bulgeZone: Qt.rect(bulgeRect.x, 0, bulgeRect.width, bulgeRect.y + bulgeRect.height)

    // The bulge stays up for unread or an open menu; otherwise only while
    // the pointer is on the corner. `hovered` reads the pointer, not the
    // bulge, so it cannot depend on the bulge it decides.
    readonly property bool sticky: root.counted || root.menuOpen
    readonly property bool hovered: !!root.host.pointer
        && root.host.pointer.contains(root.sticky ? root.bulgeZone : root.cornerZone)
    readonly property bool bulged: root.sticky || root.hovered
    // The input mask must hold the zone for the pointer to be seen at all.
    readonly property rect maskZone: root.shown
        ? (root.sticky ? root.bulgeZone : root.cornerZone) : Qt.rect(0, 0, 0, 0)
    // The click zone is the live zone, except while the menu is open: its
    // header controls sit under it and are the only targets there.
    readonly property rect clickZone: root.menuOpen ? Qt.rect(0, 0, 0, 0)
        : root.sticky ? root.bulgeZone : root.cornerZone

    // The bell gives way to the menu it opens.
    property real presence: root.menuOpen ? 0 : 1
    Behavior on presence {
        NumberAnimation { duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing }
    }

    anchors.fill: parent

    // One route for pointer, keyboard and screen reader.
    function open(): void {
        if (ShellState.modal !== "notifications")
            ShellState.toggleModal("notifications");
    }

    activeFocusOnTab: root.shown
    Accessible.role: Accessible.Button
    Accessible.name: "Notifications"
    Accessible.description: (ShellState.dnd ? "Do not disturb. " : "")
        + (root.unread > 0 ? `${root.unread} unread` : "No unread notifications")
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
            ShellState.toggleModalByPointer("notifications");
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
        animateBodySize: true
        bodyWidth: root.counted ? Theme.notificationBellCountedWidth : Theme.notificationBellWidth
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
        visible: root.shown && root.presence > 0
        x: root.cornerCenter.x + (root.glyphCenter.x - root.cornerCenter.x) * bulge.revealProgress
            - width / 2
        y: root.cornerCenter.y + (root.glyphCenter.y - root.cornerCenter.y) * bulge.revealProgress
            - height / 2

        // Do not disturb is a different glyph, so the mode reads from one
        // frame: the moon is the menu's own do-not-disturb mark.
        QsmShellComponents.SvgIcon {
            anchors.centerIn: parent
            name: ShellState.dnd ? "moon" : "bell"
            size: QsmShellStyle.Style.iconSm + 2 * bellLayer.growth
            color: QsmShellStyle.Style.tone(root.unread > 0 ? Theme.text : Theme.textMuted,
                bellLayer.hovered, bellLayer.pressed, false, root.shown, Theme.accent)
        }

        // Tucked into the corner with nothing unread, the bell is a hint,
        // not a control asking to be read: it recedes as the bulge retracts
        // and comes back to full strength as the bulge returns.
        opacity: (QsmShellStyle.Style.opacityRecede
            + (1 - QsmShellStyle.Style.opacityRecede) * bulge.revealProgress) * root.presence
    }

    // The count sits beside the glyph, never over it: a chip over a 16px
    // glyph covered the whole bell.
    QsmShellComponents.Badge {
        x: root.chipX
        y: root.glyphCenter.y - height / 2
        visible: root.shown && root.counted && opacity > 0
        opacity: bulge.revealProgress * root.presence
        tone: "accent"
        filled: true
        text: String(root.unread)
    }

    // The one click target is the whole live zone, like its hover: the
    // corner at rest, glyph and bulge together while the bulge is up. The
    // glyph answers it, growing a little and pushing in on press.
    QsmShellComponents.StateLayer {
        id: bellLayer
        x: root.clickZone.x
        y: root.clickZone.y
        width: root.clickZone.width
        height: root.clickZone.height
        extent: QsmShellStyle.Style.iconSm
        pressScale: QsmShellStyle.Motion.pressScale
        focused: root.activeFocus
        focusRadius: QsmShellStyle.Style.radiusMd
        interactive: root.shown && !root.menuOpen
        onClicked: root.open()
    }
}
