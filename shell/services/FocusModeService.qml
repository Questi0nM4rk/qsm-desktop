pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import qs.state
import qs.theme
// qmllint disable missing-property

// QSM focus is a reversible compositor transformation, not client fullscreen.
// The address is the identity: titles and classes are allowed to change while
// a client remains the same window.
QtObject {
    id: root

    property bool active: false
    property string address: ""
    property var snapshot: null
    property int recoveryAttempts: 0
    readonly property var target: {
        const service = HyprClientsService;
        return address === "" ? null : service["clients"].find(item =>
            root.normalized(item.address) === address && root.matchesSnapshot(item)) ?? null;
    }
    readonly property string targetScreen: target ? monitorNameFor(target.monitor) : ""
    readonly property bool targetPresent: target !== null
        && String(target.address).replace(/^0x/, "") === address
    readonly property bool targetStable: targetPresent && target.workspace?.id === snapshot?.workspaceId
        && String(target.monitor) === String(snapshot?.monitorId)

    // qmllint disable unresolved-type
    property FileView stateFile: FileView {
        id: stateFile
        path: ShellState.qsmStateDir + "/focus.json"
        atomicWrites: true
        printErrors: false
        watchChanges: true
        onLoadFailed: root.recover()
        onAdapterUpdated: writeAdapter()
        property alias focusActive: persisted.active
        property alias focusAddress: persisted.address
        property alias focusSnapshots: persisted.snapshots

        JsonAdapter {
            id: persisted
            property bool active: false
            property string address: ""
            property var snapshots: ({})
        }
    }
    // qmllint enable unresolved-type

    property Timer recoveryTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: root.recover()
    }

    property Timer driftPoll: Timer {
        interval: 500
        repeat: true
        running: root.active
        onTriggered: root.validateTarget()
    }

    property Timer settleTimer: Timer {
        interval: 1200
        repeat: false
    }

    property Process activeWindowProbe: Process {
        id: activeWindowProbe
        command: root.compositor(["activewindow", "-j"])
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.enterFromActive(text)
        }
    }

    function normalized(addressValue: string): string {
        return String(addressValue || "").replace(/^0x/, "");
    }

    function addressSelector(): string {
        return "address:0x" + root.address;
    }

    function matchesSnapshot(candidate: var): bool {
        if (!root.snapshot || String(candidate.class) !== root.snapshot.clientClass)
            return false;
        const pid = Number(root.snapshot.pid ?? 0);
        return pid === 0 || Number(candidate.pid ?? 0) === pid;
    }

    function compositor(args: var): var {
        const delegate = Delegate;
        return delegate["tools"]["compositor"].concat(args);
    }

    function monitorNameFor(monitorId: var): string {
        const monitor = Hyprland.monitors.values.find(item => String(item.id) === String(monitorId));
        return monitor?.name ?? "";
    }

    function screenFor(monitorName: string): var {
        return Quickshell.screens.find(item => item.name === monitorName) ?? null;
    }

    function focusFor(screen: var): bool {
        return root.active && !!screen && root.targetScreen === screen.name
            && FullscreenService.workspaceFor(screen)?.id === root.snapshot?.workspaceId;
    }

    function publishScope(): void {
        ShellState.focusModeScreen = root.active ? root.snapshot?.monitor ?? "" : "";
        ShellState.focusModeWorkspaceId = root.active ? root.snapshot?.workspaceId ?? 0 : 0;
    }

    function floatingViewport(screen: var): var {
        return {
            x: Math.round(screen.x + Theme.frameThickness),
            y: Math.round(screen.y + Theme.frameThickness),
            width: Math.max(1, Math.round(screen.width - Theme.frameThickness * 2)),
            height: Math.max(1, Math.round(screen.height - Theme.frameThickness * 2))
        };
    }

    function persist(): void {
        stateFile.focusActive = root.active;
        stateFile.focusAddress = root.address;
        const snapshots = Object.assign({}, stateFile.focusSnapshots);
        if (root.snapshot && root.address !== "")
            snapshots[root.address] = root.snapshot;
        stateFile.focusSnapshots = snapshots;
        stateFile.writeAdapter();
    }

    function dispatch(args: var): void {
        Quickshell.execDetached(root.compositor(["dispatch"].concat(args)));
    }

    function setTiledMaximized(action: string): void {
        // Hyprland 0.56 dispatches through Lua. `maximized` fills the tiled
        // viewport without asking the client for native fullscreen, and the
        // address selector keeps a later drift exit off another active window.
        const program = "hl.dispatch(hl.dsp.window.fullscreen({ mode = \"maximized\", action = \""
            + action + "\", window = \"" + addressSelector() + "\" }))";
        Quickshell.execDetached(root.compositor(["repl", program]));
    }

    function setRail(screenName: string, collapsed: bool): void {
        if (screenName !== "")
            ShellState.setRailCollapsed(screenName, collapsed);
    }

    function enter(): bool {
        if (root.active || activeWindowProbe.running)
            return false;
        ShellState.closeModal();
        activeWindowProbe.running = true;
        return true;
    }

    function enterFromActive(raw: string): void {
        let client;
        try {
            client = JSON.parse(raw);
        } catch (error) {
            return;
        }
        const addressValue = normalized(client.address);
        const service = HyprClientsService;
        const record = service["clients"].find(item =>
            root.normalized(item.address) === addressValue) ?? null;
        if (!record || addressValue === "" || client.class === "quickshell"
            || Number(record.fullscreen ?? 0) > 0)
            return;

        const monitorId = record.monitor;
        const monitor = monitorNameFor(monitorId);
        if (monitor === "")
            return;
        const workspaceId = record.workspace?.id;
        const saved = {
            address: addressValue,
            monitor: monitor,
            monitorId: monitorId,
            workspaceId: workspaceId,
            floating: record.floating === true,
            fullscreen: Number(record.fullscreen ?? 0),
            clientClass: String(record.class),
            pid: Number(record.pid ?? 0),
            at: record.at ?? [0, 0],
            size: record.size ?? [0, 0]
        };
        const screen = saved.floating ? screenFor(monitor) : null;
        if (saved.floating && !screen)
            return;
        if (saved.floating) {
            const viewport = floatingViewport(screen);
            saved.focusAt = [viewport.x, viewport.y];
            saved.focusSize = [viewport.width, viewport.height];
        }

        root.snapshot = saved;
        root.address = addressValue;
        root.active = true;
        publishScope();
        persist();
        settleTimer.restart();

        if (saved.floating) {
            placeFloating(screen);
        } else {
            setTiledMaximized("set");
        }
    }

    function placeFloating(screen: var): void {
        const viewport = floatingViewport(screen);
        dispatch(["movewindowpixel", "exact", String(viewport.x), String(viewport.y), addressSelector()]);
        dispatch(["resizewindowpixel", "exact", String(viewport.width), String(viewport.height), addressSelector()]);
    }

    function restore(): bool {
        if (!root.snapshot || root.address === "") {
            clear();
            return false;
        }
        const saved = root.snapshot;
        const client = root.target;
        if (client) {
            // A focus transformation that outlives a workspace/monitor move
            // returns the client before its saved geometry is reapplied.
            if (client.workspace?.id !== saved.workspaceId)
                dispatch(["movetoworkspacesilent", String(saved.workspaceId) + "," + addressSelector()]);
            if (String(client.monitor) !== String(saved.monitorId))
                dispatch(["movewindow", "mon:" + saved.monitor + "," + addressSelector()]);

            if (saved.floating) {
                dispatch(["movewindowpixel", "exact", String(saved.at[0]), String(saved.at[1]), addressSelector()]);
                dispatch(["resizewindowpixel", "exact", String(saved.size[0]), String(saved.size[1]), addressSelector()]);
            } else if (Number(client.fullscreen ?? 0) === 1) {
                setTiledMaximized("unset");
            }
        }
        // Snapshots from the old shortcut changed persisted rail state.
        // Current focus presentation is workspace-local and never writes it.
        if (saved.railCollapsed !== undefined)
            setRail(saved.monitor, saved.railCollapsed);
        clear();
        return true;
    }

    function clear(): void {
        root.active = false;
        root.address = "";
        root.snapshot = null;
        root.recoveryAttempts = 0;
        publishScope();
        stateFile.focusActive = false;
        stateFile.focusAddress = "";
        stateFile.writeAdapter();
    }

    function validateTarget(): void {
        if (!root.active)
            return;
        if (settleTimer.running)
            return;
        if (!root.targetPresent || !root.targetStable) {
            restore();
            return;
        }
        const changed = root.snapshot.floating
            ? root.target.floating !== true
                || root.target.at?.[0] !== root.snapshot.focusAt?.[0]
                || root.target.at?.[1] !== root.snapshot.focusAt?.[1]
                || root.target.size?.[0] !== root.snapshot.focusSize?.[0]
                || root.target.size?.[1] !== root.snapshot.focusSize?.[1]
            : Number(root.target.fullscreen ?? 0) === 0;
        if (changed)
            restore();
    }

    function recover(): void {
        if (stateFile.focusActive && stateFile.focusAddress !== "") {
            root.address = normalized(stateFile.focusAddress);
            root.snapshot = stateFile.focusSnapshots[root.address] ?? null;
            root.active = root.snapshot !== null;
            publishScope();
            if (root.active) {
                if (root.targetPresent)
                    root.restore();
                else if (root.recoveryAttempts < 5) {
                    root.recoveryAttempts++;
                    recoveryTimer.restart();
                } else {
                    if (root.snapshot.railCollapsed !== undefined)
                        setRail(root.snapshot.monitor, root.snapshot.railCollapsed);
                    clear();
                }
            } else {
                clear();
            }
        }
    }

    Component.onCompleted: recoveryTimer.start()

    property Connections hyprEvents: Connections {
        target: Hyprland
        function onRawEvent(event: var): void {
            if (root.active && (event.name.includes("window") || event.name.includes("workspace")
                || ["focusedmon", "moveworkspace", "monitor", "monitoradded",
                    "monitorremoved", "configreloaded"].includes(event.name)))
                root.validateTarget();
        }
    }
}
// qmllint enable missing-property
