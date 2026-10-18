pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

QtObject {
    id: root

    // Always a count: a screen that is not yet known counts as not fullscreen.
    readonly property int fullscreenCount: Quickshell.screens
        .filter(screen => fullscreenFor(screen) === true).length

    function workspaceFor(screen: var): var {
        if (!screen)
            return null;
        const monitor = Hyprland.monitorFor(screen);
        if (!monitor)
            return null;

        const special = monitor.lastIpcObject?.specialWorkspace;
        if (special?.id || special?.name)
            return Hyprland.workspaces.values.find(candidate =>
                candidate.id === special.id || candidate.name === special.name) ?? null;
        return monitor.activeWorkspace;
    }

    function fullscreenFor(screen: var): bool {
        const workspace = workspaceFor(screen);
        if (!workspace)
            return false;

        // The client list is populated for every monitor; toplevel IPC objects
        // can stay empty on unfocused outputs. Bit 1 is compositor fullscreen,
        // bit 0 is maximized. Client-only fullscreen is not shell suppression.
        return HyprClientsService.clients.some(client =>
            client.workspace?.id === workspace.id
            && (Number(client.fullscreen ?? 0) & 2) !== 0
            && client.mapped !== false && client.hidden !== true);
    }

    function toggle(): void {
        Quickshell.execDetached(Delegate.argv("compositor", ["repl",
            'hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))']));
    }

    function refresh(): void {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        HyprClientsService.refresh();
    }

    Component.onCompleted: refresh()

    // Special-workspace visibility lives in the monitor IPC payload, not its
    // activeWorkspace property. Both event dialects must refresh that payload.
    property Connections hyprlandEvents: Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (["fullscreen", "workspace", "workspacev2", "activespecial",
                "activespecialv2", "moveworkspace", "moveworkspacev2",
                "movewindow", "movewindowv2", "focusedmon", "monitoradded",
                "monitoraddedv2", "monitorremoved", "configreloaded"].includes(event.name))
                root.refresh();
        }
    }
}
