import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// Notification center (04/06): feeds the library's history list the merged
// live+archive stream and wires DND, Clear, dismiss and action-invoke to
// the notification service. Everything about the list itself (search,
// grouping, the keyboard cursor, the empty state) lives in the library now.
QsmShellComponents.NotificationCenter {
    id: root

    entries: [...NotificationService.live.map(entry => entry.presentationRecord), ...NotificationService.archive]
    // The feed scrolls directly on the panel rollout's shader silhouette, not
    // on a card, so its fade has to reach the band fill. The library cannot
    // know that and now asks.
    fadeColor: Theme.bandFill
    dnd: ShellState.dnd
    // A colour-picker announcement's summary IS the picked hex (owner
    // 2026-08-25); the app name that decides this is the one hardcoded
    // name this shell owns and the library must never see.
    swatchFor: entry => entry.appName === ColorPickService.notifyAppName
        && /^#[0-9a-fA-F]{6}$/.test(entry.summary) ? entry.summary : undefined

    // PanelSurface initially owns focus for tab navigation. The notification
    // tab is a typing surface, so claim it after this Loader-created tab settles.
    Component.onCompleted: Qt.callLater(root.focusField)

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

    // Delete is a list command here: the history's rows are the thing
    // being acted on, and dismissing one is what this tab is for. Tab
    // steps between a row's own actions rather than leaving the field.
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
}
