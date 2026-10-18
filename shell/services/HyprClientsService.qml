pragma Singleton

import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

// One source of truth for Hyprland client metadata (class/title/geometry
// by window address): HyprlandToplevel.lastIpcObject populates lazily and
// stays empty on unfocused monitors, which left the rail app lists with
// placeholder icons and no names. Refreshes on window lifecycle events
// plus a slow safety poll.
QtObject {
    id: root

    // [{ address, class, title, at, size, workspaceId, monitor }]
    property var clients: []
    // address (without 0x prefix differences) -> client record.
    property var byAddress: ({})
    property bool refreshPending: false

    function refresh(): void {
        if (probe.running) {
            refreshPending = true;
            return;
        }
        probe.running = true;
    }

    function infoFor(address: string): var {
        if (!address)
            return null;

        const key = String(address).replace(/^0x/, "");
        return byAddress[key] ?? null;
    }

    // HyprlandToplevel has no activate(); focus goes through the dispatcher.
    function focus(address: string): void {
        const key = String(address).replace(/^0x/, "");
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ window = "address:0x${key}" })`
            : `focuswindow address:0x${key}`);
    }

    // caelestia's pattern (services/Hypr.qml): Quickshell populates
    // toplevel/workspace lastIpcObject ONLY on explicit refresh calls —
    // without them, unfocused monitors keep empty metadata forever.
    property Connections hyprEvents: Connections {
        target: Hyprland

        function onRawEvent(event: var): void {
            const name = event.name;
            if (name.endsWith("v2"))
                return;

            if (["openwindow", "closewindow", "movewindow"].includes(name)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
                root.refresh();
            } else if (["workspace", "moveworkspace", "focusedmon"].includes(name)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                root.refresh();
            } else if (name.includes("window") || name.includes("group")
                || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(name)) {
                Hyprland.refreshToplevels();
                root.refresh();
            }
        }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshMonitors();
    }

    property Timer safetyPoll: Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    property Process probe: Process {
        id: probe
        command: Delegate.argv("compositor", ["clients", "-j"])
        running: true
        onExited: {
            if (root.refreshPending) {
                root.refreshPending = false;
                root.refresh();
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    const map = {};
                    for (const client of parsed)
                        map[String(client.address).replace(/^0x/, "")] = client;
                    root.clients = parsed;
                    root.byAddress = map;
                } catch (error) {
                    // keep the previous snapshot on a torn read
                }
            }
        }
    }
}
