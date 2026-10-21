import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// The notification menu (04): the searchable history,
// opened from the bell in the top-right corner. Everything about the list
// (search, grouping, the keyboard cursor, the empty state, the unread dot)
// lives in the library; this wires it to the service. The menu opens on the
// Unread view when something is unread, else on All. A plain click on an
// unread row marks it read, so it leaves the bell's count and the Unread
// view and stays in All.
QsmShellComponents.NotificationCenter {
    id: root

    // The pointer is on this menu; the scene keeps the menu open while the
    // bell or the menu is hovered and closes it 180ms after both are left.
    readonly property bool hovered: hoverReader.hovered

    entries: [...NotificationService.live.map(entry => entry.presentationRecord), ...NotificationService.archive]
    // The list scrolls directly on the rollout's band, not on a card.
    fadeColor: Theme.band
    dnd: ShellState.dnd
    // A colour-picker announcement's summary IS the picked hex;
    // the app name that decides this is the one hardcoded
    // name this shell owns and the library must never see.
    swatchFor: entry => entry.appName === ColorPickService.notifyAppName
        && /^#[0-9a-fA-F]{6}$/.test(entry.summary) ? entry.summary : undefined

    function open(): void {
        query = "";
        beginVisit();
        view = unreadCount > 0 ? "unread" : "all";
        focusField();
    }

    onActivated: entry => NotificationService.markRead(entry)
    onDismissRequested: entry => {
        if (entry.notificationId !== undefined)
            NotificationService.dismiss(entry.notificationId);
        else
            NotificationService.removeArchived(entry);
    }
    onActionTriggered: (entry, actionId) => {
        if (entry.notificationId !== undefined)
            NotificationService.invokeAction(entry.notificationId, actionId);
    }
    onHoverChanged: (entry, hovered) => {
        if (entry.notificationId !== undefined)
            NotificationService.setPaused(entry.notificationId, hovered);
    }
    onDndToggled: ShellState.dnd = !ShellState.dnd
    onClearRequested: NotificationService.clearArchive()
    onEscaped: ShellState.closeModal()
    onSelectionClaimed: ShellState.claimKeyboardSelection()

    // Delete is a list command here: the history's rows are the thing being
    // acted on. Tab steps between a row's own actions rather than leaving
    // the field.
    onKeyPressed: event => {
        if (event.key === Qt.Key_Delete) {
            root.removeSelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            root.moveAction(event.modifiers & Qt.ShiftModifier ? -1 : 1);
            event.accepted = true;
        }
        if (event.accepted)
            ShellState.claimKeyboardSelection();
    }

    HoverHandler {
        id: hoverReader
    }
}
