pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root

    readonly property string revision: Hyprland.toplevels.values
        .map(toplevel => `${toplevel.workspace?.id ?? 0}:${toplevel.lastIpcObject?.fullscreen ?? 0}`)
        .join("|")
    readonly property int fullscreenCount: Quickshell.screens
        .filter(screen => fullscreenFor(screen)).length

    function fullscreenFor(screen: var): bool {
        revision;
        const monitor = Hyprland.monitorFor(screen);
        if (!monitor)
            return false;

        const specialName = monitor.lastIpcObject?.specialWorkspace?.name ?? "";
        const workspace = specialName.length > 0
            ? Hyprland.workspaces.values.find(candidate => candidate.name === specialName)
            : monitor.activeWorkspace;
        return workspace?.toplevels.values.some(toplevel =>
            (toplevel.lastIpcObject?.fullscreen ?? 0) > 0) ?? false;
    }

    // lastIpcObject payloads need an explicit refresh for these events.
    property Connections hyprlandEvents: Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "fullscreen")
                Hyprland.refreshToplevels();
            else if (event.name === "activespecial")
                Hyprland.refreshMonitors();
        }
    }
}
