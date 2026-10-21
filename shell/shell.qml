import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.QsmShell.Style as QsmShellStyle
import qs.input
import qs.screen
import qs.services
import qs.state
import qs.theme

ShellRoot {
    id: root

    Binding {
        target: QsmShellStyle.Style
        property: "backend"
        value: Theme
    }

    // Who is driving. The library cannot see that a key was just pressed and
    // the pointer has not moved since, so the desktop states it once here and
    // every hovering component honours it — instead of each list repeating the
    // same guard and the ones that forgot letting a still pointer steal the
    // selection mid-keystroke.
    Binding {
        target: QsmShellStyle.Interaction
        property: "pointerSelects"
        value: !ShellState.keyboardOwnsSelection
    }

    // ACTIVATION. The shell IS the desktop: there are no environment flags
    // gating the scene, and `qs --path shell` with an empty environment
    // brings up the real thing.
    //
    // The scene instance hosting the currently focused monitor. Looked up by
    // identity against Variants.instances since nothing else keys an
    // EdgeScene by screen. A plain root function, not an IpcHandler one —
    // every function declared inside IpcHandler becomes a public IPC method,
    // and this is an internal lookup `status()` uses, not a command of its own.
    function focusedEdgeScene(): var {
        return edgeSceneVariants.instances.find(instance => instance.modelData === ShellState.focusedScreen);
    }

    // UI forensics walker: serializes an item subtree
    // so an agent can assert real geometry — positions, sizes, colors, radii —
    // instead of estimating them from screenshots. Root functions, not
    // IpcHandler ones, for the same reason as focusedEdgeScene(): only
    // inspect() is a public IPC command; these are its internals.
    function inspectTypeName(item: var): string {
        let name = String(item);
        const paren = name.indexOf("(");
        if (paren !== -1)
            name = name.substring(0, paren);
        // _QMLTYPE_n = named components, _QML_n = anonymous ones.
        const generated = name.search(/_QML(TYPE)?_\d/);
        if (generated !== -1)
            name = name.substring(0, generated);
        if (name.startsWith("QQuick"))
            name = name.substring(6);
        return name;
    }

    // Defaults are omitted from entries (visible:true, opacity:1, z:0) so a
    // full-scene dump stays small enough for one IPC reply.
    function inspectItem(item: var, visibleOnly: bool): var {
        const origin = item.mapToItem(null, 0, 0);
        const entry = {
            "type": inspectTypeName(item),
            "x": Math.round(origin.x * 10) / 10,
            "y": Math.round(origin.y * 10) / 10,
            "w": Math.round(item.width * 10) / 10,
            "h": Math.round(item.height * 10) / 10
        };
        if (item.objectName !== "")
            entry.name = item.objectName;
        if (!item.visible)
            entry.visible = false;
        if (item.opacity < 1)
            entry.opacity = Math.round(item.opacity * 100) / 100;
        if (item.z !== 0)
            entry.z = item.z;
        // Clipping is what turns a hover GROWTH into a shaved edge, and it is
        // invisible in a screenshot until you know which ancestor did it.
        if (item.clip)
            entry.clip = true;
        if (item.scale !== undefined && item.scale !== 1)
            entry.scale = Math.round(item.scale * 1000) / 1000;
        if (item.color !== undefined)
            entry.color = String(item.color);
        if (item.radius !== undefined)
            entry.radius = item.radius;
        if (item.spacing !== undefined)
            entry.spacing = item.spacing;
        // What a StateLayer actually GROWS, and by how much. Without this the
        // clip question ("does the hover response survive its container?") can
        // only be guessed at from the layer's own rect, which is the padded
        // hit area and not the thing that moves.
        // The device pixels per side a layer grows by right now, whether it
        // drives a target or its host applies the number to its own body.
        if (item.hoverScale !== undefined && item.growth !== undefined && item.growth !== 0)
            entry.growthPx = Math.round(item.growth * 1000) / 1000;
        if (item.hoverScale !== undefined && item.target !== undefined && item.target !== null
            && item.target.mapToItem !== undefined) {
            const grown = item.target.mapToItem(null, 0, 0);
            entry.growth = {
                "x": Math.round(grown.x * 10) / 10,
                "y": Math.round(grown.y * 10) / 10,
                "w": Math.round(item.target.width * 10) / 10,
                "h": Math.round(item.target.height * 10) / 10,
                "scale": item.hoverScale
            };
        }
        if (item.text !== undefined) {
            entry.text = String(item.text);
            if (item.font !== undefined)
                entry.fontPx = item.font.pixelSize;
        }
        const children = [];
        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            if (visibleOnly && !child.visible)
                continue;
            children.push(inspectItem(child, visibleOnly));
        }
        if (children.length > 0)
            entry.children = children;
        return entry;
    }

    // Hover-coverage probe. A screenshot cannot tell you WHY a cell does not
    // react to the pointer, and geometry alone cannot either: the failure mode
    // is ordering — content painted after a hover handler sits above it and
    // eats the event (PRIMER's hover law; it cost us the BLE cell). This walks
    // the stack under one point and reports, per item, whether it carries a
    // hover handler and whether that handler is hovered RIGHT NOW.
    function hoverHandlersOf(item: var): var {
        const found = [];
        // Handlers live in `data` alongside visual children; there is no typed
        // accessor for them, so identify by the class name QML prints.
        for (let i = 0; i < item.data.length; i++) {
            const obj = item.data[i];
            const name = String(obj);
            if (name.indexOf("HoverHandler") === -1)
                continue;
            found.push({
                "handler": root.inspectTypeName(obj),
                "hovered": obj.hovered === true,
                "cursorShape": obj.cursorShape === undefined ? null : obj.cursorShape
            });
        }
        return found;
    }

    // Topmost-first stack of every item whose bounds contain the point.
    function probeItem(item: var, x: real, y: real, out: var): void {
        for (let i = item.children.length - 1; i >= 0; i--) {
            const child = item.children[i];
            if (!child.visible)
                continue;
            const local = child.mapFromItem(null, x, y);
            if (local.x < 0 || local.y < 0 || local.x > child.width || local.y > child.height)
                continue;
            const handlers = root.hoverHandlersOf(child);
            out.push({
                "type": root.inspectTypeName(child),
                "x": Math.round(child.mapToItem(null, 0, 0).x * 10) / 10,
                "y": Math.round(child.mapToItem(null, 0, 0).y * 10) / 10,
                "w": Math.round(child.width * 10) / 10,
                "h": Math.round(child.height * 10) / 10,
                "handlers": handlers,
                "blocksBelow": handlers.length > 0
            });
            root.probeItem(child, x, y, out);
        }
    }

    settings.watchFiles: true

    // Every keyboard route into the shell (09). Hyprland binds these by name;
    // see docs/hyprland-binds.conf.
    Shortcuts {}

    Variants {
        model: Quickshell.screens

        delegate: Component { WallpaperWindow {} }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component { FrameExclusions {} }
    }

    // Session backdrop must map BEFORE the EdgeScenes: same wlr layer, and
    // in-layer stacking follows map order — the scene (buttons) stays above.
    Variants {
        model: Quickshell.screens

        delegate: Component { SessionBackdrop {} }
    }

    // Single-scene architecture (adopt-single-scene-rendering): the whole
    // surface composition — frame band, rail + popouts, OSD, notification
    // popups, top panel, launcher and session — renders as items inside one
    // EdgeScene per monitor. The previous per-window path is gone.
    Variants {
        id: edgeSceneVariants
        model: Quickshell.screens

        delegate: Component { EdgeScene {} }
    }

    IpcHandler {
        target: "qsm"

        function toggle(modal: string): bool {
            return ShellState.toggleModal(modal);
        }

        function close(): void {
            ShellState.closeModal();
        }

        // Test-only equivalent of Super+A. It deliberately enters through the
        // same ShellState launcher-seed pathway as Shortcuts.qml; it adds no
        // second user-facing route.
        function quickControlsTest(): bool {
            return ShellState.toggleLauncher(">action ");
        }

        function commandCentreEnterTest(): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherEnterDetail() : false;
        }

        function commandCentreEnterControlTest(id: string): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherEnterDetailFor(id) : false;
        }

        function commandCentreActivateControlTest(id: string): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherActivateControlFor(id) : false;
        }

        function commandCentreSetQueryTest(query: string): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherSetQueryForTest(query) : false;
        }

        function commandCentreBackTest(): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherBack() : false;
        }

        function commandCentreActivateDetailTest(id: string): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherActivateDetailFor(id) : false;
        }

        // Activate the first result whose confirmId starts with `prefix`.
        // Proves arm-then-fire for bluetooth-forget (forget-<address>) where
        // the exact address is runtime-specific.
        function commandCentreActivateConfirmPrefixTest(prefix: string): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherActivateConfirmPrefix(prefix) : false;
        }

        // Non-destructive device info seam: returns label, default status,
        // and data-presence for a device row at the given index in the
        // current detail view. Proves object-backed device rows exist and
        // carry their data without changing real defaults in smoke.
        function commandCentreDeviceInfoTest(kind: string, index: int): string {
            const scene = root.focusedEdgeScene();
            return scene ? scene.launcherDeviceInfoTest(kind, index) : "{}";
        }

        // Panel tab stepping seam: same stepTab the Left/Right keys call.
        function panelTabStepTest(delta: int): bool {
            const scene = root.focusedEdgeScene();
            return scene ? scene.panelTabStepTest(delta) : false;
        }

        // Lock through the SAME seam the session surface's Lock button uses,
        // so the keybind and the button are one implementation with two
        // accelerators rather than two paths (09 one-path law).
        //
        // Deliberately lock ONLY, not a general run(role): the destructive
        // roles confirm inside the session surface (08 arm-then-fire), and an
        // IPC that fired them straight would be a way around that confirm.
        function lock(): bool {
            return Delegate.open("lock");
        }

        function themeToggle(): bool {
            // External Qt/GTK material is session-static deep-night. Do not
            // imply mountain-dusk parity until its bridge writer exists.
            Theme.apply(Theme.dark ? "mountain-dusk" : "deep-night");
            return Theme.dark;
        }

        function theme(themeId: string): bool {
            Theme.apply(themeId);
            return Theme.current === themeId;
        }

        function focusToggleTest(): bool {
            return FocusModeService.active ? FocusModeService.restore() : FocusModeService.enter();
        }

        function focusEnterTest(): bool {
            return FocusModeService.enter();
        }

        function focusRestoreTest(): bool {
            return FocusModeService.restore();
        }

        function focusExitTest(): bool {
            return FocusModeService.active ? FocusModeService.restore() : false;
        }

        function focusRecoverTest(): bool {
            FocusModeService.recover();
            return true;
        }

        function focusTargetLossTest(): bool {
            if (!FocusModeService.active)
                return false;
            FocusModeService.validateTarget();
            return !FocusModeService.active;
        }

        // Super+D (09): the panel on its last-used tab.
        function panelLastTab(): bool {
            return ShellState.togglePanel("");
        }

        // Keep value/muted in the public IPC signature; services own the state.
        function osd(kind: string, value: real, muted: bool): bool {
            if (kind === "brightness")
                BrightnessService.refresh();
            return OsdState.show(kind, ShellState.focusedScreen);
        }

        // Synthetic entries for the smoke suite and for driving the surfaces
        // by hand. Real notifications arrive over the bus the service now
        // owns (NotificationService.server); these enter the SAME model.
        function notifyTest(summary: string, body: string, urgency: string, timeoutMs: int): int {
            return NotificationService.post("qsm-test", summary, body, urgency, timeoutMs, 0, false);
        }

        function notifyPost(summary: string, body: string, urgency: string,
            timeoutMs: int, replaceId: int, isTransient: bool): int {
            return NotificationService.post("qsm-test", summary, body, urgency,
                timeoutMs, replaceId, isTransient);
        }

        function notifySanitize(raw: string): string {
            return NotificationService.sanitize(raw);
        }

        function notifyDnd(enabled: bool): bool {
            ShellState.dnd = enabled;
            return ShellState.dnd;
        }

        function notifyClearArchive(): bool {
            NotificationService.clearArchive();
            return true;
        }

        function notifyDismiss(notificationId: int): bool {
            return NotificationService.dismiss(notificationId);
        }

        function notifyPause(notificationId: int, paused: bool): void {
            NotificationService.setPaused(notificationId, paused);
        }

        function railToggle(): bool {
            return ShellState.toggleRail(ShellState.focusedScreen?.name ?? "");
        }

        // Test-only seam: drives the focused
        // monitor's in-scene PopoutController through its real show/dismiss
        // path so the suite can assert the rollout mask rect joining and
        // leaving the live mask, matching the notifyTest convention.
        function railPopoutTest(open: bool): bool {
            const scene = root.focusedEdgeScene();
            if (!scene)
                return false;

            scene.testTogglePopout(open);
            return true;
        }

        // railPopoutTest's generalisation (EdgeScene.testShowPopout): any
        // popout TIER on either host, pointer-free — every surface was
        // otherwise reachable only by a human hovering the rail, making
        // "measure that tier" a request to a human. kind is a BarPopouts
        // tier name ("sound", "network", "actions", "nightlight",
        // "colorpick", ...); level 1 is the rail host, level 2 the nested
        // quick-actions detail host. New IPC function — needs a shell
        // restart like any other.
        // `screen` matters, and learning that cost a diagnosis. This defaulted
        // to the FOCUSED scene, and on a monitor holding a fullscreen client
        // spec/09 suppresses the entire scene -- so the controller reported the
        // tier open while nothing rendered and nothing was hit-testable
        // (hitProbe found no Rail, no BarPopouts, no StateLayer at any point
        // there). Measuring a surface therefore has to name the output it wants,
        // not inherit whichever one happens to be focused. "" keeps the old
        // focused-scene behaviour.
        function popoutTest(kind: string, level: int, open: bool, screen: string): bool {
            const scene = screen === ""
                ? root.focusedEdgeScene()
                : edgeSceneVariants.instances.find(instance => instance.modelData.name === screen);
            if (!scene)
                return false;

            return scene.testShowPopout(kind, level, open);
        }

        // Invoke the colour pick directly, bypassing the UI entirely.
        //
        // WHY this seam exists: from outside there is no way to tell "the
        // swatch's click never reaches pick()" from "pick() runs and
        // hyprpicker returns nothing". Both present identically: pickLast
        // stays empty.
        function pickTest(): bool {
            ColorPickService.pick();
            return ColorPickService.busy;
        }

        // Test seam: toggles the per-edge test Rollouts on the
        // focused monitor (EdgeScene.testToggleRollout).
        function rolloutTest(edge: string, open: bool): bool {
            const scene = root.focusedEdgeScene();
            if (!scene)
                return false;

            return scene.testToggleRollout(edge, open);
        }

        // UI forensics dump: the live item tree of one
        // monitor's scene as JSON, scene-mapped coordinates. screen "" =
        // focused monitor; visibleOnly prunes hidden subtrees. New IPC
        // function — needs a shell restart like any other.
        function inspect(screen: string, visibleOnly: bool): string {
            const scene = screen === ""
                ? root.focusedEdgeScene()
                : edgeSceneVariants.instances.find(instance => instance.modelData.name === screen);
            if (!scene)
                return JSON.stringify({ "error": "no scene for screen '" + screen + "'" });

            return JSON.stringify({
                "screen": scene.modelData.name,
                "width": scene.width,
                "height": scene.height,
                "tree": root.inspectItem(scene.contentItem, visibleOnly)
            });
        }

        // Which items sit under (x, y) on `screen`, topmost first, and which of
        // them can actually receive hover. Coordinates are LOGICAL scene pixels
        // — the same ones inspect() reports, not device pixels.
        //
        // Reading it: the first entry with a non-empty `handlers` list is what
        // the pointer would reach. If that entry is not the cell you expected,
        // something is painted above the cell's hover surface — the exact fault
        // that leaves a cell with no tint, no cursor and no rollout.
        function hitProbe(screen: string, x: real, y: real): string {
            const scene = screen === ""
                ? root.focusedEdgeScene()
                : edgeSceneVariants.instances.find(instance => instance.modelData.name === screen);
            if (!scene)
                return JSON.stringify({ "error": "no scene for screen '" + screen + "'" });

            const stack = [];
            root.probeItem(scene.contentItem, x, y, stack);
            const withHandlers = stack.filter(entry => entry.handlers.length > 0);
            return JSON.stringify({
                "screen": scene.modelData.name,
                "at": { "x": x, "y": y },
                // HoverHandlers do not consume, so every one of these receives
                // the hover: topmost is the outermost catcher (a peek strip, a
                // scene-wide zone), deepest is the specific cell. A cell that
                // should react and is ABSENT from this list is the bug.
                "topmostHandler": withHandlers[0]?.type ?? null,
                "deepestHandler": withHandlers[withHandlers.length - 1]?.type ?? null,
                "stack": stack
            });
        }

        // Motion trace over the bulge registry (EdgeScene.startTrace): records
        // one silhouette's geometry once per frame for durationMs so a reveal
        // can be READ as numbers — duration, overshoot, settle — instead of
        // watched; sub-500ms curves are invisible to screenshots and to single
        // inspect() snapshots. id is a bulge registry key ("bar-popout",
        // "bar-action-popout", a Rollout id, ...); status()'s sceneBulgeDump
        // lists what is live right now. New IPC function — needs a shell
        // restart like any other.
        function trace(id: string, durationMs: int): bool {
            const scene = root.focusedEdgeScene();
            if (!scene)
                return false;

            return scene.startTrace(id, durationMs);
        }

        function traceResult(): string {
            const scene = root.focusedEdgeScene();
            if (!scene)
                return JSON.stringify({ "error": "no focused scene" });

            return JSON.stringify(scene.traceResult());
        }

        function status(): string {
            const scene = root.focusedEdgeScene();
            return JSON.stringify({
                // The shell's own pid: `scripts/notification-takeover` has to
                // know whether the bus name landed on THIS instance, and the
                // process cmdline does not say which config a `qs` serves.
                "pid": Quickshell.processId,
                "modal": ShellState.modal,
                "panelTab": ShellState.panelTab,
                "screen": ShellState.focusedScreen?.name ?? "",
                "screenCount": Quickshell.screens.length,
                "workspaceCount": Hyprland.workspaces.values.length,
                "applicationCount": DesktopEntries.applications.values.length,
                "dark": Theme.dark,
                "preview": false,
                "launcherSeed": ShellState.launcherSeed,
                "launcherDetail": scene ? scene.launcherDetailId : "",
                 "launcherQuery": scene ? scene.launcherQuery : "",
                 "launcherCursor": scene ? scene.launcherCursor : -1,
                 "launcherRestoredParentActionId": scene ? scene.launcherRestoredParentActionId : "",
                 "launcherConfirm": scene ? scene.launcherConfirmId : "",
                 "launcherResultLabels": scene ? scene.launcherResultLabels : [],
                 "wifiEnabled": NetworkService.wifiEnabled,
                 "vpnAvailable": NetworkService.vpnAvailable,
                 "vpnActive": NetworkService.vpnActive,
                "sceneRailMaskWidth": scene ? scene.railMaskRect.width : 0,
                "sceneRailMaskHeight": scene ? scene.railMaskRect.height : 0,
                "sceneRailPeeking": scene ? scene.railPeeking : false,
                "sceneRolloutRects": scene ? scene.rolloutMaskRects.length : 0,
                "sceneInputIds": scene ? scene.rolloutMaskIds : [],
                "sceneBulges": scene ? scene.bulgeEntries.length : 0,
                "sceneBulgeDump": scene ? scene.bulgeDump : [],
                "sceneFullscreenCapsules": scene ? scene.fullscreenCapsuleEntries.length : 0,
                "sceneFullscreenCapsuleIds": scene ? Object.keys(scene.fullscreenCapsules) : [],
                "fullscreenSdf": scene ? scene.fullscreen : false,
                // Colour picker outcome, so "did the pick land" is answerable
                // without a capture or a hover.
                "pickBusy": ColorPickService.busy,
                "pickLast": ColorPickService.lastColor,
                "pickHistory": ColorPickService.history.length,
                "pickEditorAvailable": ColorPickService.editorAvailable,
                "popout": scene ? scene.openPopoutKind : "",
                "subPopout": scene ? scene.openSubPopoutKind : "",
                "popoutSettledRight": scene ? scene.popoutSettledRight : 0,
                "subPopoutOriginX": scene ? scene.subPopoutOriginX : 0,
                "subPopoutTop": scene ? scene.subPopoutTop : 0,
                "subPopoutHeight": scene ? scene.subPopoutHeight : 0,
                "popoutInRegion": scene ? scene.popoutInRegion : false,
                "subPopoutInRegion": scene ? scene.subPopoutInRegion : false,
                "fullscreenScreens": FullscreenService.fullscreenCount,
                "workspacePresentation": Quickshell.screens.map(screen => ({
                    screen: screen.name,
                    workspaceId: FullscreenService.workspaceFor(screen)?.id ?? null,
                    fullscreen: FullscreenService.fullscreenFor(screen),
                    focusMode: FocusModeService.focusFor(screen)
                })),
                "osdKind": OsdState.kind,
                "osdVisible": OsdState.visible,
                "notificationCount": NotificationService.live.length,
                "popupCount": NotificationService.popups.length,
                "archiveCount": NotificationService.archive.length,
                "dnd": ShellState.dnd,
                "awake": AwakeService.awake,
                "nightLight": NightLightService.active,
                "updates": UpdateService.count,
                "railCollapsed": ShellState.isRailCollapsed(ShellState.focusedScreen?.name ?? ""),
                "focusMode": FocusModeService.active,
                "focusAddress": FocusModeService.address,
                "focusSnapshot": FocusModeService.snapshot
            });
        }
    }

}
