import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// The bell in the top-right corner (04, owner 2026-10-17): a small bulge
// out of the top band, flush with the right frame, carrying a bell and the
// unread count. With everything read it sinks until half of it is left,
// waiting for a hover. Hovering it, in either state, opens the notification
// menu (the `notifications` modal); the scene closes the menu 180ms after
// the pointer has left both.
Item {
    id: root

    required property var scene
    required property var host
    readonly property int unread: NotificationService.unreadCount
    readonly property bool menuOpen: ShellState.modal === "notifications"
    readonly property bool hovered: hoverReader.hovered
    // Live popups roll out of the same corner; the bell steps back while
    // they are on screen, and in fullscreen or focus mode like every handle.
    readonly property bool shown: !root.scene.fullscreen && !root.scene.focusMode
        && !root.scene.popupActive

    anchors.fill: parent

    QsmShellComponents.Rollout {
        id: bulge
        host: root.host
        rolloutId: "notify-bell"
        edges: ["top", "right"]
        tier: "small"
        edgeInsetH: 0
        shouldBeActive: root.shown
        suppressed: root.scene.fullscreen || root.scene.focusMode
        fullscreenDetached: false
        fullscreenCapsule: false
        animateBodySize: true
        bodyWidth: Theme.notificationBellWidth
        // Half sunk when there is nothing unread and the menu is closed.
        bodyHeight: root.unread > 0 || root.menuOpen || root.hovered
            ? Theme.notificationBellHeight : Theme.notificationBellHeight / 2
        anchors.top: parent.top
        anchors.right: parent.right

        Item {
            // The bell sits at the BOTTOM of the body, so the sunk half shows
            // the bell's lower half and the badge disappears first.
            parent: bulge.contentItem
            anchors.fill: parent

            QsmShellComponents.SvgIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: (Theme.notificationBellHeight - size) / 2
                name: "bell"
                size: Theme.iconSm
                color: root.unread > 0 ? Theme.text : Theme.textMuted
            }

            QsmShellComponents.Badge {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spaceTight
                visible: root.unread > 0
                tone: "accent"
                filled: true
                text: String(root.unread)
            }

            HoverHandler {
                id: hoverReader
                onHoveredChanged: {
                    if (hovered && root.shown && ShellState.modal === "none")
                        ShellState.toggleModal("notifications");
                }
            }

            QsmShellComponents.StateLayer {
                anchors.fill: parent
                target: null
                interactive: root.shown
                onClicked: ShellState.toggleModal("notifications")
            }
        }
    }
}
